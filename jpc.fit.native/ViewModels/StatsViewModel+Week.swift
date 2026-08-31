import Foundation

/// Weekly aggregation for `StatsViewModel`: the visible 7-day window, all
/// days fetched concurrently (they're independent — serially this was 7
/// sequential round-trip waves).
extension StatsViewModel {
    func fetchWeek() async {
        isLoading = true
        defer { isLoading = false }
        let calendar = Calendar.current
        let endDate = weekEndDate
        let days: [(index: Int, date: Date)] = (0..<7).reversed().compactMap { i in
            calendar.date(byAdding: .day, value: -i, to: endDate).map { (6 - i, $0) }
        }
        let results = await withTaskGroup(of: (Int, DayStats).self) { group in
            for (index, date) in days {
                group.addTask { (index, await self.fetchDay(date: date)) }
            }
            var arr = [(Int, DayStats)]()
            for await r in group { arr.append(r) }
            return arr.sorted { $0.0 < $1.0 }.map(\.1)
        }
        // A newer fetch (chevron tap or refresh) may have superseded this one
        // while it was in flight — don't paint stale rows under a new label.
        guard !Task.isCancelled, weekEndDate == endDate else { return }
        weekData = results
        if Calendar.current.isDateInToday(endDate) { recentDays = results }
    }

    nonisolated private func fetchDay(date: Date) async -> DayStats {
        let dayString = DayKey.string(from: date)
        async let foodsTask = api.fetchFoodCalories(day: dayString)
        async let burnedTask = fetchAndSyncBurned(day: dayString, date: date)
        let (foods, burned) = await (foodsTask, burnedTask)
        let shortDay = date.formatted(.dateTime.month(.defaultDigits).day())
        return DayStats(day: dayString, shortDay: shortDay,
                        consumed: (foods ?? []).reduce(0, +), burned: burned,
                        tracked: !(foods ?? []).isEmpty, failed: foods == nil)
    }

    /// Cache-first burn lookup with HealthKit backfill: days that predate the
    /// cache get their burn computed locally and written back for next time.
    nonisolated func fetchAndSyncBurned(day: String, date: Date) async -> Int {
        let cached = await api.fetchCacheBurned(day: day)
        if cached > 0 { return cached }
        let stats = await healthKit.fetchStats(for: date)
        if stats.active > 0 || stats.basal > 0 {
            _ = await api.createHealthKitCache(activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: day)
            return Int(stats.active + stats.basal)
        }
        return 0
    }
}
