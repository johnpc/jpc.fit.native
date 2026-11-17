import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var quickAdds: [QuickAddItem] = []
    @Published private(set) var preferences: PreferencesRecord = .unknown
    @Published var errorMessage: String?

    let api: APIServiceProtocol
    let auth: AuthServiceProtocol

    init(api: APIServiceProtocol = AppServices.api, auth: AuthServiceProtocol = AppServices.auth) {
        self.api = api
        self.auth = auth
    }

    var hideProtein: Bool { preferences.hideProtein }
    var hideSteps: Bool { preferences.hideSteps }

    func fetchAll() async {
        async let q = api.fetchQuickAdds()
        async let p = api.fetchPreferences()
        quickAdds = await q
        preferences = await p
    }

    func updatePreference(hideProtein: Bool? = nil, hideSteps: Bool? = nil) {
        let hp = hideProtein ?? self.hideProtein
        let hs = hideSteps ?? self.hideSteps
        Task { await savePreferences(hideProtein: hp, hideSteps: hs) }
    }

    /// The ONE writer of `preferences`. A failed earlier fetch is retried
    /// here first, so a toggle never creates a duplicate row on the backend.
    func savePreferences(hideProtein: Bool, hideSteps: Bool) async {
        if preferences == .unknown { preferences = await api.fetchPreferences() }
        switch preferences {
        case .stored(let existing):
            await update(existing, hideProtein: hideProtein, hideSteps: hideSteps)
        case .missing:
            await create(hideProtein: hideProtein, hideSteps: hideSteps)
        case .unknown:
            errorMessage = "Couldn't load your preferences — pull to refresh and try again."
        }
    }

    private func update(_ existing: Preferences, hideProtein: Bool, hideSteps: Bool) async {
        preferences = .stored(Preferences(id: existing.id, hideProtein: hideProtein, hideSteps: hideSteps))
        if await !api.updatePreferences(id: existing.id, hideProtein: hideProtein, hideSteps: hideSteps) {
            preferences = .stored(existing)
            errorMessage = Self.saveFailed
        }
    }

    private func create(hideProtein: Bool, hideSteps: Bool) async {
        if let id = await api.createPreferences(hideProtein: hideProtein, hideSteps: hideSteps) {
            preferences = .stored(Preferences(id: id, hideProtein: hideProtein, hideSteps: hideSteps))
        } else {
            errorMessage = Self.saveFailed
        }
    }

    private static let saveFailed = "Couldn't save your preferences — check your connection and try again."

    func deleteAccount() {
        Task { await auth.deleteUser() }
    }

    func signOut() {
        Task { await auth.signOut() }
    }
}
