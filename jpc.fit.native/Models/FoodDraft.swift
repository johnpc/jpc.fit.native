import Foundation

/// The add/edit food form's fields plus the validation and naming rules that
/// used to live in the view (`FoodListView+Actions`). Pure and unit-tested.
struct FoodDraft: Equatable {
    var name = ""
    var calories = ""
    var protein = ""

    init() {}

    init(food: Food) {
        name = food.name ?? ""
        calories = "\(food.calories)"
        protein = food.protein.map { "\($0)" } ?? ""
    }

    /// Calories as entered, if they are a positive integer.
    var calorieValue: Int? {
        guard let cal = Int(calories), cal > 0 else { return nil }
        return cal
    }

    var proteinValue: Int? { Int(protein) }
    var isValid: Bool { calorieValue != nil }

    /// A custom add is always prefixed with the plate emoji; a blank name
    /// becomes "Food" so the row never reads as empty.
    var customFoodName: String { "🍽️ \(name.isEmpty ? "Food" : name)" }

    /// For edits a blank name means "keep the stored one" (nil = no change).
    var editedName: String? { name.isEmpty ? nil : name }
}

/// StateMachine: Food sheet
///
/// Which food sheet is up — one optional instead of a `showingAddFood` flag
/// plus an `editingFood` optional that could both be set.
enum FoodSheet: Identifiable, Equatable {
    case add
    case edit(Food)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let food): return "edit-\(food.id)"
        }
    }

    var title: String { isAdd ? "Add Food" : "Edit Food" }
    var confirmLabel: String { isAdd ? "Add" : "Save" }
    /// Only a fresh add focuses the name field; an edit shows the filled form.
    var focusesName: Bool { isAdd }

    var draft: FoodDraft {
        switch self {
        case .add: return FoodDraft()
        case .edit(let food): return FoodDraft(food: food)
        }
    }

    private var isAdd: Bool { self == .add }
}
