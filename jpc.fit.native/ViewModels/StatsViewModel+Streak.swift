import Foundation

/// Streak computation for `StatsViewModel` — walks back day-by-day (in
/// concurrent batches) until it finds an untracked day or hits the cap.
extension StatsViewModel {
    /// Longest streak we'll walk back — bounds the query count (a 3-year
    /// streak was ~2,200 requests on every refresh). The UI shows "365+".
    static let streakCap = 365

    /// One day of the walk: nil calories = the request failed.
    struct StreakDay {
        let offset: Int
        let calories: [Int]?
        let burned: Int
    }

    private enum WalkStep {
        case tracked(net: Int)
        case skipToday
        case streakEnded
        case requestFailed
    }

    func fetchStreak() async {
        var days = 0
        var net = 0
        var offset = 0
        while days < Self.streakCap {
            for day in await fetchStreakBatch(startingAt: offset) {
                switch classify(day) {
                case .tracked(let dayNet):
                    days += 1
                    net += dayNet
                case .skipToday:
                    continue
                case .streakEnded:
                    finishStreak(days: days, net: net)
                    return
                case .requestFailed:
                    // Leave the last known value on screen rather than
                    // reporting a false 0.
                    return
                }
            }
            offset += 14
        }
        finishStreak(days: days, net: net)
    }

    private func classify(_ day: StreakDay) -> WalkStep {
        guard let calories = day.calories else { return .requestFailed }
        if calories.isEmpty {
            // Today (offset 0) not being tracked YET doesn't break the streak —
            // at 7am, before breakfast is logged, yesterday's streak is still
            // alive. Any other empty day ends it.
            return day.offset == 0 ? .skipToday : .streakEnded
        }
        return .tracked(net: calories.reduce(0, +) - day.burned)
    }

    private func finishStreak(days: Int, net: Int) {
        streakDays = min(days, Self.streakCap)
        streakNet = net
    }

    /// Fetches 14 consecutive days concurrently, returned in walk order.
    private func fetchStreakBatch(startingAt offset: Int) async -> [StreakDay] {
        let dates = (0..<14).compactMap { i in
            Calendar.current.date(byAdding: .day, value: -(offset + i), to: Date()).map { (offset + i, $0) }
        }
        return await withTaskGroup(of: StreakDay.self) { group in
            for (dayOffset, date) in dates {
                group.addTask {
                    let dayString = DayKey.string(from: date)
                    async let foods = self.api.fetchFoodCalories(day: dayString)
                    async let burned = self.fetchAndSyncBurned(day: dayString, date: date)
                    return StreakDay(offset: dayOffset, calories: await foods, burned: await burned)
                }
            }
            var arr = [StreakDay]()
            for await r in group { arr.append(r) }
            return arr.sorted { $0.offset < $1.offset }
        }
    }
}
