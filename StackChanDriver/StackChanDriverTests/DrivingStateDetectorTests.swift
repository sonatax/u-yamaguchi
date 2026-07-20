import Foundation
import Testing
@testable import StackChanDriver

@Suite("Driving state detector")
@MainActor
struct DrivingStateDetectorTests {
    @Test("一定速度の継続で運転開始になる")
    func detectsDrivingStart() {
        var configuration = DrivingDetectionConfiguration.production
        configuration.drivingStartConfirmation = 2
        var detector = DrivingStateDetector(configuration: configuration)
        let start = Date(timeIntervalSince1970: 1_000)

        #expect(detector.process(location: sample(at: start, speed: 3), motionPeakG: 0).isEmpty)
        let events = detector.process(
            location: sample(at: start.addingTimeInterval(2), speed: 3),
            motionPeakG: 0
        )

        #expect(events.map(\.event) == [.drivingStarted])
        #expect(events.first?.level == .low)
        #expect(detector.phase == .driving)
    }

    @Test("速度低下と加速度ピークから急ブレーキを判定する")
    func detectsSuddenBrake() {
        var configuration = DrivingDetectionConfiguration.production
        configuration.drivingStartConfirmation = 0
        var detector = DrivingStateDetector(configuration: configuration)
        let start = Date(timeIntervalSince1970: 2_000)

        _ = detector.process(location: sample(at: start, speed: 10), motionPeakG: 0)
        let events = detector.process(
            location: sample(at: start.addingTimeInterval(1), speed: 6),
            motionPeakG: 0.3
        )

        #expect(events.map(\.event) == [.suddenBrake])
        #expect(events.first?.level == .medium)
    }

    @Test("加速度ピークがない速度変動は急ブレーキにしない")
    func ignoresSpeedNoiseWithoutMotion() {
        var configuration = DrivingDetectionConfiguration.production
        configuration.drivingStartConfirmation = 0
        var detector = DrivingStateDetector(configuration: configuration)
        let start = Date(timeIntervalSince1970: 3_000)

        _ = detector.process(location: sample(at: start, speed: 10), motionPeakG: 0)
        let events = detector.process(
            location: sample(at: start.addingTimeInterval(1), speed: 5),
            motionPeakG: 0.01
        )

        #expect(!events.contains(where: { $0.event == .suddenBrake }))
    }

    @Test("長時間運転の警告レベルが段階的に上がる")
    func escalatesLongDriveLevel() {
        var configuration = DrivingDetectionConfiguration.production
        configuration.drivingStartConfirmation = 0
        configuration.longDriveLow = 2
        configuration.longDriveMedium = 4
        configuration.longDriveHigh = 6
        var detector = DrivingStateDetector(configuration: configuration)
        let start = Date(timeIntervalSince1970: 4_000)

        _ = detector.process(location: sample(at: start, speed: 10), motionPeakG: 0)
        let lowEvents = detector.process(
            location: sample(at: start.addingTimeInterval(2), speed: 10),
            motionPeakG: 0
        )
        let mediumEvents = detector.process(
            location: sample(at: start.addingTimeInterval(4), speed: 10),
            motionPeakG: 0
        )

        #expect(lowEvents.first(where: { $0.event == .longDrive })?.level == .low)
        #expect(mediumEvents.first(where: { $0.event == .longDrive })?.level == .medium)
    }

    @Test("停止の継続で運転終了になる")
    func detectsDrivingFinish() {
        var configuration = DrivingDetectionConfiguration.production
        configuration.drivingStartConfirmation = 0
        configuration.drivingFinishConfirmation = 3
        var detector = DrivingStateDetector(configuration: configuration)
        let start = Date(timeIntervalSince1970: 5_000)

        _ = detector.process(location: sample(at: start, speed: 5), motionPeakG: 0)
        _ = detector.process(
            location: sample(at: start.addingTimeInterval(1), speed: 0),
            motionPeakG: 0
        )
        let events = detector.process(
            location: sample(at: start.addingTimeInterval(4), speed: 0),
            motionPeakG: 0
        )

        #expect(events.map(\.event) == [.drivingFinished])
        #expect(detector.phase == .idle)
    }

    private func sample(at date: Date, speed: Double) -> LocationSensorSample {
        LocationSensorSample(
            timestamp: date,
            speedMetersPerSecond: speed,
            horizontalAccuracyMeters: 5,
            speedAccuracyMetersPerSecond: 0.5
        )
    }
}
