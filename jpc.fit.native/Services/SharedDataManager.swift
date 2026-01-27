import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    private let suiteName = "group.com.johncorser.fit"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    func save(consumed: Int) {
        defaults?.set(consumed, forKey: "todayConsumed")
    }
}
