import XCTest

/// Walks every screen of the demo build and attaches a screenshot of each —
/// the evidence a UI change is judged by (AGENTS.md §4). Not in the CI
/// acceptance matrix; run by hand and export with
///   xcrun xcresulttool export attachments --path X.xcresult --output-path DIR
final class DemoTourTests: XCTestCase {
    private let wait: TimeInterval = 20

    func testTourEveryScreen() {
        let app = XCUIApplication()
        app.launchArguments += ["--demo"]
        app.launch()
        snap(app, "01-sign-in")

        StepDefinitions.type("demo@jpc.fit", into: app.textFields["Email"])
        StepDefinitions.type("demo-password", into: StepDefinitions.passwordField(in: app))
        app.buttons["Sign In"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Remaining"].waitForExistence(timeout: wait))
        snap(app, "02-calories")

        StepDefinitions.tap(CaloriesSteps.buttonContaining("Pizza slice", in: app), "Pizza slice quick add")
        XCTAssertTrue(StepDefinitions.reveal(app.staticTexts["1,370 cal"], in: app))
        snap(app, "03-calories-after-quick-add")

        app.tabBars.buttons["Weight"].tap()
        XCTAssertTrue(app.staticTexts["BMI"].waitForExistence(timeout: wait))
        snap(app, "04-weight")
        app.buttons["Edit Weight"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: wait))
        snap(app, "05-weight-prompt")
        app.alerts.buttons["Cancel"].tap()

        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.staticTexts["Your streak is 13 days"].waitForExistence(timeout: wait))
        snap(app, "06-stats")

        app.tabBars.buttons["Quotes"].tap()
        XCTAssertTrue(app.buttons["Randomize Quote"].waitForExistence(timeout: wait))
        snap(app, "07-quotes")

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["New Quick Add"].waitForExistence(timeout: wait))
        snap(app, "08-settings")
        XCTAssertTrue(StepDefinitions.reveal(app.buttons["Sign Out"], in: app))
        snap(app, "08b-settings-account")
        StepDefinitions.tap(app.buttons["New Quick Add"], "New Quick Add")
        XCTAssertTrue(app.navigationBars["New Quick Add"].waitForExistence(timeout: wait))
        snap(app, "09-new-quick-add-sheet")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
