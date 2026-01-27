// swiftlint:disable all
import Amplify
import Foundation

extension Height {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case currentHeight
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let height = Height.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Heights"
    model.syncPluralName = "Heights"
    
    model.attributes(
      .primaryKey(fields: [height.id])
    )
    
    model.fields(
      .field(height.id, is: .required, ofType: .string),
      .field(height.currentHeight, is: .required, ofType: .int),
      .field(height.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(height.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Height> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Height: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Height {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var currentHeight: FieldPath<Int>   {
      int("currentHeight") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}