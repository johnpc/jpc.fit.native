import Foundation
import Amplify

/// Read queries for `SettingsViewModel`: the user's quick adds and preferences.
extension SettingsViewModel {
    func fetchQuickAdds() async -> [QuickAdd] {
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

    func fetchPreferences() async -> Preferences? {
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
