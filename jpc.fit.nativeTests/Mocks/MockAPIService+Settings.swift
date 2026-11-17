import Foundation
@testable import jpc_fit

/// Quick-add, preferences and weight/height tables of the unit-test mock.
extension MockAPIService {
    func setQuickAdds(_ adds: [QuickAddItem]) { quickAdds = adds }

    func createQuickAdd(_ item: QuickAddItem) async -> String? {
        guard !failWrites else { return nil }
        let id = "server-" + item.id
        quickAdds.append(QuickAddItem(id: id, name: item.name, calories: item.calories, icon: item.icon, protein: item.protein))
        return id
    }

    func updateQuickAdd(_ item: QuickAddItem) async -> Bool {
        guard !failWrites, let idx = quickAdds.firstIndex(where: { $0.id == item.id }) else { return false }
        quickAdds[idx] = item
        return true
    }

    func deleteQuickAdd(id: String) async -> Bool {
        guard !failWrites else { return false }
        quickAdds.removeAll { $0.id == id }
        return true
    }

    func fetchPreferences() async -> PreferencesRecord { preferencesRecord }

    func setPreferences(_ p: Preferences?) { preferencesRecord = p.map { .stored($0) } ?? .missing }
    func setPreferencesRecord(_ r: PreferencesRecord) { preferencesRecord = r }

    func createPreferences(hideProtein: Bool, hideSteps: Bool) async -> String? {
        guard !failWrites else { return nil }
        createdPreferences += 1
        let row = Preferences(id: "prefs-\(createdPreferences)", hideProtein: hideProtein, hideSteps: hideSteps)
        preferencesRecord = .stored(row)
        return row.id
    }

    func updatePreferences(id: String, hideProtein: Bool, hideSteps: Bool) async -> Bool {
        guard !failWrites else { return false }
        updatedPreferences.append((id, hideProtein, hideSteps))
        preferencesRecord = .stored(Preferences(id: id, hideProtein: hideProtein, hideSteps: hideSteps))
        return true
    }

    func getCreatedPreferences() -> Int { createdPreferences }
    func getUpdatedPreferences() -> [(id: String, hideProtein: Bool, hideSteps: Bool)] { updatedPreferences }

    func setWeights(_ w: [Weight]) { weights = w }
    func setHeights(_ h: [Height]) { heights = h }
    func fetchWeights() async -> [Weight] { weights }
    func fetchHeights() async -> [Height] { heights }

    func createWeight(_ pounds: Int) async -> WriteOutcome {
        guard !failWrites else { return .failed(reason: "offline") }
        let row = Weight(id: UUID().uuidString, currentWeight: pounds)
        weights.insert(row, at: 0)
        return .saved(id: row.id)
    }

    func createHeight(_ inches: Int) async -> WriteOutcome {
        guard !failWrites else { return .failed(reason: "offline") }
        let row = Height(id: UUID().uuidString, currentHeight: inches)
        heights.insert(row, at: 0)
        return .saved(id: row.id)
    }
}
