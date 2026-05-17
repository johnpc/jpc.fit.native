import XCTest
@testable import jpc_fit

final class ModelsTests: XCTestCase {

    // MARK: - Food Model

    func testFoodInitWithAllFields() {
        let food = Food(id: "f1", name: "Pizza", calories: 800, protein: 25, day: "5/17/2026")
        XCTAssertEqual(food.id, "f1")
        XCTAssertEqual(food.name, "Pizza")
        XCTAssertEqual(food.calories, 800)
        XCTAssertEqual(food.protein, 25)
        XCTAssertEqual(food.day, "5/17/2026")
        XCTAssertNil(food.notes)
        XCTAssertNil(food.createdAt)
    }

    func testFoodInitWithMinimalFields() {
        let food = Food(calories: 100, day: "5/17/2026")
        XCTAssertNil(food.name)
        XCTAssertNil(food.protein)
        XCTAssertEqual(food.calories, 100)
    }

    func testFoodIdentifiable() {
        let food = Food(id: "unique-id", calories: 200, day: "5/17/2026")
        XCTAssertEqual(food.id, "unique-id")
    }

    // MARK: - HealthKitCache Model

    func testHealthKitCacheInit() {
        let cache = HealthKitCache(id: "hk1", activeCalories: 450.5, baseCalories: 1800.0, steps: 10000, day: "5/17/2026")
        XCTAssertEqual(cache.id, "hk1")
        XCTAssertEqual(cache.activeCalories, 450.5)
        XCTAssertEqual(cache.baseCalories, 1800.0)
        XCTAssertEqual(cache.steps, 10000)
        XCTAssertEqual(cache.day, "5/17/2026")
    }

    func testHealthKitCacheOptionalSteps() {
        let cache = HealthKitCache(id: "hk2", activeCalories: 300, baseCalories: 1700, day: "5/17/2026")
        XCTAssertNil(cache.steps)
    }

    // MARK: - QuickAddItem Model

    func testQuickAddItemInit() {
        let item = QuickAddItem(id: "qa1", name: "Coffee", calories: 50, icon: "☕", protein: 2)
        XCTAssertEqual(item.id, "qa1")
        XCTAssertEqual(item.name, "Coffee")
        XCTAssertEqual(item.calories, 50)
        XCTAssertEqual(item.icon, "☕")
        XCTAssertEqual(item.protein, 2)
    }

    func testQuickAddItemNilProtein() {
        let item = QuickAddItem(id: "qa2", name: "Soda", calories: 150, icon: "🥤", protein: nil)
        XCTAssertNil(item.protein)
    }

    // MARK: - DefaultQuickAdds

    func testDefaultQuickAddsCount() {
        XCTAssertEqual(defaultQuickAdds.count, 6)
    }

    func testDefaultQuickAddsCaloriesAscending() {
        let calories = defaultQuickAdds.map(\.calories)
        XCTAssertEqual(calories, calories.sorted())
    }

    func testDefaultQuickAddsHaveUniqueIds() {
        let ids = Set(defaultQuickAdds.map(\.id))
        XCTAssertEqual(ids.count, defaultQuickAdds.count)
    }

    func testDefaultQuickAddsHaveIcons() {
        for item in defaultQuickAdds {
            XCTAssertFalse(item.icon.isEmpty, "\(item.name) should have an icon")
        }
    }

    func testDefaultQuickAddsNilProtein() {
        for item in defaultQuickAdds {
            XCTAssertNil(item.protein, "Default quick adds should have nil protein")
        }
    }

    // MARK: - SharedDataManager

    func testSharedDataManagerSaveConsumed() {
        let mgr = SharedDataManager.shared
        mgr.save(consumed: 1500)
        // Verify it doesn't crash - actual UserDefaults may not be available in test
    }

    func testSharedDataManagerSaveBurned() {
        let mgr = SharedDataManager.shared
        mgr.save(burned: 2200)
        // Verify it doesn't crash
    }
}
