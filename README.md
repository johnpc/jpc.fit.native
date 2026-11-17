# jpc.fit (native iOS)

A native iOS health and calorie tracker (SwiftUI, iOS 17+). Tabs for
**Calories**, **Weight**, **Stats**, **Quotes** and **Settings**, backed by AWS
Amplify (Cognito auth + AppSync GraphQL), with HealthKit integration, a Watch
app and a home-screen widget.

- Product charter, architecture and quality gates: [CLAUDE.md](CLAUDE.md)
- Operating rules for agents and humans: [AGENTS.md](AGENTS.md)
- Every mode the app can be in, and who owns it: [docs/state-machines.md](docs/state-machines.md)
- Acceptance scenarios (Gherkin): [AcceptanceTests.md](AcceptanceTests.md)

## Build and run

```sh
open jpc.fit.native.xcodeproj          # scheme jpc.fit.native, any iPhone simulator
bash scripts/quality.sh                # the full local gate (what CI and pre-commit run)
bash scripts/install-hooks.sh          # one-time: pre-commit gate
```

### Demo mode: the fake backend

The app has an in-process fake backend. Launch with the `--demo` argument (or
`FIT_DEMO=1` in the environment) and nothing touches the network: no Cognito,
no AppSync, no HealthKit prompt.

- `Core/AppMode.swift` decides `live` vs `demo` once at launch;
  `Core/AppServices.swift` swaps **every** seam together — the API
  (`Services/Demo/DemoAPIService.swift`), HealthKit (`DemoHealthStats`) and
  auth (`Core/DemoSession.swift`, a sign-in form that accepts any non-blank
  email + password). Everything downstream is the real production code path.
- The seed (`Services/Demo/DemoSeed.swift`) is generated around "now" so it is
  never stale and always the same shape: today has two meals (500 cal), the 12
  days before are tracked (streak = 13 with today), every day has a 2170 cal
  burn, one weight (182 lbs) and three quick adds.
- Writes behave like the real backend (ids come back, rows persist for the
  process), so optimistic UI, rollbacks and re-keying are exercised for real.

This is what the acceptance suite and CI run against — CI never needs the
production server or an account. It is also the way to try the app without
one: in Xcode, Product → Scheme → Edit Scheme → Arguments → `--demo`.

## Tests

```sh
# Unit tests (XCTest, MockAPIService) — the gate also enforces ≥80% coverage
xcodebuild test -scheme jpc.fit.native -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:jpc.fit.nativeTests

# Acceptance tests (Gherkin .feature files → XCUITest), against the demo backend
xcodebuild test -scheme jpc.fit.native -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:jpc.fit.nativeUITests/AcceptanceTests

# The same scenarios against the live backend, by hand (never in CI):
FIT_E2E_BACKEND=live TEST_EMAIL=… TEST_PASSWORD=… xcodebuild test … -only-testing:jpc.fit.nativeUITests/AcceptanceTests

# Cold-launch timing of the demo build (reported, not gated)
xcodebuild test … -only-testing:jpc.fit.nativeUITests/LaunchPerformanceTests
```

## There is no such thing as a flaky test

A test that passes sometimes is a failing test. When a unit test, an
acceptance scenario or a gate fails intermittently — locally or in CI:

1. **Do not re-run it to green.** CI has no retry loop on purpose. Read the
   failure (the `.xcresult` is uploaded as an artifact) and find the race.
2. **Fix the cause, not the symptom.** Wait on a real condition
   (`waitForExistence`, an `XCTestExpectation`, an awaited task), never on a
   `sleep`, a longer timeout or a "settle" delay. If the race is in the app,
   fix the app.
3. **Never loosen.** No raised timeouts "to be safe", no `XCTSkip` to hide a
   failure, no quarantined tests, no `continue-on-error`, no threshold moved.
4. **Keep the seams that make this possible:** every ViewModel reads through
   `APIServiceProtocol`, HealthKit through `HealthStatsProviding`, auth through
   `AuthServiceProtocol`, notifications through `NotificationCenterProviding`;
   the acceptance suite runs on the deterministic demo backend. A test that
   needs the real network, the real clock or a real device is a test with a
   missing seam.

The same rule applies to the quality gates: thresholds never move; the code
does.

## Quality gates

`bash scripts/quality.sh` runs, in order: the 100-line file limit, Gherkin
sync, dead code, duplication, banned `Any`, Halstead ≤ 20, the state-machine
catalog, unit tests, coverage ≥ 80%, CRAP ≤ 30, and a clean build. CI
(`.github/workflows/quality-gates.yml`, on the self-hosted Mac mini) runs the
same plus the acceptance suite, then deploys `main` to App Store Connect.
