import XCTest
@testable import jpc_fit

@MainActor
final class SettingsQuickAddTests: XCTestCase {
    private var mockAPI: MockAPIService!
    private var vm: SettingsViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIService()
        vm = SettingsViewModel(api: mockAPI, auth: RecordingAuth())
    }

    private func draft(_ name: String, _ calories: String) -> QuickAddDraft {
        var d = QuickAddDraft()
        d.name = name
        d.calories = calories
        return d
    }

    /// Lets the VM's fire-and-forget write land (the mock is synchronous).
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    func testCreateIsOptimisticThenReKeyed() async {
        vm.createQuickAdd(draft("Latte", "180"))
        XCTAssertEqual(vm.quickAdds.map(\.name), ["Latte"], "row appears at tap time")
        await settle()
        XCTAssertTrue(vm.quickAdds[0].id.hasPrefix("server-"), "temp id swapped for the server id")
        let awaited1 = await mockAPI.fetchQuickAdds().count
        XCTAssertEqual(awaited1, 1)
    }

    func testInvalidDraftIsIgnored() async {
        vm.createQuickAdd(draft("", "180"))
        vm.createQuickAdd(draft("Latte", "0"))
        XCTAssertTrue(vm.quickAdds.isEmpty)
    }

    func testFailedCreateRollsBack() async {
        await mockAPI.setFailWrites(true)
        vm.createQuickAdd(draft("Latte", "180"))
        await settle()
        XCTAssertTrue(vm.quickAdds.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testUpdateIsOptimisticAndRollsBackOnFailure() async {
        let item = QuickAddItem(id: "q1", name: "Latte", calories: 180, icon: "☕", protein: nil)
        await mockAPI.setQuickAdds([item])
        await vm.fetchAll()
        vm.updateQuickAdd(id: "q1", with: draft("Flat white", "160"))
        XCTAssertEqual(vm.quickAdds[0].name, "Flat white")
        await settle()
        let awaited2 = await mockAPI.fetchQuickAdds().first?.calories
        XCTAssertEqual(awaited2, 160)

        await mockAPI.setFailWrites(true)
        vm.updateQuickAdd(id: "q1", with: draft("Mocha", "300"))
        XCTAssertEqual(vm.quickAdds[0].name, "Mocha")
        await settle()
        XCTAssertEqual(vm.quickAdds[0].name, "Flat white", "failed update reverts")
        XCTAssertNotNil(vm.errorMessage)
        vm.updateQuickAdd(id: "missing", with: draft("x", "1"))
        XCTAssertEqual(vm.quickAdds.count, 1)
    }

    func testDeleteIsOptimisticAndRestoresOnFailure() async {
        let items = [QuickAddItem(id: "q1", name: "A", calories: 1, icon: "🍎", protein: nil),
                     QuickAddItem(id: "q2", name: "B", calories: 2, icon: "🍌", protein: nil)]
        await mockAPI.setQuickAdds(items)
        await vm.fetchAll()
        vm.deleteQuickAdd(at: IndexSet(integer: 0))
        XCTAssertEqual(vm.quickAdds.map(\.id), ["q2"])
        await settle()
        let awaited3 = await mockAPI.fetchQuickAdds().map(\.id)
        XCTAssertEqual(awaited3, ["q2"])

        await mockAPI.setFailWrites(true)
        vm.deleteQuickAdd(at: IndexSet(integer: 0))
        XCTAssertTrue(vm.quickAdds.isEmpty)
        await settle()
        XCTAssertEqual(vm.quickAdds.map(\.id), ["q2"], "failed delete restores the row")
        XCTAssertNotNil(vm.errorMessage)
    }
}
