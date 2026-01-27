import SwiftUI
import Authenticator

struct ContentView: View {
    var body: some View {
        Authenticator { state in
            MainTabView(user: state.user)
        }
    }
}
