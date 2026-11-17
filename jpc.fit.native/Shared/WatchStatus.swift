import Foundation

/// StateMachine: Watch health source
///
/// Where the watch's burned-calorie number came from. Was an `authStatus:
/// String` holding "HK: 300+1500=1800", "Err: …", "Phone" or "" — four
/// states as prose. Owner: `WatchDataManager`.
enum WatchHealthStatus: Equatable {
    case unknown
    case unavailable
    case failed(String)
    case measured(active: Int, basal: Int)
    case fromPhone

    /// The caption under the big number; nil shows nothing.
    var label: String? {
        switch self {
        case .unknown: return nil
        case .unavailable: return "HK unavailable"
        case .failed(let reason): return "Err: \(reason.prefix(25))"
        case .measured(let active, let basal): return "HK: \(active)+\(basal)=\(active + basal)"
        case .fromPhone: return "Phone"
        }
    }
}

/// StateMachine: Phone link
///
/// Whether the paired phone is reachable for live messages. Was a
/// `connectionStatus: String` of "...", "📱 Reachable", "📱 Not reachable".
enum PhoneLink: Equatable {
    case unknown
    case reachable
    case unreachable

    var label: String {
        switch self {
        case .unknown: return "..."
        case .reachable: return "📱 Reachable"
        case .unreachable: return "📱 Not reachable"
        }
    }

    static func from(isReachable: Bool) -> PhoneLink {
        isReachable ? .reachable : .unreachable
    }
}
