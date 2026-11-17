import Foundation

/// The quick-add form's fields with its validation/normalization — one place
/// for "trimmed non-empty name, positive calories, plate emoji by default".
struct QuickAddDraft: Equatable {
    static let defaultIcon = "🍽️"

    var icon = QuickAddDraft.defaultIcon
    var name = ""
    var calories = ""
    var protein = ""

    init() {}

    init(item: QuickAddItem) {
        icon = item.icon
        name = item.name
        calories = "\(item.calories)"
        protein = item.protein.map { "\($0)" } ?? ""
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { item(id: "preview") != nil }

    /// The normalized item under `id`, or nil when the form is invalid.
    func item(id: String) -> QuickAddItem? {
        guard !trimmedName.isEmpty, let cal = Int(calories), cal > 0 else { return nil }
        let shownIcon = icon.isEmpty ? Self.defaultIcon : icon
        return QuickAddItem(id: id, name: trimmedName, calories: cal, icon: shownIcon, protein: Int(protein))
    }
}

/// StateMachine: Quick-add sheet
///
/// Which quick-add sheet Settings shows — replaces a `showCreateQuickAdd`
/// flag plus an `editingQuickAdd` optional.
enum QuickAddSheet: Identifiable, Equatable {
    case create
    case edit(QuickAddItem)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let item): return "edit-\(item.id)"
        }
    }

    var title: String { self == .create ? "New Quick Add" : "Edit Quick Add" }
    var confirmLabel: String { self == .create ? "Create" : "Save" }

    var draft: QuickAddDraft {
        switch self {
        case .create: return QuickAddDraft()
        case .edit(let item): return QuickAddDraft(item: item)
        }
    }
}
