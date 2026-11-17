import XCTest
@testable import jpc_fit

/// The phone <-> watch wire codec and the watch's status machines.
final class WatchProtocolTests: XCTestCase {
    func testCommandsRoundTripThroughTheWireDictionary() {
        let commands: [WatchCommand] = [
            .requestData, .syncHealthKit,
            .addFood(name: "🍎 Apple", calories: 95, protein: 1),
            .addFood(name: "🍕 Pizza", calories: 300, protein: nil),
            .deleteFood(id: "f-1"),
        ]
        for command in commands {
            XCTAssertEqual(WatchCommand(message: command.message), command, "\(command)")
        }
    }

    func testAddFoodWithZeroProteinOnTheWireMeansNoProtein() {
        // The watch has always sent 0 for "none"; the phone must not store 0g.
        let legacy: [String: Any] = ["action": "addFood", "name": "Tea", "calories": 5, "protein": 0]
        XCTAssertEqual(WatchCommand(message: legacy), .addFood(name: "Tea", calories: 5, protein: nil))
        XCTAssertEqual(WatchCommand.addFood(name: "Tea", calories: 5, protein: nil).message["protein"] as? Int, 0)
    }

    func testMalformedCommandsAreRejected() {
        XCTAssertNil(WatchCommand(message: [:]))
        XCTAssertNil(WatchCommand(message: ["action": "explode"]))
        XCTAssertNil(WatchCommand(message: ["action": "addFood", "name": "x"]), "missing calories")
        XCTAssertNil(WatchCommand(message: ["action": "deleteFood"]), "missing id")
        XCTAssertNil(WatchCommand(message: ["consumed": 1, "burned": 2]), "a snapshot is not a command")
    }

    func testSnapshotRoundTrips() {
        let snapshot = WatchSnapshot(
            consumed: 1200, burned: 2100,
            foods: [WatchFood(id: "f1", name: "☕ Coffee", calories: 50)],
            quickAdds: [WatchQuickAdd(id: "q1", name: "Salad", calories: 450, icon: "🥗", protein: 20),
                        WatchQuickAdd(id: "q2", name: "Coffee", calories: 50, icon: "☕", protein: nil)])
        XCTAssertEqual(WatchSnapshot(message: snapshot.message), snapshot)
        XCTAssertNil(WatchSnapshot(message: WatchCommand.requestData.message), "a command is not a snapshot")
        XCTAssertNil(WatchFood(message: ["id": "x"]))
        XCTAssertEqual(WatchQuickAdd(message: ["id": "q", "name": "n", "calories": 1])?.icon, "🍽️")
    }

    func testWatchHealthStatusLabels() {
        XCTAssertNil(WatchHealthStatus.unknown.label)
        XCTAssertEqual(WatchHealthStatus.unavailable.label, "HK unavailable")
        XCTAssertEqual(WatchHealthStatus.measured(active: 300, basal: 1500).label, "HK: 300+1500=1800")
        XCTAssertEqual(WatchHealthStatus.fromPhone.label, "Phone")
        XCTAssertEqual(WatchHealthStatus.failed(String(repeating: "x", count: 40)).label,
                       "Err: " + String(repeating: "x", count: 25))
    }

    func testPhoneLinkLabels() {
        XCTAssertEqual(PhoneLink.unknown.label, "...")
        XCTAssertEqual(PhoneLink.from(isReachable: true), .reachable)
        XCTAssertEqual(PhoneLink.from(isReachable: false), .unreachable)
        XCTAssertEqual(PhoneLink.reachable.label, "📱 Reachable")
        XCTAssertEqual(PhoneLink.unreachable.label, "📱 Not reachable")
    }
}
