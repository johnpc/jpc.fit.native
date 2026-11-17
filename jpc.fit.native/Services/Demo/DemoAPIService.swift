import Foundation

/// The in-process fake backend: the full `APIServiceProtocol` over in-memory
/// tables seeded by `DemoSeed`. Zero network, zero credentials, deterministic
/// — what the acceptance suite, CI and "try it without an account" run on.
/// Writes behave like the real backend (ids come back, rows persist for the
/// process lifetime) so every optimistic-UI path is exercised for real.
actor DemoAPIService {
    var foods: [Food]
    var caches: [String: HealthKitCache]
    var quickAdds: [QuickAddItem]
    var preferences: Preferences?
    var weights: [Weight]
    var heights: [Height]

    init(now: Date = Date()) {
        foods = DemoSeed.foods(now: now)
        caches = DemoSeed.caches(now: now)
        quickAdds = DemoSeed.quickAdds
        preferences = nil
        weights = DemoSeed.weights(now: now)
        heights = DemoSeed.heights(now: now)
    }

    private func newId() -> String { "demo-" + UUID().uuidString.lowercased() }
}

extension DemoAPIService: APIServiceProtocol {
    func fetchFoods(day: String) async -> [Food] {
        foods.filter { $0.day == day }
    }

    func fetchHealthKitCache(day: String) async -> HealthKitCache? {
        caches[day]
    }

    func createFood(name: String, calories: Int, protein: Int?, day: String) async -> String? {
        let food = Food(id: newId(), name: name, calories: calories, protein: protein, day: day)
        foods.append(food)
        return food.id
    }

    func deleteFood(id: String) async -> Bool {
        let before = foods.count
        foods.removeAll { $0.id == id }
        return foods.count < before
    }

    func updateFood(id: String, name: String?, calories: Int, protein: Int?) async -> Bool {
        guard let idx = foods.firstIndex(where: { $0.id == id }) else { return false }
        var food = foods[idx]
        if let name { food.name = name }
        food.calories = calories
        food.protein = protein
        foods[idx] = food
        return true
    }

    func createHealthKitCache(activeCalories: Double, baseCalories: Double, steps: Double, day: String) async -> String? {
        let row = HealthKitCache(id: newId(), activeCalories: activeCalories, baseCalories: baseCalories, steps: steps, day: day)
        caches[day] = row
        return row.id
    }

    func updateHealthKitCache(id: String, activeCalories: Double, baseCalories: Double, steps: Double) async {
        guard let day = caches.first(where: { $0.value.id == id })?.key else { return }
        caches[day] = HealthKitCache(id: id, activeCalories: activeCalories, baseCalories: baseCalories, steps: steps, day: day)
    }

    func fetchFoodCalories(day: String) async -> [Int]? {
        foods.filter { $0.day == day }.map(\.calories)
    }

    func fetchCacheBurned(day: String) async -> Int {
        guard let cache = caches[day] else { return 0 }
        return Int(cache.activeCalories + cache.baseCalories)
    }

    func fetchWeights() async -> [Weight] { weights }
    func fetchHeights() async -> [Height] { heights }

    func createWeight(_ pounds: Int) async -> WriteOutcome {
        let row = Weight(id: newId(), currentWeight: pounds, createdAt: .now())
        weights.insert(row, at: 0)
        return .saved(id: row.id)
    }

    func createHeight(_ inches: Int) async -> WriteOutcome {
        let row = Height(id: newId(), currentHeight: inches, createdAt: .now())
        heights.insert(row, at: 0)
        return .saved(id: row.id)
    }
}
