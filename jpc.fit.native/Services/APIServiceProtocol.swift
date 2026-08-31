import Foundation

protocol APIServiceProtocol: Sendable {
    func fetchFoods(day: String) async -> [Food]
    func fetchHealthKitCache(day: String) async -> HealthKitCache?
    func fetchQuickAdds() async -> [QuickAddItem]
    func fetchPreferences() async -> Preferences?
    /// nil = request failed (distinct from "no food that day").
    func fetchFoodCalories(day: String) async -> [Int]?
    /// Total burned (active+basal) from the cache row for `day`; 0 if none.
    func fetchCacheBurned(day: String) async -> Int
    @discardableResult
    func createFood(name: String, calories: Int, protein: Int?, day: String) async -> String?
    @discardableResult
    func deleteFood(id: String) async -> Bool
    @discardableResult
    func updateFood(id: String, name: String?, calories: Int, protein: Int?) async -> Bool
    func createHealthKitCache(activeCalories: Double, baseCalories: Double, steps: Double, day: String) async -> String?
    func updateHealthKitCache(id: String, activeCalories: Double, baseCalories: Double, steps: Double) async
}

extension APIService: APIServiceProtocol {}
