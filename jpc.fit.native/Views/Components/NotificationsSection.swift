import SwiftUI

/// Daily-reminder notifications section of Settings, rendered from the
/// `ReminderState` machine: times + add/remove/disable while enabled, an
/// enable button while not yet asked, and the honest "turned off in iOS
/// Settings" message (with a shortcut) when the OS has denied us.
struct NotificationsSection: View {
    @ObservedObject var notifications: NotificationManager
    @Binding var newReminderTime: Date
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section("Daily Notifications") {
            switch notifications.state {
            case .enabled:
                enabledRows
            case .osDenied:
                Text("Notifications are turned off for jpc.fit in iOS Settings.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            case .unknown, .notRequested, .userDisabled:
                Button("Enable Reminder Notifications") { Task { await notifications.requestPermission() } }
            }
        }
    }

    @ViewBuilder
    private var enabledRows: some View {
        ForEach(Array(notifications.reminderTimes.enumerated()), id: \.offset) { i, time in
            HStack { Text(formatTime(time)); Spacer() }
                .swipeActions { Button("Delete", role: .destructive) { notifications.removeTime(at: i) } }
        }
        HStack {
            DatePicker("", selection: $newReminderTime, displayedComponents: .hourAndMinute).labelsHidden()
            Spacer()
            Button("Add") { notifications.addTime(newReminderTime) }.buttonStyle(.borderless)
        }
        Button("Re-schedule Notifications") { Task { await notifications.scheduleNotifications() } }
        Button("Disable Notifications", role: .destructive) { notifications.disable() }
    }

    private func formatTime(_ dc: DateComponents) -> String {
        var cal = Calendar.current; cal.timeZone = .current
        guard let date = cal.date(from: dc) else { return "" }
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
