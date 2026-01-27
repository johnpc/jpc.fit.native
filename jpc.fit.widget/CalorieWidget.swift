import WidgetKit
import SwiftUI
import HealthKit

struct CalorieEntry: TimelineEntry {
    let date: Date
    let burned: Int
    let consumed: Int
    var remaining: Int { burned - consumed }
}

struct Provider: TimelineProvider {
    private let suiteName = "group.com.johncorser.fit"
    private let store = HKHealthStore()
    
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), burned: 2000, consumed: 1500)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
        }
    }
    
    private func fetchEntry() async -> CalorieEntry {
        async let burned = fetchHealthKitCalories()
        let consumed = loadConsumedFromShared()
        return CalorieEntry(date: Date(), burned: await burned, consumed: consumed)
    }
    
    private func loadConsumedFromShared() -> Int {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let consumed = defaults.value(forKey: "todayConsumed") as? Int else { return 0 }
        return consumed
    }
    
    private func fetchHealthKitCalories() async -> Int {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        
        async let active = querySum(type: .activeEnergyBurned, predicate: predicate)
        async let basal = querySum(type: .basalEnergyBurned, predicate: predicate)
        
        return await Int(active + basal)
    }
    
    private func querySum(type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                cont.resume(returning: result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
            }
            store.execute(query)
        }
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
