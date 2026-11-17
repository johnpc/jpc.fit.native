import Foundation

/// StateMachine: Quote bag
///
/// Shows every quote once before any repeats. `current` is the index on
/// screen (nil until the first draw); `used` is the set already shown this
/// cycle. Owner: `AphorismsView` calls `draw`, nothing else mutates it.
struct QuoteBag: Equatable {
    let count: Int
    private(set) var used: [Int] = []

    init(count: Int) {
        self.count = max(count, 1)
    }

    var current: Int? { used.last }

    /// Pick an unseen quote; once all are seen, start a fresh cycle.
    mutating func draw<R: RandomNumberGenerator>(using generator: inout R) {
        if used.count == count { used = [] }
        let remaining = (0..<count).filter { !used.contains($0) }
        guard let pick = remaining.randomElement(using: &generator) else { return }
        used.append(pick)
    }

    mutating func draw() {
        var generator = SystemRandomNumberGenerator()
        draw(using: &generator)
    }
}
