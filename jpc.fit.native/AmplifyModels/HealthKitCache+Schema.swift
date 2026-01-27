// swiftlint:disable all
import Amplify
import Foundation

extension HealthKitCache {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case activeCalories
    case baseCalories
    case weight
    case steps
    case day
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let healthKitCache = HealthKitCache.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "HealthKitCaches"
    model.syncPluralName = "HealthKitCaches"
    
    model.attributes(
      .primaryKey(fields: [healthKitCache.id])
    )
    
    model.fields(
      .field(healthKitCache.id, is: .required, ofType: .string),
      .field(healthKitCache.activeCalories, is: .required, ofType: .double),
      .field(healthKitCache.baseCalories, is: .required, ofType: .double),
      .field(healthKitCache.weight, is: .optional, ofType: .double),
      .field(healthKitCache.steps, is: .optional, ofType: .double),
      .field(healthKitCache.day, is: .required, ofType: .string),
      .field(healthKitCache.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(healthKitCache.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<HealthKitCache> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension HealthKitCache: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == HealthKitCache {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var activeCalories: FieldPath<Double>   {
      double("activeCalories") 
    }
  public var baseCalories: FieldPath<Double>   {
      double("baseCalories") 
    }
  public var weight: FieldPath<Double>   {
      double("weight") 
    }
  public var steps: FieldPath<Double>   {
      double("steps") 
    }
  public var day: FieldPath<String>   {
      string("day") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}