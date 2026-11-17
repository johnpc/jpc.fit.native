import Foundation

/// StateMachine: Day record
///
/// One day in the Stats tables. `tracked: Bool` + `failed: Bool` allowed the
/// impossible "tracked AND failed"; the status is now one value.
struct DayStats: Equatable {
    enum Status: Equatable {
        case tracked
        case untracked
        /// The request for this day failed — distinct from "nothing logged".
        case failed
    }

    let day: String
    let shortDay: String
    let consumed: Int
    let burned: Int
    let status: Status

    var net: Int { consumed - burned }
    var tracked: Bool { status == .tracked }
    var failed: Bool { status == .failed }
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
    @Published var streak: StreakState = .computing
    /// Bumped whenever the gate decides the screen must refresh; the view's
    /// `.task(id:)` keys on it so the view holds no refresh state of its own.
    @Published private(set) var refreshToken = UUID()
    private(set) var gate: RefreshGate = .offScreen(stale: false)

    let api: APIServiceProtocol
    let healthKit: HealthStatsProviding
    private var weekTask: Task<Void, Never>?

    init(api: APIServiceProtocol = AppServices.api, healthKit: HealthStatsProviding = AppServices.health) {
        self.api = api
        self.healthKit = healthKit
    }

    var weekNet: Int { weekData.filter { $0.tracked }.reduce(0) { $0 + $1.net } }
    var trackedCount: Int { weekData.filter { $0.tracked }.count }
    var isViewingCurrentWeek: Bool { Calendar.current.isDateInToday(weekEndDate) }
    var streakDaysLabel: String? { streak.daysLabel(cap: Self.streakCap) }

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
        async let streakWalk: Void = fetchStreak()
        _ = await (week, streakWalk)
    }

    // MARK: Off-screen refresh gate (see Models/RefreshGate.swift)

    func appeared() { apply(gate.appeared()) }
    func disappeared() { gate.disappeared() }
    func foodDataChanged() { apply(gate.dataChanged()) }

    private func apply(_ decision: RefreshGate.Decision) {
        if decision == .refreshNow { refreshToken = UUID() }
    }
}
