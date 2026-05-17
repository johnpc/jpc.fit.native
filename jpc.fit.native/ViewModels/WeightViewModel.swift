import Foundation
import Amplify
import AWSPluginsCore

@MainActor
class WeightViewModel: ObservableObject {
    @Published var weights: [Weight] = []
    @Published var heights: [Height] = []
    @Published var isLoading = true
    @Published var toastMessage: String?
    @Published var showToast = false

    var currentWeight: Int { weights.first?.currentWeight ?? 180 }
    var currentHeight: Int { heights.first?.currentHeight ?? 70 }
    var bmi: Double { Double(currentWeight) / Double(currentHeight * currentHeight) * 703 }

    var bmiLabel: String {
        if bmi < 18.5 { return "underweight" }
        if bmi < 25 { return "healthy" }
        if bmi < 30 { return "overweight" }
        return "obese"
    }

    var maxUnderweight: Double { 18.5 / 703 * Double(currentHeight * currentHeight) }
    var maxHealthy: Double { 25.0 / 703 * Double(currentHeight * currentHeight) }
    var maxOverweight: Double { 30.0 / 703 * Double(currentHeight * currentHeight) }

    func fetchData() async {
        isLoading = true
        async let w = fetchWeights()
        async let h = fetchHeights()
        weights = await w
        heights = await h
        isLoading = false
    }

    func saveWeight(_ value: String) {
        guard let val = Int(value), val > 0 else { return }
        Task {
            weights.insert(Weight(currentWeight: val, createdAt: .now()), at: 0)
            let request = GraphQLRequest<JSONValue>(
                document: "mutation CreateWeight($input: CreateWeightInput!) { createWeight(input: $input) { id } }",
                variables: ["input": ["currentWeight": val]],
                responseType: JSONValue.self,
                authMode: AWSAuthorizationType.amazonCognitoUserPools)
            do {
                let result = try await Amplify.API.mutate(request: request)
                if case .failure(let error) = result { showError("Weight: \(error.errorDescription)") }
            } catch { showError("Weight: \(error.localizedDescription)") }
            await fetchData()
        }
    }

    func saveHeight(_ value: String) {
        guard let val = Int(value), val > 0 else { return }
        Task {
            heights.insert(Height(currentHeight: val, createdAt: .now()), at: 0)
            let request = GraphQLRequest<JSONValue>(
                document: "mutation CreateHeight($input: CreateHeightInput!) { createHeight(input: $input) { id } }",
                variables: ["input": ["currentHeight": val]],
                responseType: JSONValue.self,
                authMode: AWSAuthorizationType.amazonCognitoUserPools)
            do {
                let result = try await Amplify.API.mutate(request: request)
                if case .failure(let error) = result { showError("Height: \(error.errorDescription)") }
            } catch { showError("Height: \(error.localizedDescription)") }
            await fetchData()
        }
    }

    func showError(_ message: String) {
        toastMessage = message
        showToast = true
    }

    private func fetchWeights() async -> [Weight] {
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

    private func fetchHeights() async -> [Height] {
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
