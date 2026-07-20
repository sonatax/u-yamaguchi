import SwiftUI

struct BLETestView: View {
    @ObservedObject var bleManager: StackChanBLEManager
    let isMonitoring: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isMonitoring {
                        Label(
                            "運転見守り中は手動イベント送信を停止しています。",
                            systemImage: "car.fill"
                        )
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }

                    ConnectionStatusView(
                        bleManager: bleManager,
                        controlsEnabled: !isMonitoring
                    )
                    EventTestView(
                        bleManager: bleManager,
                        isEnabled: !isMonitoring
                    )
                }
                .padding()
            }
            .navigationTitle("BLEテスト")
            .background(Color(.systemGroupedBackground))
        }
    }
}
