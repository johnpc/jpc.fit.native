import Foundation

/// StateMachine: Preferences record
///
/// Whether the user's Preferences row exists on the backend. A plain
/// `Preferences?` conflated "the fetch failed" with "no row yet", and toggling
/// a preference while the fetch had failed CREATED a duplicate row. The owner
/// is `SettingsViewModel.savePreferences`; `FoodViewModel` only reads.
enum PreferencesRecord: Equatable {
    /// Not fetched yet, or the last fetch failed — do not write.
    case unknown
    /// The backend answered: this user has no row (the first save creates it).
    case missing
    case stored(Preferences)

    var preferences: Preferences? {
        if case .stored(let p) = self { return p }
        return nil
    }

    var hideProtein: Bool { preferences?.hideProtein ?? false }
    var hideSteps: Bool { preferences?.hideSteps ?? false }

    static func == (lhs: PreferencesRecord, rhs: PreferencesRecord) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.missing, .missing):
            return true
        case (.stored(let a), .stored(let b)):
            return a.id == b.id && a.hideProtein == b.hideProtein && a.hideSteps == b.hideSteps
        default:
            return false
        }
    }
}
