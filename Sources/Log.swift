import Foundation
import OSLog

/// Centralized logging service using OSLog
enum Log {
    // Subsystem identifies the app (reverse DNS)
    private static let subsystem = "com.oculog.client"

    // Category-specific loggers
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let location = Logger(subsystem: subsystem, category: "Location")
    static let weather = Logger(subsystem: subsystem, category: "Weather")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let general = Logger(subsystem: subsystem, category: "General")
}
