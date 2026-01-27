// swiftlint:disable all
import Amplify
import Foundation

public struct HealthKitCache: Model {
  public let id: String
  public var activeCalories: Double
  public var baseCalories: Double
  public var weight: Double?
  public var steps: Double?
  public var day: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      activeCalories: Double,
      baseCalories: Double,
      weight: Double? = nil,
      steps: Double? = nil,
      day: String) {
    self.init(id: id,
      activeCalories: activeCalories,
      baseCalories: baseCalories,
      weight: weight,
      steps: steps,
      day: day,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      activeCalories: Double,
      baseCalories: Double,
      weight: Double? = nil,
      steps: Double? = nil,
      day: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.activeCalories = activeCalories
      self.baseCalories = baseCalories
      self.weight = weight
      self.steps = steps
      self.day = day
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}