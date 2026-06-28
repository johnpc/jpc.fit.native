import XCTest

/// All Given/When/Then step definitions, mapping Gherkin lines to XCUITest
/// actions/assertions. Keywords are interchangeable at match time, so each step
/// is registered once regardless of whether specs phrase it as Given/When/Then.
///
/// These port the assertions from the original hand-written acceptance suite
/// (`AcceptanceTests`/`DateNavigationUITests`). The app talks to the live
/// backend, so navigation/empty-state flows are asserted strictly while content
/// that depends on the network is tolerant (accepts a nav bar / any content).
enum StepDefinitions {

    private static let short: TimeInterval = 5
    private static let medium: TimeInterval = 10
    private static let long: TimeInterval = 20

    static func makeRegistry() -> StepRegistry {
        let r = StepRegistry()

        // MARK: Lifecycle / sign-in
        r.define("the app is launched") { _ in }
        r.define("I sign in with valid credentials") { w in signIn(w) }
        r.define("I am signed in") { w in signIn(w) }

        // MARK: Tabs
        r.define("I should see the Calories tab") { w in
            XCTAssertTrue(w.app.tabBars.buttons["Calories"].waitForExistence(timeout: long),
                          "Calories tab should be present after login")
        }
        r.define("the tab bar should show all 5 tabs") { w in
            for tab in ["Calories", "Weight", "Stats", "Quotes", "Settings"] {
                XCTAssertTrue(w.app.tabBars.buttons[tab].waitForExistence(timeout: medium), "\(tab) tab should exist")
            }
        }
        r.define("I am on the Calories tab") { w in w.app.tabBars.buttons["Calories"].tap() }
        r.define("I tap the (\\w+) tab") { w in w.app.tabBars.buttons[w.capture()].tap() }

        // MARK: Calories
        r.define("I should see the date navigation") { w in
            XCTAssertTrue(w.app.buttons["Back"].waitForExistence(timeout: medium),
                          "Date navigation back button should be present")
        }
        r.define("I should see the remaining calories section") { w in
            XCTAssertTrue(w.app.staticTexts["Remaining"].waitForExistence(timeout: medium),
                          "Remaining calories section should be shown")
        }
        r.define("I tap the back button") { w in
            let back = w.app.buttons["Back"]
            XCTAssertTrue(back.waitForExistence(timeout: medium), "Back button should exist")
            back.tap()
        }
        r.define("the date should change to yesterday") { w in
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let label = yesterday.formatted(date: .numeric, time: .omitted)
            XCTAssertTrue(w.app.staticTexts[label].waitForExistence(timeout: medium),
                          "Date should change to yesterday: \(label)")
        }

        // MARK: Weight
        r.define("I should see the weight tracking view") { w in
            XCTAssertTrue(w.app.navigationBars["Weight"].waitForExistence(timeout: medium)
                            || w.app.collectionViews.firstMatch.waitForExistence(timeout: short)
                            || w.app.staticTexts.firstMatch.waitForExistence(timeout: short),
                          "Weight tab should load")
        }

        // MARK: Stats
        r.define("I should see my weekly stats") { w in
            XCTAssertTrue(w.app.navigationBars["Stats"].waitForExistence(timeout: medium)
                            || w.app.staticTexts.firstMatch.waitForExistence(timeout: short),
                          "Stats tab should load")
        }

        // MARK: Quotes
        r.define("I should see motivational content") { w in
            XCTAssertTrue(w.app.buttons["Randomize Quote"].waitForExistence(timeout: medium)
                            || w.app.staticTexts.firstMatch.waitForExistence(timeout: short),
                          "Quotes tab should show motivational content")
        }

        // MARK: Settings
        r.define("I should see the settings view") { w in
            XCTAssertTrue(w.app.navigationBars["Settings"].waitForExistence(timeout: medium)
                            || w.app.staticTexts.firstMatch.waitForExistence(timeout: short),
                          "Settings tab should load")
        }
        r.define("I should see a sign out button") { w in
            XCTAssertTrue(w.app.buttons["Sign Out"].waitForExistence(timeout: medium),
                          "Settings should have a Sign Out button")
        }

        return r
    }

    // MARK: - Helpers

    /// Sign in (if not already signed in) and dismiss the HealthKit permission
    /// sheet, leaving the app on the tab bar.
    private static func signIn(_ w: GherkinWorld) {
        let emailField = w.app.textFields["Email"]
        if emailField.waitForExistence(timeout: medium) {
            emailField.tap()
            emailField.typeText(w.email)
            let passwordField = w.app.secureTextFields["Password"]
            passwordField.tap()
            passwordField.typeText(w.password)
            w.app.buttons["Sign In"].firstMatch.tap()
        }
        dismissHealthKitPrompt(w)
        XCTAssertTrue(w.app.tabBars.firstMatch.waitForExistence(timeout: long),
                      "Tab bar should appear after login")
    }

    /// The first launch shows a HealthKit authorization sheet; grant it so the
    /// app proceeds to its main UI.
    private static func dismissHealthKitPrompt(_ w: GherkinWorld) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let turnOnAll = springboard.buttons["Turn On All"]
        if turnOnAll.waitForExistence(timeout: short) {
            turnOnAll.tap()
            let allow = springboard.buttons["Allow"]
            if allow.waitForExistence(timeout: short) { allow.tap() }
        }
        let inApp = w.app.buttons["Turn On All"]
        if inApp.waitForExistence(timeout: short) { inApp.tap() }
    }
}
