@preconcurrency import CoreBluetooth

protocol CentralManagerProviding: AnyObject {
    var state: CBManagerState { get }
    var delegate: (any CBCentralManagerDelegate)? { get set }

    func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String: Any]?
    )
    func stopScan()
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheral)
}

extension CBCentralManager: CentralManagerProviding {}
