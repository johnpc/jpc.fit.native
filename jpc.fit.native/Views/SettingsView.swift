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
            philosophySection
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

    private var philosophySection: some View {
        Section {
            DisclosureGroup("Why T-Shirt Sizes?") {
                Text("**The philosophy of jpc.fit is that mindful eating is more important than counting every calorie exactly perfectly.**").font(.callout).padding(.vertical, 4)
                Text("In the USA, calorie labels can legally be wrong by up to 20%. Instead, we recommend loose estimation (and round up when it makes sense!)").font(.callout).padding(.vertical, 4)
                Text("If this philosophy doesn't work for you, you can create custom quick adds for your most common meals.").font(.callout).padding(.vertical, 4)
            }
        }
    }

    private var notificationsSection: some View {
        Section("Daily Notifications") {
            if notifications.isEnabled {
                ForEach(Array(notifications.reminderTimes.enumerated()), id: \.offset) { i, time in
                    HStack { Text(formatTime(time)); Spacer() }
                        .swipeActions { Button("Delete", role: .destructive) { notifications.removeTime(at: i) } }
                }
                HStack {
                    DatePicker("", selection: $newReminderTime, displayedComponents: .hourAndMinute).labelsHidden()
                    Spacer()
                    Button("Add") { notifications.addTime(newReminderTime) }.buttonStyle(.borderless)
                }
                Button("Re-schedule Notifications") { notifications.scheduleNotifications() }
                Button("Disable Notifications", role: .destructive) { notifications.disable() }
            } else {
                Button("Enable Reminder Notifications") { Task { await notifications.requestPermission() } }
            }
        }
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
        Section("Your Quick Adds") {
            if vm.quickAdds.isEmpty {
                Text("No custom quick adds").foregroundStyle(.secondary)
            } else {
                ForEach(vm.quickAdds, id: \.id) { qa in
                    Button { editingQuickAdd = qa } label: {
                        HStack {
                            Text(vm.iconDisplay(qa.icon)); Text(qa.name); Spacer()
                            Text("\(qa.calories) cal").foregroundStyle(.secondary)
                            if !vm.hideProtein, let p = qa.protein { Text("\(p)g").foregroundStyle(.secondary) }
                        }
                    }.foregroundStyle(.primary)
                }
                .onDelete(perform: vm.deleteQuickAdd)
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button("Sign Out", role: .destructive) { vm.signOut() }
            Button("Delete Account", role: .destructive) { showDeleteAccount = true }
        }
    }

    private var createQuickAddSheet: some View {
        NavigationStack {
            Form {
                EmojiTextField(text: $newIcon, placeholder: "Icon (emoji)")
                TextField("Name", text: $newName)
                TextField("Calories", text: $newCalories).keyboardType(.numberPad)
                if !vm.hideProtein { TextField("Protein (g)", text: $newProtein).keyboardType(.numberPad) }
            }
            .navigationTitle("New Quick Add").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showCreateQuickAdd = false; clearForm() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { vm.createQuickAdd(name: newName, calories: newCalories, protein: newProtein, icon: newIcon); showCreateQuickAdd = false; clearForm() }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || Int(newCalories) == nil)
                }
            }
        }.presentationDetents([.medium])
    }

    private func editQuickAddSheet(_ qa: QuickAdd) -> some View {
        NavigationStack {
            Form {
                EmojiTextField(text: $newIcon, placeholder: "Icon (emoji)")
                TextField("Name", text: $newName)
                TextField("Calories", text: $newCalories).keyboardType(.numberPad)
                if !vm.hideProtein { TextField("Protein (g)", text: $newProtein).keyboardType(.numberPad) }
            }
            .navigationTitle("Edit Quick Add").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editingQuickAdd = nil; clearForm() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { vm.updateQuickAdd(id: qa.id, name: newName, calories: newCalories, protein: newProtein, icon: newIcon); editingQuickAdd = nil; clearForm() } }
            }
            .onAppear { newName = qa.name; newCalories = "\(qa.calories)"; newProtein = qa.protein.map { "\($0)" } ?? ""; newIcon = vm.iconDisplay(qa.icon) }
        }.presentationDetents([.medium])
    }

    private func clearForm() { newName = ""; newCalories = ""; newProtein = ""; newIcon = "🍽️" }

    private func formatTime(_ dc: DateComponents) -> String {
        var cal = Calendar.current; cal.timeZone = .current
        guard let date = cal.date(from: dc) else { return "" }
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
