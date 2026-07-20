import CoreBluetooth
import Foundation
import Testing
@testable import StackChanDriver

@Suite("Stack-chan payload")
struct StackChanPayloadTests {
    @Test("イベントIDが仕様どおりである")
    func eventRawValues() {
        #expect(StackChanEvent.reset.rawValue == 0x00)
        #expect(StackChanEvent.drivingStarted.rawValue == 0x01)
        #expect(StackChanEvent.suddenBrake.rawValue == 0x02)
        #expect(StackChanEvent.longDrive.rawValue == 0x03)
        #expect(StackChanEvent.lowResponse.rawValue == 0x04)
        #expect(StackChanEvent.drowsiness.rawValue == 0x05)
        #expect(StackChanEvent.drivingFinished.rawValue == 0x06)
    }

    @Test("警告レベルが仕様どおりである")
    func alertLevelRawValues() {
        #expect(AlertLevel.clear.rawValue == 0x00)
        #expect(AlertLevel.low.rawValue == 0x01)
        #expect(AlertLevel.medium.rawValue == 0x02)
        #expect(AlertLevel.high.rawValue == 0x03)
    }

    @Test("全組み合わせのペイロードが2バイトである")
    func payloadIsAlwaysTwoBytes() throws {
        for event in StackChanEvent.allCases {
            for level in AlertLevel.allCases {
                let payload = try StackChanPayload(event: event, level: level)
                #expect(payload.data.count == 2)
            }
        }
    }

    @Test("眠気・中程度は 05 02")
    func drowsinessMediumPayload() throws {
        let payload = try StackChanPayload(event: .drowsiness, level: .medium)
        #expect(Array(payload.data) == [0x05, 0x02])
    }

    @Test("運転開始は 01 01")
    func drivingStartedPayload() throws {
        let payload = try StackChanPayload(event: .drivingStarted, level: .low)
        #expect(Array(payload.data) == [0x01, 0x01])
    }

    @Test("リセットは 00 00")
    func resetPayload() throws {
        let payload = try StackChanPayload(event: .reset, level: .clear)
        #expect(Array(payload.data) == [0x00, 0x00])
    }

    @Test("未接続状態では送信エラーになる")
    @MainActor
    func sendingWhileDisconnectedFails() async {
        let central = MockCentralManager()
        let manager = StackChanBLEManager(centralManager: central)

        await #expect(throws: BLEError.notConnected) {
            try await manager.send(event: .drowsiness, level: .medium)
        }
    }
}

private final class MockCentralManager: CentralManagerProviding {
    var state: CBManagerState = .poweredOn
    weak var delegate: (any CBCentralManagerDelegate)?

    func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String: Any]?
    ) {}

    func stopScan() {}
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {}
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) {}
}
