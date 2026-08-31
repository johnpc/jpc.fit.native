import SwiftUI

/// The per-day Food/Burn/Net table for the visible 7-day window.
struct StatsBreakdownSection: View {
    let weekData: [DayStats]

    var body: some View {
        Section {
            if weekData.allSatisfy({ !$0.tracked && !$0.failed }) && !weekData.isEmpty {
                Text("No food logged in these 7 days")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(weekData, id: \.day) { day in
                HStack {
                    Text(day.shortDay).frame(width: 50, alignment: .leading)
                    if day.failed {
                        Text("couldn't load").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        Text("\(day.consumed)").frame(width: 60, alignment: .trailing)
                        Text("\(day.burned)").frame(width: 60, alignment: .trailing)
                        Spacer()
                        Text("\(day.net)").foregroundStyle(day.net > 0 ? .red : .green).fontWeight(.medium)
                    }
                }
                .font(.callout)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowLabel(day))
            }
        } header: {
            HStack {
                Text("Day").frame(width: 50, alignment: .leading)
                Text("Food").frame(width: 60, alignment: .trailing)
                Text("Burn").frame(width: 60, alignment: .trailing)
                Spacer(); Text("Net")
            }.font(.caption)
        }
    }

    private func rowLabel(_ day: DayStats) -> String {
        if day.failed { return "\(day.shortDay): couldn't load" }
        let direction = day.net > 0 ? "surplus" : "deficit"
        return "\(day.shortDay): ate \(day.consumed), burned \(day.burned), net \(abs(day.net)) \(direction)"
    }
}
