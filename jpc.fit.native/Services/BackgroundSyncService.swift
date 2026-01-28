import Foundation
import BackgroundTasks
import HealthKit
import Amplify
import WidgetKit

class BackgroundSyncService {
    static let shared = BackgroundSyncService()
    private let store = HKHealthStore()
    private let api = APIService.shared
    
    func syncHealthKit() async {
        guard (try? await Amplify.Auth.getCurrentUser()) != nil else { return }
        
        let today = Date()
        let dayString = today.formatted(date: .numeric, time: .omitted)
        
        let stats = await fetchHealthKitStats(for: today)
        guard stats.active > 0 || stats.basal > 0 || stats.steps > 0 else { return }
        
        let existing = await api.fetchHealthKitCache(day: dayString)
        if let cache = existing {
            await api.updateHealthKitCache(id: cache.id, activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps)
        } else {
            _ = await api.createHealthKitCache(activeCalories: stats.active, baseCalories: stats.basal, steps: stats.steps, day: dayString)
        }
        
        // Update widget with latest burned calories
        let burned = Int(stats.active + stats.basal)
        SharedDataManager.shared.save(burned: burned)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func scheduleNextSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.johncorser.fit.healthkitsync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func fetchHealthKitStats(for date: Date) async -> (active: Double, basal: Double, steps: Double) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        async let active = querySum(type: .activeEnergyBurned, predicate: predicate)
        async let basal = querySum(type: .basalEnergyBurned, predicate: predicate)
        async let steps = querySum(type: .stepCount, predicate: predicate)
        
        return await (active, basal, steps)
    }
    
    private func querySum(type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let unit: HKUnit = type == .stepCount ? .count() : .kilocalorie()
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }
}
