import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = StackChanBLEManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConnectionStatusView(bleManager: bleManager)
                    EventTestView(bleManager: bleManager)
                }
                .padding()
            }
            .navigationTitle("Stack-chan Driver")
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    ContentView()
}
