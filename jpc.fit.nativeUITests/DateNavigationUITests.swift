import XCTest

final class DateNavigationUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testDateNavigationBackward() throws {
        sleep(2)
        
        // Handle HealthKit permission sheet
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let turnOnAll = springboard.buttons["Turn On All"]
        if turnOnAll.waitForExistence(timeout: 3) {
            turnOnAll.tap()
            sleep(1)
            let allow = springboard.buttons["Allow"]
            if allow.exists { allow.tap() }
            sleep(1)
        }
        
        let turnOnAllApp = app.buttons["Turn On All"]
        if turnOnAllApp.waitForExistence(timeout: 2) {
            turnOnAllApp.tap()
            sleep(1)
        }
        
        sleep(2)
        
        // Find today's date
        let today = Date().formatted(date: .numeric, time: .omitted)
        let dateText = app.staticTexts[today]
        XCTAssertTrue(dateText.waitForExistence(timeout: 10), "Should show today's date: \(today)")
        
        print("Before tap - date shown: \(today)")
        add(XCTAttachment(screenshot: app.screenshot()))
        
        // The chevron.left SF Symbol has accessibility label "Back"
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.exists, "Back button should exist")
        print("Back button exists: \(backButton.exists)")
        print("Back button is hittable: \(backButton.isHittable)")
        
        backButton.tap()
        sleep(2)
        
        add(XCTAttachment(screenshot: app.screenshot()))
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayString = yesterday.formatted(date: .numeric, time: .omitted)
        
        print("After tap - looking for: \(yesterdayString)")
        print("=== STATIC TEXTS AFTER TAP ===")
        for st in app.staticTexts.allElementsBoundByIndex {
            print("StaticText: '\(st.label)'")
        }
        
        XCTAssertTrue(app.staticTexts[yesterdayString].exists, "Should show yesterday: \(yesterdayString), but still shows: \(app.staticTexts.element(boundBy: 2).label)")
    }
}
