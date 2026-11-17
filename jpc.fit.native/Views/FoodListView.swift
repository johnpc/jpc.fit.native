import SwiftUI

struct FoodListView: View {
    // Internal (not private) so FoodListView+Actions can reach them.
    @StateObject var vm = FoodViewModel()
    @State var selectedDate = Date()
    /// Which sheet is up (add / edit) — see `FoodSheet`.
    @State var sheet: FoodSheet?
    @State var draft = FoodDraft()

    /// Backend partition key — locale-stable, never shown to the user.
    var dayString: String { DayKey.string(from: selectedDate) }
    /// What the user sees — follows the device region.
    var dayLabel: String { selectedDate.formatted(date: .numeric, time: .omitted) }

    var body: some View {
        NavigationStack {
            List {
                HeaderSection()
                DatePickerSection(selectedDate: $selectedDate)
                RemainingSection(remaining: vm.remainingCalories, protein: vm.totalProtein, hideProtein: vm.hideProtein)
                HealthKitSection(cache: vm.healthKitCache, consumed: vm.totalCalories, hideSteps: vm.hideSteps)
                FoodSection(state: vm.listState, dayString: dayLabel, hideProtein: vm.hideProtein,
                            onDelete: deleteFood, onEdit: { open(.edit($0)) })
                QuickAddSection(quickAdds: vm.quickAdds, onQuickAdd: addQuickFood, onCustomAdd: { open(.add) })
                ErrorSection(error: vm.errorMessage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await vm.fetchAll(day: dayString, date: selectedDate) }
            .sheet(item: $sheet) { sheet in
                FoodFormSheet(title: sheet.title, name: $draft.name, calories: $draft.calories,
                              protein: $draft.protein, hideProtein: vm.hideProtein, focusName: sheet.focusesName,
                              confirmLabel: sheet.confirmLabel, confirmDisabled: !draft.isValid,
                              onCancel: close, onConfirm: { confirm(sheet) })
            }
        }
        // task(id:) cancels the in-flight fetch when the day changes again,
        // so a slow response for day A can't land on top of day B's list.
        .task(id: selectedDate) {
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
}
