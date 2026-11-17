import Foundation

/// The ONE data-access seam. Every ViewModel talks to the backend through this
/// protocol, so the live Amplify client, the in-process demo backend and the
/// unit-test mock are interchangeable — nothing downstream knows which is in.
protocol APIServiceProtocol: Sendable {
    // Foods + HealthKit cache (Calories tab)
    func fetchFoods(day: String) async -> [Food]
    func fetchHealthKitCache(day: String) async -> HealthKitCache?
    @discardableResult
    func createFood(name: String, calories: Int, protein: Int?, day: String) async -> String?
    @discardableResult
    func deleteFood(id: String) async -> Bool
    @discardableResult
    func updateFood(id: String, name: String?, calories: Int, protein: Int?) async -> Bool
    func createHealthKitCache(activeCalories: Double, baseCalories: Double, steps: Double, day: String) async -> String?
    func updateHealthKitCache(id: String, activeCalories: Double, baseCalories: Double, steps: Double) async

    // Stats tab
    /// nil = request failed (distinct from "no food that day").
    func fetchFoodCalories(day: String) async -> [Int]?
    /// Total burned (active+basal) from the cache row for `day`; 0 if none.
    func fetchCacheBurned(day: String) async -> Int

    // Quick adds (Calories + Settings)
    func fetchQuickAdds() async -> [QuickAddItem]
    /// Returns the server id so the optimistic row can be re-keyed.
    func createQuickAdd(_ item: QuickAddItem) async -> String?
    func updateQuickAdd(_ item: QuickAddItem) async -> Bool
    func deleteQuickAdd(id: String) async -> Bool

    // Preferences (Calories + Settings)
    func fetchPreferences() async -> PreferencesRecord
    func createPreferences(hideProtein: Bool, hideSteps: Bool) async -> String?
    func updatePreferences(id: String, hideProtein: Bool, hideSteps: Bool) async -> Bool

    // Weight tab
    func fetchWeights() async -> [Weight]
    func fetchHeights() async -> [Height]
    func createWeight(_ pounds: Int) async -> WriteOutcome
    func createHeight(_ inches: Int) async -> WriteOutcome
}

extension APIService: APIServiceProtocol {}
