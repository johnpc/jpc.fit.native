import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isEnabled = false
    @Published var reminderTimes: [DateComponents] = []
    
    let defaults = UserDefaults.standard
    let timesKey = "notificationTimes"
    
    init() {
        loadTimes()
        checkPermission()
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { 
                isEnabled = granted
                if granted { scheduleNotifications() }
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func disable() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isEnabled = false
    }
}
