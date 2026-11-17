import Foundation

/// StateMachine: Streak
///
/// The Stats header's streak. `streakDays: Int?` + `streakNet` used to encode
/// this: nil meant "still computing" forever, so a failed first walk showed a
/// spinner for the rest of the session. Owner: `StatsViewModel.fetchStreak`.
enum StreakState: Equatable {
    case computing
    case known(days: Int, net: Int)
    /// Every attempt so far failed and there is no previous value to keep.
    case unavailable

    /// A failed walk keeps the last known value on screen rather than
    /// reporting a false zero; only a never-computed streak becomes unavailable.
    func afterFailure() -> StreakState {
        self == .computing ? .unavailable : self
    }

    var net: Int {
        if case .known(_, let net) = self { return net }
        return 0
    }

    /// "12" or "365+" once the walk hits the cap; nil unless known.
    func daysLabel(cap: Int) -> String? {
        guard case .known(let days, _) = self else { return nil }
        return days >= cap ? "\(days)+" : "\(days)"
    }

    var lbs: Double { Double(net) / 3500.0 }

    /// Magnitude-only estimate — the direction comes from the word, so a
    /// deficit reads "Est. 2.0 lbs lost", never "-2.0 lbs lost".
    var lbsText: String {
        if net == 0 { return "Breaking even so far" }
        return String(format: "Est. %.1f lbs %@", abs(lbs), net > 0 ? "gained" : "lost")
    }
}
