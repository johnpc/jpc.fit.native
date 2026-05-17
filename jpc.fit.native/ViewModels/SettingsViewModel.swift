import Foundation
import Amplify

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var quickAdds: [QuickAdd] = []
    @Published var preferences: Preferences?

    var hideProtein: Bool { preferences?.hideProtein ?? false }
    var hideSteps: Bool { preferences?.hideSteps ?? false }

    func fetchAll() async {
        async let q = fetchQuickAdds()
        async let p = fetchPreferences()
        quickAdds = await q
        preferences = await p
    }

    func updatePreference(hideProtein: Bool? = nil, hideSteps: Bool? = nil) {
        Task {
            let hp = hideProtein ?? self.hideProtein
            let hs = hideSteps ?? self.hideSteps
            if let existing = preferences {
                let req = GraphQLRequest<JSONValue>(
                    document: "mutation($input:UpdatePreferencesInput!){updatePreferences(input:$input){id}}",
                    variables: ["input": ["id": existing.id, "hideProtein": hp, "hideSteps": hs]],
                    responseType: JSONValue.self)
                _ = try? await Amplify.API.mutate(request: req)
                preferences = Preferences(id: existing.id, hideProtein: hp, hideSteps: hs)
            } else {
                let req = GraphQLRequest<JSONValue>(
                    document: "mutation($input:CreatePreferencesInput!){createPreferences(input:$input){id}}",
                    variables: ["input": ["hideProtein": hp, "hideSteps": hs]],
                    responseType: JSONValue.self)
                if case .success(let json) = try? await Amplify.API.mutate(request: req),
                   let id = json["createPreferences"]?["id"]?.stringValue {
                    preferences = Preferences(id: id, hideProtein: hp, hideSteps: hs)
                }
            }
        }
    }

    func createQuickAdd(name: String, calories: String, protein: String, icon: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cal = Int(calories), cal > 0 else { return }
        let ic = icon.isEmpty ? "🍽️" : icon
        let prot = Int(protein)
        Task {
            var input: [String: Any] = ["name": trimmed, "calories": cal, "icon": ic]
            if let p = prot { input["protein"] = p }
            let req = GraphQLRequest<JSONValue>(
                document: "mutation CreateQuickAdd($input: CreateQuickAddInput!) { createQuickAdd(input: $input) { id } }",
                variables: ["input": input], responseType: JSONValue.self)
            _ = try? await Amplify.API.mutate(request: req)
            quickAdds = await fetchQuickAdds()
        }
    }

    func updateQuickAdd(id: String, name: String, calories: String, protein: String, icon: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cal = Int(calories), cal > 0 else { return }
        let ic = icon.isEmpty ? "🍽️" : icon
        let prot = Int(protein)
        Task {
            var input: [String: Any] = ["id": id, "name": trimmed, "calories": cal, "icon": ic]
            if let p = prot { input["protein"] = p }
            let req = GraphQLRequest<JSONValue>(
                document: "mutation UpdateQuickAdd($input: UpdateQuickAddInput!) { updateQuickAdd(input: $input) { id } }",
                variables: ["input": input], responseType: JSONValue.self)
            _ = try? await Amplify.API.mutate(request: req)
            quickAdds = await fetchQuickAdds()
        }
    }

    func deleteQuickAdd(at offsets: IndexSet) {
        for i in offsets {
            let qa = quickAdds[i]
            Task {
                let req = GraphQLRequest<JSONValue>(
                    document: "mutation DeleteQuickAdd($input: DeleteQuickAddInput!) { deleteQuickAdd(input: $input) { id } }",
                    variables: ["input": ["id": qa.id]], responseType: JSONValue.self)
                _ = try? await Amplify.API.mutate(request: req)
                quickAdds = await fetchQuickAdds()
            }
        }
    }

    func deleteAccount() {
        Task {
            try? await Amplify.Auth.deleteUser()
            _ = await Amplify.Auth.signOut()
        }
    }

    func signOut() {
        Task { _ = await Amplify.Auth.signOut() }
    }

    func iconDisplay(_ icon: String) -> String {
        icon.unicodeScalars.first?.properties.isEmoji == true ? icon : "🍽️"
    }

    private func fetchQuickAdds() async -> [QuickAdd] {
        let req = GraphQLRequest<JSONValue>(
            document: "query ListQuickAdds { listQuickAdds { items { id name calories protein icon } } }",
            responseType: JSONValue.self)
        do {
            let result = try await Amplify.API.query(request: req)
            if case .success(let json) = result,
               let items = json["listQuickAdds"]?["items"]?.asArray {
                return items.compactMap { item -> QuickAdd? in
                    guard let id = item["id"]?.stringValue,
                          let name = item["name"]?.stringValue,
                          let cal = item["calories"]?.intValue else { return nil }
                    return QuickAdd(id: id, name: name, calories: cal, protein: item["protein"]?.intValue, icon: item["icon"]?.stringValue ?? "🍽️")
                }
            }
        } catch {}
        return []
    }

    private func fetchPreferences() async -> Preferences? {
        let req = GraphQLRequest<JSONValue>(
            document: "query { listPreferences { items { id hideProtein hideSteps } } }",
            responseType: JSONValue.self)
        do {
            let result = try await Amplify.API.query(request: req)
            if case .success(let json) = result,
               let items = json["listPreferences"]?["items"]?.asArray,
               let first = items.first {
                let id = first["id"]?.stringValue ?? UUID().uuidString
                return Preferences(id: id, hideProtein: first["hideProtein"]?.booleanValue ?? false, hideSteps: first["hideSteps"]?.booleanValue ?? false)
            }
        } catch {}
        return nil
    }
}
