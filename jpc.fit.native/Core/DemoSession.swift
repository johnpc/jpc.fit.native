import Foundation

/// StateMachine: Demo session
///
/// The sign-in state of the fake backend. In live mode Amplify's
/// `Authenticator` owns this; in demo mode this class is the single owner, and
/// `ContentView` derives which screen to show from `state`.
@MainActor
final class DemoSession: ObservableObject {
    enum State: Equatable {
        /// `message` is the last rejected attempt's explanation, if any.
        case signedOut(message: String?)
        case signedIn(email: String)
    }

    @Published private(set) var state: State = .signedOut(message: nil)

    /// Constructed by `AppServices` from a nonisolated context; the state
    /// default needs no actor.
    nonisolated init() {}

    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    /// Any non-blank email + password signs in — the demo has no accounts.
    func signIn(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            state = .signedOut(message: "Enter an email and a password to try the demo.")
            return
        }
        state = .signedIn(email: trimmedEmail)
    }

    func signOutNow() {
        state = .signedOut(message: nil)
    }
}

extension DemoSession: AuthServiceProtocol {
    func signOut() async { signOutNow() }
    func deleteUser() async { signOutNow() }
}
