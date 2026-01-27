// swiftlint:disable all
import Amplify
import Foundation

extension Weight {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case currentWeight
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let weight = Weight.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Weights"
    model.syncPluralName = "Weights"
    
    model.attributes(
      .primaryKey(fields: [weight.id])
    )
    
    model.fields(
      .field(weight.id, is: .required, ofType: .string),
      .field(weight.currentWeight, is: .required, ofType: .int),
      .field(weight.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(weight.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Weight> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Weight: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Weight {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var currentWeight: FieldPath<Int>   {
      int("currentWeight") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}