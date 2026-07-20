import Foundation

struct EventTransmissionPolicy: Sendable {
    private(set) var lastSentEvent: StackChanEvent?
    private(set) var lastSentLevel: AlertLevel?
    private var lastSentAtByEvent: [StackChanEvent: Date] = [:]

    var duplicateCooldown: TimeInterval

    init(duplicateCooldown: TimeInterval = 15) {
        self.duplicateCooldown = duplicateCooldown
    }

    func shouldSend(_ decision: DetectedDrivingEvent) -> Bool {
        if decision.event == .reset {
            return lastSentEvent != .reset
        }

        if lastSentEvent == decision.event,
           let lastSentLevel,
           decision.level.rawValue > lastSentLevel.rawValue {
            return true
        }

        guard let lastSentAt = lastSentAtByEvent[decision.event] else {
            return true
        }
        return decision.detectedAt.timeIntervalSince(lastSentAt) >= duplicateCooldown
    }

    mutating func recordSent(_ decision: DetectedDrivingEvent) {
        lastSentEvent = decision.event
        lastSentLevel = decision.level
        lastSentAtByEvent[decision.event] = decision.detectedAt
    }

    mutating func reset() {
        lastSentEvent = nil
        lastSentLevel = nil
        lastSentAtByEvent.removeAll()
    }
}
