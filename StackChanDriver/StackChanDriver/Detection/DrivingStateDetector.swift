import Foundation

struct DrivingDetectionConfiguration: Equatable, Sendable {
    var drivingStartSpeedMetersPerSecond = 2.8
    var drivingStartConfirmation: TimeInterval = 5
    var drivingFinishSpeedMetersPerSecond = 0.8
    var drivingFinishConfirmation: TimeInterval = 120

    var minimumSuddenBrakeSpeedMetersPerSecond = 5.0
    var minimumMotionPeakG = 0.12
    var suddenBrakeLowMetersPerSecondSquared = 2.5
    var suddenBrakeMediumMetersPerSecondSquared = 3.5
    var suddenBrakeHighMetersPerSecondSquared = 5.0
    var suddenBrakeCooldown: TimeInterval = 15
    var suddenBrakeClearDelay: TimeInterval = 8

    var longDriveLow: TimeInterval = 90 * 60
    var longDriveMedium: TimeInterval = 120 * 60
    var longDriveHigh: TimeInterval = 180 * 60

    var maximumHorizontalAccuracyMeters = 50.0
    var maximumSpeedAccuracyMetersPerSecond = 4.0
    var maximumLocationInterval: TimeInterval = 5

    static let production = DrivingDetectionConfiguration()
}

struct DrivingStateDetector: Sendable {
    private(set) var phase: DrivingPhase = .idle
    private(set) var drivingStartedAt: Date?

    private let configuration: DrivingDetectionConfiguration
    private var startCandidateAt: Date?
    private var stopCandidateAt: Date?
    private var previousLocation: LocationSensorSample?
    private var lastSuddenBrakeAt: Date?
    private var suddenBrakeClearAt: Date?
    private var sentLongDriveLevel: AlertLevel?

    init(configuration: DrivingDetectionConfiguration = .production) {
        self.configuration = configuration
    }

    mutating func reset() {
        phase = .idle
        drivingStartedAt = nil
        startCandidateAt = nil
        stopCandidateAt = nil
        previousLocation = nil
        lastSuddenBrakeAt = nil
        suddenBrakeClearAt = nil
        sentLongDriveLevel = nil
    }

    mutating func process(
        location sample: LocationSensorSample,
        motionPeakG: Double
    ) -> [DetectedDrivingEvent] {
        guard isUsable(sample) else { return [] }

        var events: [DetectedDrivingEvent] = []

        switch phase {
        case .idle, .confirmingStart:
            processStartCandidate(sample, events: &events)

        case .driving, .confirmingStop:
            processDriving(sample, motionPeakG: motionPeakG, events: &events)
        }

        previousLocation = sample
        return events
    }

    mutating func stopMonitoring(at date: Date) -> DetectedDrivingEvent? {
        guard phase == .driving || phase == .confirmingStop else {
            reset()
            return nil
        }

        let event = DetectedDrivingEvent(
            event: .drivingFinished,
            level: .clear,
            detectedAt: date
        )
        reset()
        return event
    }

    func drivingDuration(at date: Date) -> TimeInterval {
        guard let drivingStartedAt else { return 0 }
        return max(0, date.timeIntervalSince(drivingStartedAt))
    }

    private func isUsable(_ sample: LocationSensorSample) -> Bool {
        sample.horizontalAccuracyMeters >= 0 &&
        sample.horizontalAccuracyMeters <= configuration.maximumHorizontalAccuracyMeters &&
        (
            sample.speedAccuracyMetersPerSecond < 0 ||
            sample.speedAccuracyMetersPerSecond <= configuration.maximumSpeedAccuracyMetersPerSecond
        )
    }

    private mutating func processStartCandidate(
        _ sample: LocationSensorSample,
        events: inout [DetectedDrivingEvent]
    ) {
        guard sample.speedMetersPerSecond >= configuration.drivingStartSpeedMetersPerSecond else {
            phase = .idle
            startCandidateAt = nil
            return
        }

        if startCandidateAt == nil {
            startCandidateAt = sample.timestamp
            phase = .confirmingStart
        }

        guard let startCandidateAt,
              sample.timestamp.timeIntervalSince(startCandidateAt) >= configuration.drivingStartConfirmation else {
            return
        }

        phase = .driving
        drivingStartedAt = startCandidateAt
        stopCandidateAt = nil
        events.append(
            DetectedDrivingEvent(
                event: .drivingStarted,
                level: .low,
                detectedAt: sample.timestamp
            )
        )
    }

    private mutating func processDriving(
        _ sample: LocationSensorSample,
        motionPeakG: Double,
        events: inout [DetectedDrivingEvent]
    ) {
        if let suddenBrake = detectSuddenBrake(sample, motionPeakG: motionPeakG) {
            events.append(suddenBrake)
        }

        if let longDrive = detectLongDrive(at: sample.timestamp) {
            events.append(longDrive)
        }

        if let suddenBrakeClearAt,
           sample.timestamp >= suddenBrakeClearAt {
            events.append(
                DetectedDrivingEvent(
                    event: .reset,
                    level: .clear,
                    detectedAt: sample.timestamp
                )
            )
            self.suddenBrakeClearAt = nil
        }

        guard sample.speedMetersPerSecond <= configuration.drivingFinishSpeedMetersPerSecond else {
            phase = .driving
            stopCandidateAt = nil
            return
        }

        if stopCandidateAt == nil {
            stopCandidateAt = sample.timestamp
            phase = .confirmingStop
        }

        guard let stopCandidateAt,
              sample.timestamp.timeIntervalSince(stopCandidateAt) >= configuration.drivingFinishConfirmation else {
            return
        }

        events.removeAll(where: { $0.event == .reset })
        events.append(
            DetectedDrivingEvent(
                event: .drivingFinished,
                level: .clear,
                detectedAt: sample.timestamp
            )
        )
        reset()
    }

    private mutating func detectSuddenBrake(
        _ sample: LocationSensorSample,
        motionPeakG: Double
    ) -> DetectedDrivingEvent? {
        guard let previousLocation else { return nil }

        let interval = sample.timestamp.timeIntervalSince(previousLocation.timestamp)
        guard interval > 0,
              interval <= configuration.maximumLocationInterval,
              previousLocation.speedMetersPerSecond >= configuration.minimumSuddenBrakeSpeedMetersPerSecond,
              motionPeakG >= configuration.minimumMotionPeakG else {
            return nil
        }

        let deceleration = (
            previousLocation.speedMetersPerSecond - sample.speedMetersPerSecond
        ) / interval
        guard deceleration >= configuration.suddenBrakeLowMetersPerSecondSquared else {
            return nil
        }
        if let lastSuddenBrakeAt,
           sample.timestamp.timeIntervalSince(lastSuddenBrakeAt) < configuration.suddenBrakeCooldown {
            return nil
        }

        let level: AlertLevel
        if deceleration >= configuration.suddenBrakeHighMetersPerSecondSquared {
            level = .high
        } else if deceleration >= configuration.suddenBrakeMediumMetersPerSecondSquared {
            level = .medium
        } else {
            level = .low
        }

        lastSuddenBrakeAt = sample.timestamp
        suddenBrakeClearAt = sample.timestamp.addingTimeInterval(configuration.suddenBrakeClearDelay)
        return DetectedDrivingEvent(event: .suddenBrake, level: level, detectedAt: sample.timestamp)
    }

    private mutating func detectLongDrive(at date: Date) -> DetectedDrivingEvent? {
        let duration = drivingDuration(at: date)
        let level: AlertLevel?

        if duration >= configuration.longDriveHigh {
            level = .high
        } else if duration >= configuration.longDriveMedium {
            level = .medium
        } else if duration >= configuration.longDriveLow {
            level = .low
        } else {
            level = nil
        }

        guard let level,
              sentLongDriveLevel == nil || level.rawValue > sentLongDriveLevel!.rawValue else {
            return nil
        }

        sentLongDriveLevel = level
        return DetectedDrivingEvent(event: .longDrive, level: level, detectedAt: date)
    }
}
