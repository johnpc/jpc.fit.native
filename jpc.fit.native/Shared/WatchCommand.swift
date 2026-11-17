import Foundation

/// Watch → phone requests. The ONE place the WCSession dictionary keys live;
/// both targets compile this file, so neither side can drift. The dictionary
/// shape is `["action": …]` plus the payload — unchanged on the wire, so a
/// watch and a phone on different builds still understand each other.
enum WatchCommand: Equatable {
    case requestData
    case addFood(name: String, calories: Int, protein: Int?)
    case deleteFood(id: String)
    case syncHealthKit

    init?(message: [String: Any]) {
        switch message["action"] as? String {
        case "requestData":
            self = .requestData
        case "syncHealthKit":
            self = .syncHealthKit
        case "addFood":
            guard let name = message["name"] as? String, let calories = message["calories"] as? Int else { return nil }
            // The watch sends 0 for "no protein" — the phone must not store 0g.
            let protein = message["protein"] as? Int
            self = .addFood(name: name, calories: calories, protein: protein == 0 ? nil : protein)
        case "deleteFood":
            guard let id = message["id"] as? String else { return nil }
            self = .deleteFood(id: id)
        default:
            return nil
        }
    }

    var message: [String: Any] {
        switch self {
        case .requestData:
            return ["action": "requestData"]
        case .syncHealthKit:
            return ["action": "syncHealthKit"]
        case .addFood(let name, let calories, let protein):
            return ["action": "addFood", "name": name, "calories": calories, "protein": protein ?? 0]
        case .deleteFood(let id):
            return ["action": "deleteFood", "id": id]
        }
    }
}
