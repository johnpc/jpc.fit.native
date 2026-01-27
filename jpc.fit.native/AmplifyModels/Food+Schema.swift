// swiftlint:disable all
import Amplify
import Foundation

extension Food {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case calories
    case protein
    case day
    case notes
    case photos
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let food = Food.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Foods"
    model.syncPluralName = "Foods"
    
    model.attributes(
      .index(fields: ["day"], name: "foodsByDay"),
      .primaryKey(fields: [food.id])
    )
    
    model.fields(
      .field(food.id, is: .required, ofType: .string),
      .field(food.name, is: .optional, ofType: .string),
      .field(food.calories, is: .required, ofType: .int),
      .field(food.protein, is: .optional, ofType: .int),
      .field(food.day, is: .required, ofType: .string),
      .field(food.notes, is: .optional, ofType: .string),
      .field(food.photos, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(food.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(food.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Food> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Food: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Food {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var calories: FieldPath<Int>   {
      int("calories") 
    }
  public var protein: FieldPath<Int>   {
      int("protein") 
    }
  public var day: FieldPath<String>   {
      string("day") 
    }
  public var notes: FieldPath<String>   {
      string("notes") 
    }
  public var photos: FieldPath<String>   {
      string("photos") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}