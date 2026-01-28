import SwiftUI
import Authenticator

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.green.opacity(0.15).ignoresSafeArea()
            
            Authenticator(
                headerContent: {
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
            ) { state in
                MainTabView(user: state.user)
            }
        }
    }
}
