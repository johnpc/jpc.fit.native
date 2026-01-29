import SwiftUI

@main
struct jpc_fit_watchApp: App {
    @StateObject private var dataManager = WatchDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
