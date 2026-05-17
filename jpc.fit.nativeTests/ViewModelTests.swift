import XCTest
@testable import jpc_fit

@MainActor
final class WeightViewModelTests: XCTestCase {
    private var vm: WeightViewModel!

    override func setUp() {
        super.setUp()
        vm = WeightViewModel()
    }

    func testDefaultWeight() {
        XCTAssertEqual(vm.currentWeight, 180)
    }

    func testDefaultHeight() {
        XCTAssertEqual(vm.currentHeight, 70)
    }

    func testBMICalculation() {
        // BMI = weight / (height^2) * 703
        // 180 / (70*70) * 703 = 180 / 4900 * 703 = 25.82
        let expected = Double(180) / Double(70 * 70) * 703
        XCTAssertEqual(vm.bmi, expected, accuracy: 0.01)
    }

    func testBMILabelUnderweight() {
        // Need weight that gives BMI < 18.5 at height 70
        // BMI = w / (70*70) * 703 < 18.5 => w < 18.5 * 4900 / 703 = 128.9
        vm.weights = [Weight(id: "1", currentWeight: 120)]
        XCTAssertEqual(vm.bmiLabel, "underweight")
    }

    func testBMILabelHealthy() {
        // 18.5 <= BMI < 25 => 128.9 <= w < 174.2
        vm.weights = [Weight(id: "1", currentWeight: 150)]
        XCTAssertEqual(vm.bmiLabel, "healthy")
    }

    func testBMILabelOverweight() {
        // 25 <= BMI < 30 => 174.2 <= w < 209.1
        vm.weights = [Weight(id: "1", currentWeight: 190)]
        XCTAssertEqual(vm.bmiLabel, "overweight")
    }

    func testBMILabelObese() {
        // BMI >= 30 => w >= 209.1
        vm.weights = [Weight(id: "1", currentWeight: 250)]
        XCTAssertEqual(vm.bmiLabel, "obese")
    }

    func testMaxUnderweight() {
        // 18.5 / 703 * (70*70) = 128.9
        let expected = 18.5 / 703 * Double(70 * 70)
        XCTAssertEqual(vm.maxUnderweight, expected, accuracy: 0.01)
    }

    func testMaxHealthy() {
        let expected = 25.0 / 703 * Double(70 * 70)
        XCTAssertEqual(vm.maxHealthy, expected, accuracy: 0.01)
    }

    func testMaxOverweight() {
        let expected = 30.0 / 703 * Double(70 * 70)
        XCTAssertEqual(vm.maxOverweight, expected, accuracy: 0.01)
    }

    func testCurrentWeightUsesFirst() {
        vm.weights = [
            Weight(id: "1", currentWeight: 175),
            Weight(id: "2", currentWeight: 180),
        ]
        XCTAssertEqual(vm.currentWeight, 175)
    }

    func testCurrentHeightUsesFirst() {
        vm.heights = [
            Height(id: "1", currentHeight: 72),
            Height(id: "2", currentHeight: 70),
        ]
        XCTAssertEqual(vm.currentHeight, 72)
    }
}

@MainActor
final class StatsViewModelTests: XCTestCase {
    private var vm: StatsViewModel!

    override func setUp() {
        super.setUp()
        vm = StatsViewModel()
    }

    func testWeekNetEmpty() {
        XCTAssertEqual(vm.weekNet, 0)
    }

    func testWeekNetCalculation() {
        vm.weekData = [
            DayStats(day: "5/12/2026", shortDay: "5/12", consumed: 2000, burned: 2500, tracked: true),
            DayStats(day: "5/13/2026", shortDay: "5/13", consumed: 2200, burned: 2300, tracked: true),
            DayStats(day: "5/14/2026", shortDay: "5/14", consumed: 0, burned: 0, tracked: false),
        ]
        // Only tracked days: (2000-2500) + (2200-2300) = -500 + -100 = -600
        XCTAssertEqual(vm.weekNet, -600)
    }

    func testTrackedCount() {
        vm.weekData = [
            DayStats(day: "5/12/2026", shortDay: "5/12", consumed: 2000, burned: 2500, tracked: true),
            DayStats(day: "5/13/2026", shortDay: "5/13", consumed: 0, burned: 0, tracked: false),
            DayStats(day: "5/14/2026", shortDay: "5/14", consumed: 1800, burned: 2000, tracked: true),
        ]
        XCTAssertEqual(vm.trackedCount, 2)
    }

    func testStreakLbs() {
        vm.streakNet = -7000 // 7000 cal deficit = 2 lbs lost
        XCTAssertEqual(vm.streakLbs, -2.0, accuracy: 0.01)
    }

    func testStreakLbsPositive() {
        vm.streakNet = 3500 // 3500 cal surplus = 1 lb gained
        XCTAssertEqual(vm.streakLbs, 1.0, accuracy: 0.01)
    }

    func testWeekRangeString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        vm.weekStartDate = formatter.date(from: "5/17/2026")!
        let range = vm.weekRangeString
        XCTAssertTrue(range.contains("5/11/2026"))
        XCTAssertTrue(range.contains("5/17/2026"))
    }

    func testDayStatsNet() {
        let day = DayStats(day: "5/17/2026", shortDay: "5/17", consumed: 1800, burned: 2200, tracked: true)
        XCTAssertEqual(day.net, -400)
    }

    func testDayStatsNetPositive() {
        let day = DayStats(day: "5/17/2026", shortDay: "5/17", consumed: 3000, burned: 2200, tracked: true)
        XCTAssertEqual(day.net, 800)
    }
}
