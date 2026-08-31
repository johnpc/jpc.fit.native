import Foundation
import Amplify

/// Read queries for `SettingsViewModel`: the user's quick adds and preferences.
extension SettingsViewModel {
    /// Runs a list query and returns its `items` array (empty on failure).
    private func fetchItems(document: String, listKey: String) async -> [JSONValue] {
        let req = GraphQLRequest<JSONValue>(document: document, responseType: JSONValue.self)
        guard case .success(let json) = try? await Amplify.API.query(request: req) else { return [] }
        return json[listKey]?["items"]?.asArray ?? []
    }

    func fetchQuickAdds() async -> [QuickAdd] {
        let items = await fetchItems(
            document: "query ListQuickAdds { listQuickAdds { items { id name calories protein icon } } }",
            listKey: "listQuickAdds")
        return items.compactMap { item -> QuickAdd? in
            guard let id = item["id"]?.stringValue,
                  let name = item["name"]?.stringValue,
                  let cal = item["calories"]?.intValue else { return nil }
            return QuickAdd(id: id, name: name, calories: cal, protein: item["protein"]?.intValue, icon: item["icon"]?.stringValue ?? "🍽️")
        }
    }

    func fetchPreferences() async -> Preferences? {
        let items = await fetchItems(
            document: "query { listPreferences { items { id hideProtein hideSteps } } }",
            listKey: "listPreferences")
        guard let first = items.first else { return nil }
        let id = first["id"]?.stringValue ?? UUID().uuidString
        return Preferences(id: id, hideProtein: first["hideProtein"]?.booleanValue ?? false, hideSteps: first["hideSteps"]?.booleanValue ?? false)
    }
}
