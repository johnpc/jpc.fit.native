import Foundation

/// Streak computation for `StatsViewModel` — walks back day-by-day (in
/// concurrent batches) until it finds an untracked day or hits the cap.
extension StatsViewModel {
    /// Longest streak we'll walk back — bounds the query count (a 3-year
    /// streak was ~2,200 requests on every refresh). The UI shows "365+".
    static let streakCap = 365

    func fetchStreak() async {
        var days = 0
        var net = 0
        var offset = 0
        let batchSize = 14
        while days < Self.streakCap {
            let dates = (0..<batchSize).compactMap { Calendar.current.date(byAdding: .day, value: -(offset + $0), to: Date()) }
            let results = await withTaskGroup(of: (Int, [Int]?, Int).self) { group in
                for (i, date) in dates.enumerated() {
                    group.addTask {
                        let dayString = DayKey.string(from: date)
                        async let foods = self.api.fetchFoodCalories(day: dayString)
                        async let burned = self.fetchAndSyncBurned(day: dayString, date: date)
                        return (i, await foods, await burned)
                    }
                }
                var arr = [(Int, [Int]?, Int)]()
                for await r in group { arr.append(r) }
                return arr.sorted { $0.0 < $1.0 }
            }
            for (i, foods, burned) in results {
                // nil = request failed. Don't call the streak over — leave the
                // last known value on screen rather than reporting a false 0.
                guard let foods else { return }
                if foods.isEmpty {
                    // Today (the first day of the walk) not being tracked YET
                    // doesn't break the streak — at 7am, before breakfast is
                    // logged, yesterday's streak is still alive. Any other
                    // empty day ends it.
                    if offset + i == 0 { continue }
                    streakDays = min(days, Self.streakCap)
                    streakNet = net
                    return
                }
                days += 1
                net += foods.reduce(0, +) - burned
            }
            offset += batchSize
        }
        streakDays = min(days, Self.streakCap)
        streakNet = net
    }
}
