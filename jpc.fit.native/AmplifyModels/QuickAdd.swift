// swiftlint:disable all
import Amplify
import Foundation

public struct QuickAdd: Model {
  public let id: String
  public var name: String
  public var calories: Int
  public var protein: Int?
  public var icon: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      calories: Int,
      protein: Int? = nil,
      icon: String) {
    self.init(id: id,
      name: name,
      calories: calories,
      protein: protein,
      icon: icon,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      calories: Int,
      protein: Int? = nil,
      icon: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.calories = calories
      self.protein = protein
      self.icon = icon
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}