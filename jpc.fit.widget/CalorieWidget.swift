import WidgetKit
import SwiftUI

struct SharedData: Codable {
    var burned: Int
    var consumed: Int
    var day: String
}

struct CalorieEntry: TimelineEntry {
    let date: Date
    let burned: Int
    let consumed: Int
    var remaining: Int { burned - consumed }
}

struct Provider: TimelineProvider {
    private let suiteName = "group.com.johncorser.fit"
    
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), burned: 2000, consumed: 1500)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        let entry = loadFromShared() ?? CalorieEntry(date: Date(), burned: 2000, consumed: 1500)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = loadFromShared() ?? CalorieEntry(date: Date(), burned: 0, consumed: 0)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
    
    private func loadFromShared() -> CalorieEntry? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "widgetData"),
              let shared = try? JSONDecoder().decode(SharedData.self, from: data) else { return nil }
        
        let today = Date().formatted(date: .numeric, time: .omitted)
        guard shared.day == today else { return nil }
        
        return CalorieEntry(date: Date(), burned: shared.burned, consumed: shared.consumed)
    }
}

struct CalorieWidgetEntryView: View {
    var entry: CalorieEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🥕 fit.jpc.io")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack {
                Text("Burned:")
                Spacer()
                Text("\(entry.burned)")
            }
            .font(.caption)
            
            HStack {
                Text("Food:")
                Spacer()
                Text("\(entry.consumed)")
            }
            .font(.caption)
            
            Divider()
            
            HStack {
                Text("Left:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.remaining)")
                    .fontWeight(.bold)
                    .foregroundStyle(entry.remaining >= 0 ? .green : .red)
            }
            .font(.callout)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CalorieWidget: Widget {
    let kind: String = "CalorieWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalorieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calorie Tracker")
        .description("Shows burned vs consumed calories")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieWidget()
    }
}
