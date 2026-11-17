import Foundation
@testable import jpc_fit

/// HealthKit stand-in for unit tests: no permission prompt, configurable
/// totals (zero by default so cache rows are never written as a side effect).
struct NoHealthStats: HealthStatsProviding {
    var active = 0.0
    var basal = 0.0
    var steps = 0.0

    func requestAuthorization() async {}

    func fetchStats(for date: Date) async -> (active: Double, basal: Double, steps: Double) {
        (active: active, basal: basal, steps: steps)
    }
}
