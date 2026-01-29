import Foundation
import Combine

enum WeatherLoadingState: Equatable {
    case idle
    case loading
    case loaded(UnifiedWeather)
    case error(String)

    static func == (lhs: WeatherLoadingState, rhs: WeatherLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let l), .loaded(let r)):
            return l.locationName == r.locationName && l.temperatureC == r.temperatureC
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}

@MainActor
class WeatherState: ObservableObject {
    @Published var state: WeatherLoadingState = .idle

    private let baseURL = "http://localhost:8000"

    func fetchWeather(latitude: Double, longitude: Double) async {
        state = .loading
        Log.weather.info("Fetching weather for \(latitude, privacy: .public), \(longitude, privacy: .public)...")

        do {
            var components = URLComponents(string: "\(baseURL)/weather")
            components?.queryItems = [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude))
            ]

            guard let url = components?.url else {
                state = .error("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 10  // 10 second timeout
            if let token = KeychainManager.get(forKey: .accessToken) {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                Log.weather.error("Weather: invalid response")
                state = .error("Invalid response")
                return
            }

            Log.weather.info("Weather response: \(httpResponse.statusCode, privacy: .public)")

            guard httpResponse.statusCode == 200 else {
                state = .error("Weather API error (\(httpResponse.statusCode))")
                return
            }

            let weatherResponse = try JSONDecoder().decode(UnifiedWeather.self, from: data)
            Log.weather.info("Weather loaded: \(weatherResponse.locationName ?? "unknown", privacy: .public)")
            state = .loaded(weatherResponse)
        } catch {
            Log.weather.error("Weather error: \(error.localizedDescription, privacy: .public)")
            state = .error("Weather unavailable")
        }
    }
}
