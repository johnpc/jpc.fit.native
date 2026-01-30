import WidgetKit
import SwiftUI
import HealthKit

struct CaloriesEntry: TimelineEntry {
    let date: Date
    let remaining: Int
    let consumed: Int
    let burned: Int
}

struct CaloriesProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.johncorser.fit")
    private let healthStore = HKHealthStore()
    
    func placeholder(in context: Context) -> CaloriesEntry {
        CaloriesEntry(date: Date(), remaining: 500, consumed: 1500, burned: 2000)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CaloriesEntry) -> Void) {
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CaloriesEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
        }
    }
    
    private func fetchEntry() async -> CaloriesEntry {
        let consumed = defaults?.integer(forKey: "watchConsumed") ?? 0
        
        // Fetch burned from HealthKit directly
        let burned = await fetchBurnedCalories()
        let remaining = burned - consumed
        
        return CaloriesEntry(date: Date(), remaining: remaining, consumed: consumed, burned: burned)
    }
    
    private func fetchBurnedCalories() async -> Int {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        async let active = querySum(.activeEnergyBurned, predicate: predicate)
        async let basal = querySum(.basalEnergyBurned, predicate: predicate)
        
        let (a, b) = await (active, basal)
        return Int(a + b)
    }
    
    private func querySum(_ type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}

struct CaloriesWidgetView: View {
    var entry: CaloriesEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text("\(entry.remaining)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(entry.remaining >= 0 ? .green : .red)
                Text("cal")
                    .font(.system(size: 10))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.remaining) cal")
                    .font(.headline)
                    .foregroundColor(entry.remaining >= 0 ? .green : .red)
                HStack {
                    Label("\(entry.burned)", systemImage: "flame.fill")
                    Label("\(entry.consumed)", systemImage: "fork.knife")
                }
                .font(.caption2)
            }
        case .accessoryCorner:
            Text("\(entry.remaining)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(entry.remaining >= 0 ? .green : .red)
                .widgetLabel {
                    Text("cal")
                }
        case .accessoryInline:
            Text("\(entry.remaining) cal remaining")
        default:
            Text("\(entry.remaining)")
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
