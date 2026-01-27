// swiftlint:disable all
import Amplify
import Foundation

public struct Height: Model {
  public let id: String
  public var currentHeight: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      currentHeight: Int) {
    self.init(id: id,
      currentHeight: currentHeight,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      currentHeight: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.currentHeight = currentHeight
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}