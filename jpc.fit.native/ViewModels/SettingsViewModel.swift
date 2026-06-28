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
}
