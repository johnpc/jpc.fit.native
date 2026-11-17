import XCTest
@testable import jpc_fit

/// Transition tables for the small pure machines: StreakState,
/// PreferencesRecord, RefreshGate, QuoteBag, MeasurementPrompt.
final class StateTransitionTests: XCTestCase {
    // MARK: StreakState

    func testFailureOnlyDemotesAComputingStreak() {
        XCTAssertEqual(StreakState.computing.afterFailure(), .unavailable)
        XCTAssertEqual(StreakState.unavailable.afterFailure(), .unavailable)
        XCTAssertEqual(StreakState.known(days: 9, net: 5).afterFailure(), .known(days: 9, net: 5))
    }

    func testStreakLabelsOnlyWhileKnown() {
        XCTAssertNil(StreakState.computing.daysLabel(cap: 365))
        XCTAssertNil(StreakState.unavailable.daysLabel(cap: 365))
        XCTAssertEqual(StreakState.known(days: 12, net: 0).daysLabel(cap: 365), "12")
        XCTAssertEqual(StreakState.known(days: 365, net: 0).daysLabel(cap: 365), "365+")
        XCTAssertEqual(StreakState.unavailable.net, 0)
    }

    // MARK: PreferencesRecord

    func testPreferencesRecordDerivesFlags() {
        XCTAssertFalse(PreferencesRecord.unknown.hideProtein)
        XCTAssertFalse(PreferencesRecord.missing.hideSteps)
        XCTAssertNil(PreferencesRecord.missing.preferences)
        let stored = PreferencesRecord.stored(Preferences(id: "p", hideProtein: true, hideSteps: false))
        XCTAssertTrue(stored.hideProtein)
        XCTAssertFalse(stored.hideSteps)
        XCTAssertEqual(stored.preferences?.id, "p")
    }

    func testPreferencesRecordEquality() {
        let a = PreferencesRecord.stored(Preferences(id: "p", hideProtein: true, hideSteps: false))
        let b = PreferencesRecord.stored(Preferences(id: "p", hideProtein: true, hideSteps: false))
        let c = PreferencesRecord.stored(Preferences(id: "p", hideProtein: false, hideSteps: false))
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertNotEqual(PreferencesRecord.unknown, .missing)
        XCTAssertNotEqual(a, .missing)
    }

    // MARK: RefreshGate

    func testDataChangeOnScreenRefreshesImmediately() {
        var gate = RefreshGate.offScreen(stale: false)
        XCTAssertEqual(gate.appeared(), .none)
        XCTAssertEqual(gate, .onScreen)
        XCTAssertEqual(gate.dataChanged(), .refreshNow)
        XCTAssertEqual(gate, .onScreen)
    }

    func testDataChangeOffScreenIsDeferredUntilNextAppearance() {
        var gate = RefreshGate.onScreen
        gate.disappeared()
        XCTAssertEqual(gate, .offScreen(stale: false))
        XCTAssertEqual(gate.dataChanged(), .deferred)
        XCTAssertEqual(gate.dataChanged(), .deferred, "a second change keeps it stale, no double refresh")
        XCTAssertEqual(gate, .offScreen(stale: true))
        XCTAssertEqual(gate.appeared(), .refreshNow)
        XCTAssertEqual(gate, .onScreen)
        gate.disappeared()
        XCTAssertEqual(gate.appeared(), .none, "returning without changes does not refresh")
    }

    // MARK: QuoteBag

    func testQuoteBagShowsEveryQuoteOnceBeforeRepeating() {
        var bag = QuoteBag(count: 5)
        XCTAssertNil(bag.current)
        var seen: [Int] = []
        for _ in 0..<5 {
            bag.draw()
            seen.append(bag.current ?? -1)
        }
        XCTAssertEqual(Set(seen).count, 5, "a full cycle has no repeats")
        XCTAssertEqual(Set(seen), Set(0..<5))
        bag.draw()
        XCTAssertEqual(bag.used.count, 1, "the sixth draw starts a fresh cycle")
    }

    func testQuoteBagIsDeterministicUnderASeededGenerator() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        var bagA = QuoteBag(count: 7)
        var bagB = QuoteBag(count: 7)
        for _ in 0..<10 {
            bagA.draw(using: &first)
            bagB.draw(using: &second)
            XCTAssertEqual(bagA.current, bagB.current, "same seed, same sequence")
        }
        XCTAssertEqual(bagA.used.count, 3, "10 draws over 7 quotes = one full cycle + 3")
        XCTAssertEqual(QuoteBag(count: 0).count, 1, "an empty list still renders something")
    }

    // MARK: MeasurementPrompt

    func testMeasurementPromptCopy() {
        XCTAssertEqual(MeasurementPrompt.weight.title, "Enter Weight (lbs)")
        XCTAssertEqual(MeasurementPrompt.height.title, "Enter Height (inches)")
        XCTAssertEqual(MeasurementPrompt.weight.fieldLabel, "Weight")
        XCTAssertEqual(MeasurementPrompt.height.fieldLabel, "Height")
        XCTAssertEqual(MeasurementPrompt.weight.icon, "scalemass")
        XCTAssertEqual(MeasurementPrompt.height.icon, "ruler")
        XCTAssertNotEqual(MeasurementPrompt.weight.id, MeasurementPrompt.height.id)
    }
}

/// SplitMix64: a tiny deterministic generator (a constant generator would
/// make `Int.random`'s rejection sampling spin forever).
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
