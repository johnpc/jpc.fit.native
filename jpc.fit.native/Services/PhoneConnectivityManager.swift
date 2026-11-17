import Foundation
import WatchConnectivity

/// Phone side of the watch link. Every message is a `WatchCommand` (watch →
/// phone) or a `WatchSnapshot` (phone → watch) — the shared codec in
/// `Shared/` is the only place the dictionary keys exist.
@MainActor
class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    /// Read at use time: the shared instance is built before `AppServices.configure`.
    private var api: APIServiceProtocol { AppServices.api }

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func sendDataToWatch() {
        guard let session, session.isReachable else { return }
        Task {
            let snapshot = await buildSnapshot()
            session.sendMessage(snapshot.message, replyHandler: nil)
        }
    }

    private func buildSnapshot() async -> WatchSnapshot {
        let day = DayKey.today
        let foods = await api.fetchFoods(day: day)
        let quickAdds = await api.fetchQuickAdds()
        let cache = await api.fetchHealthKitCache(day: day)
        return WatchSnapshot(
            consumed: foods.reduce(0) { $0 + $1.calories },
            burned: Int(cache?.activeCalories ?? 0) + Int(cache?.baseCalories ?? 0),
            foods: foods.map { WatchFood(id: $0.id, name: $0.name ?? "Food", calories: $0.calories) },
            quickAdds: quickAdds.map { WatchQuickAdd(id: $0.id, name: $0.name, calories: $0.calories, icon: $0.icon, protein: $0.protein) })
    }

    private func handle(_ command: WatchCommand) async {
        switch command {
        case .requestData:
            break
        case .addFood(let name, let calories, let protein):
            await api.createFood(name: name, calories: calories, protein: protein, day: DayKey.today)
            NotificationCenter.default.post(name: .foodDataChanged, object: nil)
        case .deleteFood(let id):
            await api.deleteFood(id: id)
            NotificationCenter.default.post(name: .foodDataChanged, object: nil)
        case .syncHealthKit:
            await BackgroundSyncService.shared.syncHealthKit()
        }
        sendDataToWatch()
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleMessage(userInfo)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }

    private nonisolated func handleMessage(_ message: [String: Any]) {
        guard let command = WatchCommand(message: message) else { return }
        Task { @MainActor in await handle(command) }
    }
}
