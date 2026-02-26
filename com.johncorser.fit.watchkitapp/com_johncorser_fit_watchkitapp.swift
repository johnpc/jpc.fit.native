import WidgetKit
import SwiftUI

struct CaloriesEntry: TimelineEntry {
    let date: Date
    let remaining: Int
    let consumed: Int
    let burned: Int
}

struct CaloriesProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.johncorser.fit")
    
    func placeholder(in context: Context) -> CaloriesEntry {
        CaloriesEntry(date: Date(), remaining: 500, consumed: 1500, burned: 2000)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CaloriesEntry) -> Void) {
        completion(fetchEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CaloriesEntry>) -> Void) {
        let entry = fetchEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }
    
    private func fetchEntry() -> CaloriesEntry {
        let consumed = defaults?.integer(forKey: "watchConsumed") ?? 0
        let burned = defaults?.integer(forKey: "watchBurned") ?? 0
        let remaining = burned - consumed
        return CaloriesEntry(date: Date(), remaining: remaining, consumed: consumed, burned: burned)
    }
}

struct CaloriesWidgetView: View {
    var entry: CaloriesEntry
    @Environment(\.widgetFamily) var family
    
    private func format(_ n: Int) -> String {
        let abs = abs(n)
        if abs >= 1000 {
            return String(format: "%.1fk", Double(abs) / 1000)
        }
        return "\(abs)"
    }
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(format(entry.remaining))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(entry.remaining >= 0 ? .green : .red)
                Text("cal")
                    .font(.system(size: 10))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("\(format(entry.remaining)) cal")
                    .font(.headline)
                    .foregroundColor(entry.remaining >= 0 ? .green : .red)
                HStack {
                    Text("🔥\(format(entry.burned))")
                    Text("🍽️\(format(entry.consumed))")
                }
                .font(.caption2)
            }
        case .accessoryCorner:
            Text(format(entry.remaining))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(entry.remaining >= 0 ? .green : .red)
                .widgetCurvesContent()
                .widgetLabel {
                    Text("cal")
                }
        case .accessoryInline:
            Text("\(format(entry.remaining)) cal left")
        default:
            Text(format(entry.remaining))
        }
    }
}

struct CaloriesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CaloriesWidget", provider: CaloriesProvider()) { entry in
            CaloriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories")
        .description("Shows remaining calories")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}
