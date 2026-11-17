import XCTest
@testable import jpc_fit

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private var mockAPI: MockAPIService!
    private var auth: RecordingAuth!
    private var vm: SettingsViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIService()
        auth = RecordingAuth()
        vm = SettingsViewModel(api: mockAPI, auth: auth)
    }

    // MARK: Preferences record (StateMachine "Preferences record")

    func testFirstSaveCreatesTheRowWhenMissing() async {
        await vm.fetchAll()
        XCTAssertEqual(vm.preferences, .missing)
        await vm.savePreferences(hideProtein: true, hideSteps: false)
        XCTAssertTrue(vm.hideProtein)
        let awaited1 = await mockAPI.getCreatedPreferences()
        XCTAssertEqual(awaited1, 1)
        XCTAssertEqual(vm.preferences.preferences?.id, "prefs-1")
    }

    func testLaterSavesUpdateInsteadOfCreating() async {
        await mockAPI.setPreferences(Preferences(id: "p1", hideProtein: false, hideSteps: false))
        await vm.fetchAll()
        await vm.savePreferences(hideProtein: false, hideSteps: true)
        XCTAssertTrue(vm.hideSteps)
        let awaited2 = await mockAPI.getCreatedPreferences()
        XCTAssertEqual(awaited2, 0, "must never create a second row")
        let awaited3 = await mockAPI.getUpdatedPreferences().map(\.id)
        XCTAssertEqual(awaited3, ["p1"])
    }

    func testUnknownRecordRefetchesBeforeWriting() async {
        // Regression: a failed fetch left `preferences == nil`, and the next
        // toggle CREATED a duplicate row. Now the save re-fetches first.
        await mockAPI.setPreferences(Preferences(id: "p1", hideProtein: false, hideSteps: false))
        XCTAssertEqual(vm.preferences, .unknown)
        await vm.savePreferences(hideProtein: true, hideSteps: false)
        let awaited4 = await mockAPI.getCreatedPreferences()
        XCTAssertEqual(awaited4, 0)
        let awaited5 = await mockAPI.getUpdatedPreferences().count
        XCTAssertEqual(awaited5, 1)
        XCTAssertTrue(vm.hideProtein)
    }

    func testStillUnknownAfterRefetchWritesNothing() async {
        await mockAPI.setPreferencesRecord(.unknown)
        await vm.savePreferences(hideProtein: true, hideSteps: true)
        let awaited6 = await mockAPI.getCreatedPreferences()
        XCTAssertEqual(awaited6, 0)
        XCTAssertFalse(vm.hideProtein, "the toggle snaps back")
        XCTAssertEqual(vm.errorMessage, "Couldn't load your preferences — pull to refresh and try again.")
    }

    func testFailedUpdateRollsBack() async {
        await mockAPI.setPreferences(Preferences(id: "p1", hideProtein: false, hideSteps: false))
        await vm.fetchAll()
        await mockAPI.setFailWrites(true)
        await vm.savePreferences(hideProtein: true, hideSteps: false)
        XCTAssertFalse(vm.hideProtein)
        XCTAssertNotNil(vm.errorMessage)
        await vm.savePreferences(hideProtein: false, hideSteps: true)
        XCTAssertFalse(vm.hideSteps)
    }

    func testFailedCreateSurfacesAnError() async {
        await vm.fetchAll()
        await mockAPI.setFailWrites(true)
        await vm.savePreferences(hideProtein: true, hideSteps: false)
        XCTAssertEqual(vm.preferences, .missing)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testUpdatePreferenceMergesTheOtherFlag() async {
        await mockAPI.setPreferences(Preferences(id: "p1", hideProtein: true, hideSteps: false))
        await vm.fetchAll()
        vm.updatePreference(hideSteps: true)
        await Task.yield()
        await vm.savePreferences(hideProtein: vm.hideProtein, hideSteps: vm.hideSteps)
        XCTAssertTrue(vm.hideProtein, "untouched flag is preserved")
        XCTAssertTrue(vm.hideSteps)
    }

    // MARK: Account

    func testSignOutAndDeleteGoThroughTheAuthSeam() async {
        vm.signOut()
        vm.deleteAccount()
        await auth.drain()
        XCTAssertEqual(auth.signOuts, 1)
        XCTAssertEqual(auth.deletes, 1)
    }
}

/// Counts auth calls. Main-actor like the VM's fire-and-forget tasks, so
/// `drain` and the counters can never race; `drain` yields to let those
/// tasks run and fails loudly instead of hanging if they never do.
@MainActor
final class RecordingAuth: AuthServiceProtocol {
    private(set) var signOuts = 0
    private(set) var deletes = 0

    func signOut() async { signOuts += 1 }
    func deleteUser() async { deletes += 1 }

    func drain(expecting calls: Int = 2, file: StaticString = #file, line: UInt = #line) async {
        var yields = 0
        while signOuts + deletes < calls, yields < 1_000 {
            await Task.yield()
            yields += 1
        }
        XCTAssertEqual(signOuts + deletes, calls, "auth calls never landed", file: file, line: line)
    }
}
