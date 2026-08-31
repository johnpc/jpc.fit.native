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

    // Saves are OPTIMISTIC: the row is inserted at tap time and stays — no
    // post-write refetch (it flipped isLoading and grayed the screen for the
    // whole round trip, and an immediate re-list can miss the new row anyway
    // per DynamoDB eventual consistency). On failure: toast + roll back.
    func saveWeight(_ value: String) {
        guard let val = Int(value), val > 0 else { return }
        let optimistic = Weight(currentWeight: val, createdAt: .now())
        weights.insert(optimistic, at: 0)
        Task {
            let doc = "mutation CreateWeight($input: CreateWeightInput!) { createWeight(input: $input) { id } }"
            if let failure = await runCreate(document: doc, input: ["currentWeight": val]) {
                showError("Weight: \(failure)")
                weights.removeAll { $0.id == optimistic.id }
            }
        }
    }

    func saveHeight(_ value: String) {
        guard let val = Int(value), val > 0 else { return }
        let optimistic = Height(currentHeight: val, createdAt: .now())
        heights.insert(optimistic, at: 0)
        Task {
            let doc = "mutation CreateHeight($input: CreateHeightInput!) { createHeight(input: $input) { id } }"
            if let failure = await runCreate(document: doc, input: ["currentHeight": val]) {
                showError("Height: \(failure)")
                heights.removeAll { $0.id == optimistic.id }
            }
        }
    }

    /// Runs a create mutation; returns a failure description or nil on success.
    private func runCreate(document: String, input: [String: Any]) async -> String? {
        let request = GraphQLRequest<JSONValue>(
            document: document, variables: ["input": input], responseType: JSONValue.self,
            authMode: AWSAuthorizationType.amazonCognitoUserPools)
        do {
            if case .failure(let error) = try await Amplify.API.mutate(request: request) {
                return error.errorDescription
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func showError(_ message: String) {
        toastMessage = message
        showToast = true
    }
}
