import Foundation
import Amplify

/// Preferences read/write for `APIService` — split by concern like the other
/// `APIService+*` files.
extension APIService {
    /// A failed query is `.unknown` (never `.missing`): the caller must not
    /// create a second row just because the network blinked.
    func fetchPreferences() async -> PreferencesRecord {
        let req = GraphQLRequest<JSONValue>(
            document: "query{listPreferences{items{id hideProtein hideSteps}}}",
            variables: [:], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data.value(at: "listPreferences.items"),
              case .array(let arr) = items else { return .unknown }
        guard let first = arr.first else { return .missing }
        guard let parsed = parsePreferences(first) else { return .unknown }
        return .stored(parsed)
    }

    func createPreferences(hideProtein: Bool, hideSteps: Bool) async -> String? {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:CreatePreferencesInput!){createPreferences(input:$input){id}}",
            variables: ["input": ["hideProtein": hideProtein, "hideSteps": hideSteps]],
            responseType: JSONValue.self)
        return await createdId(req, at: "createPreferences.id")
    }

    func updatePreferences(id: String, hideProtein: Bool, hideSteps: Bool) async -> Bool {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:UpdatePreferencesInput!){updatePreferences(input:$input){id}}",
            variables: ["input": ["id": id, "hideProtein": hideProtein, "hideSteps": hideSteps]],
            responseType: JSONValue.self)
        return await mutateSucceeded(req)
    }
}
