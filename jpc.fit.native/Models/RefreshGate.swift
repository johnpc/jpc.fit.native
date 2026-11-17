import Foundation

/// StateMachine: Off-screen refresh
///
/// Whether a background `.foodDataChanged` should refresh the Stats screen now
/// or wait until it is next shown. Three view-level flags (`isVisible`,
/// `isStale`, a refresh UUID) used to encode this; now one value, owned by
/// `StatsViewModel`, with every transition unit-tested.
enum RefreshGate: Equatable {
    case onScreen
    case offScreen(stale: Bool)

    enum Decision: Equatable {
        case refreshNow
        case deferred
        case none
    }

    mutating func appeared() -> Decision {
        let wasStale = self == .offScreen(stale: true)
        self = .onScreen
        return wasStale ? .refreshNow : .none
    }

    mutating func disappeared() {
        self = .offScreen(stale: false)
    }

    /// Data changed somewhere (this tab's own writes, the watch, ...).
    mutating func dataChanged() -> Decision {
        switch self {
        case .onScreen:
            return .refreshNow
        case .offScreen:
            self = .offScreen(stale: true)
            return .deferred
        }
    }
}
