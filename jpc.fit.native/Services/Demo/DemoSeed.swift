import Foundation

/// The fake backend's starting data, generated around "now" so it is never
/// stale: today has two meals, the 12 days before it are all tracked (streak
/// = 13 with today), the 13th day back is empty (the streak's end), and every
/// day in that span has a HealthKit cache row. Deterministic by construction
/// — the acceptance suite asserts on these exact numbers.
enum DemoSeed {
    static let trackedPastDays = 12
    static let todayFoods: [(name: String, calories: Int, protein: Int?)] = [
        ("☕ Coffee", 50, nil),
        ("🥗 Salad", 450, 20),
    ]
    static let pastDayFoods: [(name: String, calories: Int, protein: Int?)] = [
        ("🍳 Breakfast", 500, 25),
        ("🍽️ Lunch", 750, 35),
        ("🍕 Dinner", 800, 30),
    ]
    static let activeCalories = 420.0
    static let basalCalories = 1750.0
    static let steps = 8200.0
    static let quickAdds: [QuickAddItem] = [
        QuickAddItem(id: "demo-qa-coffee", name: "Coffee", calories: 50, icon: "☕", protein: nil),
        QuickAddItem(id: "demo-qa-salad", name: "Salad", calories: 450, icon: "🥗", protein: 20),
        QuickAddItem(id: "demo-qa-pizza", name: "Pizza slice", calories: 300, icon: "🍕", protein: 12),
    ]

    static func dayKey(daysAgo: Int, now: Date, calendar: Calendar = .current) -> String {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        return DayKey.string(from: date)
    }

    static func foods(now: Date) -> [Food] {
        var rows: [Food] = []
        let today = dayKey(daysAgo: 0, now: now)
        for (index, meal) in todayFoods.enumerated() {
            rows.append(Food(id: "demo-food-0-\(index)", name: meal.name, calories: meal.calories, protein: meal.protein, day: today))
        }
        for daysAgo in 1...trackedPastDays {
            let day = dayKey(daysAgo: daysAgo, now: now)
            for (index, meal) in pastDayFoods.enumerated() {
                rows.append(Food(id: "demo-food-\(daysAgo)-\(index)", name: meal.name, calories: meal.calories, protein: meal.protein, day: day))
            }
        }
        return rows
    }

    /// One cache row per seeded day (today through the first empty day).
    static func caches(now: Date) -> [String: HealthKitCache] {
        var rows: [String: HealthKitCache] = [:]
        for daysAgo in 0...(trackedPastDays + 1) {
            let day = dayKey(daysAgo: daysAgo, now: now)
            rows[day] = HealthKitCache(id: "demo-cache-\(daysAgo)", activeCalories: activeCalories,
                                       baseCalories: basalCalories, steps: steps, day: day)
        }
        return rows
    }

    static func weights(now: Date) -> [Weight] {
        [Weight(id: "demo-weight", currentWeight: 182, createdAt: .init(now))]
    }

    static func heights(now: Date) -> [Height] {
        [Height(id: "demo-height", currentHeight: 70, createdAt: .init(now))]
    }
}
