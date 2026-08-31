import Foundation
import Amplify

/// Paginated weight/height fetches for `WeightViewModel` — one generic
/// nextToken walk parameterized by list field + row parser.
extension WeightViewModel {
    func fetchWeights() async -> [Weight] {
        let doc = "query ListWeights($limit: Int, $nextToken: String) { listWeights(limit: $limit, nextToken: $nextToken) { items { id currentWeight createdAt } nextToken } }"
        let items = await fetchAllPages(document: doc, listKey: "listWeights") { item -> Weight? in
            guard let id = item["id"]?.stringValue,
                  let cw = item["currentWeight"]?.intValue else { return nil }
            return Weight(id: id, currentWeight: cw, createdAt: Self.parseDate(item))
        }
        return items.sorted { ($0.createdAt?.foundationDate ?? .distantPast) > ($1.createdAt?.foundationDate ?? .distantPast) }
    }

    func fetchHeights() async -> [Height] {
        let doc = "query ListHeights($limit: Int, $nextToken: String) { listHeights(limit: $limit, nextToken: $nextToken) { items { id currentHeight createdAt } nextToken } }"
        let items = await fetchAllPages(document: doc, listKey: "listHeights") { item -> Height? in
            guard let id = item["id"]?.stringValue,
                  let ch = item["currentHeight"]?.intValue else { return nil }
            return Height(id: id, currentHeight: ch, createdAt: Self.parseDate(item))
        }
        return items.sorted { ($0.createdAt?.foundationDate ?? .distantPast) > ($1.createdAt?.foundationDate ?? .distantPast) }
    }

    static func parseDate(_ item: JSONValue) -> Temporal.DateTime? {
        try? Temporal.DateTime(iso8601String: item["createdAt"]?.stringValue ?? "")
    }

    /// Walks `nextToken` until the list is drained, parsing each row.
    private func fetchAllPages<T>(document: String, listKey: String, parse: (JSONValue) -> T?) async -> [T] {
        var all: [T] = []
        var nextToken: String?
        repeat {
            guard let page = await fetchPage(document: document, listKey: listKey, nextToken: nextToken) else { break }
            nextToken = page["nextToken"]?.stringValue
            all += (page["items"]?.asArray ?? []).compactMap(parse)
        } while nextToken != nil
        return all
    }

    /// One page of a paginated list query; nil = request failed.
    private func fetchPage(document: String, listKey: String, nextToken: String?) async -> JSONValue? {
        var variables: [String: Any] = ["limit": 1000]
        if let token = nextToken { variables["nextToken"] = token }
        let request = GraphQLRequest<JSONValue>(document: document, variables: variables, responseType: JSONValue.self)
        guard case .success(let json) = try? await Amplify.API.query(request: request) else { return nil }
        return json[listKey]
    }
}
