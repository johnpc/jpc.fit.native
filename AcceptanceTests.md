# Acceptance Tests

Acceptance tests are **Gherkin**. The source of truth is the `.feature` files in
[`jpc.fit.nativeUITests/Features/`](jpc.fit.nativeUITests/Features/) — this file
is just a human-readable catalogue of what they cover.

## How it works

```
jpc.fit.nativeUITests/
  Features/*.feature              ← source of truth (edit these)
  GherkinParser.swift             ← tiny dependency-free .feature parser
  StepRegistry.swift              ← regex-matched step registry + GherkinWorld
  StepDefinitions.swift           ← Given/When/Then → XCUITest actions/assertions
  AcceptanceTests.swift           ← runScenario(feature:scenario:) runner
  AcceptanceTests.generated.swift ← @generated concrete test_… methods (committed)
```

Each `Scenario` in a `.feature` file becomes one concrete XCUITest method (so
`-only-testing` filtering and crash recovery work by selector name). Those
methods are **generated** — never hand-edit `AcceptanceTests.generated.swift`.

### Adding or changing a scenario

1. Edit/add a `.feature` file under `jpc.fit.nativeUITests/Features/`.
2. Reuse existing step phrasings where possible; a genuinely new line needs a
   matching definition in `StepDefinitions.swift` (its pattern is a regex).
3. Regenerate and commit the methods:
   `python3 scripts/generate_acceptance_tests.py`
4. A quality gate (`--check`, in `scripts/quality.sh` and CI) fails if the
   generated file drifts from the `.feature` files.

The app signs in with the `TEST_EMAIL` / `TEST_PASSWORD` credentials (from the
environment or a local `.env`) and grants the HealthKit permission prompt on
first launch.

## Scenario catalogue

- **User Login** (`login.feature`) — successful login lands on Calories with all 5 tabs.
- **Calories Tab** (`calories.feature`) — today's food list (date nav + remaining
  calories); navigating to the previous day.
- **Weight Tab** (`weight.feature`) — the weight tracking view loads.
- **Stats Tab** (`stats.feature`) — weekly stats load.
- **Quotes Tab** (`quotes.feature`) — motivational content shows.
- **Settings Tab** (`settings.feature`) — settings view with a Sign Out button.
