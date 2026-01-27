// swiftlint:disable all
import Amplify
import Foundation

extension Preferences {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case hideProtein
    case hideSteps
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let preferences = Preferences.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Preferences"
    model.syncPluralName = "Preferences"
    
    model.attributes(
      .primaryKey(fields: [preferences.id])
    )
    
    model.fields(
      .field(preferences.id, is: .required, ofType: .string),
      .field(preferences.hideProtein, is: .optional, ofType: .bool),
      .field(preferences.hideSteps, is: .optional, ofType: .bool),
      .field(preferences.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(preferences.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Preferences> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Preferences: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Preferences {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var hideProtein: FieldPath<Bool>   {
      bool("hideProtein") 
    }
  public var hideSteps: FieldPath<Bool>   {
      bool("hideSteps") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}