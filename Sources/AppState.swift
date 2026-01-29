import SwiftUI

enum LoadingState: Equatable {
    case loading
    case loaded
    case error(String)
}

@MainActor
class AppState: ObservableObject {
    @Published var loadingState: LoadingState = .loading
    @Published var items: [Item] = []
    @Published var apiStatus: String = "Checking..."

    private let baseURL = "http://localhost:8000"
    private let minimumSplashDuration: TimeInterval = 10.0

    func loadData() async {
        loadingState = .loading
        let startTime = Date()

        // Check health
        do {
            let url = URL(string: "\(baseURL)/health")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let health = try JSONDecoder().decode(HealthResponse.self, from: data)
            apiStatus = health.status
        } catch {
            apiStatus = "offline"
            await ensureMinimumSplashTime(startTime: startTime)
            loadingState = .error("API not running. Start with: cd services/api && uv run fastapi dev")
            return
        }

        // Fetch items
        do {
            let url = URL(string: "\(baseURL)/items")!
            let (data, _) = try await URLSession.shared.data(from: url)
            items = try JSONDecoder().decode([Item].self, from: data)
        } catch {
            await ensureMinimumSplashTime(startTime: startTime)
            loadingState = .error("Failed to load items")
            return
        }

        // Ensure minimum splash duration for polish
        await ensureMinimumSplashTime(startTime: startTime)
        loadingState = .loaded
    }

    func retry() async {
        await loadData()
    }

    private func ensureMinimumSplashTime(startTime: Date) async {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = minimumSplashDuration - elapsed
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
    }
}
