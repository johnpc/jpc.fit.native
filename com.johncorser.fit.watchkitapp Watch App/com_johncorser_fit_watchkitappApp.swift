import SwiftUI
import WidgetKit

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

// The complication widget lives in the watch widget extension
// (com.johncorser.fit.watchkitapp/com_johncorser_fit_watchkitapp.swift) —
// a duplicate copy here in the app target was never registered (no
// WidgetBundle) and has been removed.
