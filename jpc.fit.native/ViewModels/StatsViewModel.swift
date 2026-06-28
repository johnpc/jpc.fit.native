import Foundation
import Amplify
import HealthKit

struct DayStats {
    let day: String
    let shortDay: String
    let consumed: Int
    let burned: Int
    var net: Int { consumed - burned }
    let tracked: Bool
}

@MainActor
class StatsViewModel: ObservableObject {
    @Published var weekStartDate = Date()
    @Published var weekData: [DayStats] = []
    @Published var isLoading = true
    @Published var streakDays: Int?
    @Published var streakNet = 0

    var weekNet: Int { weekData.filter { $0.tracked }.reduce(0) { $0 + $1.net } }
    var trackedCount: Int { weekData.filter { $0.tracked }.count }
    var streakLbs: Double { Double(streakNet) / 3500.0 }

    var weekRangeString: String {
        let end = weekStartDate
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end)!
        return "\(start.formatted(date: .numeric, time: .omitted)) - \(end.formatted(date: .numeric, time: .omitted))"
    }

    func changeWeek(_ days: Int) {
        weekStartDate = Calendar.current.date(byAdding: .day, value: days, to: weekStartDate)!
        Task { await fetchWeek() }
    }

    func refresh() async {
        await fetchWeek()
        await fetchStreak()
    }

    func fetchWeek() async {
        isLoading = true
        var results: [DayStats] = []
        for i in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: weekStartDate)!
            let dayString = date.formatted(date: .numeric, time: .omitted)
            async let foods = fetchFoodCalories(day: dayString)
            async let burned = fetchAndSyncCache(day: dayString, date: date)
            let (f, b) = await (foods, burned)
            let consumed = f.reduce(0, +)
            let parts = dayString.split(separator: "/")
            let shortDay = parts.count >= 2 ? "\(parts[0])/\(parts[1])" : dayString
            results.append(DayStats(day: dayString, shortDay: String(shortDay), consumed: consumed, burned: b, tracked: !f.isEmpty))
        }
        weekData = results
        isLoading = false
    }

    func fetchStreak() async {
        var days = 0
        var net = 0
        var offset = 0
        let batchSize = 14
        while true {
            let dates = (0..<batchSize).map { Calendar.current.date(byAdding: .day, value: -(offset + $0), to: Date())! }
            let results = await withTaskGroup(of: (Int, [Int], Int).self) { group in
                for (i, date) in dates.enumerated() {
                    group.addTask {
                        let dayString = date.formatted(date: .numeric, time: .omitted)
                        async let foods = self.fetchFoodCalories(day: dayString)
                        async let burned = self.fetchCacheBurned(day: dayString)
                        return (i, await foods, await burned)
                    }
                }
                var arr = [(Int, [Int], Int)]()
                for await r in group { arr.append(r) }
                return arr.sorted { $0.0 < $1.0 }
            }
            for (_, foods, burned) in results {
                if foods.isEmpty { streakDays = days; streakNet = net; return }
                days += 1
                net += foods.reduce(0, +) - burned
            }
            offset += batchSize
        }
    }

    nonisolated func fetchAndSyncCache(day: String, date: Date) async -> Int {
        let cached = await fetchCacheBurned(day: day)
        if cached > 0 { return cached }
        let stats = await fetchHealthKit(date: date)
        if stats.active > 0 || stats.basal > 0 {
            await createCache(day: day, active: stats.active, basal: stats.basal, steps: stats.steps)
            return Int(stats.active + stats.basal)
        }
        return 0
    }
}
