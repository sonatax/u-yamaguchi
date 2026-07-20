import Foundation

@MainActor
protocol StackChanBLEManaging: AnyObject {
    var bluetoothState: BluetoothAvailabilityState { get }
    var discoveryState: BLEDiscoveryState { get }
    var connectionState: BLEConnectionState { get }
    var characteristicState: CharacteristicDiscoveryState { get }
    var lastSentDescription: String { get }
    var lastSendResult: String { get }
    var errorMessage: String? { get }

    func startScanning()
    func stopScanning()
    func connect()
    func disconnect()
    func send(event: StackChanEvent, level: AlertLevel) async throws
}
