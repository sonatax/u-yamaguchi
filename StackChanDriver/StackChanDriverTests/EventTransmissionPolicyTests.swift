import Foundation
import Testing
@testable import StackChanDriver

@Suite("Event transmission policy")
struct EventTransmissionPolicyTests {
    @Test("同一イベントの連続送信を抑制する")
    func suppressesDuplicateEvent() {
        var policy = EventTransmissionPolicy(duplicateCooldown: 15)
        let start = Date(timeIntervalSince1970: 10_000)
        let first = DetectedDrivingEvent(event: .suddenBrake, level: .low, detectedAt: start)
        let duplicate = DetectedDrivingEvent(
            event: .suddenBrake,
            level: .low,
            detectedAt: start.addingTimeInterval(5)
        )

        #expect(policy.shouldSend(first))
        policy.recordSent(first)
        #expect(!policy.shouldSend(duplicate))
    }

    @Test("警告レベル上昇はクールダウン中でも送信する")
    func allowsEscalation() {
        var policy = EventTransmissionPolicy(duplicateCooldown: 15)
        let start = Date(timeIntervalSince1970: 11_000)
        let low = DetectedDrivingEvent(event: .longDrive, level: .low, detectedAt: start)
        let medium = DetectedDrivingEvent(
            event: .longDrive,
            level: .medium,
            detectedAt: start.addingTimeInterval(1)
        )

        policy.recordSent(low)
        #expect(policy.shouldSend(medium))
    }

    @Test("リセットは状態回復ごとに一度だけ送信する")
    func sendsResetOnce() {
        var policy = EventTransmissionPolicy()
        let date = Date(timeIntervalSince1970: 12_000)
        let alert = DetectedDrivingEvent(event: .suddenBrake, level: .high, detectedAt: date)
        let reset = DetectedDrivingEvent(
            event: .reset,
            level: .clear,
            detectedAt: date.addingTimeInterval(10)
        )

        policy.recordSent(alert)
        #expect(policy.shouldSend(reset))
        policy.recordSent(reset)
        #expect(!policy.shouldSend(reset))
    }
}
