import XCTest

/// Acceptance runner. The **source of truth is the `.feature` files** under
/// `jpc.fit.nativeUITests/Features/`. Each scenario maps to one concrete `test…`
/// method in `AcceptanceTests.generated.swift` (regenerated from the features by
/// `scripts/generate_acceptance_tests.py`). Every generated method delegates to
/// `runScenario(feature:scenario:)` below, which parses that feature at runtime
/// and executes its Given/When/Then steps against the definitions in
/// `StepDefinitions.swift`.
///
/// Why generated concrete methods instead of a fully dynamic suite: XCTest's
/// `-only-testing` filtering and crash-recovery both work by selector name, so
/// real methods are required for CI's targeted retry and for clean crash
/// recovery. The `.feature` files remain the only thing an author edits; the
/// generated file is mechanical and kept in sync by a quality gate.
///
/// These are real end-to-end tests against the live backend: sign-in uses the
/// `TEST_EMAIL` / `TEST_PASSWORD` credentials (read from the environment or a
/// local `.env`), exposed to steps via `GherkinWorld`.
final class AcceptanceTests: XCTestCase {

    /// Parse the named bundled feature file, find the scenario, and run its steps.
    func runScenario(feature fileName: String, scenario name: String,
                     file: StaticString = #file, line: UInt = #line) throws {
        continueAfterFailure = false

        let email = ProcessInfo.processInfo.environment["TEST_EMAIL"] ?? Self.loadEnv("TEST_EMAIL")
        let password = ProcessInfo.processInfo.environment["TEST_PASSWORD"] ?? Self.loadEnv("TEST_PASSWORD")
        guard let email, let password else {
            throw XCTSkip("TEST_EMAIL and TEST_PASSWORD required for acceptance tests")
        }

        guard let scenario = Self.scenario(named: name, inFeature: fileName) else {
            XCTFail("Scenario “\(name)” not found in \(fileName) — regenerate with scripts/generate_acceptance_tests.py",
                    file: file, line: line)
            return
        }

        let app = XCUIApplication()
        app.launch()

        let world = GherkinWorld(app: app)
        world.email = email
        world.password = password
        let registry = StepDefinitions.makeRegistry()

        for step in scenario.steps {
            XCTContext.runActivity(named: "\(step.keyword) \(step.text)") { _ in
                if registry.isAmbiguous(step.text) {
                    XCTFail("Ambiguous step matches multiple definitions: “\(step.text)” (\(name):\(step.line))",
                            file: file, line: line)
                    return
                }
                guard let run = registry.match(step.text) else {
                    XCTFail("Undefined step: “\(step.text)” — add a matching definition in StepDefinitions.swift (\(name):\(step.line))",
                            file: file, line: line)
                    return
                }
                run(world)
            }
        }
    }

    /// Locate and parse a scenario by name in a bundled `.feature` file. The file
    /// may be bundled flattened at the root or under a "Features" subdirectory.
    private static func scenario(named name: String, inFeature fileName: String) -> GherkinScenario? {
        let bundle = Bundle(for: AcceptanceTests.self)
        let resource = (fileName as NSString).deletingPathExtension
        let url = bundle.url(forResource: resource, withExtension: "feature")
            ?? bundle.url(forResource: resource, withExtension: "feature", subdirectory: "Features")
        guard let url, let contents = try? String(contentsOf: url, encoding: .utf8),
              let feature = GherkinParser.parse(contents) else { return nil }
        return feature.scenarios.first { $0.name == name }
    }

    /// Read a key from a local `.env` file (used when the value isn't in the
    /// process environment, e.g. running from Xcode rather than CI).
    private static func loadEnv(_ key: String) -> String? {
        let paths = [
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { "\($0)/.env" },
            FileManager.default.currentDirectoryPath + "/.env",
        ].compactMap { $0 }

        for envPath in paths {
            guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else { continue }
            for line in content.components(separatedBy: .newlines) {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2, String(parts[0]) == key {
                    return String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
}
