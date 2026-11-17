import SwiftUI

/// Streak header + the last-4-days flame strip. Reads `recentDays`, which
/// stays pinned to the ACTUAL most recent days — navigating to an old week
/// must not relabel the streak strip with that week's days.
struct StatsStreakSection: View {
    @ObservedObject var vm: StatsViewModel

    var body: some View {
        Section {
            VStack(spacing: 8) {
                streakHeader
                HStack(spacing: 16) {
                    ForEach(vm.recentDays.suffix(4), id: \.day) { day in
                        VStack {
                            Text(flame(for: day.status)).font(.title)
                            Text(day.shortDay).font(.caption)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.shortDay): \(caption(for: day.status))")
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var streakHeader: some View {
        switch vm.streak {
        case .computing:
            HStack(spacing: 8) { ProgressView(); Text("Calculating streak...") }
        case .known:
            Text("Your streak is \(vm.streakDaysLabel ?? "0") days").font(.headline)
            Text(vm.streak.lbsText)
                .font(.subheadline)
                .foregroundStyle(vm.streak.net > 0 ? .red : .green)
        case .unavailable:
            Text("Couldn't load your streak").font(.headline)
            Text("Pull down to try again.").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func flame(for status: DayStats.Status) -> String {
        switch status {
        case .tracked: return "🔥"
        case .untracked: return "◻️"
        case .failed: return "⚠️"
        }
    }

    private func caption(for status: DayStats.Status) -> String {
        switch status {
        case .tracked: return "tracked"
        case .untracked: return "not tracked"
        case .failed: return "couldn't load"
        }
    }
}
