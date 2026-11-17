import Foundation

@MainActor
class WeightViewModel: ObservableObject {
    @Published var weights: [Weight] = []
    @Published var heights: [Height] = []
    @Published var isLoading = true
    /// StateMachine: Weight toast
    /// The error toast is ONE optional: visible iff non-nil (`toastMessage` +
    /// `showToast` could disagree). Auto-hides after `toastDuration`; a newer
    /// toast restarts the clock.
    @Published private(set) var toast: String?

    let api: APIServiceProtocol
    private let toastDuration: Duration
    private var toastTask: Task<Void, Never>?

    init(api: APIServiceProtocol = AppServices.api, toastDuration: Duration = .seconds(4)) {
        self.api = api
        self.toastDuration = toastDuration
    }

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
        async let w = api.fetchWeights()
        async let h = api.fetchHeights()
        weights = await w
        heights = await h
        isLoading = false
    }

    /// Saves are OPTIMISTIC: the row is inserted at tap time and stays — no
    /// post-write refetch (it flipped isLoading and grayed the screen for the
    /// whole round trip, and an immediate re-list can miss the new row anyway
    /// per DynamoDB eventual consistency). On failure: toast + roll back.
    /// Returns false when the text isn't a positive whole number.
    @discardableResult
    func save(_ prompt: MeasurementPrompt, value: String) -> Bool {
        guard let val = Int(value), val > 0 else { return false }
        switch prompt {
        case .weight: saveWeight(val)
        case .height: saveHeight(val)
        }
        return true
    }

    private func saveWeight(_ val: Int) {
        let optimistic = Weight(currentWeight: val, createdAt: .now())
        weights.insert(optimistic, at: 0)
        Task {
            if case .failed(let reason) = await api.createWeight(val) {
                showError("Weight: \(reason)")
                weights.removeAll { $0.id == optimistic.id }
            }
        }
    }

    private func saveHeight(_ val: Int) {
        let optimistic = Height(currentHeight: val, createdAt: .now())
        heights.insert(optimistic, at: 0)
        Task {
            if case .failed(let reason) = await api.createHeight(val) {
                showError("Height: \(reason)")
                heights.removeAll { $0.id == optimistic.id }
            }
        }
    }

    func showError(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { [toastDuration] in
            try? await Task.sleep(for: toastDuration)
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    /// Lets a test await the auto-hide instead of sleeping.
    func awaitToastDismissal() async {
        await toastTask?.value
    }
}
