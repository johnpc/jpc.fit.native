import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import BackgroundTasks
import WatchConnectivity
import HealthKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        HKHealthStore().handleAuthorizationForExtension { success, error in
            if let error {
                print("Watch HealthKit auth error: \(error)")
            }
        }
    }
}

@main
struct jpc_fit_nativeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private let connectivityManager = PhoneConnectivityManager.shared
    
    init() {
        configureAmplify()
        registerBackgroundTasks()
    }
    
    func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(with: .amplifyOutputs)
            print("Amplify configured successfully")
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.johncorser.fit.healthkitsync", using: nil) { task in
            Task {
                await BackgroundSyncService.shared.syncHealthKit()
                task.setTaskCompleted(success: true)
                BackgroundSyncService.shared.scheduleNextSync()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await BackgroundSyncService.shared.syncHealthKit() }
                    } else if phase == .background {
                        BackgroundSyncService.shared.scheduleNextSync()
                    }
                }
        }
    }
}
