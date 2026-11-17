import Foundation
import Combine
import WatchConnectivity
import HealthKit
import WidgetKit

/// Owner of the watch's two machines — `WatchHealthStatus` (where the burn
/// number came from) and `PhoneLink` (is the phone reachable) — plus today's
/// totals. Talks to the phone only through `WatchCommand` / `WatchSnapshot`.
@MainActor
class WatchDataManager: NSObject, ObservableObject {
    static let shared = WatchDataManager()

    @Published var health: WatchHealthStatus = .unknown
    @Published var phoneLink: PhoneLink = .unknown
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
            health = .unavailable
            return
        }
        let types: Set<HKQuantityType> = [HKQuantityType(.activeEnergyBurned), HKQuantityType(.basalEnergyBurned), HKQuantityType(.stepCount)]
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
            await fetchHealthKitData()
        } catch {
            health = .failed(error.localizedDescription)
        }
    }

    func refresh() async {
        isLoading = true
        await fetchHealthKitData()
        if let session, session.activationState == .activated {
            phoneLink = .from(isReachable: session.isReachable)
            send(.requestData, fallbackToTransfer: true)
        }
        isLoading = false
    }

    func addFood(name: String, calories: Int, protein: Int?) {
        send(.addFood(name: name, calories: calories, protein: protein))
        consumedCalories += calories
        updateComplication()
    }

    func deleteFood(id: String, calories: Int) {
        send(.deleteFood(id: id))
        consumedCalories -= calories
        foods.removeAll { $0.id == id }
        updateComplication()
    }

    /// Live message when reachable; `transferUserInfo` queues it otherwise.
    private func send(_ command: WatchCommand, fallbackToTransfer: Bool = false) {
        guard let session else { return }
        if session.isReachable || !fallbackToTransfer {
            session.sendMessage(command.message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(command.message)
        }
    }

    private func fetchHealthKitData() async {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let (a, aErr) = await querySum(.activeEnergyBurned, predicate: predicate)
        let (b, bErr) = await querySum(.basalEnergyBurned, predicate: predicate)
        let (s, _) = await querySum(.stepCount, predicate: predicate)

        if let err = aErr ?? bErr {
            health = .failed(err.localizedDescription)
        } else {
            burnedCalories = Int(a + b)
            steps = Int(s)
            health = .measured(active: Int(a), basal: Int(b))
            defaults?.set(burnedCalories, forKey: "watchBurned")
        }
        updateComplication()
        send(.syncHealthKit)
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
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Applies a phone snapshot: totals, rows, tiles (cached for next launch).
    func apply(_ snapshot: WatchSnapshot) {
        consumedCalories = snapshot.consumed
        burnedCalories = snapshot.burned
        foods = snapshot.foods
        userQuickAdds = snapshot.quickAdds
        if let encoded = try? JSONEncoder().encode(userQuickAdds) {
            defaults?.set(encoded, forKey: "watchQuickAdds")
        }
        health = .fromPhone
        updateComplication()
    }
}

extension WatchDataManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let snapshot = WatchSnapshot(message: message) else { return }
        Task { @MainActor in apply(snapshot) }
    }
}

extension WatchQuickAdd {
    static let defaults: [WatchQuickAdd] = [
        WatchQuickAdd(id: "dqa-100", name: "xx-small", calories: 100, icon: "🍎", protein: nil),
        WatchQuickAdd(id: "dqa-250", name: "x-small", calories: 250, icon: "🍽️", protein: nil),
        WatchQuickAdd(id: "dqa-500", name: "small", calories: 500, icon: "🍕", protein: nil),
        WatchQuickAdd(id: "dqa-750", name: "medium", calories: 750, icon: "🍽️", protein: nil),
    ]
}
