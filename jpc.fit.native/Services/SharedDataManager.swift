import Foundation

struct SharedData: Codable {
    var burned: Int
    var consumed: Int
    var day: String
}

class SharedDataManager {
    static let shared = SharedDataManager()
    private let suiteName = "group.com.johncorser.fit"
    private let key = "widgetData"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    func save(burned: Int, consumed: Int, day: String) {
        let data = SharedData(burned: burned, consumed: consumed, day: day)
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: key)
        }
    }
    
    func load() -> SharedData? {
        guard let data = defaults?.data(forKey: key),
              let decoded = try? JSONDecoder().decode(SharedData.self, from: data) else { return nil }
        return decoded
    }
}
