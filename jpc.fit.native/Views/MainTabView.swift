import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FoodListView()
                .tabItem {
                    Label("Calories", systemImage: "fork.knife")
                }

            WeightView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            AphorismsView()
                .tabItem {
                    Label("Quotes", systemImage: "quote.bubble")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
