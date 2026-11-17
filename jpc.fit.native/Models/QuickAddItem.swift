import Foundation

struct QuickAddItem: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let calories: Int
    let icon: String
    let protein: Int?
}
