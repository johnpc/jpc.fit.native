// swiftlint:disable all
import Amplify
import Foundation

extension QuickAdd {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case calories
    case protein
    case icon
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let quickAdd = QuickAdd.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "QuickAdds"
    model.syncPluralName = "QuickAdds"
    
    model.attributes(
      .primaryKey(fields: [quickAdd.id])
    )
    
    model.fields(
      .field(quickAdd.id, is: .required, ofType: .string),
      .field(quickAdd.name, is: .required, ofType: .string),
      .field(quickAdd.calories, is: .required, ofType: .int),
      .field(quickAdd.protein, is: .optional, ofType: .int),
      .field(quickAdd.icon, is: .required, ofType: .string),
      .field(quickAdd.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(quickAdd.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<QuickAdd> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension QuickAdd: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == QuickAdd {
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
  public var icon: FieldPath<String>   {
      string("icon") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}