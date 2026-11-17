import Foundation

/// StateMachine: Measurement prompt
///
/// Which number the Weight tab is asking for. Two `showWeightAlert` /
/// `showHeightAlert` flags (and two near-identical alerts) became one optional.
enum MeasurementPrompt: Identifiable, Equatable {
    case weight
    case height

    var id: String { title }

    var title: String {
        switch self {
        case .weight: return "Enter Weight (lbs)"
        case .height: return "Enter Height (inches)"
        }
    }

    var fieldLabel: String {
        switch self {
        case .weight: return "Weight"
        case .height: return "Height"
        }
    }

    var icon: String {
        switch self {
        case .weight: return "scalemass"
        case .height: return "ruler"
        }
    }
}
