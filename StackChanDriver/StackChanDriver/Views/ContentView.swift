import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager: StackChanBLEManager
    @ObservedObject var monitoringManager: DrivingMonitoringManager

    var body: some View {
        TabView {
            MonitoringView(
                bleManager: bleManager,
                monitoringManager: monitoringManager
            )
            .tabItem {
                Label("運転見守り", systemImage: "car.fill")
            }

            BLETestView(
                bleManager: bleManager,
                isMonitoring: monitoringManager.isMonitoring ||
                    monitoringManager.isAutomaticTransmissionActive
            )
            .tabItem {
                Label("BLEテスト", systemImage: "antenna.radiowaves.left.and.right")
            }
        }
        .task {
            if bleManager.connectionState == .disconnected,
               bleManager.discoveryState != .discovered {
                bleManager.startScanning()
            }
        }
    }
}

#Preview {
    let bleManager = StackChanBLEManager()
    ContentView(
        bleManager: bleManager,
        monitoringManager: DrivingMonitoringManager(bleManager: bleManager)
    )
}
