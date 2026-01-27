// swiftlint:disable all
import Amplify
import Foundation

public struct Preferences: Model {
  public let id: String
  public var hideProtein: Bool?
  public var hideSteps: Bool?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      hideProtein: Bool? = nil,
      hideSteps: Bool? = nil) {
    self.init(id: id,
      hideProtein: hideProtein,
      hideSteps: hideSteps,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      hideProtein: Bool? = nil,
      hideSteps: Bool? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.hideProtein = hideProtein
      self.hideSteps = hideSteps
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}