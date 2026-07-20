@preconcurrency import CoreBluetooth
import Combine
import Foundation

@MainActor
final class StackChanBLEManager: NSObject, ObservableObject, StackChanBLEManaging {
    static let deviceName = "StackChan-Driver"
    static let serviceUUID = CBUUID(string: "7DDA0001-5A5A-4E4F-9B3A-2E65F5A10001")
    static let eventCharacteristicUUID = CBUUID(string: "7DDA0002-5A5A-4E4F-9B3A-2E65F5A10001")

    @Published private(set) var bluetoothState: BluetoothAvailabilityState = .unknown
    @Published private(set) var discoveryState: BLEDiscoveryState = .idle
    @Published private(set) var connectionState: BLEConnectionState = .disconnected
    @Published private(set) var characteristicState: CharacteristicDiscoveryState = .notStarted
    @Published private(set) var lastSentDescription = "未送信"
    @Published private(set) var lastSendResult = "—"
    @Published private(set) var errorMessage: String?

    private var centralManager: (any CentralManagerProviding)!
    private var discoveredPeripheral: CBPeripheral?
    private var eventCharacteristic: CBCharacteristic?
    private var shouldReconnect = false
    private var scanRequested = false
    private let writeTimeout: Duration
    private var pendingWrite: PendingWrite?

    private struct PendingWrite {
        let id: UUID
        let continuation: CheckedContinuation<Void, any Error>
    }

    init(
        centralManager: (any CentralManagerProviding)? = nil,
        writeTimeout: Duration = .seconds(5)
    ) {
        self.writeTimeout = writeTimeout
        super.init()

        self.centralManager = centralManager ?? CBCentralManager(delegate: nil, queue: .main)
        self.centralManager.delegate = self
        bluetoothState = BluetoothAvailabilityState(self.centralManager.state)
    }

    func startScanning() {
        scanRequested = true
        errorMessage = nil

        guard bluetoothState == .poweredOn else {
            if bluetoothState != .unknown && bluetoothState != .resetting {
                present(error: .bluetoothUnavailable)
            }
            return
        }
        guard discoveredPeripheral?.state != .connected,
              discoveredPeripheral?.state != .connecting else {
            scanRequested = false
            present(error: .connectionFailed("再スキャンする前に切断してください。"))
            return
        }

        stopScanning(clearRequest: false)
        discoveredPeripheral = nil
        eventCharacteristic = nil
        discoveryState = .scanning
        characteristicState = .notStarted
        connectionState = .disconnected
        centralManager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        print("[BLE] Scanning started")
    }

    func stopScanning() {
        stopScanning(clearRequest: true)
    }

    func connect() {
        errorMessage = nil

        guard bluetoothState == .poweredOn else {
            present(error: .bluetoothUnavailable)
            return
        }
        guard let discoveredPeripheral else {
            present(error: .deviceNotFound)
            return
        }
        guard discoveredPeripheral.state == .disconnected else {
            present(error: .connectionFailed("すでに接続処理中です。"))
            return
        }

        stopScanning(clearRequest: true)
        shouldReconnect = true
        connectionState = .connecting
        centralManager.connect(discoveredPeripheral, options: nil)
    }

    func disconnect() {
        scanRequested = false
        shouldReconnect = false
        stopScanning(clearRequest: true)
        if pendingWrite != nil {
            lastSendResult = "失敗"
            present(error: .notConnected)
            failPendingWrite(with: .notConnected)
        }

        guard let discoveredPeripheral else {
            resetConnectionState()
            return
        }
        centralManager.cancelPeripheralConnection(discoveredPeripheral)
    }

    func send(event: StackChanEvent, level: AlertLevel) async throws {
        guard connectionState.isReady,
              let discoveredPeripheral,
              discoveredPeripheral.state == .connected else {
            lastSendResult = "失敗"
            present(error: .notConnected)
            throw BLEError.notConnected
        }
        guard let eventCharacteristic else {
            lastSendResult = "失敗"
            present(error: .characteristicNotFound)
            throw BLEError.characteristicNotFound
        }
        guard pendingWrite == nil else {
            lastSendResult = "失敗"
            present(error: .writeInProgress)
            throw BLEError.writeInProgress
        }

        let payload = try StackChanPayload(event: event, level: level)
        let data = payload.data
        guard data.count == StackChanPayload.byteCount else {
            lastSendResult = "失敗"
            present(error: .invalidPayload)
            throw BLEError.invalidPayload
        }

        lastSentDescription = "\(event.displayName) / \(level.displayName)"
        lastSendResult = "送信中"
        errorMessage = nil
        print(String(format: "[BLE] TX event=0x%02X level=0x%02X", event.rawValue, level.rawValue))

        let writeID = UUID()
        try await withCheckedThrowingContinuation { continuation in
            pendingWrite = PendingWrite(id: writeID, continuation: continuation)
            discoveredPeripheral.writeValue(data, for: eventCharacteristic, type: .withResponse)

            Task { [weak self] in
                guard let self else { return }
                try? await Task.sleep(for: self.writeTimeout)
                self.handleWriteTimeout(id: writeID)
            }
        }
    }

    private func stopScanning(clearRequest: Bool) {
        centralManager.stopScan()
        if clearRequest {
            scanRequested = false
        }
        if discoveryState == .scanning {
            discoveryState = .idle
        }
    }

    private func handleWriteTimeout(id: UUID) {
        guard pendingWrite?.id == id else { return }
        lastSendResult = "失敗"
        present(error: .writeTimedOut)
        failPendingWrite(with: .writeTimedOut)
    }

    private func completePendingWrite() {
        guard let pendingWrite else { return }
        self.pendingWrite = nil
        pendingWrite.continuation.resume()
    }

    private func failPendingWrite(with error: BLEError) {
        guard let pendingWrite else { return }
        self.pendingWrite = nil
        pendingWrite.continuation.resume(throwing: error)
    }

    private func resetConnectionState() {
        eventCharacteristic = nil
        characteristicState = .notStarted
        connectionState = .disconnected
    }

    private func present(error: BLEError) {
        errorMessage = error.localizedDescription
    }

    private func reconnectIfNeeded(to peripheral: CBPeripheral) {
        guard shouldReconnect, bluetoothState == .poweredOn else { return }
        connectionState = .reconnecting
        centralManager.connect(peripheral, options: nil)
    }
}

extension StackChanBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = BluetoothAvailabilityState(central.state)
        print("[BLE] State changed: \(bluetoothState.logName)")

        if bluetoothState == .poweredOn {
            errorMessage = nil
            if shouldReconnect,
               let discoveredPeripheral,
               discoveredPeripheral.state != .connected {
                reconnectIfNeeded(to: discoveredPeripheral)
            } else if scanRequested {
                startScanning()
            }
        } else {
            stopScanning(clearRequest: false)
            failPendingWrite(with: .bluetoothUnavailable)
            resetConnectionState()
            if bluetoothState != .unknown && bluetoothState != .resetting {
                present(error: .bluetoothUnavailable)
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        guard peripheral.name == Self.deviceName || advertisedName == Self.deviceName else { return }

        discoveredPeripheral = peripheral
        peripheral.delegate = self
        discoveryState = .discovered
        stopScanning(clearRequest: true)
        print("[BLE] Stack-chan discovered")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectionState = .discoveringServices
        errorMessage = nil
        print("[BLE] Connected")
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        let bleError = BLEError.connectionFailed(error?.localizedDescription ?? "原因不明")
        connectionState = .failed(bleError.localizedDescription)
        present(error: bleError)
        reconnectIfNeeded(to: peripheral)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        print("[BLE] Disconnected")
        failPendingWrite(with: .notConnected)
        eventCharacteristic = nil
        characteristicState = .notStarted

        if shouldReconnect {
            if let error {
                errorMessage = "接続が切断されました: \(error.localizedDescription)"
            }
            reconnectIfNeeded(to: peripheral)
        } else {
            connectionState = .disconnected
        }
    }
}

extension StackChanBLEManager: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)?
    ) {
        if let error {
            let bleError = BLEError.serviceNotFound
            connectionState = .failed(error.localizedDescription)
            present(error: bleError)
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            let bleError = BLEError.serviceNotFound
            connectionState = .failed(bleError.localizedDescription)
            present(error: bleError)
            return
        }

        print("[BLE] Service discovered")
        connectionState = .discoveringCharacteristic
        characteristicState = .searching
        peripheral.discoverCharacteristics([Self.eventCharacteristicUUID], for: service)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        guard error == nil,
              let characteristic = service.characteristics?.first(where: {
                  $0.uuid == Self.eventCharacteristicUUID
              }) else {
            characteristicState = .notFound
            let bleError = BLEError.characteristicNotFound
            connectionState = .failed(bleError.localizedDescription)
            present(error: bleError)
            return
        }

        eventCharacteristic = characteristic
        characteristicState = .discovered
        connectionState = .ready
        errorMessage = nil
        print("[BLE] Characteristic discovered")
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        guard characteristic.uuid == Self.eventCharacteristicUUID,
              pendingWrite != nil else { return }

        if let error {
            let bleError = BLEError.writeFailed(error.localizedDescription)
            lastSendResult = "失敗"
            present(error: bleError)
            failPendingWrite(with: bleError)
        } else {
            lastSendResult = "成功"
            print("[BLE] Write succeeded")
            completePendingWrite()
        }
    }
}
