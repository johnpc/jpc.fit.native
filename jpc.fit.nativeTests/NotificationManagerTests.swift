import XCTest
import UserNotifications
@testable import jpc_fit

@MainActor
final class NotificationManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var center: FakeNotificationCenter!
    private let suite = "NotificationManagerTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        center = FakeNotificationCenter()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    /// A manager whose launch-time OS check has settled (no racing the init task).
    private func makeManager() async -> NotificationManager {
        let manager = NotificationManager(defaults: defaults, center: center)
        await manager.initialRefresh?.value
        return manager
    }

    func testDisablePersistsAcrossRelaunch() async {
        // Regression: disable() only flipped the in-memory flag; on next
        // launch checkPermission() re-derived isEnabled from OS authorization
        // (still granted) and notifications silently came back.
        center.status = .authorized
        let manager = await makeManager()
        XCTAssertEqual(manager.state, .enabled)
        manager.disable()
        XCTAssertEqual(manager.state, .userDisabled)
        XCTAssertFalse(manager.isEnabled)
        XCTAssertTrue(defaults.bool(forKey: manager.disabledKey))
        XCTAssertEqual(center.removeAllCalls, 1)

        // Simulate relaunch: a fresh manager over the same store must stay
        // disabled regardless of what the OS authorization status says.
        let relaunched = NotificationManager(defaults: defaults, center: center)
        XCTAssertEqual(relaunched.state, .userDisabled, "known before the OS even answers")
        await relaunched.initialRefresh?.value
        XCTAssertEqual(relaunched.state, .userDisabled, "the OS answer does not override the stored choice")
    }

    func testStateFollowsTheOSAnswer() async {
        // StateMachine "Reminders": the OS status maps onto distinct states so
        // the UI can tell "never asked" from "denied in iOS Settings".
        let unsettled = NotificationManager(defaults: defaults, center: center)
        XCTAssertEqual(unsettled.state, .unknown, "before the OS answers")
        center.status = .notDetermined
        let manager = await makeManager()
        XCTAssertEqual(manager.state, .notRequested)
        center.status = .denied
        await manager.refreshState()
        XCTAssertEqual(manager.state, .osDenied)
        center.status = .provisional
        await manager.refreshState()
        XCTAssertEqual(manager.state, .enabled)
        XCTAssertEqual(ReminderState.from(.authorized, userDisabled: true), .userDisabled)
    }

    func testGrantedPermissionEnablesAndSchedulesEveryTime() async {
        center.grant = true
        let manager = await makeManager()
        let granted = await manager.requestPermission()
        XCTAssertTrue(granted)
        XCTAssertEqual(manager.state, .enabled)
        XCTAssertEqual(center.added.map(\.identifier), ["reminder-0", "reminder-1"])
        XCTAssertFalse(defaults.bool(forKey: manager.disabledKey), "re-enabling clears the stored disable")
    }

    func testDeniedPermissionIsOsDeniedAndSchedulesNothing() async {
        center.grant = false
        let manager = await makeManager()
        let granted = await manager.requestPermission()
        XCTAssertFalse(granted)
        XCTAssertEqual(manager.state, .osDenied)
        XCTAssertTrue(center.added.isEmpty)
        await manager.scheduleNotifications()
        XCTAssertTrue(center.added.isEmpty, "nothing is ever scheduled behind a denied state")
    }

    func testPermissionErrorLeavesStateAlone() async {
        center.error = URLError(.cancelled)
        let manager = await makeManager()
        XCTAssertEqual(manager.state, .notRequested)
        let granted = await manager.requestPermission()
        XCTAssertFalse(granted)
        XCTAssertEqual(manager.state, .notRequested)
    }

    func testDefaultReminderTimesAre1pmAnd8pm() async {
        let manager = await makeManager()
        XCTAssertEqual(manager.reminderTimes.map(\.hour), [13, 20])
        XCTAssertEqual(manager.reminderTimes.map(\.minute), [0, 0])
    }

    func testAddAndRemoveTimePersist() async {
        let manager = await makeManager()
        var comps = DateComponents()
        comps.hour = 9; comps.minute = 30
        let date = Calendar.current.date(from: comps)!

        manager.addTime(date)
        XCTAssertEqual(manager.reminderTimes.count, 3)

        let reloaded = await makeManager()
        XCTAssertEqual(reloaded.reminderTimes.count, 3)
        XCTAssertEqual(reloaded.reminderTimes.last?.hour, 9)
        XCTAssertEqual(reloaded.reminderTimes.last?.minute, 30)

        manager.removeTime(at: 2)
        let afterRemoval = await makeManager()
        XCTAssertEqual(afterRemoval.reminderTimes.count, 2)
    }
}

/// Scripted stand-in for UNUserNotificationCenter.
final class FakeNotificationCenter: NotificationCenterProviding, @unchecked Sendable {
    var status: UNAuthorizationStatus = .notDetermined
    var grant = false
    var error: Error?
    private(set) var removeAllCalls = 0
    private(set) var added: [UNNotificationRequest] = []

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
        if let error { throw error }
        status = grant ? .authorized : .denied
        return grant
    }

    func removeAllPendingRequests() {
        removeAllCalls += 1
        added = []
    }

    func add(_ request: UNNotificationRequest) async throws { added.append(request) }
}
