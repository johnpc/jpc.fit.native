import Foundation

extension Notification.Name {
    /// Posted after any food mutation (app or watch originated) so open
    /// screens can reconcile. Carries the mutating `FoodViewModel` as the
    /// notification object so a view can skip its own writes.
    static let foodDataChanged = Notification.Name("foodDataChanged")
}
