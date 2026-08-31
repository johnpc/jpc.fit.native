import Foundation

/// Canonical "day" string used as the backend partition key for foods and
/// HealthKit cache rows. MUST be locale-stable: `Date.formatted(date: .numeric)`
/// follows the device region (8/30/26 vs 30.08.26 vs 2026/08/30), which would
/// split a user's history the moment they change region. The fixed en_US_POSIX
/// M/d/yyyy pattern matches every row already written by earlier builds
/// (`.numeric` rendered 8/30/2026 under en_US).
enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "M/d/yyyy"
        return f
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static var today: String { string(from: Date()) }
}
