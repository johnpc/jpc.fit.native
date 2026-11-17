import Foundation
import Amplify

/// Live account actions over Amplify Cognito.
struct AmplifyAuthService: AuthServiceProtocol {
    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    func deleteUser() async {
        try? await Amplify.Auth.deleteUser()
        _ = await Amplify.Auth.signOut()
    }
}
