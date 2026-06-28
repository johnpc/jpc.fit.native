import SwiftUI
import Amplify

struct SettingsView: View {
    let user: AuthUser
    @StateObject private var vm = SettingsViewModel()
    @State private var showCreateQuickAdd = false
    @State private var newName = ""
    @State private var newCalories = ""
    @State private var newProtein = ""
    @State private var newIcon = "🍽️"
    @State private var showDeleteAccount = false
    @StateObject private var notifications = NotificationManager.shared
    @State private var newReminderTime = Date()
    @State private var editingQuickAdd: QuickAdd?

    var body: some View {
        List {
            HeaderSection()
            PhilosophySection()
            notificationsSection
            preferencesSection
            createQuickAddSection
            quickAddsListSection
            accountSection
            Section { Link("Contact Support", destination: URL(string: "mailto:john@johncorser.com")!) }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showCreateQuickAdd) { createQuickAddSheet }
        .sheet(item: $editingQuickAdd) { qa in editQuickAddSheet(qa) }
        .alert("Delete Account?", isPresented: $showDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { vm.deleteAccount() }
        } message: { Text("This will permanently delete your account and all data.") }
        .task { await vm.fetchAll() }
        .refreshable { await vm.fetchAll() }
    }

    private var notificationsSection: some View {
        NotificationsSection(notifications: notifications, newReminderTime: $newReminderTime)
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Hide Protein", isOn: Binding(get: { vm.hideProtein }, set: { vm.updatePreference(hideProtein: $0) }))
            Toggle("Hide Steps", isOn: Binding(get: { vm.hideSteps }, set: { vm.updatePreference(hideSteps: $0) }))
        }
    }

    private var createQuickAddSection: some View {
        Section("Create Quick Add") {
            Button { showCreateQuickAdd = true } label: { Label("New Quick Add", systemImage: "plus.circle") }
        }
    }

    private var quickAddsListSection: some View {
        QuickAddsListSection(quickAdds: vm.quickAdds, hideProtein: vm.hideProtein,
                             iconDisplay: vm.iconDisplay, onEdit: { editingQuickAdd = $0 },
                             onDelete: vm.deleteQuickAdd)
    }

    private var accountSection: some View {
        Section("Account") {
            Button("Sign Out", role: .destructive) { vm.signOut() }
            Button("Delete Account", role: .destructive) { showDeleteAccount = true }
        }
    }

    private var createQuickAddSheet: some View {
        QuickAddFormSheet(title: "New Quick Add", icon: $newIcon, name: $newName, calories: $newCalories,
                          protein: $newProtein, hideProtein: vm.hideProtein, confirmLabel: "Create",
                          confirmDisabled: newName.trimmingCharacters(in: .whitespaces).isEmpty || Int(newCalories) == nil,
                          onCancel: { showCreateQuickAdd = false; clearForm() },
                          onConfirm: { vm.createQuickAdd(name: newName, calories: newCalories, protein: newProtein, icon: newIcon); showCreateQuickAdd = false; clearForm() })
    }

    private func editQuickAddSheet(_ qa: QuickAdd) -> some View {
        QuickAddFormSheet(title: "Edit Quick Add", icon: $newIcon, name: $newName, calories: $newCalories,
                          protein: $newProtein, hideProtein: vm.hideProtein, confirmLabel: "Save", confirmDisabled: false,
                          onCancel: { editingQuickAdd = nil; clearForm() },
                          onConfirm: { vm.updateQuickAdd(id: qa.id, name: newName, calories: newCalories, protein: newProtein, icon: newIcon); editingQuickAdd = nil; clearForm() })
            .onAppear { newName = qa.name; newCalories = "\(qa.calories)"; newProtein = qa.protein.map { "\($0)" } ?? ""; newIcon = vm.iconDisplay(qa.icon) }
    }

    private func clearForm() { newName = ""; newCalories = ""; newProtein = ""; newIcon = "🍽️" }
}
