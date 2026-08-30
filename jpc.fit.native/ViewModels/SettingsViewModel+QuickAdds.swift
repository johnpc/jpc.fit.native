import Foundation
import Amplify

/// Quick-add create/update/delete mutations for `SettingsViewModel` — all
/// OPTIMISTIC: `quickAdds` updates at tap time (create swaps a temp id for the
/// server id when it arrives). No post-write refetch — it kept the UI stale-
/// feeling for the whole round trip and can miss the new row (DynamoDB
/// eventual consistency).
extension SettingsViewModel {
    func createQuickAdd(name: String, calories: String, protein: String, icon: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cal = Int(calories), cal > 0 else { return }
        let ic = icon.isEmpty ? "🍽️" : icon
        let prot = Int(protein)
        let temp = QuickAdd(id: UUID().uuidString, name: trimmed, calories: cal, protein: prot, icon: ic)
        quickAdds.append(temp)
        Task {
            var input: [String: Any] = ["name": trimmed, "calories": cal, "icon": ic]
            if let p = prot { input["protein"] = p }
            let req = GraphQLRequest<JSONValue>(
                document: "mutation CreateQuickAdd($input: CreateQuickAddInput!) { createQuickAdd(input: $input) { id } }",
                variables: ["input": input], responseType: JSONValue.self)
            if case .success(let json) = try? await Amplify.API.mutate(request: req),
               let id = json["createQuickAdd"]?["id"]?.stringValue,
               let idx = quickAdds.firstIndex(where: { $0.id == temp.id }) {
                quickAdds[idx] = QuickAdd(id: id, name: trimmed, calories: cal, protein: prot, icon: ic)
            }
        }
    }

    func updateQuickAdd(id: String, name: String, calories: String, protein: String, icon: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cal = Int(calories), cal > 0 else { return }
        let ic = icon.isEmpty ? "🍽️" : icon
        let prot = Int(protein)
        if let idx = quickAdds.firstIndex(where: { $0.id == id }) {
            quickAdds[idx] = QuickAdd(id: id, name: trimmed, calories: cal, protein: prot, icon: ic)
        }
        Task {
            var input: [String: Any] = ["id": id, "name": trimmed, "calories": cal, "icon": ic]
            if let p = prot { input["protein"] = p }
            let req = GraphQLRequest<JSONValue>(
                document: "mutation UpdateQuickAdd($input: UpdateQuickAddInput!) { updateQuickAdd(input: $input) { id } }",
                variables: ["input": input], responseType: JSONValue.self)
            _ = try? await Amplify.API.mutate(request: req)
        }
    }

    func deleteQuickAdd(at offsets: IndexSet) {
        let removed = offsets.map { quickAdds[$0] }
        quickAdds.remove(atOffsets: offsets)
        for qa in removed {
            Task {
                let req = GraphQLRequest<JSONValue>(
                    document: "mutation DeleteQuickAdd($input: DeleteQuickAddInput!) { deleteQuickAdd(input: $input) { id } }",
                    variables: ["input": ["id": qa.id]], responseType: JSONValue.self)
                _ = try? await Amplify.API.mutate(request: req)
            }
        }
    }
}
