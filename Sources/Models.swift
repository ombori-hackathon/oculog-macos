import Foundation
import SwiftUI

// MARK: - Auth Models

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

struct AuthUser: Codable {
    let id: UUID
    let login: String
    let email: String?
    let timezone: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, login, email, timezone
        case createdAt = "created_at"
    }
}

// MARK: - Other Models

struct Item: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let price: Double
}

struct HealthResponse: Codable {
    let status: String
}

struct WeatherInfo: Codable {
    let temperatureC: Double
    let condition: String
    let iconCode: String

    enum CodingKeys: String, CodingKey {
        case temperatureC = "temperature_c"
        case condition
        case iconCode = "icon_code"
    }

    var sfSymbolName: String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

struct AirQualityInfo: Codable {
    let aqi: Int
    let category: String

    var color: Color {
        switch aqi {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
}

struct LocationWeatherResponse: Codable {
    let city: String
    let country: String
    let weather: WeatherInfo
    let airQuality: AirQualityInfo

    enum CodingKeys: String, CodingKey {
        case city, country, weather
        case airQuality = "air_quality"
    }
}

struct UnifiedWeather: Codable {
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let temperatureC: Double?
    let condition: String?
    let iconCode: String?
    let humidityPercent: Int?
    let pressureHpa: Double?
    let windSpeedKmh: Double?
    let airQualityIndex: Int?
    let uvIndex: Double?
    let pollenCount: Int?
    let recordedAt: String?

    enum CodingKeys: String, CodingKey {
        case locationName = "location_name"
        case latitude, longitude
        case temperatureC = "temperature_c"
        case condition
        case iconCode = "icon_code"
        case humidityPercent = "humidity_percent"
        case pressureHpa = "pressure_hpa"
        case windSpeedKmh = "wind_speed_kmh"
        case airQualityIndex = "air_quality_index"
        case uvIndex = "uv_index"
        case pollenCount = "pollen_count"
        case recordedAt = "recorded_at"
    }

    var sfSymbolName: String {
        guard let code = iconCode else { return "cloud.fill" }
        switch code {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }

    var aqiColor: Color {
        guard let aqi = airQualityIndex else { return .gray }
        switch aqi {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
}

struct ConditionLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let logDate: String
    let city: String?  // Nullable for backward compat with existing logs
    let overallRating: Int?
    let comments: String?
    let createdAt: String
    let updatedAt: String

    // Symptoms (0-10)
    let burning: Int?
    let redness: Int?
    let itching: Int?
    let tearing: Int?
    let swelling: Int?
    let dryness: Int?

    // Lifestyle
    let screenTimeHours: Double?
    let sleepHours: Double?
    let sleepQuality: Int?
    let waterIntakeLiters: Double?
    let caffeineCups: Int?
    let alcoholUnits: Int?
    let stressLevel: Int?
    let outdoorHours: Double?

    // Treatments (bool)
    let usedArtificialTears: Bool?
    let usedWarmCompress: Bool?
    let usedLidScrub: Bool?
    let usedPrescriptionDrops: Bool?
    let usedOmega3: Bool?
    let usedHumidifier: Bool?

    // Environment (bool)
    let woreContacts: Bool?
    let acExposure: Bool?
    let heatingExposure: Bool?

    // Notes
    let treatmentsNotes: String?

    // Weather (included from log details endpoint)
    let weather: UnifiedWeather?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case logDate = "log_date"
        case city
        case overallRating = "overall_rating"
        case comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"

        // Symptoms
        case burning, redness, itching, tearing, swelling, dryness

        // Lifestyle
        case screenTimeHours = "screen_time_hours"
        case sleepHours = "sleep_hours"
        case sleepQuality = "sleep_quality"
        case waterIntakeLiters = "water_intake_liters"
        case caffeineCups = "caffeine_cups"
        case alcoholUnits = "alcohol_units"
        case stressLevel = "stress_level"
        case outdoorHours = "outdoor_hours"

        // Treatments
        case usedArtificialTears = "used_artificial_tears"
        case usedWarmCompress = "used_warm_compress"
        case usedLidScrub = "used_lid_scrub"
        case usedPrescriptionDrops = "used_prescription_drops"
        case usedOmega3 = "used_omega3"
        case usedHumidifier = "used_humidifier"

        // Environment
        case woreContacts = "wore_contacts"
        case acExposure = "ac_exposure"
        case heatingExposure = "heating_exposure"

        // Notes
        case treatmentsNotes = "treatments_notes"

        // Weather
        case weather
    }

    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        if let date = inputFormatter.date(from: logDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy"
            return outputFormatter.string(from: date)
        }
        return logDate
    }

    var truncatedComments: String {
        guard let comments = comments else { return "–" }
        if comments.count <= 50 {
            return comments
        }
        return String(comments.prefix(47)) + "..."
    }

    var ratingDisplay: String {
        if let rating = overallRating {
            return "\(rating)"
        }
        return "–"
    }

    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: logDate)
    }
}

struct ConditionLogCreate: Codable {
    let logDate: String
    var city: String  // Required
    var overallRating: Int?
    var comments: String?

    // Symptoms (0-10)
    var burning: Int?
    var redness: Int?
    var itching: Int?
    var tearing: Int?
    var swelling: Int?
    var dryness: Int?

    // Lifestyle
    var screenTimeHours: Double?
    var sleepHours: Double?
    var sleepQuality: Int?
    var waterIntakeLiters: Double?
    var caffeineCups: Int?
    var alcoholUnits: Int?
    var stressLevel: Int?
    var outdoorHours: Double?

    // Treatments (bool)
    var usedArtificialTears: Bool?
    var usedWarmCompress: Bool?
    var usedLidScrub: Bool?
    var usedPrescriptionDrops: Bool?
    var usedOmega3: Bool?
    var usedHumidifier: Bool?

    // Environment (bool)
    var woreContacts: Bool?
    var acExposure: Bool?
    var heatingExposure: Bool?

    // Notes
    var treatmentsNotes: String?

    enum CodingKeys: String, CodingKey {
        case logDate = "log_date"
        case city
        case overallRating = "overall_rating"
        case comments

        // Symptoms
        case burning, redness, itching, tearing, swelling, dryness

        // Lifestyle
        case screenTimeHours = "screen_time_hours"
        case sleepHours = "sleep_hours"
        case sleepQuality = "sleep_quality"
        case waterIntakeLiters = "water_intake_liters"
        case caffeineCups = "caffeine_cups"
        case alcoholUnits = "alcohol_units"
        case stressLevel = "stress_level"
        case outdoorHours = "outdoor_hours"

        // Treatments
        case usedArtificialTears = "used_artificial_tears"
        case usedWarmCompress = "used_warm_compress"
        case usedLidScrub = "used_lid_scrub"
        case usedPrescriptionDrops = "used_prescription_drops"
        case usedOmega3 = "used_omega3"
        case usedHumidifier = "used_humidifier"

        // Environment
        case woreContacts = "wore_contacts"
        case acExposure = "ac_exposure"
        case heatingExposure = "heating_exposure"

        // Notes
        case treatmentsNotes = "treatments_notes"
    }
}

struct ConditionLogUpdate: Codable {
    var logDate: String?
    var city: String?  // Optional for partial updates
    var overallRating: Int?
    var comments: String?

    // Symptoms (0-10)
    var burning: Int?
    var redness: Int?
    var itching: Int?
    var tearing: Int?
    var swelling: Int?
    var dryness: Int?

    // Lifestyle
    var screenTimeHours: Double?
    var sleepHours: Double?
    var sleepQuality: Int?
    var waterIntakeLiters: Double?
    var caffeineCups: Int?
    var alcoholUnits: Int?
    var stressLevel: Int?
    var outdoorHours: Double?

    // Treatments (bool)
    var usedArtificialTears: Bool?
    var usedWarmCompress: Bool?
    var usedLidScrub: Bool?
    var usedPrescriptionDrops: Bool?
    var usedOmega3: Bool?
    var usedHumidifier: Bool?

    // Environment (bool)
    var woreContacts: Bool?
    var acExposure: Bool?
    var heatingExposure: Bool?

    // Notes
    var treatmentsNotes: String?

    enum CodingKeys: String, CodingKey {
        case logDate = "log_date"
        case city
        case overallRating = "overall_rating"
        case comments

        // Symptoms
        case burning, redness, itching, tearing, swelling, dryness

        // Lifestyle
        case screenTimeHours = "screen_time_hours"
        case sleepHours = "sleep_hours"
        case sleepQuality = "sleep_quality"
        case waterIntakeLiters = "water_intake_liters"
        case caffeineCups = "caffeine_cups"
        case alcoholUnits = "alcohol_units"
        case stressLevel = "stress_level"
        case outdoorHours = "outdoor_hours"

        // Treatments
        case usedArtificialTears = "used_artificial_tears"
        case usedWarmCompress = "used_warm_compress"
        case usedLidScrub = "used_lid_scrub"
        case usedPrescriptionDrops = "used_prescription_drops"
        case usedOmega3 = "used_omega3"
        case usedHumidifier = "used_humidifier"

        // Environment
        case woreContacts = "wore_contacts"
        case acExposure = "ac_exposure"
        case heatingExposure = "heating_exposure"

        // Notes
        case treatmentsNotes = "treatments_notes"
    }
}

struct PaginatedLogsResponse: Codable {
    let items: [ConditionLog]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case items, total, page
        case pageSize = "page_size"
        case totalPages = "total_pages"
    }
}

// MARK: - Unified API Error Types

/// Generic API error response that matches backend format
struct APIErrorResponse: Codable {
    let type: String
    let message: String
    let data: [String: AnyCodable]?
}

/// Type-safe wrapper for JSON any value
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let double = value as? Double {
            try container.encode(double)
        } else {
            try container.encodeNil()
        }
    }

    var stringValue: String? { value as? String }
    var intValue: Int? { value as? Int }
    var boolValue: Bool? { value as? Bool }
    var doubleValue: Double? { value as? Double }
}

/// Error types matching backend ErrorType enum
enum APIErrorType: String {
    case invalidCredentials = "invalid_credentials"
    case unauthorized = "unauthorized"
    case emailAlreadyExists = "email_already_exists"
    case notFound = "not_found"
    case forbidden = "forbidden"
    case duplicateDate = "duplicate_date"
    case validationError = "validation_error"
    case serviceUnavailable = "service_unavailable"
    case badGateway = "bad_gateway"
    case serverError = "server_error"
    case unknown = "unknown"
}

enum APIError: LocalizedError, @unchecked Sendable {
    case invalidResponse
    case apiError(type: APIErrorType, message: String, data: [String: Any]?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(_, let message, _):
            return message
        }
    }

    var errorType: APIErrorType {
        switch self {
        case .invalidResponse:
            return .unknown
        case .apiError(let type, _, _):
            return type
        }
    }

    var data: [String: Any]? {
        switch self {
        case .invalidResponse:
            return nil
        case .apiError(_, _, let data):
            return data
        }
    }

    // Convenience accessors for common data fields
    var existingLogId: UUID? {
        guard let idString = data?["existing_log_id"] as? String else { return nil }
        return UUID(uuidString: idString)
    }

    var resourceId: String? {
        data?["id"] as? String
    }

    var resourceType: String? {
        data?["resource"] as? String
    }
}

