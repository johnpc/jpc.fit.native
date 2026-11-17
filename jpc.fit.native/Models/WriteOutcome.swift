import Foundation

/// Result of a create mutation that the UI must react to: the server id of the
/// saved row (so an optimistic row can be re-keyed) or why it failed.
enum WriteOutcome: Equatable {
    case saved(id: String)
    case failed(reason: String)
}
