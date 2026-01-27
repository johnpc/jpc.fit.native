import SwiftUI
import Amplify

struct MainTabView: View {
    let user: AuthUser
    
    var body: some View {
        TabView {
            FoodListView(user: user)
                .tabItem {
                    Label("Calories", systemImage: "fork.knife")
                }
            
            WeightView(user: user)
                .tabItem {
                    Label("Weight", systemImage: "scalemass")
                }
            
            AphorismsView()
                .tabItem {
                    Label("Quotes", systemImage: "quote.bubble")
                }
            
            SettingsView(user: user)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
