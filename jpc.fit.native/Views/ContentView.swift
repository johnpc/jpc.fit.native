import SwiftUI
import Authenticator

/// Root screen. Live mode hands the session to Amplify's `Authenticator`;
/// demo mode renders the in-process `DemoSession` (see `Core/DemoSession`).
struct ContentView: View {
    let mode: AppMode

    var body: some View {
        ZStack {
            Color.green.opacity(0.15).ignoresSafeArea()
            switch mode {
            case .live:
                Authenticator(headerContent: { AuthHeader() }) { _ in
                    MainTabView()
                }
            case .demo:
                DemoSessionView(session: AppServices.demoSession)
            }
        }
    }
}

/// App icon + title block above both sign-in forms.
struct AuthHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("AppIconImage")
                .resizable()
                .frame(width: 70, height: 70)
                .cornerRadius(14)
            VStack(alignment: .leading) {
                Text("fit.jpc.io").font(.title2).fontWeight(.bold)
                Text("Health and Calorie Tracker").font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}
