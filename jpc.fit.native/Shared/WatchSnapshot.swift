import Foundation

/// A food row as the watch shows it.
struct WatchFood: Identifiable, Equatable {
    let id: String
    let name: String
    let calories: Int

    var message: [String: Any] { ["id": id, "name": name, "calories": calories] }

    init(id: String, name: String, calories: Int) {
        self.id = id
        self.name = name
        self.calories = calories
    }

    init?(message: [String: Any]) {
        guard let id = message["id"] as? String, let name = message["name"] as? String,
              let calories = message["calories"] as? Int else { return nil }
        self.init(id: id, name: name, calories: calories)
    }
}

/// A quick-add tile as the watch shows it (also cached on the watch).
struct WatchQuickAdd: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let calories: Int
    let icon: String
    let protein: Int?

    var message: [String: Any] {
        ["id": id, "name": name, "calories": calories, "icon": icon, "protein": protein ?? 0]
    }

    init(id: String, name: String, calories: Int, icon: String, protein: Int?) {
        self.id = id
        self.name = name
        self.calories = calories
        self.icon = icon
        self.protein = protein
    }

    init?(message: [String: Any]) {
        guard let row = WatchFood(message: message) else { return nil }
        let protein = message["protein"] as? Int
        self.init(id: row.id, name: row.name, calories: row.calories,
                  icon: message["icon"] as? String ?? "🍽️", protein: protein == 0 ? nil : protein)
    }
}

/// Phone → watch state: today's totals, rows and tiles, in one message.
struct WatchSnapshot: Equatable {
    let consumed: Int
    let burned: Int
    let foods: [WatchFood]
    let quickAdds: [WatchQuickAdd]

    init(consumed: Int, burned: Int, foods: [WatchFood], quickAdds: [WatchQuickAdd]) {
        self.consumed = consumed
        self.burned = burned
        self.foods = foods
        self.quickAdds = quickAdds
    }

    /// nil when the message is not a snapshot (e.g. it is a `WatchCommand`).
    init?(message: [String: Any]) {
        guard let consumed = message["consumed"] as? Int, let burned = message["burned"] as? Int else { return nil }
        let foods = (message["foods"] as? [[String: Any]] ?? []).compactMap(WatchFood.init(message:))
        let quickAdds = (message["quickAdds"] as? [[String: Any]] ?? []).compactMap(WatchQuickAdd.init(message:))
        self.init(consumed: consumed, burned: burned, foods: foods, quickAdds: quickAdds)
    }

    var message: [String: Any] {
        ["consumed": consumed, "burned": burned,
         "foods": foods.map(\.message), "quickAdds": quickAdds.map(\.message)]
    }
}
