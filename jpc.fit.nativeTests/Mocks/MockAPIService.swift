import Foundation
@testable import jpc_fit

actor MockAPIService: APIServiceProtocol {
    var foods: [Food] = []
    var healthKitCache: HealthKitCache?
    var quickAdds: [QuickAddItem] = []
    var createdFoods: [(name: String, calories: Int, protein: Int?, day: String)] = []
    var deletedIds: [String] = []
    var updatedFoods: [(id: String, name: String?, calories: Int, protein: Int?)] = []
    var createdCaches: [(active: Double, base: Double, steps: Double, day: String)] = []
    var updatedCaches: [(id: String, active: Double, base: Double, steps: Double)] = []

    var fetchFoodsCalls = 0
    /// When true, all food mutations fail — exercises the rollback paths.
    var failWrites = false

    func setFailWrites(_ fail: Bool) { failWrites = fail }

    func fetchFoods(day: String) async -> [Food] {
        fetchFoodsCalls += 1
        return foods.filter { $0.day == day }
    }

    func getFetchFoodsCalls() -> Int { fetchFoodsCalls }

    func fetchHealthKitCache(day: String) async -> HealthKitCache? {
        healthKitCache
    }

    func fetchQuickAdds() async -> [QuickAddItem] {
        quickAdds
    }

    var preferences: Preferences?

    func fetchPreferences() async -> Preferences? {
        preferences
    }

    func setPreferences(_ p: Preferences?) { preferences = p }

    @discardableResult
    func createFood(name: String, calories: Int, protein: Int?, day: String) async -> String? {
        guard !failWrites else { return nil }
        let food = Food(id: UUID().uuidString, name: name, calories: calories, protein: protein, day: day)
        foods.append(food)
        createdFoods.append((name, calories, protein, day))
        return food.id
    }

    @discardableResult
    func deleteFood(id: String) async -> Bool {
        guard !failWrites else { return false }
        foods.removeAll { $0.id == id }
        deletedIds.append(id)
        return true
    }

    @discardableResult
    func updateFood(id: String, name: String?, calories: Int, protein: Int?) async -> Bool {
        guard !failWrites else { return false }
        if let idx = foods.firstIndex(where: { $0.id == id }) {
            foods[idx] = Food(id: id, name: name, calories: calories, protein: protein, day: foods[idx].day)
        }
        updatedFoods.append((id, name, calories, protein))
        return true
    }

    func createHealthKitCache(activeCalories: Double, baseCalories: Double, steps: Double, day: String) async -> String? {
        let id = UUID().uuidString
        healthKitCache = HealthKitCache(id: id, activeCalories: activeCalories, baseCalories: baseCalories, steps: steps, day: day)
        createdCaches.append((activeCalories, baseCalories, steps, day))
        return id
    }

    func updateHealthKitCache(id: String, activeCalories: Double, baseCalories: Double, steps: Double) async {
        if let existing = healthKitCache {
            healthKitCache = HealthKitCache(id: existing.id, activeCalories: activeCalories, baseCalories: baseCalories, steps: steps, day: existing.day)
        }
        updatedCaches.append((id, activeCalories, baseCalories, steps))
    }
}
