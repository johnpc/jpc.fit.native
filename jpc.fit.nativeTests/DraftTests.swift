import XCTest
@testable import jpc_fit

/// The form drafts + sheet machines that moved out of the views.
final class DraftTests: XCTestCase {
    // MARK: FoodDraft / FoodSheet

    func testFoodDraftValidation() {
        var draft = FoodDraft()
        XCTAssertFalse(draft.isValid)
        draft.calories = "0"
        XCTAssertFalse(draft.isValid, "zero calories is not a food")
        draft.calories = "abc"
        XCTAssertFalse(draft.isValid)
        draft.calories = "250"
        XCTAssertTrue(draft.isValid)
        XCTAssertEqual(draft.calorieValue, 250)
        XCTAssertNil(draft.proteinValue)
        draft.protein = "12"
        XCTAssertEqual(draft.proteinValue, 12)
    }

    func testFoodDraftNamingRules() {
        var draft = FoodDraft()
        XCTAssertEqual(draft.customFoodName, "🍽️ Food", "a blank custom add is still named")
        XCTAssertNil(draft.editedName, "a blank edit keeps the stored name")
        draft.name = "Tacos"
        XCTAssertEqual(draft.customFoodName, "🍽️ Tacos")
        XCTAssertEqual(draft.editedName, "Tacos")
    }

    func testFoodSheetPrefillsAndLabels() {
        let food = Food(id: "f1", name: "Pizza", calories: 800, protein: 25, day: "5/17/2026")
        let edit = FoodSheet.edit(food)
        XCTAssertEqual(edit.draft, {
            var d = FoodDraft(); d.name = "Pizza"; d.calories = "800"; d.protein = "25"; return d
        }())
        XCTAssertEqual(edit.title, "Edit Food")
        XCTAssertEqual(edit.confirmLabel, "Save")
        XCTAssertFalse(edit.focusesName)
        XCTAssertEqual(edit.id, "edit-f1")

        let add = FoodSheet.add
        XCTAssertEqual(add.draft, FoodDraft())
        XCTAssertEqual(add.title, "Add Food")
        XCTAssertEqual(add.confirmLabel, "Add")
        XCTAssertTrue(add.focusesName)
        XCTAssertEqual(add.id, "add")
        XCTAssertEqual(FoodDraft(food: Food(id: "x", calories: 1, day: "d")).protein, "")
    }

    // MARK: QuickAddDraft / QuickAddSheet

    func testQuickAddDraftNormalizes() {
        var draft = QuickAddDraft()
        XCTAssertFalse(draft.isValid)
        draft.name = "  Latte  "
        draft.calories = "180"
        draft.icon = ""
        let item = draft.item(id: "q1")
        XCTAssertEqual(item, QuickAddItem(id: "q1", name: "Latte", calories: 180, icon: "🍽️", protein: nil))
        draft.protein = "9"
        draft.icon = "☕"
        XCTAssertEqual(draft.item(id: "q1")?.protein, 9)
        XCTAssertEqual(draft.item(id: "q1")?.icon, "☕")
        draft.calories = "-5"
        XCTAssertNil(draft.item(id: "q1"))
        draft.calories = "5"
        draft.name = "   "
        XCTAssertNil(draft.item(id: "q1"), "whitespace-only names are rejected")
    }

    func testQuickAddSheetPrefillsAndLabels() {
        let item = QuickAddItem(id: "q1", name: "Latte", calories: 180, icon: "☕", protein: 9)
        let edit = QuickAddSheet.edit(item)
        XCTAssertEqual(edit.draft, {
            var d = QuickAddDraft(); d.icon = "☕"; d.name = "Latte"; d.calories = "180"; d.protein = "9"; return d
        }())
        XCTAssertEqual(edit.title, "Edit Quick Add")
        XCTAssertEqual(edit.confirmLabel, "Save")
        XCTAssertEqual(edit.id, "edit-q1")
        XCTAssertEqual(QuickAddSheet.create.draft, QuickAddDraft())
        XCTAssertEqual(QuickAddSheet.create.title, "New Quick Add")
        XCTAssertEqual(QuickAddSheet.create.confirmLabel, "Create")
        XCTAssertEqual(QuickAddSheet.create.id, "create")
    }
}
