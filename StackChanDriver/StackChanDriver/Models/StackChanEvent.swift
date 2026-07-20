import Foundation

enum StackChanEvent: UInt8, CaseIterable, Sendable {
    case reset = 0x00
    case drivingStarted = 0x01
    case suddenBrake = 0x02
    case longDrive = 0x03
    case lowResponse = 0x04
    case drowsiness = 0x05
    case drivingFinished = 0x06

    var displayName: String {
        switch self {
        case .reset: "通常状態へ戻す"
        case .drivingStarted: "運転開始"
        case .suddenBrake: "急ブレーキ"
        case .longDrive: "長時間運転"
        case .lowResponse: "ドライバーの反応低下"
        case .drowsiness: "眠気の可能性"
        case .drivingFinished: "運転終了"
        }
    }

    var requiresAlertLevelSelection: Bool {
        switch self {
        case .suddenBrake, .longDrive, .lowResponse, .drowsiness:
            true
        case .reset, .drivingStarted, .drivingFinished:
            false
        }
    }
}
