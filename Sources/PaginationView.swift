import SwiftUI

struct PaginationView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Text("\(appState.totalLogs) logs")
                .foregroundStyle(.secondary)

            Spacer()

            if appState.totalPages > 1 {
                Button {
                    Task { await appState.goToPage(appState.currentPage - 1) }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(appState.currentPage <= 1)
                .buttonStyle(.plain)

                Text("Page \(appState.currentPage) of \(appState.totalPages)")
                    .monospacedDigit()

                Button {
                    Task { await appState.goToPage(appState.currentPage + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(appState.currentPage >= appState.totalPages)
                .buttonStyle(.plain)
            }
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
