import SwiftUI
import Amplify

struct FoodListView: View {
    let user: AuthUser
    // Internal (not private) so FoodListView+Actions can reach them.
    @StateObject var vm = FoodViewModel()
    @State var selectedDate = Date()
    @State var showingAddFood = false
    @State var editingFood: Food?
    @State var newFoodName = ""
    @State var newFoodCalories = ""
    @State var newFoodProtein = ""

    var dayString: String { selectedDate.formatted(date: .numeric, time: .omitted) }

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
        .onReceive(NotificationCenter.default.publisher(for: .foodDataChanged)) { note in
            // Our own optimistic writes already updated `foods` — only reconcile
            // changes from elsewhere (watch), and silently (no spinner flash).
            guard (note.object as? FoodViewModel) !== vm else { return }
            Task { await vm.fetchAll(day: dayString, date: selectedDate, showLoading: false) }
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

}
