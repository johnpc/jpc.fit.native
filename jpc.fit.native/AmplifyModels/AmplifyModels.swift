// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "a8e51564e30cb02cc6e62b3f52f49515"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Food.self)
    ModelRegistry.register(modelType: Goal.self)
    ModelRegistry.register(modelType: QuickAdd.self)
    ModelRegistry.register(modelType: Weight.self)
    ModelRegistry.register(modelType: Height.self)
    ModelRegistry.register(modelType: HealthKitCache.self)
    ModelRegistry.register(modelType: Preferences.self)
  }
}