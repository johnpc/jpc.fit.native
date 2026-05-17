import Foundation

protocol APIServiceProtocol: Sendable {
    func fetchFoods(day: String) async -> [Food]
    func fetchHealthKitCache(day: String) async -> HealthKitCache?
    func fetchQuickAdds() async -> [QuickAddItem]
    func createFood(name: String, calories: Int, protein: Int?, day: String) async
    func deleteFood(id: String) async
    func updateFood(id: String, name: String?, calories: Int, protein: Int?) async
    func createHealthKitCache(activeCalories: Double, baseCalories: Double, steps: Double, day: String) async -> String?
    func updateHealthKitCache(id: String, activeCalories: Double, baseCalories: Double, steps: Double) async
}

extension APIService: APIServiceProtocol {}
