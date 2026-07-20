import Foundation

enum AlertLevel: UInt8, CaseIterable, Sendable {
    case clear = 0x00
    case low = 0x01
    case medium = 0x02
    case high = 0x03

    var displayName: String {
        switch self {
        case .clear: "解除"
        case .low: "軽度"
        case .medium: "中程度"
        case .high: "強度"
        }
    }

    static let selectableAlerts: [AlertLevel] = [.low, .medium, .high]
}
