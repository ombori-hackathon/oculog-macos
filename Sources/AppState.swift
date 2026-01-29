import SwiftUI
import Combine
import CoreLocation

enum LoadingState: Equatable {
    case loading
    case loaded
    case error(String)
}

enum DateFilterPreset: String, CaseIterable {
    case last7Days = "Last 7 days"
    case last30Days = "Last 30 days"
    case last90Days = "Last 90 days"
    case custom = "Custom"
}

@MainActor
class AppState: ObservableObject {
    @Published var loadingState: LoadingState = .loading
    @Published var logs: [ConditionLog] = []
    @Published var apiStatus: String = "Checking..."

    // Modal state
    @Published var isShowingLogForm: Bool = false
    @Published var editingLog: ConditionLog? = nil
    @Published var listError: String? = nil

    // Filter state
    @Published var dateFilterPreset: DateFilterPreset = .last30Days
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @Published var customEndDate: Date = Date()

    // Pagination state
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var totalLogs: Int = 0

    var effectiveStartDate: Date {
        switch dateFilterPreset {
        case .last7Days: return Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        case .last30Days: return Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        case .last90Days: return Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        case .custom: return customStartDate
        }
    }

    var effectiveEndDate: Date {
        return dateFilterPreset == .custom ? customEndDate : Date()
    }

    let locationManager = LocationManager()
    let weatherState = WeatherState()
    let authState: AuthState

    private let baseURL = "http://localhost:8000"
    private let minimumSplashDuration: TimeInterval = 2.0
    private var cancellables = Set<AnyCancellable>()

    private func authorizedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = KeychainManager.get(forKey: .accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    var currentUserId: UUID? {
        authState.currentUser?.id
    }

    init(authState: AuthState) {
        self.authState = authState
        setupLocationObserver()
    }

    private func setupLocationObserver() {
        locationManager.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                Log.weather.info("Location changed, triggering weather fetch")
                self?.fetchWeather(for: location)
            }
            .store(in: &cancellables)
    }

    private func fetchWeather(for location: CLLocation) {
        Log.weather.info("Fetching weather for \(location.coordinate.latitude, privacy: .public), \(location.coordinate.longitude, privacy: .public)")
        Task {
            await weatherState.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

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

        // Fetch logs (errors handled in main UI via listError)
        await refreshLogs(page: 1)

        // Ensure minimum splash duration for polish
        await ensureMinimumSplashTime(startTime: startTime)
        loadingState = .loaded

        // Trigger location request after successful API load
        locationManager.requestLocation()
    }

    func retry() async {
        await loadData()
    }

    func refreshWeather() {
        guard let location = locationManager.location else {
            Log.weather.info("refreshWeather called but no location")
            return
        }
        fetchWeather(for: location)
    }

    func refreshLogs(page: Int = 1) async {
        listError = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var components = URLComponents(string: "\(baseURL)/logs")!
        components.queryItems = [
            URLQueryItem(name: "start_date", value: formatter.string(from: effectiveStartDate)),
            URLQueryItem(name: "end_date", value: formatter.string(from: effectiveEndDate)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: "50"),
        ]

        let request = authorizedRequest(url: components.url!)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let response = try JSONDecoder().decode(PaginatedLogsResponse.self, from: data)
                logs = response.items
                currentPage = response.page
                totalPages = response.totalPages
                totalLogs = response.total
            } catch {
                Log.network.error("Decoding error: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    Log.network.debug("Raw response: \(dataString.prefix(1000))")
                }
                listError = "Failed to load logs: \(error.localizedDescription)"
            }
        } catch {
            listError = "Failed to load logs: \(error.localizedDescription)"
        }
    }

    func goToPage(_ page: Int) async {
        guard page >= 1 && page <= totalPages else { return }
        await refreshLogs(page: page)
    }

    func createLog(_ log: ConditionLogCreate) async throws -> ConditionLog {
        let url = URL(string: "\(baseURL)/logs")!
        var request = authorizedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(log)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            throw parseAPIError(data: data, statusCode: httpResponse.statusCode)
        }

        let createdLog = try JSONDecoder().decode(ConditionLog.self, from: data)
        await refreshLogs()
        return createdLog
    }

    func updateLog(id: UUID, _ update: ConditionLogUpdate) async throws -> ConditionLog {
        let url = URL(string: "\(baseURL)/logs/\(id.uuidString)")!
        var request = authorizedRequest(url: url, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(update)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            throw parseAPIError(data: data, statusCode: httpResponse.statusCode)
        }

        let updatedLog = try JSONDecoder().decode(ConditionLog.self, from: data)
        await refreshLogs()
        return updatedLog
    }

    func deleteLog(id: UUID) async throws {
        let url = URL(string: "\(baseURL)/logs/\(id.uuidString)")!
        let request = authorizedRequest(url: url, method: "DELETE")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 400 && httpResponse.statusCode != 204 {
            throw parseAPIError(data: data, statusCode: httpResponse.statusCode)
        }

        await refreshLogs()
    }

    func openLogForm(editing log: ConditionLog? = nil) {
        editingLog = log
        isShowingLogForm = true
    }

    func closeLogForm() {
        isShowingLogForm = false
        editingLog = nil
    }

    private func ensureMinimumSplashTime(startTime: Date) async {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = minimumSplashDuration - elapsed
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
    }

    // MARK: - Unified Error Parsing

    func parseAPIError(data: Data, statusCode: Int) -> APIError {
        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            let errorType = APIErrorType(rawValue: errorResponse.type) ?? .unknown
            let dataDict = errorResponse.data?.mapValues { $0.value }
            return .apiError(type: errorType, message: errorResponse.message, data: dataDict)
        }
        // Fallback for non-unified responses
        let message = String(data: data, encoding: .utf8) ?? "Unknown error (status: \(statusCode))"
        return .apiError(type: .serverError, message: message, data: nil)
    }
}
