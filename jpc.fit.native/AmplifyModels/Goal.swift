// swiftlint:disable all
import Amplify
import Foundation

public struct Goal: Model {
  public let id: String
  public var dietCalories: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      dietCalories: Int) {
    self.init(id: id,
      dietCalories: dietCalories,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      dietCalories: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.dietCalories = dietCalories
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}