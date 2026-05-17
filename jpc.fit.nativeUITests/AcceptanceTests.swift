import XCTest

final class AcceptanceTests: XCTestCase {
    private var app: XCUIApplication!
    private var testEmail: String!
    private var testPassword: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        testEmail = ProcessInfo.processInfo.environment["TEST_EMAIL"] ?? loadEnv("TEST_EMAIL")
        testPassword = ProcessInfo.processInfo.environment["TEST_PASSWORD"] ?? loadEnv("TEST_PASSWORD")

        guard testEmail != nil, testPassword != nil else {
            throw XCTSkip("TEST_EMAIL and TEST_PASSWORD required for acceptance tests")
        }
    }

    private func loadEnv(_ key: String) -> String? {
        let paths = [
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { "\($0)/.env" },
            "/Users/johnpc/repo/jpc.fit.native/.env",
        ].compactMap { $0 }

        for envPath in paths {
            guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else { continue }
            for line in content.components(separatedBy: .newlines) {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2, String(parts[0]) == key {
                    return String(parts[1])
                }
            }
        }
        return nil
    }

    private func signIn() {
        app.launch()

        let emailField = app.textFields["Email"]
        if emailField.waitForExistence(timeout: 10) {
            emailField.tap()
            emailField.typeText(testEmail)

            let passwordField = app.secureTextFields["Password"]
            passwordField.tap()
            passwordField.typeText(testPassword)

            app.buttons["Sign In"].firstMatch.tap()
        } else if app.tabBars.firstMatch.waitForExistence(timeout: 5) {
            return
        }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "Tab bar should appear after login")
    }

    // MARK: - Feature: User Login

    @MainActor
    func testSuccessfulLogin() throws {
        signIn()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        XCTAssertTrue(tabBar.buttons.count >= 5, "Should have 5 tabs")
    }

    // MARK: - Feature: Calories Tab

    @MainActor
    func testCaloriesTabLoads() throws {
        signIn()
        app.tabBars.buttons["Calories"].tap()
        // Should see date navigation and remaining calories
        let hasContent = app.navigationBars.firstMatch.waitForExistence(timeout: 10)
            || app.staticTexts.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(hasContent, "Calories tab should show content")
    }

    // MARK: - Feature: Weight Tab

    @MainActor
    func testWeightTabLoads() throws {
        signIn()
        app.tabBars.buttons["Weight"].tap()
        let loaded = app.staticTexts["Weight"].waitForExistence(timeout: 5)
            || app.navigationBars["Weight"].waitForExistence(timeout: 2)
            || app.collectionViews.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(loaded, "Weight tab should load")
    }

    // MARK: - Feature: Stats Tab

    @MainActor
    func testStatsTabLoads() throws {
        signIn()
        app.tabBars.buttons["Stats"].tap()
        let loaded = app.staticTexts["Stats"].waitForExistence(timeout: 5)
            || app.navigationBars["Stats"].waitForExistence(timeout: 2)
            || app.collectionViews.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(loaded, "Stats tab should load")
    }

    // MARK: - Feature: Quotes Tab

    @MainActor
    func testQuotesTabLoads() throws {
        signIn()
        app.tabBars.buttons["Quotes"].tap()
        let loaded = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            || app.navigationBars.firstMatch.waitForExistence(timeout: 2)
        XCTAssertTrue(loaded, "Quotes tab should load")
    }

    // MARK: - Feature: Settings Tab

    @MainActor
    func testSettingsTabLoads() throws {
        signIn()
        app.tabBars.buttons["Settings"].tap()
        let loaded = app.staticTexts["Settings"].waitForExistence(timeout: 5)
            || app.navigationBars["Settings"].waitForExistence(timeout: 2)
        XCTAssertTrue(loaded, "Settings tab should load")
    }

    @MainActor
    func testSettingsHasSignOut() throws {
        signIn()
        app.tabBars.buttons["Settings"].tap()
        let signOut = app.buttons["Sign Out"].waitForExistence(timeout: 10)
        XCTAssertTrue(signOut, "Settings should have Sign Out button")
    }
}
