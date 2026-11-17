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
/// real methods are required for clean crash recovery. The `.feature` files
/// remain the only thing an author edits; the generated file is mechanical and
/// kept in sync by a quality gate.
///
/// Backend: by default every scenario launches the app in DEMO mode — the
/// in-process fake backend (`DemoAPIService`), zero network, deterministic seed
/// — so the suite passes identically on a laptop, the Mac mini and CI. Set
/// `FIT_E2E_BACKEND=live` (plus `TEST_EMAIL` / `TEST_PASSWORD`) to drive the
/// same scenarios against the real Cognito + AppSync backend by hand.
final class AcceptanceTests: XCTestCase {

    /// Parse the named bundled feature file, find the scenario, and run its steps.
    func runScenario(feature fileName: String, scenario name: String,
                     file: StaticString = #file, line: UInt = #line) throws {
        continueAfterFailure = false

        guard let scenario = Self.scenario(named: name, inFeature: fileName) else {
            XCTFail("Scenario “\(name)” not found in \(fileName) — regenerate with scripts/generate_acceptance_tests.py",
                    file: file, line: line)
            return
        }

        let backend = try E2EBackend.fromEnvironment()
        if scenario.tags.contains("@demo-data"), case .live = backend {
            // Asserts on the demo seed's exact numbers; meaningless against a
            // real account. Never skipped in CI, which always runs demo.
            throw XCTSkip("“\(name)” asserts on demo-seed data; FIT_E2E_BACKEND=live has none")
        }
        let app = XCUIApplication()
        app.launchArguments += backend.launchArguments
        app.launch()

        let world = GherkinWorld(app: app, backend: backend)
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
}
