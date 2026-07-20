import Foundation

enum AutomaticTransmissionOutcome: Sendable {
    case sent
    case suppressed
    case failed(String)
}

@MainActor
final class EventTransmissionCoordinator {
    private let bleManager: StackChanBLEManager
    private var policy: EventTransmissionPolicy

    init(
        bleManager: StackChanBLEManager,
        policy: EventTransmissionPolicy? = nil
    ) {
        self.bleManager = bleManager
        self.policy = policy ?? EventTransmissionPolicy()
    }

    func submit(_ decision: DetectedDrivingEvent) async -> AutomaticTransmissionOutcome {
        guard policy.shouldSend(decision) else {
            print("[Monitoring] Suppressed duplicate event=\(decision.event.displayName)")
            return .suppressed
        }

        do {
            try await bleManager.send(event: decision.event, level: decision.level)
            policy.recordSent(decision)
            return .sent
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func reset() {
        policy.reset()
    }
}
