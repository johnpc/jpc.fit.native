import Foundation
import Amplify

/// Lightweight per-day aggregation reads used by the Stats tab — split by
/// concern like the other `APIService+*` files.
extension APIService {
    /// nil means the request FAILED — callers must not confuse that with an
    /// empty day, or one flaky request ends the streak at the wrong number.
    func fetchFoodCalories(day: String) async -> [Int]? {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listFoodByDay(day:$day){items{calories}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data["listFoodByDay"]?["items"]?.asArray else { return nil }
        return items.compactMap { $0["calories"]?.intValue }
    }

    func fetchCacheBurned(day: String) async -> Int {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listHealthKitCacheByDay(day:$day){items{activeCalories baseCalories}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data["listHealthKitCacheByDay"]?["items"]?.asArray,
              let first = items.first else { return 0 }
        return Int((first["activeCalories"]?.doubleValue ?? 0) + (first["baseCalories"]?.doubleValue ?? 0))
    }
}
