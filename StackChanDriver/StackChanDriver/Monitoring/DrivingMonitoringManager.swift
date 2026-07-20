import Combine
import CoreLocation
import Foundation

@MainActor
final class DrivingMonitoringManager: ObservableObject {
    @Published private(set) var isMonitoring = false
    @Published private(set) var sensorState: MonitoringSensorState = .stopped
    @Published private(set) var drivingPhase: DrivingPhase = .idle
    @Published private(set) var currentSpeedKilometersPerHour = 0.0
    @Published private(set) var currentAccelerationG = 0.0
    @Published private(set) var drivingDuration: TimeInterval = 0
    @Published private(set) var lastDetectedEvent = "未検出"
    @Published private(set) var lastAutomaticSendResult = "—"
    @Published private(set) var errorMessage: String?
    @Published private(set) var isAutomaticTransmissionActive = false

    private let motionSensor: any MotionSensorProviding
    private let locationSensor: any LocationSensorProviding
    private let transmissionCoordinator: EventTransmissionCoordinator
    private var detector: DrivingStateDetector
    private var motionPeakG = 0.0
    private var durationTask: Task<Void, Never>?
    private var transmissionTask: Task<Void, Never>?
    private var pendingEvents: [DetectedDrivingEvent] = []

    init(
        bleManager: StackChanBLEManager,
        motionSensor: (any MotionSensorProviding)? = nil,
        locationSensor: (any LocationSensorProviding)? = nil,
        detector: DrivingStateDetector? = nil
    ) {
        self.motionSensor = motionSensor ?? MotionSensorService()
        self.locationSensor = locationSensor ?? LocationSensorService()
        self.detector = detector ?? DrivingStateDetector()
        transmissionCoordinator = EventTransmissionCoordinator(bleManager: bleManager)
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        detector.reset()
        transmissionCoordinator.reset()
        motionPeakG = 0
        drivingDuration = 0
        currentSpeedKilometersPerHour = 0
        currentAccelerationG = 0
        lastDetectedEvent = "未検出"
        lastAutomaticSendResult = "—"
        errorMessage = nil
        sensorState = .preparing

        do {
            try motionSensor.start(
                onSample: { [weak self] sample in
                    self?.handleMotion(sample)
                },
                onError: { [weak self] error in
                    self?.handleSensorError(error)
                }
            )
            try locationSensor.start(
                onSample: { [weak self] sample in
                    self?.handleLocation(sample)
                },
                onReady: { [weak self] in
                    self?.markMonitoringReady()
                },
                onError: { [weak self] error in
                    self?.handleSensorError(error)
                }
            )

            isMonitoring = true
            startDurationUpdates()
            if locationSensor.authorizationStatus == .authorizedAlways ||
                locationSensor.authorizationStatus == .authorizedWhenInUse {
                markMonitoringReady()
            }
            print("[Monitoring] Started")
        } catch {
            stopSensors()
            let sensorError = error as? SensorServiceError ?? .locationUpdateFailed(error.localizedDescription)
            sensorState = .failed(sensorError.localizedDescription)
            errorMessage = sensorError.localizedDescription
        }
    }

    func stopMonitoring() {
        guard isMonitoring || sensorState == .preparing else { return }

        if let finishEvent = detector.stopMonitoring(at: Date()) {
            enqueue([finishEvent])
        }
        stopSensors()
        isMonitoring = false
        sensorState = .stopped
        drivingPhase = .idle
        drivingDuration = 0
        print("[Monitoring] Stopped")
    }

    private func handleMotion(_ sample: MotionSensorSample) {
        guard isMonitoring else { return }
        currentAccelerationG = sample.magnitudeG
        motionPeakG = max(motionPeakG, sample.magnitudeG)
    }

    private func handleLocation(_ sample: LocationSensorSample) {
        guard isMonitoring else { return }

        currentSpeedKilometersPerHour = sample.speedKilometersPerHour
        let events = detector.process(location: sample, motionPeakG: motionPeakG)
        motionPeakG = 0
        drivingPhase = detector.phase
        drivingDuration = detector.drivingDuration(at: sample.timestamp)
        enqueue(events)
    }

    private func enqueue(_ events: [DetectedDrivingEvent]) {
        guard !events.isEmpty else { return }
        for event in events {
            lastDetectedEvent = event.displayName
            print("[Monitoring] Detected \(event.displayName)")
            pendingEvents.append(event)
        }
        processTransmissionQueueIfNeeded()
    }

    private func processTransmissionQueueIfNeeded() {
        guard transmissionTask == nil else { return }

        isAutomaticTransmissionActive = true
        transmissionTask = Task { [weak self] in
            guard let self else { return }
            while !self.pendingEvents.isEmpty {
                let event = self.pendingEvents.removeFirst()
                let outcome = await self.transmissionCoordinator.submit(event)
                switch outcome {
                case .sent:
                    self.lastAutomaticSendResult = "成功: \(event.displayName)"
                case .suppressed:
                    self.lastAutomaticSendResult = "重複抑制: \(event.displayName)"
                case let .failed(message):
                    self.lastAutomaticSendResult = "失敗: \(event.displayName)"
                    self.errorMessage = message
                }
            }
            self.transmissionTask = nil
            self.isAutomaticTransmissionActive = false
        }
    }

    private func markMonitoringReady() {
        guard isMonitoring || sensorState == .preparing else { return }
        sensorState = .monitoring
    }

    private func handleSensorError(_ error: SensorServiceError) {
        errorMessage = error.localizedDescription
        sensorState = .failed(error.localizedDescription)
        isMonitoring = false
        stopSensors()
    }

    private func startDurationUpdates() {
        durationTask?.cancel()
        durationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.drivingDuration = self.detector.drivingDuration(at: Date())
            }
        }
    }

    private func stopSensors() {
        durationTask?.cancel()
        durationTask = nil
        motionSensor.stop()
        locationSensor.stop()
    }
}
