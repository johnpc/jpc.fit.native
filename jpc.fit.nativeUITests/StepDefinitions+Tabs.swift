import XCTest

/// Calories-tab steps: date navigation, remaining budget, quick adds.
enum CaloriesSteps {
    static func register(in r: StepRegistry) {
        r.define("I should see the date navigation") { w in
            XCTAssertTrue(w.app.buttons["Previous day"].waitForExistence(timeout: StepDefinitions.medium),
                          "Date navigation should be present")
        }
        r.define("I should see the remaining calories section") { w in
            XCTAssertTrue(w.app.staticTexts["Remaining"].waitForExistence(timeout: StepDefinitions.medium),
                          "Remaining calories section should be shown")
        }
        r.define("I tap the back button") { w in
            StepDefinitions.tap(w.app.buttons["Previous day"], "Previous day button")
        }
        r.define("the date should change to yesterday") { w in
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let label = yesterday.formatted(date: .numeric, time: .omitted)
            XCTAssertTrue(w.app.staticTexts[label].waitForExistence(timeout: StepDefinitions.medium),
                          "Date should change to yesterday: \(label)")
        }
        r.define("remaining calories should read \"(.+)\"") { w in
            XCTAssertTrue(StepDefinitions.reveal(w.app.staticTexts[w.capture()], in: w.app),
                          "Remaining should read \(w.capture())")
        }
        r.define("I tap the quick add \"(.+)\"") { w in
            StepDefinitions.tap(buttonContaining(w.capture(), in: w.app), "quick add \(w.capture())")
        }
        r.define("the food list should show \"(.+)\"") { w in
            XCTAssertTrue(StepDefinitions.reveal(buttonContaining(w.capture(), in: w.app), in: w.app),
                          "Food row “\(w.capture())” should be listed")
        }
    }

    /// Rows and tiles are Buttons whose accessibility label joins their texts.
    static func buttonContaining(_ text: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}

/// Weight-tab steps: the measurement prompt.
enum WeightSteps {
    static func register(in r: StepRegistry) {
        r.define("I enter \"(.+)\" in the prompt and save") { w in
            let field = w.app.alerts.textFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: StepDefinitions.medium), "Prompt text field should appear")
            StepDefinitions.type(w.capture(), into: field)
            StepDefinitions.tap(w.app.alerts.buttons["Save"], "Save")
        }
    }
}
