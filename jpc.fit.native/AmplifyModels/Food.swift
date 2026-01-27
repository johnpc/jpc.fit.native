// swiftlint:disable all
import Amplify
import Foundation

public struct Food: Model {
  public let id: String
  public var name: String?
  public var calories: Int
  public var protein: Int?
  public var day: String
  public var notes: String?
  public var photos: [String?]?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String? = nil,
      calories: Int,
      protein: Int? = nil,
      day: String,
      notes: String? = nil,
      photos: [String?]? = nil) {
    self.init(id: id,
      name: name,
      calories: calories,
      protein: protein,
      day: day,
      notes: notes,
      photos: photos,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      calories: Int,
      protein: Int? = nil,
      day: String,
      notes: String? = nil,
      photos: [String?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.calories = calories
      self.protein = protein
      self.day = day
      self.notes = notes
      self.photos = photos
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}