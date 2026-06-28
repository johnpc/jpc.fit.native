import Foundation
import Amplify

/// JSON → model parsing for `APIService`. Kept separate from the network calls
/// so each file stays small and the pure decoding is easy to scan.
extension APIService {
    func parseFood(_ item: JSONValue) -> Food? {
        guard case .string(let id) = item.value(at: "id"),
              case .number(let cal) = item.value(at: "calories"),
              case .string(let day) = item.value(at: "day") else { return nil }
        let name: String? = if case .string(let n) = item.value(at: "name") { n } else { nil }
        let protein: Int? = if case .number(let p) = item.value(at: "protein") { Int(p) } else { nil }
        var createdAt: Temporal.DateTime? = nil
        if case .string(let c) = item.value(at: "createdAt") { createdAt = try? Temporal.DateTime(iso8601String: c) }
        return Food(id: id, name: name, calories: Int(cal), protein: protein, day: day, notes: nil, photos: nil, createdAt: createdAt, updatedAt: nil)
    }

    func parseCache(_ item: JSONValue) -> HealthKitCache? {
        guard case .string(let id) = item.value(at: "id"),
              case .number(let active) = item.value(at: "activeCalories"),
              case .number(let base) = item.value(at: "baseCalories"),
              case .string(let day) = item.value(at: "day") else { return nil }
        let steps: Double = if case .number(let s) = item.value(at: "steps") { s } else { 0 }
        return HealthKitCache(id: id, activeCalories: active, baseCalories: base, steps: steps, day: day)
    }

    func parseQuickAdd(_ item: JSONValue) -> QuickAddItem? {
        guard case .string(let id) = item.value(at: "id"),
              case .string(let name) = item.value(at: "name"),
              case .number(let cal) = item.value(at: "calories") else { return nil }
        var icon = "🍽️"
        if case .string(let i) = item.value(at: "icon") {
            icon = i.unicodeScalars.first?.properties.isEmoji == true ? i : "🍽️"
        }
        let protein: Int? = if case .number(let p) = item.value(at: "protein") { Int(p) } else { nil }
        return QuickAddItem(id: id, name: name, calories: Int(cal), icon: icon, protein: protein)
    }
}
