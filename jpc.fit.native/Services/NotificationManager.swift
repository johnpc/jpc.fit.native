import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isEnabled = false
    @Published var reminderTimes: [DateComponents] = []

    let defaults: UserDefaults
    let timesKey = "notificationTimes"
    let disabledKey = "notificationsUserDisabled"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadTimes()
        checkPermission()
    }

    /// OS authorization alone isn't enough: a user who tapped "Disable
    /// Notifications" still has the OS permission granted, so without the
    /// stored flag the toggle silently flipped back on at next launch.
    func checkPermission() {
        guard !defaults.bool(forKey: disabledKey) else {
            isEnabled = false
            return
        }
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
                defaults.set(false, forKey: disabledKey)
                isEnabled = granted
                if granted { scheduleNotifications() }
            }
            return granted
        } catch {
            Log.notifications.error("Notification permission error: \(error)")
            return false
        }
    }

    func disable() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        defaults.set(true, forKey: disabledKey)
        isEnabled = false
    }
}
