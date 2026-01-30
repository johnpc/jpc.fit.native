import Foundation
import WatchConnectivity

@MainActor
class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private let api = APIService.shared
    
    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }
    
    func sendDataToWatch() {
        guard let session, session.isReachable else { return }
        
        Task {
            let day = Date().formatted(date: .numeric, time: .omitted)
            let foods = await api.fetchFoods(day: day)
            let quickAdds = await api.fetchQuickAdds()
            let cache = await api.fetchHealthKitCache(day: day)
            
            let consumed = foods.reduce(0) { $0 + $1.calories }
            let burned = Int(cache?.activeCalories ?? 0) + Int(cache?.baseCalories ?? 0)
            
            let foodsData = foods.map { ["id": $0.id, "name": $0.name ?? "Food", "calories": $0.calories] as [String: Any] }
            let qaData = quickAdds.map { ["id": $0.id, "name": $0.name, "calories": $0.calories, "icon": $0.icon, "protein": $0.protein ?? 0] as [String: Any] }
            
            let message: [String: Any] = [
                "consumed": consumed,
                "burned": burned,
                "foods": foodsData,
                "quickAdds": qaData
            ]
            
            session.sendMessage(message, replyHandler: nil)
        }
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
        Task { @MainActor in
            guard let action = message["action"] as? String else { return }
            let day = Date().formatted(date: .numeric, time: .omitted)
            
            switch action {
            case "requestData":
                sendDataToWatch()
                
            case "addFood":
                if let name = message["name"] as? String,
                   let calories = message["calories"] as? Int {
                    let protein = message["protein"] as? Int
                    await api.createFood(name: name, calories: calories, protein: protein == 0 ? nil : protein, day: day)
                    sendDataToWatch()
                    NotificationCenter.default.post(name: .foodDataChanged, object: nil)
                }
                
            case "deleteFood":
                if let id = message["id"] as? String {
                    await api.deleteFood(id: id)
                    sendDataToWatch()
                    NotificationCenter.default.post(name: .foodDataChanged, object: nil)
                }
                
            case "syncHealthKit":
                await BackgroundSyncService.shared.syncHealthKit()
                sendDataToWatch()
                
            default:
                break
            }
        }
    }
}
