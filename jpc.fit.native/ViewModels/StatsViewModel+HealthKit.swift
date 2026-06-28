import Foundation
import Amplify
import HealthKit

/// HealthKit querying and cache-write helpers for `StatsViewModel`. Kept apart
/// from the week/streak aggregation so each file stays small.
extension StatsViewModel {
    nonisolated func fetchFoodCalories(day: String) async -> [Int] {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listFoodByDay(day:$day){items{calories}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data["listFoodByDay"]?["items"]?.asArray else { return [] }
        return items.compactMap { $0["calories"]?.intValue }
    }

    nonisolated func fetchCacheBurned(day: String) async -> Int {
        let req = GraphQLRequest<JSONValue>(
            document: "query($day:String!){listHealthKitCacheByDay(day:$day){items{activeCalories baseCalories}}}",
            variables: ["day": day], responseType: JSONValue.self)
        guard case .success(let data) = try? await Amplify.API.query(request: req),
              let items = data["listHealthKitCacheByDay"]?["items"]?.asArray,
              let first = items.first else { return 0 }
        return Int((first["activeCalories"]?.doubleValue ?? 0) + (first["baseCalories"]?.doubleValue ?? 0))
    }

    nonisolated func fetchHealthKit(date: Date) async -> (active: Double, basal: Double, steps: Double) {
        let store = HKHealthStore()
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        async let active = querySum(store: store, type: .activeEnergyBurned, predicate: predicate)
        async let basal = querySum(store: store, type: .basalEnergyBurned, predicate: predicate)
        async let steps = querySum(store: store, type: .stepCount, predicate: predicate)
        return await (active, basal, steps)
    }

    nonisolated func querySum(store: HKHealthStore, type: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(type), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let unit: HKUnit = type == .stepCount ? .count() : .kilocalorie()
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    nonisolated func createCache(day: String, active: Double, basal: Double, steps: Double) async {
        let req = GraphQLRequest<JSONValue>(
            document: "mutation($input:CreateHealthKitCacheInput!){createHealthKitCache(input:$input){id}}",
            variables: ["input": ["activeCalories": active, "baseCalories": basal, "steps": steps, "day": day]],
            responseType: JSONValue.self)
        _ = try? await Amplify.API.mutate(request: req)
    }
}
