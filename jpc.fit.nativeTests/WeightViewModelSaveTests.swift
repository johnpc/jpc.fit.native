import XCTest
@testable import jpc_fit

/// Weight/height saves through the seam + the one-field toast machine.
@MainActor
final class WeightViewModelSaveTests: XCTestCase {
    private var mockAPI: MockAPIService!
    private var vm: WeightViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIService()
        vm = WeightViewModel(api: mockAPI, toastDuration: .milliseconds(1))
    }

    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    func testFetchDataLoadsNewestFirst() async {
        await mockAPI.setWeights([Weight(id: "w1", currentWeight: 175), Weight(id: "w2", currentWeight: 180)])
        await mockAPI.setHeights([Height(id: "h1", currentHeight: 72)])
        XCTAssertTrue(vm.isLoading)
        await vm.fetchData()
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.currentWeight, 175)
        XCTAssertEqual(vm.currentHeight, 72)
    }

    func testSaveRejectsNonPositiveInput() {
        XCTAssertFalse(vm.save(.weight, value: ""))
        XCTAssertFalse(vm.save(.weight, value: "0"))
        XCTAssertFalse(vm.save(.height, value: "abc"))
        XCTAssertTrue(vm.weights.isEmpty)
        XCTAssertTrue(vm.heights.isEmpty)
    }

    func testSavesAreOptimisticAndPersist() async {
        XCTAssertTrue(vm.save(.weight, value: "185"))
        XCTAssertTrue(vm.save(.height, value: "71"))
        XCTAssertEqual(vm.currentWeight, 185, "row shows at tap time")
        XCTAssertEqual(vm.currentHeight, 71)
        await settle()
        let awaited1 = await mockAPI.fetchWeights().first?.currentWeight
        XCTAssertEqual(awaited1, 185)
        let awaited2 = await mockAPI.fetchHeights().first?.currentHeight
        XCTAssertEqual(awaited2, 71)
        XCTAssertNil(vm.toast)
    }

    func testFailedSaveRollsBackAndToasts() async {
        await mockAPI.setFailWrites(true)
        vm.save(.weight, value: "185")
        await settle()
        XCTAssertTrue(vm.weights.isEmpty, "failed save must not leave a phantom row")
        XCTAssertEqual(vm.toast, "Weight: offline")

        vm.save(.height, value: "71")
        await settle()
        XCTAssertTrue(vm.heights.isEmpty)
        XCTAssertEqual(vm.toast, "Height: offline")
    }

    func testToastHidesItselfAndANewerToastRestartsTheClock() async {
        // StateMachine "Weight toast": visible iff non-nil; one owner.
        vm.showError("first")
        XCTAssertEqual(vm.toast, "first")
        vm.showError("second")
        XCTAssertEqual(vm.toast, "second")
        await vm.awaitToastDismissal()
        XCTAssertNil(vm.toast)
    }
}
