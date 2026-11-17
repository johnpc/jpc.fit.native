import XCTest

/// Cold-launch timing of the demo build, reported (never gated) by XCTest's
/// launch metric. Not part of the acceptance matrix — run it by hand:
///   xcodebuild test … -only-testing:jpc.fit.nativeUITests/LaunchPerformanceTests
final class LaunchPerformanceTests: XCTestCase {
    func testDemoLaunchTime() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments += ["--demo"]
            app.launch()
        }
    }
}
