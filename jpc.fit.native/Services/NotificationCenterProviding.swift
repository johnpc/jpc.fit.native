import Foundation
import UserNotifications

/// The slice of `UNUserNotificationCenter` the reminder machine needs, so the
/// OS authorization answer can be faked in unit tests.
protocol NotificationCenterProviding: Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func removeAllPendingRequests()
    func add(_ request: UNNotificationRequest) async throws
}

struct SystemNotificationCenter: NotificationCenterProviding {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func removeAllPendingRequests() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
}
