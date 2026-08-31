import XCTest
@testable import jpc_fit

final class NotificationManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "NotificationManagerTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func testDisablePersistsAcrossRelaunch() {
        // Regression: disable() only flipped the in-memory flag; on next
        // launch checkPermission() re-derived isEnabled from OS authorization
        // (still granted) and notifications silently came back.
        let manager = NotificationManager(defaults: defaults)
        manager.disable()
        XCTAssertFalse(manager.isEnabled)
        XCTAssertTrue(defaults.bool(forKey: manager.disabledKey))

        // Simulate relaunch: a fresh manager over the same store must stay
        // disabled regardless of what the OS authorization status says.
        let relaunched = NotificationManager(defaults: defaults)
        XCTAssertFalse(relaunched.isEnabled)
    }

    func testDefaultReminderTimesAre1pmAnd8pm() {
        let manager = NotificationManager(defaults: defaults)
        XCTAssertEqual(manager.reminderTimes.map(\.hour), [13, 20])
        XCTAssertEqual(manager.reminderTimes.map(\.minute), [0, 0])
    }

    func testAddAndRemoveTimePersist() {
        let manager = NotificationManager(defaults: defaults)
        var comps = DateComponents()
        comps.hour = 9; comps.minute = 30
        let date = Calendar.current.date(from: comps)!

        manager.addTime(date)
        XCTAssertEqual(manager.reminderTimes.count, 3)

        let reloaded = NotificationManager(defaults: defaults)
        XCTAssertEqual(reloaded.reminderTimes.count, 3)
        XCTAssertEqual(reloaded.reminderTimes.last?.hour, 9)
        XCTAssertEqual(reloaded.reminderTimes.last?.minute, 30)

        manager.removeTime(at: 2)
        XCTAssertEqual(NotificationManager(defaults: defaults).reminderTimes.count, 2)
    }
}
