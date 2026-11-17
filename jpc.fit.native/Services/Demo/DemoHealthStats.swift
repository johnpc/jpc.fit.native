import Foundation

/// Fixed HealthKit numbers for the fake backend — no permission sheet, no
/// device data, the same burn every day so Stats math is predictable.
struct DemoHealthStats: HealthStatsProviding {
    func requestAuthorization() async {}

    func fetchStats(for date: Date) async -> (active: Double, basal: Double, steps: Double) {
        (active: DemoSeed.activeCalories, basal: DemoSeed.basalCalories, steps: DemoSeed.steps)
    }
}
