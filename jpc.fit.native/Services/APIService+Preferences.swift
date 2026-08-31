import Foundation
import Amplify

/// Preferences read for `APIService` — split by concern like the other
/// `APIService+*` files.
extension APIService {
    func fetchPreferences() async -> Preferences? {
        let req = GraphQLRequest<JSONValue>(
            document: "query{listPreferences{items{id hideProtein hideSteps}}}",
            variables: [:], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data.value(at: "listPreferences.items"),
              case .array(let arr) = items, let first = arr.first else { return nil }
        return parsePreferences(first)
    }
}
