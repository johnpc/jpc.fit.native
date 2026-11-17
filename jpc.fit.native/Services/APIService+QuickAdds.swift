import Foundation
import Amplify

/// Quick-add reads and writes for `APIService`.
extension APIService {
    func fetchQuickAdds() async -> [QuickAddItem] {
        let req = GraphQLRequest<JSONValue>(
            document: "query{listQuickAdds{items{id name calories protein icon}}}", variables: [:], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data.value(at: "listQuickAdds.items"),
              case .array(let arr) = items else { return [] }
        return arr.compactMap { parseQuickAdd($0) }
    }

    private func quickAddInput(_ item: QuickAddItem, includeId: Bool) -> [String: Any] {
        var input: [String: Any] = ["name": item.name, "calories": item.calories, "icon": item.icon]
        if includeId { input["id"] = item.id }
        if let p = item.protein { input["protein"] = p }
        return input
    }

    func createQuickAdd(_ item: QuickAddItem) async -> String? {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:CreateQuickAddInput!){createQuickAdd(input:$input){id}}",
            variables: ["input": quickAddInput(item, includeId: false)], responseType: JSONValue.self)
        return await createdId(req, at: "createQuickAdd.id")
    }

    func updateQuickAdd(_ item: QuickAddItem) async -> Bool {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:UpdateQuickAddInput!){updateQuickAdd(input:$input){id}}",
            variables: ["input": quickAddInput(item, includeId: true)], responseType: JSONValue.self)
        return await mutateSucceeded(req)
    }

    func deleteQuickAdd(id: String) async -> Bool {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:DeleteQuickAddInput!){deleteQuickAdd(input:$input){id}}",
            variables: ["input": ["id": id]], responseType: JSONValue.self)
        return await mutateSucceeded(req)
    }
}
