import XCTest

/// All Given/When/Then step definitions, mapping Gherkin lines to XCUITest
/// actions/assertions. Keywords are interchangeable at match time, so each step
/// is registered once regardless of whether specs phrase it as Given/When/Then.
///
/// Every wait is a real condition (`waitForExistence`, an expectation on the
/// element) — never a sleep. Every assertion is strict: the suite runs against
/// the deterministic demo backend, so there is nothing to be tolerant about.
enum StepDefinitions {

    static let medium: TimeInterval = 10
    static let long: TimeInterval = 20

    static func makeRegistry() -> StepRegistry {
        let r = StepRegistry()

        // MARK: Lifecycle / sign-in
        r.define("the app is launched") { _ in }
        r.define("I sign in with valid credentials") { w in signIn(w) }
        r.define("I am signed in") { w in signIn(w) }
        r.define("I tap Sign In without entering credentials") { w in
            tap(w.app.buttons["Sign In"], "Sign In button")
        }
        r.define("I should see the sign-in screen") { w in
            XCTAssertTrue(w.app.textFields["Email"].waitForExistence(timeout: long), "Email field should be shown")
        }

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
        r.define("I am on the Calories tab") { w in tap(w.app.tabBars.buttons["Calories"], "Calories tab") }
        r.define("I tap the (\\w+) tab") { w in tap(w.app.tabBars.buttons[w.capture()], "\(w.capture()) tab") }

        // MARK: Generic
        r.define("I should see \"(.+)\"") { w in
            XCTAssertTrue(reveal(w.app.staticTexts[w.capture()], in: w.app), "Expected text “\(w.capture())”")
        }
        r.define("I should see the \"(.+)\" button") { w in
            XCTAssertTrue(reveal(w.app.buttons[w.capture()], in: w.app), "Expected button “\(w.capture())”")
        }
        r.define("I tap the \"(.+)\" button") { w in tap(w.app.buttons[w.capture()], "\(w.capture()) button") }

        CaloriesSteps.register(in: r)
        WeightSteps.register(in: r)
        return r
    }

    // MARK: - Helpers

    /// Lists and grids are lazy: a row below the fold is not in the hierarchy
    /// at all. Look for the element where we are, then page down, then back
    /// up — each probe is a bounded `waitForExistence`, never a sleep.
    @discardableResult
    static func reveal(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if element.waitForExistence(timeout: medium) && isVisible(element, in: app) { return true }
        for _ in 0..<3 {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) && isVisible(element, in: app) { return true }
        }
        for _ in 0..<6 {
            app.swipeDown()
            if element.waitForExistence(timeout: 1) && isVisible(element, in: app) { return true }
        }
        return element.exists
    }

    /// On screen, judged from the element's frame. NOT `isHittable`: for a row
    /// that is mid-insert or scrolled under the tab bar, `isHittable` itself
    /// fails the test ("Activation point invalid and no suggested hit points",
    /// seen in CI on PR #21) instead of returning false.
    static func isVisible(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        let frame = element.frame
        let window = app.windows.firstMatch.frame
        return !frame.isEmpty && window.contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    /// Reveal the element (scrolling if the list has it off screen), then tap.
    static func tap(_ element: XCUIElement, _ what: String) {
        XCTAssertTrue(reveal(element, in: XCUIApplication()), "\(what) should exist")
        element.tap()
    }

    /// Sign in (if not already signed in) and, on the live backend only,
    /// grant the HealthKit permission sheet — leaving the app on the tab bar.
    private static func signIn(_ w: GherkinWorld) {
        let emailField = w.app.textFields["Email"]
        if emailField.waitForExistence(timeout: medium) {
            type(w.email, into: emailField)
            type(w.password, into: passwordField(in: w.app))
            w.app.buttons["Sign In"].firstMatch.tap()
        }
        if w.backend.showsHealthKitPrompt { dismissHealthKitPrompt(w) }
        XCTAssertTrue(w.app.tabBars.firstMatch.waitForExistence(timeout: long),
                      "Tab bar should appear after login")
    }

    /// Typing into a field that has not yet taken keyboard focus is the
    /// classic XCUITest race ("Neither element nor any descendant has keyboard
    /// focus"). Tap, then WAIT for focus — and if the tap was swallowed by a
    /// layout/transition animation (observed: focus never arrives), tap once
    /// more and log it, so the rate stays visible.
    static func type(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: medium), "field should exist before typing")
        field.tap()
        if !waitForKeyboardFocus(field) {
            NSLog("[harness] tap on \(field) did not focus it; tapping again")
            field.tap()
            XCTAssertTrue(waitForKeyboardFocus(field), "field never took keyboard focus")
        }
        field.typeText(text)
    }

    private static func waitForKeyboardFocus(_ field: XCUIElement) -> Bool {
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: field)
        return XCTWaiter().wait(for: [focused], timeout: medium) == .completed
    }

    /// Amplify's Authenticator uses a secure field; the demo form a plain one
    /// (a secure field makes iOS offer to save the fake password).
    static func passwordField(in app: XCUIApplication) -> XCUIElement {
        let secure = app.secureTextFields["Password"]
        return secure.exists ? secure : app.textFields["Password"]
    }

    /// The live app's first launch shows a HealthKit authorization sheet;
    /// grant it so the app proceeds to its main UI.
    private static func dismissHealthKitPrompt(_ w: GherkinWorld) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let turnOnAll = springboard.buttons["Turn On All"]
        if turnOnAll.waitForExistence(timeout: medium) {
            turnOnAll.tap()
            let allow = springboard.buttons["Allow"]
            if allow.waitForExistence(timeout: medium) { allow.tap() }
        }
    }
}
