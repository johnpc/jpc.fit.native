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
}
