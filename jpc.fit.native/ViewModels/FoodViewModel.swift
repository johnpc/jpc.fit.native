import Foundation
import WidgetKit

@MainActor
class FoodViewModel: ObservableObject {
    @Published var foods: [Food] = []
    @Published var healthKitCache: HealthKitCache?
    @Published var userQuickAdds: [QuickAddItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var preferences: Preferences?

    let api: APIServiceProtocol
    private let healthKit = HealthKitService.shared

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    var totalCalories: Int { foods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { foods.reduce(0) { $0 + ($1.protein ?? 0) } }
    var burnedCalories: Int { Int(healthKitCache?.activeCalories ?? 0) + Int(healthKitCache?.baseCalories ?? 0) }
    var remainingCalories: Int { burnedCalories - totalCalories }
    var quickAdds: [QuickAddItem] { userQuickAdds.isEmpty ? defaultQuickAdds : userQuickAdds }
    var hideProtein: Bool { preferences?.hideProtein ?? false }
    var hideSteps: Bool { preferences?.hideSteps ?? false }

    func requestHealthKitPermission() async {
        await healthKit.requestAuthorization()
    }

    /// `showLoading: false` refreshes silently — used for reconciliation
    /// (e.g. a watch-originated change) so the list doesn't flash a spinner
    /// over data that's already on screen.
    func fetchAll(day: String, date: Date, showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil
        async let foodsTask = api.fetchFoods(day: day)
        async let cacheTask = api.fetchHealthKitCache(day: day)
        async let quickAddsTask = api.fetchQuickAdds()
        async let preferencesTask = api.fetchPreferences()

        let (f, c, q, p) = await (foodsTask, cacheTask, quickAddsTask, preferencesTask)
        // The owning view runs this under .task(id: selectedDate); if the user
        // switched days again while we were in flight, drop this stale result
        // (Amplify requests don't reliably honor Task cancellation mid-await).
        guard !Task.isCancelled else { return }
        foods = f
        healthKitCache = c
        userQuickAdds = q
        preferences = p

        // Sync HealthKit after we know if cache exists
        await syncHealthKit(day: day, date: date)

        isLoading = false
        updateWidget(day: day)
    }

    func updateWidget(day: String) {
        // Only update widget with today's data
        let today = DayKey.today
        if day == today {
            SharedDataManager.shared.save(consumed: totalCalories)
            SharedDataManager.shared.save(burned: burnedCalories)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func syncHealthKit(day: String, date: Date) async {
        let stats = await healthKit.fetchStats(for: date)
        let hasData = stats.active > 0 || stats.basal > 0 || stats.steps > 0
        guard hasData else { return }
        let id = await upsertCache(stats: stats, day: day)
        healthKitCache = HealthKitCache(id: id, activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: day)
    }

    /// Update the existing cache row or create one; returns the row id.
    private func upsertCache(stats: (active: Double, basal: Double, steps: Double), day: String) async -> String {
        if let existing = healthKitCache {
            await api.updateHealthKitCache(id: existing.id, activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps)
            return existing.id
        }
        let newId = await api.createHealthKitCache(activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: day)
        return newId ?? UUID().uuidString
    }
}
