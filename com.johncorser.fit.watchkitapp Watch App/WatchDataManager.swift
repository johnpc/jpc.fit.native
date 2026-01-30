import Foundation
import Combine
import WatchConnectivity
import HealthKit
import WidgetKit

@MainActor
class WatchDataManager: NSObject, ObservableObject {
    static let shared = WatchDataManager()
    
    @Published var authStatus: String = ""
    @Published var foods: [WatchFood] = []
    @Published var userQuickAdds: [WatchQuickAdd] = []
    @Published var consumedCalories: Int = 0
    @Published var burnedCalories: Int = 0
    @Published var steps: Int = 0
    @Published var isLoading = false
    
    var remainingCalories: Int { burnedCalories - consumedCalories }
    var quickAdds: [WatchQuickAdd] { userQuickAdds.isEmpty ? WatchQuickAdd.defaults : userQuickAdds }
    
    private let healthStore = HKHealthStore()
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private let defaults = UserDefaults(suiteName: "group.com.johncorser.fit")
    
    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
        loadCachedData()
    }
    
    func requestHealthKitAuth() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authStatus = "HK unavailable"
            return
        }
        
        let activeType = HKQuantityType(.activeEnergyBurned)
        let basalType = HKQuantityType(.basalEnergyBurned)
        let stepsType = HKQuantityType(.stepCount)
        let types: Set<HKQuantityType> = [activeType, basalType, stepsType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
            // Check if we can actually query
            await fetchHealthKitData()
        } catch {
            authStatus = "Err: \(error.localizedDescription.prefix(30))"
        }
    }
    
    func refresh() async {
        isLoading = true
        
        // Request data from phone
        if let session, session.activationState == .activated {
            session.transferUserInfo(["action": "requestData"])
            if session.isReachable {
                session.sendMessage(["action": "requestData"], replyHandler: nil, errorHandler: nil)
            }
        }
        isLoading = false
    }
    
    func addFood(name: String, calories: Int, protein: Int?) {
        let message: [String: Any] = [
            "action": "addFood",
            "name": name,
            "calories": calories,
            "protein": protein ?? 0
        ]
        session?.sendMessage(message, replyHandler: nil, errorHandler: nil)
        consumedCalories += calories
        updateComplication()
    }
    
    func deleteFood(id: String, calories: Int) {
        session?.sendMessage(["action": "deleteFood", "id": id], replyHandler: nil, errorHandler: nil)
        consumedCalories -= calories
        foods.removeAll { $0.id == id }
        updateComplication()
    }
    
    private func fetchHealthKitData() async {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        let (a, aErr) = await querySum(.activeEnergyBurned, predicate: predicate)
        let (b, bErr) = await querySum(.basalEnergyBurned, predicate: predicate)
        let (s, _) = await querySum(.stepCount, predicate: predicate)
        
        if let err = aErr ?? bErr {
            authStatus = "Err: \(err.localizedDescription.prefix(25))"
        } else {
            burnedCalories = Int(a + b)
            steps = Int(s)
            authStatus = "HK: \(Int(a))+\(Int(b))=\(burnedCalories)"
            defaults?.set(burnedCalories, forKey: "watchBurned")
        }
        
        updateComplication()
        session?.sendMessage(["action": "syncHealthKit"], replyHandler: nil, errorHandler: nil)
    }
    
    private func querySum(_ type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> (Double, Error?) {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                let unit: HKUnit = type == .stepCount ? .count() : .kilocalorie()
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: (value, error))
            }
            healthStore.execute(query)
        }
    }
    
    private func requestDataFromPhone() {
        session?.sendMessage(["action": "requestData"], replyHandler: nil, errorHandler: nil)
    }
    
    private func loadCachedData() {
        consumedCalories = defaults?.integer(forKey: "watchConsumed") ?? 0
        burnedCalories = defaults?.integer(forKey: "watchBurned") ?? 0
        
        if let data = defaults?.data(forKey: "watchQuickAdds"),
           let qa = try? JSONDecoder().decode([WatchQuickAdd].self, from: data) {
            userQuickAdds = qa
        }
    }
    
    private func updateComplication() {
        defaults?.set(consumedCalories, forKey: "watchConsumed")
        defaults?.set(burnedCalories, forKey: "watchBurned")
        defaults?.set(remainingCalories, forKey: "watchRemaining")
        defaults?.synchronize()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension WatchDataManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let consumed = message["consumed"] as? Int {
                consumedCalories = consumed
            }
            if let burned = message["burned"] as? Int {
                burnedCalories = burned
            }
            if let foodsData = message["foods"] as? [[String: Any]] {
                foods = foodsData.compactMap { WatchFood(dict: $0) }
            }
            if let qaData = message["quickAdds"] as? [[String: Any]] {
                userQuickAdds = qaData.compactMap { WatchQuickAdd(dict: $0) }
                if let encoded = try? JSONEncoder().encode(userQuickAdds) {
                    defaults?.set(encoded, forKey: "watchQuickAdds")
                }
            }
            authStatus = "Phone"
            updateComplication()
        }
    }
}

struct WatchFood: Identifiable {
    let id: String
    let name: String
    let calories: Int
    
    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let calories = dict["calories"] as? Int else { return nil }
        self.id = id
        self.name = name
        self.calories = calories
    }
}

struct WatchQuickAdd: Identifiable, Codable {
    let id: String
    let name: String
    let calories: Int
    let icon: String
    let protein: Int?
    
    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let calories = dict["calories"] as? Int else { return nil }
        self.id = id
        self.name = name
        self.calories = calories
        self.icon = dict["icon"] as? String ?? "🍽️"
        self.protein = dict["protein"] as? Int
    }
    
    init(id: String, name: String, calories: Int, icon: String, protein: Int?) {
        self.id = id
        self.name = name
        self.calories = calories
        self.icon = icon
        self.protein = protein
    }
    
    static let defaults: [WatchQuickAdd] = [
        WatchQuickAdd(id: "dqa-100", name: "xx-small", calories: 100, icon: "🍎", protein: nil),
        WatchQuickAdd(id: "dqa-250", name: "x-small", calories: 250, icon: "🍽️", protein: nil),
        WatchQuickAdd(id: "dqa-500", name: "small", calories: 500, icon: "🍕", protein: nil),
        WatchQuickAdd(id: "dqa-750", name: "medium", calories: 750, icon: "🍽️", protein: nil),
    ]
}
