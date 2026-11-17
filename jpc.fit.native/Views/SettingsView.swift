import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @StateObject private var notifications = NotificationManager.shared
    /// Which quick-add sheet is up (create / edit) — see `QuickAddSheet`.
    @State private var sheet: QuickAddSheet?
    @State private var draft = QuickAddDraft()
    @State private var showDeleteAccount = false
    @State private var newReminderTime = Date()

    var body: some View {
        List {
            HeaderSection()
            PhilosophySection()
            NotificationsSection(notifications: notifications, newReminderTime: $newReminderTime)
            preferencesSection
            Section("Create Quick Add") {
                Button { open(.create) } label: { Label("New Quick Add", systemImage: "plus.circle") }
            }
            QuickAddsListSection(quickAdds: vm.quickAdds, hideProtein: vm.hideProtein,
                                 onEdit: { open(.edit($0)) }, onDelete: vm.deleteQuickAdd)
            accountSection
            ErrorSection(error: vm.errorMessage)
            Section { Link("Contact Support", destination: URL(string: "mailto:john@johncorser.com")!) }
        }
        .navigationTitle("Settings")
        .sheet(item: $sheet) { sheet in
            QuickAddFormSheet(title: sheet.title, icon: $draft.icon, name: $draft.name, calories: $draft.calories,
                              protein: $draft.protein, hideProtein: vm.hideProtein, confirmLabel: sheet.confirmLabel,
                              confirmDisabled: !draft.isValid, onCancel: close, onConfirm: { confirm(sheet) })
        }
        .alert("Delete Account?", isPresented: $showDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { vm.deleteAccount() }
        } message: { Text("This will permanently delete your account and all data.") }
        .task { await vm.fetchAll() }
        .refreshable { await vm.fetchAll() }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Hide Protein", isOn: Binding(get: { vm.hideProtein }, set: { vm.updatePreference(hideProtein: $0) }))
            Toggle("Hide Steps", isOn: Binding(get: { vm.hideSteps }, set: { vm.updatePreference(hideSteps: $0) }))
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button("Sign Out", role: .destructive) { vm.signOut() }
            Button("Delete Account", role: .destructive) { showDeleteAccount = true }
        }
    }

    private func open(_ next: QuickAddSheet) {
        draft = next.draft
        sheet = next
    }

    private func close() {
        sheet = nil
        draft = QuickAddDraft()
    }

    private func confirm(_ current: QuickAddSheet) {
        switch current {
        case .create: vm.createQuickAdd(draft)
        case .edit(let item): vm.updateQuickAdd(id: item.id, with: draft)
        }
        close()
    }
}
