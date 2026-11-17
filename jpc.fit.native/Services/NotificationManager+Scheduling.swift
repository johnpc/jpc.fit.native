import Foundation
import UserNotifications

/// Reminder-time persistence and notification scheduling for `NotificationManager`.
extension NotificationManager {
    func loadTimes() {
        if let data = defaults.data(forKey: timesKey),
           let times = try? JSONDecoder().decode([[String: Int]].self, from: data) {
            reminderTimes = times.map { dict in
                var dc = DateComponents()
                dc.hour = dict["hour"]
                dc.minute = dict["minute"]
                return dc
            }
        } else {
            // Defaults: 1pm and 8pm
            var t1 = DateComponents(); t1.hour = 13; t1.minute = 0
            var t2 = DateComponents(); t2.hour = 20; t2.minute = 0
            reminderTimes = [t1, t2]
        }
    }

    func saveTimes() {
        let times = reminderTimes.map { ["hour": $0.hour ?? 0, "minute": $0.minute ?? 0] }
        if let data = try? JSONEncoder().encode(times) {
            defaults.set(data, forKey: timesKey)
        }
        Task { await scheduleNotifications() }
    }

    func addTime(_ date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        reminderTimes.append(comps)
        saveTimes()
    }

    func removeTime(at index: Int) {
        reminderTimes.remove(at: index)
        saveTimes()
    }

    /// Replaces every pending reminder with one per configured time. A no-op
    /// unless reminders are enabled — nothing is ever scheduled behind a
    /// disabled or denied state.
    func scheduleNotifications() async {
        center.removeAllPendingRequests()
        guard isEnabled else { return }

        for (i, time) in reminderTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Track your calories"
            content.body = "Don't forget to log your food today!"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            let request = UNNotificationRequest(identifier: "reminder-\(i)", content: content, trigger: trigger)
            do {
                try await center.add(request)
            } catch {
                Log.notifications.error("Failed to schedule notification: \(error)")
            }
        }
    }
}
