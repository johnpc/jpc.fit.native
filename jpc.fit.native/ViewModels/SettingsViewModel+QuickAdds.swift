import Foundation
import Amplify

/// Quick-add create/update/delete mutations for `SettingsViewModel` — all
/// OPTIMISTIC: `quickAdds` updates at tap time (create swaps a temp id for the
/// server id when it arrives). No post-write refetch — it kept the UI stale-
/// feeling for the whole round trip and can miss the new row (DynamoDB
/// eventual consistency).
extension SettingsViewModel {
    /// Validates and normalizes the quick-add form fields; nil = invalid form.
    private func parsedQuickAdd(id: String, name: String, calories: String, protein: String, icon: String) -> QuickAdd? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cal = Int(calories), cal > 0 else { return nil }
        return QuickAdd(id: id, name: trimmed, calories: cal, protein: Int(protein), icon: icon.isEmpty ? "🍽️" : icon)
    }

    private func mutationInput(for qa: QuickAdd, includeId: Bool) -> [String: Any] {
        var input: [String: Any] = ["name": qa.name, "calories": qa.calories, "icon": qa.icon]
        if includeId { input["id"] = qa.id }
        if let p = qa.protein { input["protein"] = p }
        return input
    }

    func createQuickAdd(name: String, calories: String, protein: String, icon: String) {
        guard let temp = parsedQuickAdd(id: UUID().uuidString, name: name, calories: calories, protein: protein, icon: icon) else { return }
        quickAdds.append(temp)
        Task {
            let req = GraphQLRequest<JSONValue>(
                document: "mutation CreateQuickAdd($input: CreateQuickAddInput!) { createQuickAdd(input: $input) { id } }",
                variables: ["input": mutationInput(for: temp, includeId: false)], responseType: JSONValue.self)
            if case .success(let json) = try? await Amplify.API.mutate(request: req),
               let id = json["createQuickAdd"]?["id"]?.stringValue,
               let idx = quickAdds.firstIndex(where: { $0.id == temp.id }) {
                quickAdds[idx] = QuickAdd(id: id, name: temp.name, calories: temp.calories, protein: temp.protein, icon: temp.icon)
            }
        }
    }

    func updateQuickAdd(id: String, name: String, calories: String, protein: String, icon: String) {
        guard let updated = parsedQuickAdd(id: id, name: name, calories: calories, protein: protein, icon: icon) else { return }
        if let idx = quickAdds.firstIndex(where: { $0.id == id }) {
            quickAdds[idx] = updated
        }
        Task {
            let req = GraphQLRequest<JSONValue>(
                document: "mutation UpdateQuickAdd($input: UpdateQuickAddInput!) { updateQuickAdd(input: $input) { id } }",
                variables: ["input": mutationInput(for: updated, includeId: true)], responseType: JSONValue.self)
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
