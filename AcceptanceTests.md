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

### Backend

Every scenario launches the app with `--demo`: the in-process fake backend
(`DemoAPIService`, seeded by `DemoSeed`), zero network, deterministic data. The
sign-in step types demo credentials into the demo sign-in form, whose labels
match Amplify's Authenticator so the same steps drive both backends. Scenarios
that assert on seed numbers are tagged `@demo-data`.

To drive the same scenarios against the live backend by hand set
`FIT_E2E_BACKEND=live` plus `TEST_EMAIL` / `TEST_PASSWORD` (environment or a
local `.env`); the live app's HealthKit permission prompt is granted on first
launch. `@demo-data` scenarios are skipped there (and only there) because the
numbers they assert do not exist on a real account. CI always runs demo.

Every wait is a real condition (`waitForExistence`, expectations) — never a
sleep — and every assertion is strict. A scenario that fails intermittently is
a bug to fix, never to retry (see README "There is no such thing as a flaky
test"); CI runs the suite exactly once.

## Scenario catalogue

- **User Login** (`login.feature`) — successful login lands on Calories with all 5 tabs;
  empty credentials are rejected with an explanation.
- **Calories Tab** (`calories.feature`) — today's food list (date nav + remaining
  calories); navigating to the previous day; a quick add logs a food instantly and
  the remaining budget drops.
- **Weight Tab** (`weight.feature`) — BMI and range sections; saving a new weight.
- **Stats Tab** (`stats.feature`) — weekly stats load; the streak counts every
  tracked day including today.
- **Quotes Tab** (`quotes.feature`) — the Randomize Quote button and header show.
- **Settings Tab** (`settings.feature`) — New Quick Add and Sign Out buttons; signing
  out returns to the sign-in screen.
