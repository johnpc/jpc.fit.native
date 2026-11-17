import Foundation

/// A day's HealthKit totals. The seam lets the fake backend return fixed
/// numbers so no screen ever needs the HealthKit permission sheet in tests.
protocol HealthStatsProviding: Sendable {
    func requestAuthorization() async
    func fetchStats(for date: Date) async -> (active: Double, basal: Double, steps: Double)
}

extension HealthKitService: HealthStatsProviding {}
