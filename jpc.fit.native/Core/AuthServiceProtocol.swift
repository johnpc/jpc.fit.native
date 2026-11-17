import Foundation

/// Account actions the Settings screen can trigger. Live = Amplify Cognito;
/// demo = the in-process `DemoSession`.
protocol AuthServiceProtocol: Sendable {
    func signOut() async
    func deleteUser() async
}
