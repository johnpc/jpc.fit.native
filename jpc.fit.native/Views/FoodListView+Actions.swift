import SwiftUI

/// Sheet + food actions for `FoodListView` — split by concern to keep the
/// view file within the line budget. All writes are optimistic via the VM;
/// validation and naming rules live in `FoodDraft`.
extension FoodListView {
    func open(_ next: FoodSheet) {
        draft = next.draft
        sheet = next
    }

    func close() {
        sheet = nil
        draft = FoodDraft()
    }

    func confirm(_ current: FoodSheet) {
        switch current {
        case .add: addCustomFood()
        case .edit(let food): updateFood(food)
        }
        close()
    }

    func addQuickFood(_ qa: QuickAddItem) {
        Task { await vm.addFood(name: "\(qa.icon) \(qa.name)", calories: qa.calories, protein: qa.protein, day: dayString) }
    }

    private func addCustomFood() {
        guard let cal = draft.calorieValue else { return }
        let name = draft.customFoodName
        let protein = draft.proteinValue
        Task { await vm.addFood(name: name, calories: cal, protein: protein, day: dayString) }
    }

    func deleteFood(at offsets: IndexSet) {
        // Resolve rows BEFORE any removal — deleting by live index while other
        // deletes mutate `foods` targets the wrong row (or crashes).
        let doomed = offsets.map { vm.foods[$0] }
        Task { for food in doomed { await vm.deleteFood(food, day: dayString) } }
    }

    private func updateFood(_ food: Food) {
        guard let cal = draft.calorieValue else { return }
        let protein = draft.proteinValue
        let name = draft.editedName
        Task { await vm.updateFood(id: food.id, name: name, calories: cal, protein: protein, day: dayString) }
    }
}
