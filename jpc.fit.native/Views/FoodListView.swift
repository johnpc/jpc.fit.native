import SwiftUI
import Amplify

struct FoodListView: View {
    let user: AuthUser
    @StateObject private var vm = FoodViewModel()
    @State private var selectedDate = Date()
    @State private var showingAddFood = false
    @State private var editingFood: Food?
    @State private var newFoodName = ""
    @State private var newFoodCalories = ""
    @State private var newFoodProtein = ""

    private var dayString: String { selectedDate.formatted(date: .numeric, time: .omitted) }

    var body: some View {
        NavigationStack {
            List {
                HeaderSection()
                dateSection
                RemainingSection(remaining: vm.remainingCalories, protein: vm.totalProtein, hideProtein: vm.hideProtein)
                HealthKitSection(cache: vm.healthKitCache, consumed: vm.totalCalories, hideSteps: vm.hideSteps)
                FoodSection(foods: vm.foods, isLoading: vm.isLoading, dayString: dayString, hideProtein: vm.hideProtein, onDelete: deleteFood, onEdit: { editingFood = $0 })
                QuickAddSection(quickAdds: vm.quickAdds, onQuickAdd: addQuickFood, onCustomAdd: { showingAddFood = true })
                ErrorSection(error: vm.errorMessage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await vm.fetchAll(day: dayString, date: selectedDate) }
            .sheet(isPresented: $showingAddFood) {
                FoodFormSheet(title: "Add Food", name: $newFoodName, calories: $newFoodCalories,
                              protein: $newFoodProtein, hideProtein: vm.hideProtein, focusName: true,
                              confirmLabel: "Add", confirmDisabled: newFoodCalories.isEmpty,
                              onCancel: { showingAddFood = false; clearForm() },
                              onConfirm: { addCustomFood(); showingAddFood = false })
            }
            .sheet(item: $editingFood) { food in editFoodSheet(food) }
            .onChange(of: selectedDate) { _, _ in Task { await vm.fetchAll(day: dayString, date: selectedDate) } }
        }
        .task {
            await vm.requestHealthKitPermission()
            await vm.fetchAll(day: dayString, date: selectedDate)
        }
        .onReceive(NotificationCenter.default.publisher(for: .foodDataChanged)) { _ in
            Task { await vm.fetchAll(day: dayString, date: selectedDate) }
        }
    }

    private var dateSection: some View {
        Section {
            HStack {
                Button { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)! } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.borderless)
                Spacer()
                Text(dayString).fontWeight(.bold)
                Spacer()
                Button { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)! } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.borderless)
            }
        }
    }

    private func editFoodSheet(_ food: Food) -> some View {
        FoodFormSheet(title: "Edit Food", name: $newFoodName, calories: $newFoodCalories,
                      protein: $newFoodProtein, hideProtein: vm.hideProtein, focusName: false,
                      confirmLabel: "Save", confirmDisabled: false,
                      onCancel: { editingFood = nil; clearForm() },
                      onConfirm: { updateFood(food); editingFood = nil })
            .onAppear { newFoodName = food.name ?? ""; newFoodCalories = "\(food.calories)"; newFoodProtein = food.protein.map { "\($0)" } ?? "" }
    }

    private func addQuickFood(_ qa: QuickAddItem) {
        Task { await vm.addFood(name: "\(qa.icon) \(qa.name)", calories: qa.calories, protein: qa.protein, day: dayString) }
    }

    private func addCustomFood() {
        if let cal = Int(newFoodCalories), cal > 0 {
            let name = "🍽️ \(newFoodName.isEmpty ? "Food" : newFoodName)"
            let protein = Int(newFoodProtein)
            Task { await vm.addFood(name: name, calories: cal, protein: protein, day: dayString) }
        }
        clearForm()
    }

    private func deleteFood(at offsets: IndexSet) {
        for i in offsets { Task { await vm.deleteFood(vm.foods[i], day: dayString) } }
    }

    private func updateFood(_ food: Food) {
        guard let cal = Int(newFoodCalories), cal > 0 else { clearForm(); return }
        let protein = Int(newFoodProtein)
        let name = newFoodName.isEmpty ? nil : newFoodName
        Task { await vm.updateFood(id: food.id, name: name, calories: cal, protein: protein, day: dayString) }
        clearForm()
    }

    private func clearForm() { newFoodName = ""; newFoodCalories = ""; newFoodProtein = "" }
}
