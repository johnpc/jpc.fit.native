import SwiftUI

/// Streak header + the last-4-days flame strip. Reads `recentDays`, which
/// stays pinned to the ACTUAL most recent days — navigating to an old week
/// must not relabel the streak strip with that week's days.
struct StatsStreakSection: View {
    @ObservedObject var vm: StatsViewModel

    var body: some View {
        Section {
            VStack(spacing: 8) {
                if let label = vm.streakDaysLabel {
                    Text("Your streak is \(label) days").font(.headline)
                    Text(vm.streakLbsText)
                        .font(.subheadline)
                        .foregroundStyle(vm.streakNet > 0 ? .red : .green)
                } else {
                    HStack(spacing: 8) { ProgressView(); Text("Calculating streak...") }
                }
                HStack(spacing: 16) {
                    ForEach(vm.recentDays.suffix(4), id: \.day) { day in
                        VStack {
                            Text(day.tracked ? "🔥" : (day.failed ? "⚠️" : "◻️")).font(.title)
                            Text(day.shortDay).font(.caption)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.shortDay): \(day.failed ? "couldn't load" : day.tracked ? "tracked" : "not tracked")")
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }
}
