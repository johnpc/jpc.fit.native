// swiftlint:disable all
import Amplify
import Foundation

extension StringType {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case value
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let stringType = StringType.keys
    
    model.listPluralName = "StringTypes"
    model.syncPluralName = "StringTypes"
    
    model.fields(
      .field(stringType.value, is: .optional, ofType: .string)
    )
    }
}