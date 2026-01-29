import SwiftUI

struct WeatherHeaderView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherState: WeatherState
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            content
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var content: some View {
        // Location errors take priority
        if let error = locationManager.errorMessage {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
            retryButton
        } else if locationManager.isRequesting {
            // Requesting location
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
            Text("Getting location...")
                .foregroundStyle(.secondary)
        } else if locationManager.location == nil {
            // No location yet, not requesting - idle state
            Image(systemName: "location.slash")
                .foregroundStyle(.secondary)
            Text("Location unavailable")
                .foregroundStyle(.secondary)
            retryButton
        } else {
            // Have location, show weather states
            switch weatherState.state {
            case .idle:
                // Should not stay here long - weather fetch should start
                Image(systemName: "location.fill")
                    .foregroundStyle(.secondary)
                Text("Preparing weather...")
                    .foregroundStyle(.secondary)

            case .loading:
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
                Text("Loading weather...")
                    .foregroundStyle(.secondary)

            case .loaded(let weather):
                WeatherDisplayView(weather: weather, compact: true)

            case .error:
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.secondary)
                Text("Weather unavailable")
                    .foregroundStyle(.secondary)
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
    }
}
