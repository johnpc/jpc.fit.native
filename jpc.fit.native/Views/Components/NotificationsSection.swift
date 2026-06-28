import SwiftUI

/// Daily-reminder notifications section of Settings: lists configured times,
/// allows adding/removing them, and toggling notifications on/off.
struct NotificationsSection: View {
    @ObservedObject var notifications: NotificationManager
    @Binding var newReminderTime: Date

    var body: some View {
        Section("Daily Notifications") {
            if notifications.isEnabled {
                ForEach(Array(notifications.reminderTimes.enumerated()), id: \.offset) { i, time in
                    HStack { Text(formatTime(time)); Spacer() }
                        .swipeActions { Button("Delete", role: .destructive) { notifications.removeTime(at: i) } }
                }
                HStack {
                    DatePicker("", selection: $newReminderTime, displayedComponents: .hourAndMinute).labelsHidden()
                    Spacer()
                    Button("Add") { notifications.addTime(newReminderTime) }.buttonStyle(.borderless)
                }
                Button("Re-schedule Notifications") { notifications.scheduleNotifications() }
                Button("Disable Notifications", role: .destructive) { notifications.disable() }
            } else {
                Button("Enable Reminder Notifications") { Task { await notifications.requestPermission() } }
            }
        }
    }

    private func formatTime(_ dc: DateComponents) -> String {
        var cal = Calendar.current; cal.timeZone = .current
        guard let date = cal.date(from: dc) else { return "" }
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
