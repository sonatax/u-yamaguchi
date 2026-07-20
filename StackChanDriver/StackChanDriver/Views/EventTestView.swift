import SwiftUI

struct EventTestView: View {
    @ObservedObject var bleManager: StackChanBLEManager
    let isEnabled: Bool
    @State private var selectedLevels: [StackChanEvent: AlertLevel] = [
        .suddenBrake: .low,
        .longDrive: .low,
        .lowResponse: .low,
        .drowsiness: .low,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("テスト送信", systemImage: "paperplane")
                .font(.headline)

            fixedEventButton(.reset, level: .clear)
            fixedEventButton(.drivingStarted, level: .low)

            alertEventRow(.suddenBrake)
            alertEventRow(.longDrive)
            alertEventRow(.lowResponse)
            alertEventRow(.drowsiness)

            fixedEventButton(.drivingFinished, level: .clear)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func fixedEventButton(
        _ event: StackChanEvent,
        level: AlertLevel
    ) -> some View {
        Button {
            send(event, level: level)
        } label: {
            HStack {
                Text(event.displayName)
                Spacer()
                Image(systemName: "paperplane.fill")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(!bleManager.connectionState.isReady || !isEnabled)
    }

    private func alertEventRow(_ event: StackChanEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.displayName)
                .font(.subheadline.weight(.semibold))

            Picker(
                "警告レベル",
                selection: Binding(
                    get: { selectedLevels[event] ?? .low },
                    set: { selectedLevels[event] = $0 }
                )
            ) {
                ForEach(AlertLevel.selectableAlerts, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Button("送信") {
                send(event, level: selectedLevels[event] ?? .low)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .disabled(!bleManager.connectionState.isReady || !isEnabled)
        }
        .padding(.vertical, 4)
    }

    private func send(_ event: StackChanEvent, level: AlertLevel) {
        Task {
            do {
                try await bleManager.send(event: event, level: level)
            } catch {
                // BLE manager publishes the detailed failure for the status view.
            }
        }
    }
}
