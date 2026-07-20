import Foundation

struct StackChanPayload: Equatable, Sendable {
    static let byteCount = 2

    let event: StackChanEvent
    let level: AlertLevel

    var data: Data {
        Data([event.rawValue, level.rawValue])
    }

    init(event: StackChanEvent, level: AlertLevel) throws {
        self.event = event
        self.level = level

        guard data.count == Self.byteCount else {
            throw BLEError.invalidPayload
        }
    }
}
