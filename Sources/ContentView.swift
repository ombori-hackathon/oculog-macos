import SwiftUI

struct ContentView: View {
    let items: [Item]
    let apiStatus: String

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("oculog")
                    .font(.title.bold())
                Spacer()
                Circle()
                    .fill(apiStatus == "healthy" ? .green : .red)
                    .frame(width: 12, height: 12)
                Text(apiStatus)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.bar)

            Divider()

            // Content
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No items found")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ItemsTable(items: items)
            }
        }
    }
}
