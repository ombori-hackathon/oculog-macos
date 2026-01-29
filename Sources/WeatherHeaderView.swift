import SwiftUI

struct WeatherHeaderView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherState: WeatherState
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .font(.system(size: 14))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(minWidth: 200, minHeight: 36)  // Fixed minimum size to prevent layout jump
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var content: some View {
        // Location errors take priority
        if let error = locationManager.errorMessage {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            retryButton
        } else if locationManager.isRequesting {
            // Requesting location
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 18, height: 18)
            Text("Getting location...")
                .foregroundStyle(.secondary)
        } else if locationManager.location == nil {
            // No location yet, not requesting - idle state
            Image(systemName: "location.slash")
                .font(.system(size: 16))
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
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text("Preparing weather...")
                    .foregroundStyle(.secondary)

            case .loading:
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 18, height: 18)
                Text("Loading weather...")
                    .foregroundStyle(.secondary)

            case .loaded(let weather):
                WeatherDisplayView(weather: weather, compact: true)

            case .error:
                Image(systemName: "cloud.fill")
                    .font(.system(size: 16))
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
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
    }
}
