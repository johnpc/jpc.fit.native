import SwiftUI
import Amplify

struct FoodListView: View {
    let user: AuthUser
    @StateObject private var vm = FoodViewModel()
    @State private var selectedDate = Date()
    @State private var showingAddFood = false
    @State private var newFoodName = ""
    @State private var newFoodCalories = ""
    
    var dayString: String { selectedDate.formatted(date: .numeric, time: .omitted) }
    var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    
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
                RemainingSection(remaining: vm.remainingCalories)
                HealthKitSection(cache: vm.healthKitCache, consumed: vm.totalCalories)
                FoodSection(foods: vm.foods, isLoading: vm.isLoading, dayString: dayString, onDelete: deleteFood)
                QuickAddSection(quickAdds: vm.quickAdds, onQuickAdd: addQuickFood, onCustomAdd: { showingAddFood = true })
                ErrorSection(error: vm.errorMessage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") { Task { _ = await Amplify.Auth.signOut() } }
                }
            }
            .refreshable { await vm.fetchAll(day: dayString, date: selectedDate) }
            .alert("Add Food", isPresented: $showingAddFood) {
                TextField("Name", text: $newFoodName)
                TextField("Calories", text: $newFoodCalories).keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { clearForm() }
                Button("Add") { addCustomFood() }
            }
            .onChange(of: selectedDate) { _, _ in Task { await vm.fetchAll(day: dayString, date: selectedDate) } }
        }
        .task {
            await vm.requestHealthKitPermission()
            await vm.fetchAll(day: dayString, date: selectedDate)
        }
    }
    
    private func addQuickFood(_ qa: QuickAddItem) {
        Task { await vm.addFood(name: qa.name, calories: qa.calories, day: dayString) }
    }
    
    private func addCustomFood() {
        if let cal = Int(newFoodCalories), cal > 0 {
            Task { await vm.addFood(name: newFoodName.isEmpty ? "Food" : newFoodName, calories: cal, day: dayString) }
        }
        clearForm()
    }
    
    private func deleteFood(at offsets: IndexSet) {
        for i in offsets { Task { await vm.deleteFood(vm.foods[i], day: dayString) } }
    }
    
    private func clearForm() {
        newFoodName = ""
        newFoodCalories = ""
    }
}
