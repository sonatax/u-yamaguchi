import SwiftUI

struct MonitoringView: View {
    @ObservedObject var bleManager: StackChanBLEManager
    @ObservedObject var monitoringManager: DrivingMonitoringManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monitoringControlCard
                    liveSensorCard
                    automaticEventCard
                    implementationNotice
                }
                .padding()
            }
            .navigationTitle("運転見守り")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var monitoringControlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("見守り状態", systemImage: "car.side.fill")
                .font(.headline)

            statusRow("BLE接続", value: bleManager.connectionState.displayName)
            statusRow("センサー", value: monitoringManager.sensorState.displayName)
            statusRow("運転判定", value: monitoringManager.drivingPhase.displayName)

            if let errorMessage = monitoringManager.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if monitoringManager.isMonitoring {
                Button("見守りを終了", role: .destructive) {
                    monitoringManager.stopMonitoring()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            } else {
                Button("見守りを開始") {
                    monitoringManager.startMonitoring()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!bleManager.connectionState.isReady)

                if !bleManager.connectionState.isReady {
                    Text("BLEテスト画面でStack-chanへ接続すると開始できます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }

    private var liveSensorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("リアルタイムセンサー", systemImage: "waveform.path.ecg")
                .font(.headline)

            metricRow(
                title: "速度",
                value: monitoringManager.currentSpeedKilometersPerHour,
                format: "%.1f",
                unit: "km/h"
            )
            metricRow(
                title: "加速度",
                value: monitoringManager.currentAccelerationG,
                format: "%.3f",
                unit: "G"
            )
            statusRow(
                "運転時間",
                value: durationText(monitoringManager.drivingDuration)
            )
        }
        .cardStyle()
    }

    private var automaticEventCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("自動判定・送信", systemImage: "bolt.horizontal.circle")
                .font(.headline)

            statusRow("最後の検出", value: monitoringManager.lastDetectedEvent)
            statusRow("自動送信結果", value: monitoringManager.lastAutomaticSendResult)
            statusRow("BLE送信結果", value: bleManager.lastSendResult)
        }
        .cardStyle()
    }

    private var implementationNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("現在の自動判定", systemImage: "info.circle")
                .font(.headline)
            Text("運転開始・終了、急ブレーキ、長時間運転に対応しています。反応低下と眠気のカメラ判定は未実装です。")
                .font(.callout)
            Text("急ブレーキ判定中はiPhoneを車載ホルダーへ固定してください。本アプリの判定は運転支援の補助であり、安全装置を代替するものではありません。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
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

    private func metricRow(
        title: String,
        value: Double,
        format: String,
        unit: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: format, value))
                .font(.title3.monospacedDigit())
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

private extension View {
    func cardStyle() -> some View {
        padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
