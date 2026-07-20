import CoreBluetooth
import Foundation

enum BluetoothAvailabilityState: Equatable, Sendable {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn

    init(_ state: CBManagerState) {
        switch state {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .poweredOff
        case .poweredOn: self = .poweredOn
        @unknown default: self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .unknown: "確認中"
        case .resetting: "リセット中"
        case .unsupported: "非対応"
        case .unauthorized: "権限なし"
        case .poweredOff: "オフ"
        case .poweredOn: "オン"
        }
    }

    var logName: String {
        switch self {
        case .unknown: "unknown"
        case .resetting: "resetting"
        case .unsupported: "unsupported"
        case .unauthorized: "unauthorized"
        case .poweredOff: "poweredOff"
        case .poweredOn: "poweredOn"
        }
    }
}

enum BLEDiscoveryState: Equatable, Sendable {
    case idle
    case scanning
    case discovered

    var displayName: String {
        switch self {
        case .idle: "未検出"
        case .scanning: "検索中"
        case .discovered: "検出済み"
        }
    }
}

enum BLEConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case reconnecting
    case discoveringServices
    case discoveringCharacteristic
    case ready
    case failed(String)

    var displayName: String {
        switch self {
        case .disconnected: "未接続"
        case .connecting: "接続中"
        case .reconnecting: "再接続中"
        case .discoveringServices: "Service探索中"
        case .discoveringCharacteristic: "Characteristic探索中"
        case .ready: "接続済み"
        case let .failed(message): "エラー: \(message)"
        }
    }

    var isReady: Bool { self == .ready }
}

enum CharacteristicDiscoveryState: Equatable, Sendable {
    case notStarted
    case searching
    case discovered
    case notFound

    var displayName: String {
        switch self {
        case .notStarted: "未探索"
        case .searching: "探索中"
        case .discovered: "探索済み"
        case .notFound: "見つかりません"
        }
    }
}

enum BLEError: LocalizedError, Equatable, Sendable {
    case bluetoothUnavailable
    case deviceNotFound
    case notConnected
    case serviceNotFound
    case characteristicNotFound
    case writeFailed(String)
    case writeTimedOut
    case invalidPayload
    case writeInProgress
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable: "Bluetoothを利用できません。設定と権限を確認してください。"
        case .deviceNotFound: "Stack-chanが見つかりません。"
        case .notConnected: "Stack-chanに接続されていません。"
        case .serviceNotFound: "指定されたBLE Serviceが見つかりません。"
        case .characteristicNotFound: "書き込み用Characteristicが見つかりません。"
        case let .writeFailed(message): "書き込みに失敗しました: \(message)"
        case .writeTimedOut: "書き込みがタイムアウトしました。"
        case .invalidPayload: "送信ペイロードが2バイトではありません。"
        case .writeInProgress: "別の書き込みを処理中です。"
        case let .connectionFailed(message): "接続に失敗しました: \(message)"
        }
    }
}
