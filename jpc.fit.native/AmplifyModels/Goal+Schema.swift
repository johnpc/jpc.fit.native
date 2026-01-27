// swiftlint:disable all
import Amplify
import Foundation

extension Goal {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case dietCalories
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let goal = Goal.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Goals"
    model.syncPluralName = "Goals"
    
    model.attributes(
      .primaryKey(fields: [goal.id])
    )
    
    model.fields(
      .field(goal.id, is: .required, ofType: .string),
      .field(goal.dietCalories, is: .required, ofType: .int),
      .field(goal.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(goal.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Goal> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Goal: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Goal {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var dietCalories: FieldPath<Int>   {
      int("dietCalories") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}