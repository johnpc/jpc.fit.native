import XCTest
@testable import jpc_fit

@MainActor
final class FoodViewModelTests: XCTestCase {
    private var mockAPI: MockAPIService!
    private var vm: FoodViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIService()
        vm = FoodViewModel(api: mockAPI)
    }

    // MARK: - Computed Properties

    func testTotalCalories() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setFoods([
            Food(id: "1", name: "Apple", calories: 100, day: today),
            Food(id: "2", name: "Bread", calories: 250, day: today),
        ])
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.totalCalories, 350)
    }

    func testTotalProtein() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setFoods([
            Food(id: "1", name: "Chicken", calories: 300, protein: 30, day: today),
            Food(id: "2", name: "Rice", calories: 200, protein: 5, day: today),
            Food(id: "3", name: "Soda", calories: 150, day: today),
        ])
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.totalProtein, 35)
    }

    func testBurnedCalories() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setCache(HealthKitCache(id: "c1", activeCalories: 500, baseCalories: 1800, steps: 8000, day: today))
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.burnedCalories, 2300)
    }

    func testRemainingCalories() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setFoods([Food(id: "1", name: "Lunch", calories: 800, day: today)])
        await mockAPI.setCache(HealthKitCache(id: "c1", activeCalories: 400, baseCalories: 1600, steps: 5000, day: today))
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.remainingCalories, 1200) // 2000 burned - 800 consumed
    }

    func testQuickAddsDefaultsWhenEmpty() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.quickAdds.count, defaultQuickAdds.count)
    }

    func testQuickAddsUsesUserAddsWhenAvailable() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        let custom = [QuickAddItem(id: "qa1", name: "Coffee", calories: 50, icon: "☕", protein: nil)]
        await mockAPI.setQuickAdds(custom)
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.quickAdds.count, 1)
        XCTAssertEqual(vm.quickAdds.first?.name, "Coffee")
    }

    // MARK: - Fetch

    func testFetchAllSetsLoadingState() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        XCTAssertTrue(vm.isLoading)
        await vm.fetchAll(day: today, date: Date())
        XCTAssertFalse(vm.isLoading)
    }

    func testFetchAllPopulatesFoods() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setFoods([
            Food(id: "1", name: "Breakfast", calories: 400, day: today),
        ])
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.foods.count, 1)
        XCTAssertEqual(vm.foods.first?.name, "Breakfast")
    }

    // MARK: - Add Food

    func testAddFood() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await vm.addFood(name: "Salad", calories: 200, protein: 10, day: today)
        let created = await mockAPI.getCreatedFoods()
        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created.first?.name, "Salad")
        XCTAssertEqual(created.first?.calories, 200)
        XCTAssertEqual(created.first?.protein, 10)
    }

    // MARK: - Delete Food

    func testDeleteFood() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        let food = Food(id: "del-1", name: "Junk", calories: 500, day: today)
        await mockAPI.setFoods([food])
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.foods.count, 1)

        await vm.deleteFood(food, day: today)
        let deleted = await mockAPI.getDeletedIds()
        XCTAssertTrue(deleted.contains("del-1"))
    }

    // MARK: - Update Food

    func testUpdateFood() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setFoods([Food(id: "upd-1", name: "Old", calories: 100, day: today)])
        await vm.fetchAll(day: today, date: Date())

        await vm.updateFood(id: "upd-1", name: "New", calories: 200, protein: 15, day: today)
        let updated = await mockAPI.getUpdatedFoods()
        XCTAssertEqual(updated.count, 1)
        XCTAssertEqual(updated.first?.id, "upd-1")
        XCTAssertEqual(updated.first?.calories, 200)
    }

    // MARK: - Edge Cases

    func testEmptyFoodsReturnsZeroTotals() {
        XCTAssertEqual(vm.totalCalories, 0)
        XCTAssertEqual(vm.totalProtein, 0)
    }

    func testNilHealthKitCacheReturnsZeroBurned() {
        XCTAssertEqual(vm.burnedCalories, 0)
    }

    func testRemainingCaloriesNegativeWhenOverEating() async {
        let today = Date().formatted(date: .numeric, time: .omitted)
        await mockAPI.setFoods([Food(id: "1", name: "Feast", calories: 3000, day: today)])
        await mockAPI.setCache(HealthKitCache(id: "c1", activeCalories: 300, baseCalories: 1700, steps: 5000, day: today))
        await vm.fetchAll(day: today, date: Date())
        XCTAssertEqual(vm.remainingCalories, -1000) // 2000 - 3000
    }
}

// MARK: - MockAPIService Helpers

extension MockAPIService {
    func setFoods(_ newFoods: [Food]) {
        foods = newFoods
    }

    func setCache(_ cache: HealthKitCache?) {
        healthKitCache = cache
    }

    func setQuickAdds(_ adds: [QuickAddItem]) {
        quickAdds = adds
    }

    func getCreatedFoods() -> [(name: String, calories: Int, protein: Int?, day: String)] {
        createdFoods
    }

    func getDeletedIds() -> [String] {
        deletedIds
    }

    func getUpdatedFoods() -> [(id: String, name: String?, calories: Int, protein: Int?)] {
        updatedFoods
    }
}
