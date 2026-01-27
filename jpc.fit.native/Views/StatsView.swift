import SwiftUI
import Amplify
import HealthKit

struct StatsView: View {
    @State private var weekStartDate = Date()
    @State private var weekData: [DayStats] = []
    @State private var isLoading = true
    @State private var streakDays: Int?
    @State private var streakNet = 0
    
    private var weekNet: Int { weekData.filter { $0.tracked }.reduce(0) { $0 + $1.net } }
    private var trackedCount: Int { weekData.filter { $0.tracked }.count }
    private var streakLbs: Double { Double(streakNet) / 3500.0 }
    
    var body: some View {
        List {
            HeaderSection()
            
            // Streak section
            Section {
                VStack(spacing: 8) {
                    if let days = streakDays {
                        Text("Your streak is \(days) days")
                            .font(.headline)
                        Text("Est. \(streakLbs, specifier: "%.1f") lbs \(streakLbs > 0 ? "gained" : "lost")")
                            .font(.subheadline)
                            .foregroundStyle(streakLbs > 0 ? .red : .green)
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Calculating streak...")
                        }
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(weekData.suffix(4), id: \.day) { day in
                            VStack {
                                Text(day.tracked ? "🔥" : "❌").font(.title)
                                Text(day.shortDay).font(.caption)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Week summary
            Section("This Week") {
                HStack {
                    Spacer()
                    Text("Net \(weekNet) cal")
                        .foregroundStyle(weekNet > 0 ? .red : .green)
                        .fontWeight(.semibold)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text("1 lb of fat ≈ 3500 calories").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            // Week navigation
            Section {
                HStack {
                    Button { changeWeek(-7) } label: { Image(systemName: "chevron.left") }
                        .buttonStyle(.borderless)
                    Spacer()
                    Text(weekRangeString).fontWeight(.bold)
                    Spacer()
                    Button { changeWeek(7) } label: { Image(systemName: "chevron.right") }
                        .buttonStyle(.borderless)
                }
                
                if !Calendar.current.isDateInToday(weekStartDate) {
                    Button("Today") { weekStartDate = Date(); Task { await fetchWeek() } }
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Daily breakdown
            Section {
                ForEach(weekData, id: \.day) { day in
                    HStack {
                        Text(day.shortDay).frame(width: 50, alignment: .leading)
                        Text("\(day.consumed)").frame(width: 60, alignment: .trailing)
                        Text("\(day.burned)").frame(width: 60, alignment: .trailing)
                        Spacer()
                        Text("\(day.net)")
                            .foregroundStyle(day.net > 0 ? .red : .green)
                            .fontWeight(.medium)
                    }
                    .font(.callout)
                }
            } header: {
                HStack {
                    Text("Day").frame(width: 50, alignment: .leading)
                    Text("Food").frame(width: 60, alignment: .trailing)
                    Text("Burn").frame(width: 60, alignment: .trailing)
                    Spacer()
                    Text("Net")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Stats")
        .task { await fetchWeek(); await fetchStreak() }
        .refreshable { await fetchWeek(); await fetchStreak() }
        .overlay { if isLoading { ProgressView() } }
    }
    
    private var weekRangeString: String {
        let end = weekStartDate
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end)!
        return "\(start.formatted(date: .numeric, time: .omitted)) - \(end.formatted(date: .numeric, time: .omitted))"
    }
    
    private func changeWeek(_ days: Int) {
        weekStartDate = Calendar.current.date(byAdding: .day, value: days, to: weekStartDate)!
        Task { await fetchWeek() }
    }
    
    private func fetchWeek() async {
        isLoading = true
        var results: [DayStats] = []
        
        for i in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: weekStartDate)!
            let dayString = date.formatted(date: .numeric, time: .omitted)
            
            async let foods = fetchFoods(day: dayString)
            async let cacheAndSync = fetchAndSyncCache(day: dayString, date: date)
            
            let (f, burned) = await (foods, cacheAndSync)
            let consumed = f.reduce(0) { $0 + $1 }
            let parts = dayString.split(separator: "/")
            let shortDay = parts.count >= 2 ? "\(parts[0])/\(parts[1])" : dayString
            
            results.append(DayStats(day: dayString, shortDay: String(shortDay), consumed: consumed, burned: burned, tracked: !f.isEmpty))
        }
        
        weekData = results
        isLoading = false
    }
    
    private func fetchAndSyncCache(day: String, date: Date) async -> Int {
        // First check if cache exists
        var cached = await fetchCache(day: day)
        
        // If no cache, fetch from HealthKit and create cache
        if cached == 0 {
            let stats = await fetchHealthKit(date: date)
            if stats.active > 0 || stats.basal > 0 {
                await createCache(day: day, active: stats.active, basal: stats.basal, steps: stats.steps)
                cached = Int(stats.active + stats.basal)
            }
        }
        
        return cached
    }
    
    private func fetchHealthKit(date: Date) async -> (active: Double, basal: Double, steps: Double) {
        let store = HKHealthStore()
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        async let active = querySum(store: store, type: .activeEnergyBurned, predicate: predicate)
        async let basal = querySum(store: store, type: .basalEnergyBurned, predicate: predicate)
        async let steps = querySum(store: store, type: .stepCount, predicate: predicate)
        
        return await (active, basal, steps)
    }
    
    private func querySum(store: HKHealthStore, type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let unit: HKUnit = type == .stepCount ? .count() : .kilocalorie()
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }
    
    private func createCache(day: String, active: Double, basal: Double, steps: Double) async {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:CreateHealthKitCacheInput!){createHealthKitCache(input:$input){id}}",
            variables: ["input": ["activeCalories": active, "baseCalories": basal, "steps": steps, "day": day]],
            responseType: JSONValue.self)
        _ = try? await Amplify.API.mutate(request: req)
    }
    
    private func fetchFoods(day: String) async -> [Int] {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listFoodByDay(day:$day){items{calories}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data["listFoodByDay"]?["items"]?.asArray else { return [] }
        return items.compactMap { $0["calories"]?.intValue }
    }
    
    private func fetchCache(day: String) async -> Int {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listHealthKitCacheByDay(day:$day){items{activeCalories baseCalories}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data["listHealthKitCacheByDay"]?["items"]?.asArray,
              let first = items.first else { return 0 }
        let active = first["activeCalories"]?.doubleValue ?? 0
        let basal = first["baseCalories"]?.doubleValue ?? 0
        return Int(active + basal)
    }
    
    private func fetchStreak() async {
        var days = 0
        var net = 0
        var offset = 0
        let batchSize = 14
        
        while true {
            // Fetch batch of days in parallel
            let dates = (0..<batchSize).map { Calendar.current.date(byAdding: .day, value: -(offset + $0), to: Date())! }
            let results = await withTaskGroup(of: (Int, [Int], Int).self) { group in
                for (i, date) in dates.enumerated() {
                    group.addTask {
                        let dayString = date.formatted(date: .numeric, time: .omitted)
                        async let foods = self.fetchFoods(day: dayString)
                        async let burned = self.fetchCache(day: dayString)
                        return (i, await foods, await burned)
                    }
                }
                var arr = [(Int, [Int], Int)]()
                for await r in group { arr.append(r) }
                return arr.sorted { $0.0 < $1.0 }
            }
            
            for (_, foods, burned) in results {
                if foods.isEmpty {
                    streakDays = days
                    streakNet = net
                    return
                }
                days += 1
                net += foods.reduce(0, +) - burned
            }
            offset += batchSize
        }
    }
}

struct DayStats {
    let day: String
    let shortDay: String
    let consumed: Int
    let burned: Int
    var net: Int { consumed - burned }
    let tracked: Bool
}
