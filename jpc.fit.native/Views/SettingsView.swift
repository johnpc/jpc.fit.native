import SwiftUI
import Amplify

struct SettingsView: View {
    let user: AuthUser
    @State private var quickAdds: [QuickAdd] = []
    @State private var preferences: Preferences?
    @State private var showCreateQuickAdd = false
    @State private var newName = ""
    @State private var newCalories = ""
    @State private var newProtein = ""
    @State private var newIcon = "🍽️"
    @State private var showDeleteAccount = false
    @StateObject private var notifications = NotificationManager.shared
    @State private var newReminderTime = Date()
    @State private var editingQuickAdd: QuickAdd?
    
    private var hideProtein: Bool { preferences?.hideProtein ?? false }
    private var hideSteps: Bool { preferences?.hideSteps ?? false }
    
    var body: some View {
        List {
            HeaderSection()
            
            Section {
                DisclosureGroup("Why T-Shirt Sizes?") {
                    Text("**The philosophy of jpc.fit is that mindful eating is more important than counting every calorie exactly perfectly.**")
                        .font(.callout)
                        .padding(.vertical, 4)
                    Text("In the USA, calorie labels can legally be wrong by up to 20%. The painstaking math to calculate exact calories isn't worth the effort. Instead, we recommend loose estimation (and round up when it makes sense!)")
                        .font(.callout)
                        .padding(.vertical, 4)
                    Text("If this philosophy doesn't work for you, you can create custom quick adds for your most common meals.")
                        .font(.callout)
                        .padding(.vertical, 4)
                }
            }
            
            Section("Daily Notifications") {
                if notifications.isEnabled {
                    ForEach(Array(notifications.reminderTimes.enumerated()), id: \.offset) { i, time in
                        HStack {
                            Text(formatTime(time))
                            Spacer()
                        }
                        .swipeActions { Button("Delete", role: .destructive) { notifications.removeTime(at: i) } }
                    }
                    HStack {
                        DatePicker("", selection: $newReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Spacer()
                        Button("Add") {
                            notifications.addTime(newReminderTime)
                        }
                        .buttonStyle(.borderless)
                    }
                    Button("Disable Notifications", role: .destructive) {
                        notifications.disable()
                    }
                } else {
                    Button("Enable Reminder Notifications") {
                        Task { await notifications.requestPermission() }
                    }
                }
            }
            
            Section("Preferences") {
                Toggle("Hide Protein", isOn: Binding(
                    get: { hideProtein },
                    set: { updatePreference(hideProtein: $0) }
                ))
                Toggle("Hide Steps", isOn: Binding(
                    get: { hideSteps },
                    set: { updatePreference(hideSteps: $0) }
                ))
            }
            
            Section("Create Quick Add") {
                Button { showCreateQuickAdd = true } label: {
                    Label("New Quick Add", systemImage: "plus.circle")
                }
            }
            
            Section("Your Quick Adds") {
                if quickAdds.isEmpty {
                    Text("No custom quick adds").foregroundStyle(.secondary)
                } else {
                    ForEach(quickAdds, id: \.id) { qa in
                        Button {
                            editingQuickAdd = qa
                        } label: {
                            HStack {
                                Text(iconDisplay(qa.icon))
                                Text(qa.name)
                                Spacer()
                                Text("\(qa.calories) cal").foregroundStyle(.secondary)
                                if !hideProtein, let p = qa.protein {
                                    Text("\(p)g").foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: deleteQuickAdd)
                }
            }
            
            Section("Account") {
                Button("Sign Out", role: .destructive) {
                    Task { _ = await Amplify.Auth.signOut() }
                }
                Button("Delete Account", role: .destructive) {
                    showDeleteAccount = true
                }
            }
            
            Section {
                Link("Contact Support", destination: URL(string: "mailto:john@johncorser.com")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showCreateQuickAdd) {
            NavigationStack {
                Form {
                    EmojiTextField(text: $newIcon, placeholder: "Icon (emoji)")
                    TextField("Name", text: $newName)
                    TextField("Calories", text: $newCalories)
                        .keyboardType(.numberPad)
                    if !hideProtein {
                        TextField("Protein (g)", text: $newProtein)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("New Quick Add")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showCreateQuickAdd = false; clearForm() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { createQuickAdd(); showCreateQuickAdd = false }
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || Int(newCalories) == nil)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $editingQuickAdd) { qa in
            NavigationStack {
                Form {
                    EmojiTextField(text: $newIcon, placeholder: "Icon (emoji)")
                    TextField("Name", text: $newName)
                    TextField("Calories", text: $newCalories)
                        .keyboardType(.numberPad)
                    if !hideProtein {
                        TextField("Protein (g)", text: $newProtein)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("Edit Quick Add")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingQuickAdd = nil; clearForm() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { updateQuickAdd(qa); editingQuickAdd = nil }
                    }
                }
                .onAppear {
                    newName = qa.name
                    newCalories = "\(qa.calories)"
                    newProtein = qa.protein.map { "\($0)" } ?? ""
                    newIcon = iconDisplay(qa.icon)
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Delete Account?", isPresented: $showDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This will permanently delete your account and all data.")
        }
        .task { await fetchAll() }
        .refreshable { await fetchAll() }
    }
    
    private func fetchAll() async {
        async let q = fetchQuickAdds()
        async let p = fetchPreferences()
        quickAdds = await q
        preferences = await p
    }
    
    private func fetchQuickAdds() async -> [QuickAdd] {
        let request = GraphQLRequest<JSONValue>(
            document: "query ListQuickAdds { listQuickAdds { items { id name calories protein icon } } }",
            responseType: JSONValue.self
        )
        do {
            let result = try await Amplify.API.query(request: request)
            if case .success(let json) = result,
               let items = json["listQuickAdds"]?["items"]?.asArray {
                return items.compactMap { item -> QuickAdd? in
                    guard let id = item["id"]?.stringValue,
                          let name = item["name"]?.stringValue,
                          let cal = item["calories"]?.intValue else { return nil }
                    let protein = item["protein"]?.intValue
                    let icon = item["icon"]?.stringValue ?? "🍽️"
                    return QuickAdd(id: id, name: name, calories: cal, protein: protein, icon: icon)
                }
            }
        } catch {}
        return []
    }
    
    private func fetchPreferences() async -> Preferences? {
        let request = GraphQLRequest<JSONValue>(
            document: "query { listPreferences { items { id hideProtein hideSteps } } }",
            responseType: JSONValue.self
        )
        do {
            let result = try await Amplify.API.query(request: request)
            if case .success(let json) = result,
               let items = json["listPreferences"]?["items"]?.asArray,
               let first = items.first {
                let id = first["id"]?.stringValue ?? UUID().uuidString
                let hideProtein = first["hideProtein"]?.booleanValue ?? false
                let hideSteps = first["hideSteps"]?.booleanValue ?? false
                return Preferences(id: id, hideProtein: hideProtein, hideSteps: hideSteps)
            }
        } catch {}
        return nil
    }
    
    private func updatePreference(hideProtein: Bool? = nil, hideSteps: Bool? = nil) {
        Task {
            let hp = hideProtein ?? self.hideProtein
            let hs = hideSteps ?? self.hideSteps
            
            if let existing = preferences {
                let request = GraphQLRequest<JSONValue>(
                    document: "mutation($input:UpdatePreferencesInput!){updatePreferences(input:$input){id}}",
                    variables: ["input": ["id": existing.id, "hideProtein": hp, "hideSteps": hs]],
                    responseType: JSONValue.self
                )
                _ = try? await Amplify.API.mutate(request: request)
                preferences = Preferences(id: existing.id, hideProtein: hp, hideSteps: hs)
            } else {
                let request = GraphQLRequest<JSONValue>(
                    document: "mutation($input:CreatePreferencesInput!){createPreferences(input:$input){id}}",
                    variables: ["input": ["hideProtein": hp, "hideSteps": hs]],
                    responseType: JSONValue.self
                )
                if case .success(let json) = try? await Amplify.API.mutate(request: request),
                   let id = json["createPreferences"]?["id"]?.stringValue {
                    preferences = Preferences(id: id, hideProtein: hp, hideSteps: hs)
                }
            }
        }
    }
    
    private func createQuickAdd() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let cal = Int(newCalories), cal > 0 else { 
            clearForm()
            return 
        }
        let icon = newIcon.isEmpty ? "🍽️" : newIcon
        let protein = Int(newProtein)
        Task {
            var input: [String: Any] = ["name": trimmedName, "calories": cal, "icon": icon]
            if let p = protein { input["protein"] = p }
            let request = GraphQLRequest<JSONValue>(
                document: "mutation CreateQuickAdd($input: CreateQuickAddInput!) { createQuickAdd(input: $input) { id } }",
                variables: ["input": input],
                responseType: JSONValue.self
            )
            _ = try? await Amplify.API.mutate(request: request)
            quickAdds = await fetchQuickAdds()
        }
        clearForm()
    }
    
    private func updateQuickAdd(_ qa: QuickAdd) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let cal = Int(newCalories), cal > 0 else { 
            clearForm()
            return 
        }
        let icon = newIcon.isEmpty ? "🍽️" : newIcon
        let protein = Int(newProtein)
        Task {
            var input: [String: Any] = ["id": qa.id, "name": trimmedName, "calories": cal, "icon": icon]
            if let p = protein { input["protein"] = p }
            let request = GraphQLRequest<JSONValue>(
                document: "mutation UpdateQuickAdd($input: UpdateQuickAddInput!) { updateQuickAdd(input: $input) { id } }",
                variables: ["input": input],
                responseType: JSONValue.self
            )
            _ = try? await Amplify.API.mutate(request: request)
            quickAdds = await fetchQuickAdds()
        }
        clearForm()
    }
    
    private func deleteQuickAdd(at offsets: IndexSet) {
        for i in offsets {
            let qa = quickAdds[i]
            Task {
                let request = GraphQLRequest<JSONValue>(
                    document: "mutation DeleteQuickAdd($input: DeleteQuickAddInput!) { deleteQuickAdd(input: $input) { id } }",
                    variables: ["input": ["id": qa.id]],
                    responseType: JSONValue.self
                )
                _ = try? await Amplify.API.mutate(request: request)
                quickAdds = await fetchQuickAdds()
            }
        }
    }
    
    private func deleteAccount() {
        Task {
            try? await Amplify.Auth.deleteUser()
            _ = await Amplify.Auth.signOut()
        }
    }
    
    private func clearForm() {
        newName = ""
        newCalories = ""
        newProtein = ""
        newIcon = "🍽️"
    }
    
    private func formatTime(_ dc: DateComponents) -> String {
        var cal = Calendar.current
        cal.timeZone = .current
        guard let date = cal.date(from: dc) else { return "" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
    
    private func iconDisplay(_ icon: String) -> String {
        icon.unicodeScalars.first?.properties.isEmoji == true ? icon : "🍽️"
    }
}
