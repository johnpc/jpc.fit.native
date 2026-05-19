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
    @FocusState private var nameFieldFocused: Bool

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
            .sheet(isPresented: $showingAddFood) { addFoodSheet }
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

    private var addFoodSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newFoodName).focused($nameFieldFocused).textInputAutocapitalization(.words)
                TextField("Calories", text: $newFoodCalories).keyboardType(.numberPad)
                if !vm.hideProtein { TextField("Protein (g)", text: $newFoodProtein).keyboardType(.numberPad) }
            }
            .navigationTitle("Add Food").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddFood = false; clearForm() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { addCustomFood(); showingAddFood = false }.disabled(newFoodCalories.isEmpty) }
            }
            .onAppear { nameFieldFocused = true }
        }.presentationDetents([.medium])
    }

    private func editFoodSheet(_ food: Food) -> some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newFoodName)
                TextField("Calories", text: $newFoodCalories).keyboardType(.numberPad)
                if !vm.hideProtein { TextField("Protein (g)", text: $newFoodProtein).keyboardType(.numberPad) }
            }
            .navigationTitle("Edit Food").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editingFood = nil; clearForm() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { updateFood(food); editingFood = nil } }
            }
            .onAppear { newFoodName = food.name ?? ""; newFoodCalories = "\(food.calories)"; newFoodProtein = food.protein.map { "\($0)" } ?? "" }
        }.presentationDetents([.medium])
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
