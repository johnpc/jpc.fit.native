import XCTest
@testable import jpc_fit

@MainActor
final class StatsViewModelWeekTests: XCTestCase {
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

    func testFetchWeekPopulatesSevenDaysInOrder() async {
        await mockAPI.setDayCalories([dayKey(daysAgo: 0): [800], dayKey(daysAgo: 6): [500]])
        await vm.fetchWeek()
        XCTAssertEqual(vm.weekData.count, 7)
        XCTAssertEqual(vm.weekData.first?.consumed, 500, "oldest day first")
        XCTAssertEqual(vm.weekData.last?.consumed, 800, "today last")
        XCTAssertFalse(vm.isLoading)
    }

    func testFailedDayIsMarkedFailedNotUntracked() async {
        // Network failure must be distinguishable from an empty day — it
        // used to render as ❌ "not tracked" and skew the week net.
        await mockAPI.setFailingDays([dayKey(daysAgo: 2)])
        await mockAPI.setDayCalories([dayKey(daysAgo: 1): [1000]])
        await vm.fetchWeek()
        let failedDay = vm.weekData.first { $0.failed }
        XCTAssertNotNil(failedDay)
        XCTAssertFalse(failedDay!.tracked)
        XCTAssertEqual(vm.weekData.filter(\.failed).count, 1)
    }

    func testWeekNetExcludesFailedDays() async {
        await mockAPI.setDayCalories([dayKey(daysAgo: 1): [2000]])
        await mockAPI.setDayBurned([dayKey(daysAgo: 1): 2500])
        await mockAPI.setFailingDays([dayKey(daysAgo: 2)])
        await vm.fetchWeek()
        XCTAssertEqual(vm.weekNet, -500)
    }

    func testRecentDaysOnlyUpdatesForCurrentWindow() async {
        await mockAPI.setDayCalories([dayKey(daysAgo: 0): [700]])
        await vm.fetchWeek()
        XCTAssertEqual(vm.recentDays.count, 7, "current window seeds recentDays")

        // Navigate two weeks back: weekData changes, recentDays must not.
        let before = vm.recentDays.map(\.day)
        vm.weekEndDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        await vm.fetchWeek()
        XCTAssertEqual(vm.recentDays.map(\.day), before, "flame strip stays pinned to actual recent days")
        XCTAssertNotEqual(vm.weekData.map(\.day), before)
    }

    func testForwardNavigationDisabledAtToday() {
        XCTAssertTrue(vm.isViewingCurrentWeek)
        vm.weekEndDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        XCTAssertFalse(vm.isViewingCurrentWeek)
    }

    func testGoToTodayRestoresCurrentWindow() async {
        vm.weekEndDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        vm.goToToday()
        XCTAssertTrue(vm.isViewingCurrentWeek)
    }
}
