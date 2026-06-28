import Foundation
import Amplify

/// Paginated weight/height fetches for `WeightViewModel`, kept separate so the
/// view model file stays small. Both walk `nextToken` until the list is drained.
extension WeightViewModel {
    func fetchWeights() async -> [Weight] {
        var allItems: [Weight] = []
        var nextToken: String? = nil
        repeat {
            let doc = "query ListWeights($limit: Int, $nextToken: String) { listWeights(limit: $limit, nextToken: $nextToken) { items { id currentWeight createdAt } nextToken } }"
            var variables: [String: Any] = ["limit": 1000]
            if let token = nextToken { variables["nextToken"] = token }
            let request = GraphQLRequest<JSONValue>(document: doc, variables: variables, responseType: JSONValue.self)
            do {
                let result = try await Amplify.API.query(request: request)
                if case .success(let json) = result {
                    nextToken = json["listWeights"]?["nextToken"]?.stringValue
                    if let items = json["listWeights"]?["items"]?.asArray {
                        allItems += items.compactMap { item -> Weight? in
                            guard let id = item["id"]?.stringValue,
                                  let cw = item["currentWeight"]?.intValue else { return nil }
                            let createdAt = item["createdAt"]?.stringValue ?? ""
                            return Weight(id: id, currentWeight: cw, createdAt: try? Temporal.DateTime(iso8601String: createdAt))
                        }
                    }
                } else { break }
            } catch { break }
        } while nextToken != nil
        return allItems.sorted { ($0.createdAt?.foundationDate ?? .distantPast) > ($1.createdAt?.foundationDate ?? .distantPast) }
    }

    func fetchHeights() async -> [Height] {
        var allItems: [Height] = []
        var nextToken: String? = nil
        repeat {
            let doc = "query ListHeights($limit: Int, $nextToken: String) { listHeights(limit: $limit, nextToken: $nextToken) { items { id currentHeight createdAt } nextToken } }"
            var variables: [String: Any] = ["limit": 1000]
            if let token = nextToken { variables["nextToken"] = token }
            let request = GraphQLRequest<JSONValue>(document: doc, variables: variables, responseType: JSONValue.self)
            do {
                let result = try await Amplify.API.query(request: request)
                if case .success(let json) = result {
                    nextToken = json["listHeights"]?["nextToken"]?.stringValue
                    if let items = json["listHeights"]?["items"]?.asArray {
                        allItems += items.compactMap { item -> Height? in
                            guard let id = item["id"]?.stringValue,
                                  let ch = item["currentHeight"]?.intValue else { return nil }
                            let createdAt = item["createdAt"]?.stringValue ?? ""
                            return Height(id: id, currentHeight: ch, createdAt: try? Temporal.DateTime(iso8601String: createdAt))
                        }
                    }
                } else { break }
            } catch { break }
        } while nextToken != nil
        return allItems.sorted { ($0.createdAt?.foundationDate ?? .distantPast) > ($1.createdAt?.foundationDate ?? .distantPast) }
    }
}
