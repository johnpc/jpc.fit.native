import XCTest
@testable import jpc_fit

/// Behavioral tests for the streak walk and week fetch — possible now that
/// StatsViewModel reads through APIServiceProtocol.
@MainActor
final class StatsViewModelStreakTests: XCTestCase {
    private var mockAPI: MockAPIService!
    private var vm: StatsViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIService()
        vm = StatsViewModel(api: mockAPI)
    }

    private func dayKey(daysAgo: Int) -> String {
        DayKey.string(from: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    /// Tracked days from yesterday back `length` days (today untracked).
    private func seedStreak(length: Int, caloriesPerDay: Int = 2000, burnedPerDay: Int = 2500) async {
        var cals: [String: [Int]] = [:]
        var burned: [String: Int] = [:]
        for i in 1...length {
            cals[dayKey(daysAgo: i)] = [caloriesPerDay]
            burned[dayKey(daysAgo: i)] = burnedPerDay
        }
        await mockAPI.setDayCalories(cals)
        await mockAPI.setDayBurned(burned)
    }

    func testStreakSurvivesUntrackedToday() async {
        // 7am scenario: breakfast not logged yet. An empty TODAY must not
        // reset the streak to 0 — it ends on the first empty PAST day.
        await seedStreak(length: 5)
        await vm.fetchStreak()
        XCTAssertEqual(vm.streakDays, 5)
    }

    func testStreakCountsTodayWhenTracked() async {
        await seedStreak(length: 3)
        await mockAPI.setDayCalories(await mockAPI.dayCalories.merging([dayKey(daysAgo: 0): [500]]) { a, _ in a })
        await vm.fetchStreak()
        XCTAssertEqual(vm.streakDays, 4)
    }

    func testStreakZeroWhenNothingTracked() async {
        await vm.fetchStreak()
        XCTAssertEqual(vm.streakDays, 0)
    }

    func testStreakNetIncludesBurn() async {
        await seedStreak(length: 2, caloriesPerDay: 2000, burnedPerDay: 2500)
        await vm.fetchStreak()
        XCTAssertEqual(vm.streakNet, -1000) // 2×(2000−2500)
        XCTAssertEqual(vm.streakLbsText, "Est. 0.3 lbs lost")
    }

    func testStreakLbsTextNeverShowsNegativeNumber() {
        vm.streakNet = -7000
        XCTAssertEqual(vm.streakLbsText, "Est. 2.0 lbs lost")
        vm.streakNet = 3500
        XCTAssertEqual(vm.streakLbsText, "Est. 1.0 lbs gained")
        vm.streakNet = 0
        XCTAssertEqual(vm.streakLbsText, "Breaking even so far")
    }

    func testNetworkFailureAbortsWithoutFalseZero() async {
        // A failed request mid-walk must abort and preserve the previous
        // streak value, not report a false end-of-streak.
        await seedStreak(length: 5)
        await mockAPI.setFailingDays([dayKey(daysAgo: 3)])
        vm.streakDays = 42 // previous known value
        await vm.fetchStreak()
        XCTAssertEqual(vm.streakDays, 42, "failure must not overwrite the last known streak")
    }

    func testStreakCapClamps() async {
        // Seed more tracked days than the cap; the reported value must clamp.
        await seedStreak(length: StatsViewModel.streakCap + 30)
        await vm.fetchStreak()
        XCTAssertEqual(vm.streakDays, StatsViewModel.streakCap)
        XCTAssertEqual(vm.streakDaysLabel, "\(StatsViewModel.streakCap)+")
    }
}
