import XCTest
@testable import jpc_fit

/// The in-process fake backend behaves like the real one and its seed is the
/// exact shape the acceptance scenarios assert on.
final class DemoAPIServiceTests: XCTestCase {
    private let now = Date()

    private func key(daysAgo: Int) -> String { DemoSeed.dayKey(daysAgo: daysAgo, now: now) }

    func testSeedShape() async {
        let api = DemoAPIService(now: now)
        let today = await api.fetchFoods(day: key(daysAgo: 0))
        XCTAssertEqual(today.map(\.name), ["☕ Coffee", "🥗 Salad"])
        XCTAssertEqual(today.map(\.calories).reduce(0, +), 500)

        for daysAgo in 1...DemoSeed.trackedPastDays {
            let calories = await api.fetchFoodCalories(day: key(daysAgo: daysAgo))
            XCTAssertEqual(calories?.reduce(0, +), 2050, "day -\(daysAgo) is tracked")
            let burned = await api.fetchCacheBurned(day: key(daysAgo: daysAgo))
            XCTAssertEqual(burned, 2170)
        }
        let streakEnd = await api.fetchFoodCalories(day: key(daysAgo: DemoSeed.trackedPastDays + 1))
        XCTAssertEqual(streakEnd, [], "the day after the streak is empty, not failed")
        let beyond = await api.fetchCacheBurned(day: key(daysAgo: 40))
        XCTAssertEqual(beyond, 0)
    }

    func testStreakAndWeekOverTheSeedAreDeterministic() async {
        let api = DemoAPIService(now: now)
        let vm = await StatsViewModel(api: api, healthKit: DemoHealthStats())
        await vm.refresh()
        let label = await vm.streakDaysLabel
        XCTAssertEqual(label, "\(DemoSeed.trackedPastDays + 1)")
        let tracked = await vm.trackedCount
        XCTAssertEqual(tracked, 7)
    }

    func testFoodWritesPersist() async {
        let api = DemoAPIService(now: now)
        let day = key(daysAgo: 0)
        let id = await api.createFood(name: "🍌 Banana", calories: 105, protein: nil, day: day)
        XCTAssertNotNil(id)
        var foods = await api.fetchFoods(day: day)
        XCTAssertEqual(foods.count, 3)

        let updated = await api.updateFood(id: id ?? "", name: nil, calories: 110, protein: 2)
        XCTAssertTrue(updated)
        foods = await api.fetchFoods(day: day)
        XCTAssertEqual(foods.last?.name, "🍌 Banana", "nil name keeps the stored name")
        XCTAssertEqual(foods.last?.calories, 110)
        XCTAssertEqual(foods.last?.protein, 2)

        let awaited1 = await api.deleteFood(id: id ?? "")
        XCTAssertTrue(awaited1)
        let awaited2 = await api.deleteFood(id: "nope")
        XCTAssertFalse(awaited2)
        let awaited3 = await api.updateFood(id: "nope", name: nil, calories: 1, protein: nil)
        XCTAssertFalse(awaited3)
        foods = await api.fetchFoods(day: day)
        XCTAssertEqual(foods.count, 2)
    }

    func testHealthKitCacheUpsert() async {
        let api = DemoAPIService(now: now)
        let day = key(daysAgo: 40)
        let awaited4 = await api.fetchHealthKitCache(day: day)
        XCTAssertNil(awaited4)
        let id = await api.createHealthKitCache(activeCalories: 100, baseCalories: 1000, steps: 10, day: day)
        let awaited5 = await api.fetchHealthKitCache(day: day)?.id
        XCTAssertEqual(awaited5, id)
        await api.updateHealthKitCache(id: id ?? "", activeCalories: 200, baseCalories: 1000, steps: 10)
        let awaited6 = await api.fetchCacheBurned(day: day)
        XCTAssertEqual(awaited6, 1200)
        await api.updateHealthKitCache(id: "missing", activeCalories: 1, baseCalories: 1, steps: 1)
        let awaited7 = await api.fetchCacheBurned(day: day)
        XCTAssertEqual(awaited7, 1200, "an unknown id is a no-op")
    }

    func testQuickAddsAndPreferences() async {
        let api = DemoAPIService(now: now)
        let awaited8 = await api.fetchQuickAdds().count
        XCTAssertEqual(awaited8, 3)
        let id = await api.createQuickAdd(QuickAddItem(id: "tmp", name: "Tea", calories: 5, icon: "🍵", protein: nil))
        XCTAssertNotNil(id)
        let awaited9 = await api.updateQuickAdd(QuickAddItem(id: id ?? "", name: "Green tea", calories: 5, icon: "🍵", protein: nil))
        XCTAssertTrue(awaited9)
        let awaited10 = await api.fetchQuickAdds().last?.name
        XCTAssertEqual(awaited10, "Green tea")
        let awaited11 = await api.updateQuickAdd(QuickAddItem(id: "nope", name: "x", calories: 1, icon: "", protein: nil))
        XCTAssertFalse(awaited11)
        let awaited12 = await api.deleteQuickAdd(id: id ?? "")
        XCTAssertTrue(awaited12)
        let awaited13 = await api.deleteQuickAdd(id: id ?? "")
        XCTAssertFalse(awaited13)

        let awaited14 = await api.fetchPreferences()
        XCTAssertEqual(awaited14, .missing)
        let awaited15 = await api.updatePreferences(id: "nope", hideProtein: true, hideSteps: true)
        XCTAssertFalse(awaited15)
        let prefsId = await api.createPreferences(hideProtein: true, hideSteps: false)
        let awaited16 = await api.fetchPreferences().hideProtein
        XCTAssertEqual(awaited16, true)
        let awaited17 = await api.updatePreferences(id: prefsId ?? "", hideProtein: false, hideSteps: true)
        XCTAssertTrue(awaited17)
        let awaited18 = await api.fetchPreferences()
        XCTAssertEqual(awaited18, .stored(Preferences(id: prefsId ?? "", hideProtein: false, hideSteps: true)))
    }

    func testWeightsAndHeights() async {
        let api = DemoAPIService(now: now)
        let awaited19 = await api.fetchWeights().first?.currentWeight
        XCTAssertEqual(awaited19, 182)
        let awaited20 = await api.fetchHeights().first?.currentHeight
        XCTAssertEqual(awaited20, 70)
        guard case .saved = await api.createWeight(179) else { return XCTFail("weight save should succeed") }
        guard case .saved = await api.createHeight(71) else { return XCTFail("height save should succeed") }
        let awaited21 = await api.fetchWeights().first?.currentWeight
        XCTAssertEqual(awaited21, 179, "newest first")
        let awaited22 = await api.fetchHeights().first?.currentHeight
        XCTAssertEqual(awaited22, 71)
        let stats = await DemoHealthStats().fetchStats(for: now)
        XCTAssertEqual(stats.active + stats.basal, 2170)
    }
}
