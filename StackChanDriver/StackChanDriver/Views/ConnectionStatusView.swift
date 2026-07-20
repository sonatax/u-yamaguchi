import SwiftUI

struct ConnectionStatusView: View {
    @ObservedObject var bleManager: StackChanBLEManager
    var controlsEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("接続状況", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)

            statusRow("Bluetooth", value: bleManager.bluetoothState.displayName)
            statusRow("Stack-chan", value: bleManager.discoveryState.displayName)
            statusRow("接続", value: bleManager.connectionState.displayName)
            statusRow("Characteristic", value: bleManager.characteristicState.displayName)

            Divider()

            statusRow("最後のイベント", value: bleManager.lastSentDescription)
            statusRow("送信結果", value: bleManager.lastSendResult)

            if let errorMessage = bleManager.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("bleErrorMessage")
            }

            HStack {
                Button("接続") {
                    bleManager.connect()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    !controlsEnabled ||
                    bleManager.discoveryState != .discovered ||
                    bleManager.connectionState != .disconnected
                )

                Button("切断", role: .destructive) {
                    bleManager.disconnect()
                }
                .buttonStyle(.bordered)
                .disabled(!controlsEnabled || bleManager.connectionState == .disconnected)

                Button("再スキャン") {
                    bleManager.startScanning()
                }
                .buttonStyle(.bordered)
                .disabled(
                    !controlsEnabled ||
                    bleManager.bluetoothState != .poweredOn ||
                    bleManager.connectionState != .disconnected
                )
            }
            .font(.callout)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statusRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
