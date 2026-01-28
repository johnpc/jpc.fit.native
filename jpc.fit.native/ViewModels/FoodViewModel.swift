import Foundation
import WidgetKit

extension Notification.Name {
    static let foodDataChanged = Notification.Name("foodDataChanged")
}

@MainActor
class FoodViewModel: ObservableObject {
    @Published var foods: [Food] = []
    @Published var healthKitCache: HealthKitCache?
    @Published var userQuickAdds: [QuickAddItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    private let healthKit = HealthKitService.shared
    
    var totalCalories: Int { foods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { foods.reduce(0) { $0 + ($1.protein ?? 0) } }
    var burnedCalories: Int { Int(healthKitCache?.activeCalories ?? 0) + Int(healthKitCache?.baseCalories ?? 0) }
    var remainingCalories: Int { burnedCalories - totalCalories }
    var quickAdds: [QuickAddItem] { userQuickAdds.isEmpty ? defaultQuickAdds : userQuickAdds }
    
    func requestHealthKitPermission() async {
        await healthKit.requestAuthorization()
    }
    
    func fetchAll(day: String, date: Date) async {
        isLoading = true
        errorMessage = nil
        async let foodsTask = api.fetchFoods(day: day)
        async let cacheTask = api.fetchHealthKitCache(day: day)
        async let quickAddsTask = api.fetchQuickAdds()
        
        let (f, c, q) = await (foodsTask, cacheTask, quickAddsTask)
        foods = f
        healthKitCache = c
        userQuickAdds = q
        
        // Sync HealthKit after we know if cache exists
        await syncHealthKit(day: day, date: date)
        
        isLoading = false
        updateWidget(day: day)
    }
    
    func addFood(name: String, calories: Int, protein: Int? = nil, day: String) async {
        await api.createFood(name: name, calories: calories, protein: protein, day: day)
        foods = await api.fetchFoods(day: day)
        updateWidget(day: day)
        NotificationCenter.default.post(name: .foodDataChanged, object: nil)
    }
    
    func deleteFood(_ food: Food, day: String) async {
        await api.deleteFood(id: food.id)
        foods = await api.fetchFoods(day: day)
        updateWidget(day: day)
        NotificationCenter.default.post(name: .foodDataChanged, object: nil)
    }
    
    private func updateWidget(day: String) {
        // Only update widget with today's consumed calories
        let today = Date().formatted(date: .numeric, time: .omitted)
        if day == today {
            SharedDataManager.shared.save(consumed: totalCalories)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func syncHealthKit(day: String, date: Date) async {
        let stats = await healthKit.fetchStats(for: date)
        guard stats.active > 0 || stats.basal > 0 || stats.steps > 0 else { return }
        
        if let existing = healthKitCache {
            await api.updateHealthKitCache(id: existing.id, activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps)
            healthKitCache = HealthKitCache(id: existing.id, activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: day)
        } else {
            let newId = await api.createHealthKitCache(activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: day)
            healthKitCache = HealthKitCache(id: newId ?? UUID().uuidString, activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: day)
        }
    }
}
