import Foundation

/// Quick-add create/update/delete for `SettingsViewModel` — all OPTIMISTIC:
/// `quickAdds` updates at tap time (create swaps a temp id for the server id
/// when it arrives). No post-write refetch — it kept the UI stale-feeling
/// for the whole round trip and can miss the new row (DynamoDB eventual
/// consistency). A failed write rolls back and surfaces `errorMessage`.
extension SettingsViewModel {
    func createQuickAdd(_ draft: QuickAddDraft) {
        guard let temp = draft.item(id: UUID().uuidString) else { return }
        quickAdds.append(temp)
        Task {
            guard let id = await api.createQuickAdd(temp) else {
                quickAdds.removeAll { $0.id == temp.id }
                errorMessage = "Couldn't save \"\(temp.name)\" — check your connection and try again."
                return
            }
            if let idx = quickAdds.firstIndex(where: { $0.id == temp.id }) {
                quickAdds[idx] = QuickAddItem(id: id, name: temp.name, calories: temp.calories, icon: temp.icon, protein: temp.protein)
            }
        }
    }

    func updateQuickAdd(id: String, with draft: QuickAddDraft) {
        guard let updated = draft.item(id: id), let idx = quickAdds.firstIndex(where: { $0.id == id }) else { return }
        let original = quickAdds[idx]
        quickAdds[idx] = updated
        Task {
            if await !api.updateQuickAdd(updated), let i = quickAdds.firstIndex(where: { $0.id == id }) {
                quickAdds[i] = original
                errorMessage = "Couldn't save changes to \"\(original.name)\" — try again."
            }
        }
    }

    func deleteQuickAdd(at offsets: IndexSet) {
        let removed = offsets.map { quickAdds[$0] }
        quickAdds.remove(atOffsets: offsets)
        for item in removed {
            Task {
                if await !api.deleteQuickAdd(id: item.id) {
                    quickAdds.append(item)
                    errorMessage = "Couldn't delete \"\(item.name)\" — check your connection and try again."
                }
            }
        }
    }
}
