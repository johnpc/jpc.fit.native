import Foundation
import UserNotifications

/// StateMachine: Reminders
///
/// Daily-reminder notifications. One `isEnabled` flag used to stand for four
/// different situations, so a user who had denied notifications in iOS
/// Settings saw an "Enable" button that silently did nothing. Owner:
/// `NotificationManager`.
enum ReminderState: Equatable {
    /// The OS has not been asked yet this launch.
    case unknown
    /// iOS has never shown the permission prompt — asking will show it.
    case notRequested
    /// The user tapped "Disable Notifications" in this app (persisted).
    case userDisabled
    /// Denied in iOS Settings; only the Settings app can change that.
    case osDenied
    case enabled

    var isEnabled: Bool { self == .enabled }

    /// Maps the OS answer onto our states; the in-app disable wins over any
    /// OS authorization because the user explicitly asked for silence.
    static func from(_ status: UNAuthorizationStatus, userDisabled: Bool) -> ReminderState {
        if userDisabled { return .userDisabled }
        switch status {
        case .notDetermined: return .notRequested
        case .denied: return .osDenied
        default: return .enabled
        }
    }
}
