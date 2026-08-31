import Foundation

struct DayStats {
    let day: String
    let shortDay: String
    let consumed: Int
    let burned: Int
    var net: Int { consumed - burned }
    let tracked: Bool
    /// The request for this day failed — distinct from "nothing logged".
    var failed: Bool = false
}

@MainActor
class StatsViewModel: ObservableObject {
    /// Last day of the visible 7-day window (it ends on this date).
    @Published var weekEndDate = Date()
    @Published var weekData: [DayStats] = []
    /// Always the ACTUAL most recent days — feeds the streak flame strip,
    /// which must not follow week navigation into the past.
    @Published var recentDays: [DayStats] = []
    @Published var isLoading = true
    @Published var streakDays: Int?
    @Published var streakNet = 0

    let api: APIServiceProtocol
    let healthKit = HealthKitService.shared
    private var weekTask: Task<Void, Never>?

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    var weekNet: Int { weekData.filter { $0.tracked }.reduce(0) { $0 + $1.net } }
    var trackedCount: Int { weekData.filter { $0.tracked }.count }
    var streakLbs: Double { Double(streakNet) / 3500.0 }
    var isViewingCurrentWeek: Bool { Calendar.current.isDateInToday(weekEndDate) }

    /// "12" or "365+" once the walk hits the cap; nil while still computing.
    var streakDaysLabel: String? {
        guard let days = streakDays else { return nil }
        return days >= Self.streakCap ? "\(days)+" : "\(days)"
    }

    /// Magnitude-only estimate — the direction comes from the word, so a
    /// deficit reads "Est. 2.0 lbs lost", never "-2.0 lbs lost".
    var streakLbsText: String {
        if streakNet == 0 { return "Breaking even so far" }
        return String(format: "Est. %.1f lbs %@", abs(streakLbs), streakNet > 0 ? "gained" : "lost")
    }

    var weekRangeString: String {
        let end = weekEndDate
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
        return "\(start.formatted(date: .numeric, time: .omitted)) - \(end.formatted(date: .numeric, time: .omitted))"
    }

    func changeWeek(_ days: Int) {
        guard let moved = Calendar.current.date(byAdding: .day, value: days, to: weekEndDate) else { return }
        weekEndDate = moved
        reloadWeek()
    }

    func goToToday() {
        weekEndDate = Date()
        reloadWeek()
    }

    /// Cancels any in-flight week fetch first, so rapid chevron taps can't
    /// paint week A's rows under week C's label.
    func reloadWeek() {
        weekTask?.cancel()
        weekTask = Task { await fetchWeek() }
    }

    func refresh() async {
        weekTask?.cancel()
        // Week and streak are independent — run them concurrently so the
        // screen settles in max(week, streak) rather than the sum.
        async let week: Void = fetchWeek()
        async let streak: Void = fetchStreak()
        _ = await (week, streak)
    }
}
