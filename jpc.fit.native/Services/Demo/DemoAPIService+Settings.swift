import Foundation

/// Quick-add and preferences tables of the fake backend.
extension DemoAPIService {
    func fetchQuickAdds() async -> [QuickAddItem] { quickAdds }

    func createQuickAdd(_ item: QuickAddItem) async -> String? {
        let id = "demo-qa-" + UUID().uuidString.lowercased()
        quickAdds.append(QuickAddItem(id: id, name: item.name, calories: item.calories, icon: item.icon, protein: item.protein))
        return id
    }

    func updateQuickAdd(_ item: QuickAddItem) async -> Bool {
        guard let idx = quickAdds.firstIndex(where: { $0.id == item.id }) else { return false }
        quickAdds[idx] = item
        return true
    }

    func deleteQuickAdd(id: String) async -> Bool {
        let before = quickAdds.count
        quickAdds.removeAll { $0.id == id }
        return quickAdds.count < before
    }

    func fetchPreferences() async -> PreferencesRecord {
        preferences.map { .stored($0) } ?? .missing
    }

    func createPreferences(hideProtein: Bool, hideSteps: Bool) async -> String? {
        let row = Preferences(id: "demo-preferences", hideProtein: hideProtein, hideSteps: hideSteps)
        preferences = row
        return row.id
    }

    func updatePreferences(id: String, hideProtein: Bool, hideSteps: Bool) async -> Bool {
        guard preferences?.id == id else { return false }
        preferences = Preferences(id: id, hideProtein: hideProtein, hideSteps: hideSteps)
        return true
    }
}
