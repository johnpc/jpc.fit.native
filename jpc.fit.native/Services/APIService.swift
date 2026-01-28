import Foundation
import Amplify

actor APIService {
    static let shared = APIService()
    
    func fetchFoods(day: String) async -> [Food] {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listFoodByDay(day:$day){items{id name calories protein day createdAt}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data.value(at: "listFoodByDay.items"),
              case .array(let arr) = items else { return [] }
        return arr.compactMap { parseFood($0) }
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
    
    // MARK: - Parsing
    
    private func parseFood(_ item: JSONValue) -> Food? {
        guard case .string(let id) = item.value(at: "id"),
              case .number(let cal) = item.value(at: "calories"),
              case .string(let day) = item.value(at: "day") else { return nil }
        let name: String? = if case .string(let n) = item.value(at: "name") { n } else { nil }
        let protein: Int? = if case .number(let p) = item.value(at: "protein") { Int(p) } else { nil }
        return Food(id: id, name: name, calories: Int(cal), protein: protein, day: day)
    }
    
    private func parseCache(_ item: JSONValue) -> HealthKitCache? {
        guard case .string(let id) = item.value(at: "id"),
              case .number(let active) = item.value(at: "activeCalories"),
              case .number(let base) = item.value(at: "baseCalories"),
              case .string(let day) = item.value(at: "day") else { return nil }
        let steps: Double = if case .number(let s) = item.value(at: "steps") { s } else { 0 }
        return HealthKitCache(id: id, activeCalories: active, baseCalories: base, steps: steps, day: day)
    }
    
    private func parseQuickAdd(_ item: JSONValue) -> QuickAddItem? {
        guard case .string(let id) = item.value(at: "id"),
              case .string(let name) = item.value(at: "name"),
              case .number(let cal) = item.value(at: "calories") else { return nil }
        var icon = "🍽️"
        if case .string(let i) = item.value(at: "icon") {
            icon = i.unicodeScalars.first?.properties.isEmoji == true ? i : "🍽️"
        }
        let protein: Int? = if case .number(let p) = item.value(at: "protein") { Int(p) } else { nil }
        return QuickAddItem(id: id, name: name, calories: Int(cal), icon: icon, protein: protein)
    }
}
