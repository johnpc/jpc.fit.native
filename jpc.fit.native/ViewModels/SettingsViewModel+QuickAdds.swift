import Foundation
import Amplify

/// Quick-add create/update/delete mutations for `SettingsViewModel`. Each
/// mutation re-fetches the list so the UI reflects the server state.
extension SettingsViewModel {
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
}
