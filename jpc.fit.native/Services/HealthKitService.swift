import Foundation
import HealthKit

actor HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() async {
        let types: Set<HKQuantityType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.stepCount)
        ]
        try? await healthStore.requestAuthorization(toShare: [], read: types)
    }
    
    func fetchStats(for date: Date) async -> (active: Double, basal: Double, steps: Double) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        async let active = querySum(.activeEnergyBurned, predicate: predicate)
        async let basal = querySum(.basalEnergyBurned, predicate: predicate)
        async let steps = querySum(.stepCount, predicate: predicate)
        
        return await (active, basal, steps)
    }
    
    private func querySum(_ type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let unit: HKUnit = type == .stepCount ? .count() : .kilocalorie()
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }
}
