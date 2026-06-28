import Foundation
import Amplify

actor APIService {
    static let shared = APIService()
    
    private func signOutIfUnauthorized(_ error: Error?) async {
        guard let error, "\(error)".contains("Unauthorized") || "\(error)".contains("401") else { return }
        _ = await Amplify.Auth.signOut()
    }
    
    func fetchFoods(day: String) async -> [Food] {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listFoodByDay(day:$day){items{id name calories protein day createdAt}}}",
            variables: ["day": day], responseType: JSONValue.self)
        do {
            let result = try await Amplify.API.query(request: req)
            if case .success(let data) = result,
               let items = data.value(at: "listFoodByDay.items"),
               case .array(let arr) = items {
                return arr.compactMap { parseFood($0) }.sorted { ($0.createdAt?.iso8601String ?? "") < ($1.createdAt?.iso8601String ?? "") }
            }
            if case .failure(let gqlError) = result {
                await signOutIfUnauthorized(gqlError)
            }
        } catch {
            await signOutIfUnauthorized(error)
        }
        return []
    }
    
    func fetchHealthKitCache(day: String) async -> HealthKitCache? {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listHealthKitCacheByDay(day:$day){items{id activeCalories baseCalories steps day}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data.value(at: "listHealthKitCacheByDay.items"),
              case .array(let arr) = items, let first = arr.first else { return nil }
        return parseCache(first)
    }
    
    func fetchQuickAdds() async -> [QuickAddItem] {
        let req = GraphQLRequest<JSONValue>(
            document: "query{listQuickAdds{items{id name calories protein icon}}}", variables: [:], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data.value(at: "listQuickAdds.items"),
              case .array(let arr) = items else { return [] }
        return arr.compactMap { parseQuickAdd($0) }
    }
    
    func createFood(name: String, calories: Int, protein: Int? = nil, day: String) async {
        var input: [String: Any] = ["name": name, "calories": calories, "day": day]
        if let p = protein { input["protein"] = p }
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:CreateFoodInput!){createFood(input:$input){id}}",
            variables: ["input": input],
            responseType: JSONValue.self)
        _ = try? await Amplify.API.mutate(request: req)
    }
    
    func deleteFood(id: String) async {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:DeleteFoodInput!){deleteFood(input:$input){id}}",
            variables: ["input": ["id": id]], responseType: JSONValue.self)
        _ = try? await Amplify.API.mutate(request: req)
    }
    
    func updateFood(id: String, name: String?, calories: Int, protein: Int?) async {
        var input: [String: Any] = ["id": id, "calories": calories]
        if let n = name { input["name"] = n }
        if let p = protein { input["protein"] = p }
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:UpdateFoodInput!){updateFood(input:$input){id}}",
            variables: ["input": input], responseType: JSONValue.self)
        _ = try? await Amplify.API.mutate(request: req)
    }
    
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
