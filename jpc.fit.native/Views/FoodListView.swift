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
    @State private var preferences: Preferences?
    @FocusState private var nameFieldFocused: Bool
    
    var dayString: String { selectedDate.formatted(date: .numeric, time: .omitted) }
    var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    private var hideProtein: Bool { preferences?.hideProtein ?? false }
    
    var body: some View {
        NavigationStack {
            List {
                HeaderSection()
                Section {
                    HStack {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                        } label: {
                            Image(systemName: "chevron.left")
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        Text(selectedDate.formatted(date: .numeric, time: .omitted)).fontWeight(.bold)
                        Spacer()
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                        } label: {
                            Image(systemName: "chevron.right")
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
                RemainingSection(remaining: vm.remainingCalories, protein: vm.totalProtein, hideProtein: hideProtein)
                HealthKitSection(cache: vm.healthKitCache, consumed: vm.totalCalories, hideSteps: preferences?.hideSteps ?? false)
                FoodSection(foods: vm.foods, isLoading: vm.isLoading, dayString: dayString, hideProtein: hideProtein, onDelete: deleteFood, onEdit: { editingFood = $0 })
                QuickAddSection(quickAdds: vm.quickAdds, onQuickAdd: addQuickFood, onCustomAdd: { showingAddFood = true })
                ErrorSection(error: vm.errorMessage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await vm.fetchAll(day: dayString, date: selectedDate) }
            .sheet(isPresented: $showingAddFood) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newFoodName)
                            .focused($nameFieldFocused)
                            .textInputAutocapitalization(.words)
                            .textContentType(.name)
                        TextField("Calories", text: $newFoodCalories)
                            .keyboardType(.numberPad)
                        if !hideProtein {
                            TextField("Protein (g)", text: $newFoodProtein)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("Add Food")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddFood = false; clearForm() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") { addCustomFood(); showingAddFood = false }
                                .disabled(newFoodCalories.isEmpty)
                        }
                    }
                    .onAppear { nameFieldFocused = true }
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $editingFood) { food in
                NavigationStack {
                    Form {
                        TextField("Name", text: $newFoodName)
                        TextField("Calories", text: $newFoodCalories)
                            .keyboardType(.numberPad)
                        if !hideProtein {
                            TextField("Protein (g)", text: $newFoodProtein)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("Edit Food")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { editingFood = nil; clearForm() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { updateFood(food); editingFood = nil }
                        }
                    }
                    .onAppear {
                        newFoodName = food.name ?? ""
                        newFoodCalories = "\(food.calories)"
                        newFoodProtein = food.protein.map { "\($0)" } ?? ""
                    }
                }
                .presentationDetents([.medium])
            }
            .onChange(of: selectedDate) { _, _ in Task { await vm.fetchAll(day: dayString, date: selectedDate) } }
        }
        .task {
            await vm.requestHealthKitPermission()
            preferences = await fetchPreferences()
        }
        .onAppear {
            Task { await vm.fetchAll(day: dayString, date: selectedDate) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .foodDataChanged)) { _ in
            Task { await vm.fetchAll(day: dayString, date: selectedDate) }
        }
    }
    
    private func addQuickFood(_ qa: QuickAddItem) {
        let name = "\(qa.icon) \(qa.name)"
        Task { await vm.addFood(name: name, calories: qa.calories, protein: qa.protein, day: dayString) }
    }
    
    private func addCustomFood() {
        if let cal = Int(newFoodCalories), cal > 0 {
            let protein = Int(newFoodProtein)
            let name = "🍽️ \(newFoodName.isEmpty ? "Food" : newFoodName)"
            Task { await vm.addFood(name: name, calories: cal, protein: protein, day: dayString) }
        }
        clearForm()
    }
    
    private func deleteFood(at offsets: IndexSet) {
        for i in offsets { Task { await vm.deleteFood(vm.foods[i], day: dayString) } }
    }
    
    private func clearForm() {
        newFoodName = ""
        newFoodCalories = ""
        newFoodProtein = ""
    }
    
    private func updateFood(_ food: Food) {
        guard let cal = Int(newFoodCalories), cal > 0 else { clearForm(); return }
        let protein = Int(newFoodProtein)
        Task {
            await vm.updateFood(id: food.id, name: newFoodName.isEmpty ? nil : newFoodName, calories: cal, protein: protein, day: dayString)
        }
        clearForm()
    }
    
    private func fetchPreferences() async -> Preferences? {
        let req = GraphQLRequest<JSONValue>(
            document: "query{listPreferences{items{id hideProtein hideSteps}}}",
            responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let item = data["listPreferences"]?["items"]?.asArray?.first else { return nil }
        var hp: Bool? = nil
        var hs: Bool? = nil
        if case .boolean(let b) = item["hideProtein"] { hp = b }
        if case .boolean(let b) = item["hideSteps"] { hs = b }
        return Preferences(id: item["id"]?.stringValue ?? "", hideProtein: hp, hideSteps: hs)
    }
}
