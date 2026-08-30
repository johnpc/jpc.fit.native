import SwiftUI

/// Form-driven food actions for `FoodListView` — split by concern to keep the
/// view file within the line budget. All writes are optimistic via the VM.
extension FoodListView {
    func addQuickFood(_ qa: QuickAddItem) {
        Task { await vm.addFood(name: "\(qa.icon) \(qa.name)", calories: qa.calories, protein: qa.protein, day: dayString) }
    }

    func addCustomFood() {
        if let cal = Int(newFoodCalories), cal > 0 {
            let name = "🍽️ \(newFoodName.isEmpty ? "Food" : newFoodName)"
            let protein = Int(newFoodProtein)
            Task { await vm.addFood(name: name, calories: cal, protein: protein, day: dayString) }
        }
        clearForm()
    }

    func deleteFood(at offsets: IndexSet) {
        for i in offsets { Task { await vm.deleteFood(vm.foods[i], day: dayString) } }
    }

    func updateFood(_ food: Food) {
        guard let cal = Int(newFoodCalories), cal > 0 else { clearForm(); return }
        let protein = Int(newFoodProtein)
        let name = newFoodName.isEmpty ? nil : newFoodName
        Task { await vm.updateFood(id: food.id, name: name, calories: cal, protein: protein, day: dayString) }
        clearForm()
    }

    func clearForm() { newFoodName = ""; newFoodCalories = ""; newFoodProtein = "" }
}
