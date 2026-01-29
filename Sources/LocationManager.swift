import Foundation
import CoreLocation

struct IPLocationResponse: Codable {
    let status: String
    let lat: Double?
    let lon: Double?
    let city: String?
    let country: String?
}

@MainActor
class LocationManager: ObservableObject {
    @Published var location: CLLocation?
    @Published var errorMessage: String?
    @Published var isRequesting: Bool = false
    @Published var cityName: String?

    func requestLocation() {
        guard !isRequesting else { return }

        errorMessage = nil
        isRequesting = true

        Task {
            await fetchLocationFromIP()
        }
    }

    private func fetchLocationFromIP() async {
        Log.location.info("Fetching location from IP...")

        do {
            let url = URL(string: "http://ip-api.com/json/?fields=status,lat,lon,city,country")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(IPLocationResponse.self, from: data)

            if response.status == "success", let lat = response.lat, let lon = response.lon {
                Log.location.info("Got location: \(lat, privacy: .public), \(lon, privacy: .public) (\(response.city ?? "unknown", privacy: .public))")
                location = CLLocation(latitude: lat, longitude: lon)
                cityName = response.city
                errorMessage = nil
            } else {
                Log.location.error("IP location failed: \(response.status, privacy: .public)")
                errorMessage = "Could not determine location"
            }
        } catch {
            Log.location.error("IP location error: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Location unavailable"
        }

        isRequesting = false
    }
}
