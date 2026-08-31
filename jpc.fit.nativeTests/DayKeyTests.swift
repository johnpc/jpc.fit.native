import XCTest
@testable import jpc_fit

final class DayKeyTests: XCTestCase {
    func testKnownDate() {
        // 2026-08-30 in the current calendar/timezone
        let comps = DateComponents(year: 2026, month: 8, day: 30, hour: 12)
        let date = Calendar.current.date(from: comps)!
        XCTAssertEqual(DayKey.string(from: date), "8/30/2026")
    }

    func testNoZeroPadding() {
        let comps = DateComponents(year: 2026, month: 1, day: 5, hour: 12)
        let date = Calendar.current.date(from: comps)!
        XCTAssertEqual(DayKey.string(from: date), "1/5/2026")
    }

    func testMatchesLegacyNumericFormatUnderEnUS() {
        // The pre-DayKey code used `.formatted(date: .numeric, time: .omitted)`,
        // which under en_US produced M/d/yyyy. DayKey must keep emitting the
        // exact same keys so existing backend rows still resolve.
        let date = Date()
        let legacy = Date.FormatStyle(date: .numeric, time: .omitted, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(DayKey.string(from: date), date.formatted(legacy))
    }

    func testTodayIsToday() {
        XCTAssertEqual(DayKey.today, DayKey.string(from: Date()))
    }

    func testStableAcrossLocaleFormatting() {
        // The whole point: DayKey must not follow the device region the way
        // `.formatted(date: .numeric)` does (30.08.2026 in de_DE etc.).
        let date = Date()
        XCTAssertFalse(DayKey.string(from: date).contains("."))
        XCTAssertEqual(DayKey.string(from: date).filter { $0 == "/" }.count, 2)
    }
}
