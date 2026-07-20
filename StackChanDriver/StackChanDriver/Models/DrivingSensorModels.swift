import Foundation

struct MotionSensorSample: Equatable, Sendable {
    let timestamp: Date
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double

    var magnitudeG: Double {
        sqrt(
            accelerationX * accelerationX +
            accelerationY * accelerationY +
            accelerationZ * accelerationZ
        )
    }
}

struct LocationSensorSample: Equatable, Sendable {
    let timestamp: Date
    let speedMetersPerSecond: Double
    let horizontalAccuracyMeters: Double
    let speedAccuracyMetersPerSecond: Double

    var speedKilometersPerHour: Double {
        speedMetersPerSecond * 3.6
    }
}

struct DetectedDrivingEvent: Equatable, Sendable {
    let event: StackChanEvent
    let level: AlertLevel
    let detectedAt: Date

    var displayName: String {
        "\(event.displayName) / \(level.displayName)"
    }
}

enum DrivingPhase: Equatable, Sendable {
    case idle
    case confirmingStart
    case driving
    case confirmingStop

    var displayName: String {
        switch self {
        case .idle: "待機中"
        case .confirmingStart: "運転開始を確認中"
        case .driving: "運転中"
        case .confirmingStop: "停止を確認中"
        }
    }
}

enum MonitoringSensorState: Equatable, Sendable {
    case stopped
    case preparing
    case monitoring
    case failed(String)

    var displayName: String {
        switch self {
        case .stopped: "停止中"
        case .preparing: "権限・センサー確認中"
        case .monitoring: "監視中"
        case let .failed(message): "エラー: \(message)"
        }
    }
}

enum SensorServiceError: LocalizedError, Equatable, Sendable {
    case motionUnavailable
    case locationUnavailable
    case locationPermissionDenied
    case motionUpdateFailed(String)
    case locationUpdateFailed(String)

    var errorDescription: String? {
        switch self {
        case .motionUnavailable:
            "モーションセンサーを利用できません。"
        case .locationUnavailable:
            "位置情報サービスを利用できません。"
        case .locationPermissionDenied:
            "位置情報の利用が許可されていません。設定を確認してください。"
        case let .motionUpdateFailed(message):
            "モーションデータの取得に失敗しました: \(message)"
        case let .locationUpdateFailed(message):
            "位置情報の取得に失敗しました: \(message)"
        }
    }
}
