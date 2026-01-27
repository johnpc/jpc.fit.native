// swiftlint:disable all
import Amplify
import Foundation

public struct Weight: Model {
  public let id: String
  public var currentWeight: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      currentWeight: Int) {
    self.init(id: id,
      currentWeight: currentWeight,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      currentWeight: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.currentWeight = currentWeight
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}