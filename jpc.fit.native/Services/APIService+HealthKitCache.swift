import Foundation
import Amplify

/// HealthKitCache create/update mutations — split from `APIService` by concern
/// (same shape as `APIService+Parsing`).
extension APIService {
    func createHealthKitCache(activeCalories: Double, baseCalories: Double, steps: Double, day: String) async -> String? {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:CreateHealthKitCacheInput!){createHealthKitCache(input:$input){id}}",
            variables: ["input": ["activeCalories": activeCalories, "baseCalories": baseCalories, "steps": steps, "day": day]],
            responseType: JSONValue.self)
        if case .success(let data) = try? await Amplify.API.mutate(request: req),
           let id = data.value(at: "createHealthKitCache.id"), case .string(let idStr) = id {
            return idStr
        }
        return nil
    }

    func updateHealthKitCache(id: String, activeCalories: Double, baseCalories: Double, steps: Double) async {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:UpdateHealthKitCacheInput!){updateHealthKitCache(input:$input){id}}",
            variables: ["input": ["id": id, "activeCalories": activeCalories, "baseCalories": baseCalories, "steps": steps]],
            responseType: JSONValue.self)
        _ = try? await Amplify.API.mutate(request: req)
    }
}
