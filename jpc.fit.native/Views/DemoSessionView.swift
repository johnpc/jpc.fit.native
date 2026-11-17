import SwiftUI

/// Demo-mode root: derives the screen from `DemoSession.state`.
struct DemoSessionView: View {
    @ObservedObject var session: DemoSession

    var body: some View {
        switch session.state {
        case .signedOut(let message):
            DemoSignInView(session: session, message: message)
        case .signedIn:
            MainTabView()
        }
    }
}

/// The demo sign-in form. Field and button labels match Amplify's
/// Authenticator ("Email", "Password", "Sign In") so the same acceptance
/// steps drive both backends.
struct DemoSignInView: View {
    @ObservedObject var session: DemoSession
    let message: String?
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            AuthHeader()
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
            // Not a real credential, so not a SecureField: any secure entry
            // makes iOS raise its "Save Password?" sheet after sign-in (even
            // with `.oneTimeCode`), which is wrong for a demo and sat over
            // the whole app in the acceptance suite.
            TextField("Password", text: $password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            if let message {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
            Button("Sign In") { session.signIn(email: email, password: password) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Text("Demo mode — sample data, no account or network needed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
