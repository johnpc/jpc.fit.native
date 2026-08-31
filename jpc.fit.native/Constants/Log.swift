import os

/// App-wide loggers — use these instead of `print` so messages carry
/// subsystem/category metadata and stay out of release stdout.
enum Log {
    static let app = Logger(subsystem: "com.johncorser.fit", category: "app")
    static let notifications = Logger(subsystem: "com.johncorser.fit", category: "notifications")
}
