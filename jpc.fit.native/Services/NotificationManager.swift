import Foundation
import UserNotifications

/// Owner of the `ReminderState` machine (see `Models/ReminderState.swift`).
/// The in-app "Disable Notifications" choice is persisted, because the OS
/// authorization alone can't express it: a user who disabled reminders still
/// has the OS permission granted, so without the stored flag the toggle
/// silently flipped back on at the next launch.
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var state: ReminderState = .unknown
    @Published var reminderTimes: [DateComponents] = []

    let defaults: UserDefaults
    let center: NotificationCenterProviding
    let timesKey = "notificationTimes"
    let disabledKey = "notificationsUserDisabled"
    /// The launch-time OS check; await it to observe the settled state.
    private(set) var initialRefresh: Task<Void, Never>?

    var isEnabled: Bool { state.isEnabled }

    init(defaults: UserDefaults = .standard, center: NotificationCenterProviding = SystemNotificationCenter()) {
        self.defaults = defaults
        self.center = center
        loadTimes()
        if defaults.bool(forKey: disabledKey) { state = .userDisabled }
        initialRefresh = Task { await refreshState() }
    }

    /// Re-derive the state from the stored choice + the OS answer.
    func refreshState() async {
        let status = await center.authorizationStatus()
        state = ReminderState.from(status, userDisabled: defaults.bool(forKey: disabledKey))
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization()
            defaults.set(false, forKey: disabledKey)
            state = granted ? .enabled : .osDenied
            if granted { await scheduleNotifications() }
            return granted
        } catch {
            Log.notifications.error("Notification permission error: \(error)")
            return false
        }
    }

    func disable() {
        center.removeAllPendingRequests()
        defaults.set(true, forKey: disabledKey)
        state = .userDisabled
    }
}
