import SwiftUI

struct WeatherDisplayView: View {
    let weather: UnifiedWeather
    var compact: Bool = true

    var body: some View {
        if compact {
            compactView
        } else {
            expandedView
        }
    }

    private var compactView: some View {
        HStack(spacing: 10) {
            // Location
            if let location = weather.locationName {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                Text(location)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text("·")
                    .foregroundStyle(.secondary)
            }

            // Weather icon and temp
            Image(systemName: weather.sfSymbolName)
                .font(.system(size: 16))
            if let temp = weather.temperatureC {
                Text("\(Int(round(temp)))°")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            // AQI
            if let aqi = weather.airQualityIndex {
                Text("·")
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(weather.aqiColor)
                    .frame(width: 10, height: 10)
                Text("AQI \(aqi)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with location and main weather
            HStack(spacing: 12) {
                // Weather icon
                Image(systemName: weather.sfSymbolName)
                    .font(.system(size: 36))
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    // Temperature
                    if let temp = weather.temperatureC {
                        Text("\(Int(round(temp)))°C")
                            .font(.title2.bold())
                    }

                    // Condition
                    if let condition = weather.condition {
                        Text(condition)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Location
                if let location = weather.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.secondary)
                        Text(location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Extended weather details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                // Air Quality
                if let aqi = weather.airQualityIndex {
                    WeatherDetailItem(
                        icon: "aqi.medium",
                        label: "Air Quality",
                        value: "\(aqi)",
                        color: weather.aqiColor
                    )
                }

                // Humidity
                if let humidity = weather.humidityPercent {
                    WeatherDetailItem(
                        icon: "humidity",
                        label: "Humidity",
                        value: "\(humidity)%",
                        color: .blue
                    )
                }

                // Wind
                if let wind = weather.windSpeedKmh {
                    WeatherDetailItem(
                        icon: "wind",
                        label: "Wind",
                        value: "\(Int(round(wind))) km/h",
                        color: .gray
                    )
                }

                // Pressure
                if let pressure = weather.pressureHpa {
                    WeatherDetailItem(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        label: "Pressure",
                        value: "\(Int(round(pressure))) hPa",
                        color: .purple
                    )
                }

                // UV Index
                if let uv = weather.uvIndex {
                    WeatherDetailItem(
                        icon: "sun.max.fill",
                        label: "UV Index",
                        value: String(format: "%.1f", uv),
                        color: uvColor(uv)
                    )
                }

                // Pollen
                if let pollen = weather.pollenCount {
                    WeatherDetailItem(
                        icon: "leaf.fill",
                        label: "Pollen",
                        value: "\(pollen)",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func uvColor(_ uv: Double) -> Color {
        switch uv {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }
}

private struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
