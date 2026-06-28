# jpc.fit.native

A native iOS health and calorie tracker (SwiftUI, iOS 26+). Tabs for **Calories**,
**Weight**, **Stats**, **Quotes**, and **Settings**, backed by AWS Amplify
(Cognito auth + AppSync GraphQL) with HealthKit integration, a Watch app, and a
home-screen widget.

## How we work together (read this first)

The person directing you may be **non-technical** — an "idea guy" who owns the
**product**. They define **WHAT**: features, intent, and Gherkin acceptance
scenarios. **You own the HOW**: architecture, code quality, testing, and every
technical decision below.

- **Never ask them to make a technical call.** Don't surface coverage numbers,
  CRAP, lint, file-length, or library choices as questions. Decide them yourself,
  to the standards in this file, silently.
- **Translate vague ideas into Gherkin.** When they describe a feature, propose
  concrete `.feature` scenarios (Given/When/Then) and confirm those — that's the
  spec you build to.
- **Only escalate genuine _product_ questions** — ambiguous behavior, scope, copy,
  what a screen should do. Those are theirs. Everything technical is yours.
- The standards here are the owner's, non-negotiable defaults. Apply them by
  default; you don't need permission to enforce them.

## Workflow: specs-first vertical slices

Every feature ships as one **thin vertical slice** — view + ViewModel/Service +
tests, just enough for the scenario, nothing speculative.

1. **Spec first.** Write/confirm Gherkin acceptance scenarios as real
   `.feature` files in `jpc.fit.nativeUITests/Features/` (the source of truth),
   executed by the native Swift runner (`GherkinParser` + `StepDefinitions` +
   `StepRegistry`). **Prefer reusing existing step phrasings** — each step must
   match exactly one definition in `StepDefinitions.swift`, so a near-duplicate
   line fails as undefined or ambiguous; a genuinely new phrasing needs a new
   definition there (its pattern is a regex — escape literals like `(` and `?`).
   Then regenerate **and commit** the concrete XCUITest methods
   (`AcceptanceTests.generated.swift`):
   `python3 scripts/generate_acceptance_tests.py`. See `AcceptanceTests.md` for
   the catalogue of scenarios.
2. **Implement to pass the spec** — follow the architecture and conventions below.
3. **Run the full quality gate** and get it green locally (`bash scripts/quality.sh`).
4. **Conventional commit, push, CI green.** Open a PR; CI blocks the merge.

## Stack

- **Client:** SwiftUI, iOS 26+, Swift 5.
- **Backend:** AWS Amplify — Cognito (auth, via the Authenticator UI) and AppSync
  GraphQL (foods, weights, heights, quick adds, preferences, HealthKit cache).
- **Health:** HealthKit for active/basal calories and steps.
- **Tests:** XCTest unit tests (`jpc.fit.nativeTests`, with `MockAPIService`) +
  Gherkin acceptance tests (`jpc.fit.nativeUITests`).

## Architecture (the one mental model that matters)

- **Views only render.** No data transformation, fetching, or business logic in a
  `View`. Those move to a `*ViewModel` (`ObservableObject`) or a `Service`.
- **ViewModels own state + side effects.** `FoodViewModel`, `WeightViewModel`,
  `StatsViewModel`, `SettingsViewModel` are `@MainActor ObservableObject`s. They
  talk to the API through `APIServiceProtocol` so they're testable against
  `MockAPIService`.
- **`APIService` is the network layer.** It wraps Amplify GraphQL queries/
  mutations and parsing behind `APIServiceProtocol`; inject the protocol, not the
  concrete type, so unit tests run without a backend.
- **Large types split by concern via extensions** — e.g. `APIService+Parsing`,
  `StatsViewModel+HealthKit`, `SettingsViewModel+Fetch`. Keeps every file small
  and single-purpose.

### Code organization (follow the existing shape)

- **`Views/`** — screens; **`Views/Components/`** — reusable subviews and sections.
- **`ViewModels/`** — `ObservableObject` state + logic, injectable deps.
- **`Services/`** — `APIService`, `HealthKitService`, `NotificationManager`, etc.
- **`Models/` / `Constants/`** — value types and static data.
- **`AmplifyModels/`** — generated; do not hand-edit, exempt from the gates.
- Tests under `jpc.fit.nativeTests/` (unit) and `jpc.fit.nativeUITests/` (Gherkin).

## Quality gates (non-negotiable — CI + pre-commit enforce them)

These are hard gates. **Enforce them yourself without asking** — when one fails, fix
the code, never the gate.

- **No force-unwraps in logic, no `as!`, no `try!` outside tests.** Handle the
  optional/error path. (Test fixtures may use `try!`/`!` for brevity.)
- **Every source file ≤ 100 lines** (`scripts/check_line_limit.sh`) — applies to
  **all** Swift files in the app target, not just views (generated `AmplifyModels`
  are exempt). Over the limit → extract a helper, a ViewModel/Service, or split by
  concern into an extension file. **Never raise the limit.**
- **≥ 80% line coverage** across the app target (`scripts/coverage_check.py`). Fix by
  **writing tests** — never by adding exclusions. 80% is a floor; push to 90%+.
- **CRAP ≤ 30 per function** (`scripts/crap_check.py`, decision-point based). Over →
  raise its coverage or reduce its complexity (extract the branchy bit into a tested
  helper).
- **Acceptance tests are always Gherkin** — real `.feature` files in
  `jpc.fit.nativeUITests/Features/`, executed by the native runner. Never ship a
  feature without its acceptance scenario. The concrete XCUITest methods are
  **generated** from the `.feature` files (`AcceptanceTests.generated.swift`); a
  gate (`scripts/generate_acceptance_tests.py --check`, in `quality.sh` and CI)
  fails if they drift, so regenerate after editing any `.feature` file.
- **Build must pass** for the app, unit, and UI-test targets.

### Honest e2e: exercise the real behavior, not just navigation

- An acceptance test must assert on **observable app behavior** (a control appears,
  the date changes, the Sign Out button shows), never merely that a tab is selected.
- These run against the **live backend** with the `TEST_EMAIL` / `TEST_PASSWORD`
  credentials (from the environment or a local `.env`), and grant the HealthKit
  permission prompt on first launch. Network-dependent assertions use generous
  waits and `XCTSkip` when credentials are absent, so CI stays green when the
  backend is unavailable — but offline-deterministic flows (tab nav, the Sign Out
  button, date navigation) are asserted **strictly**.
- A feature whose logic can be unit-tested deterministically (calorie math,
  streaks, parsing) **must** have those unit tests in addition to the Gherkin flow.
  The Gherkin proves the wiring; the unit tests prove the logic.

## Definition of done

A slice is done only when **all** of these hold:

1. Full quality gate green locally (`bash scripts/quality.sh`): line limit,
   coverage ≥80%, CRAP ≤30, build.
2. Gherkin acceptance Scenario(s) added as `.feature` files in
   `jpc.fit.nativeUITests/Features/` (generated methods regenerated), and
   colocated unit tests, all passing.
3. Conventional commit, branch pushed, PR open, **CI green**.

## Conventions

- **Conventional commits** (`feat:`, `fix:`, `chore:`, `ci:`, `docs:` …).
- Keep logic out of views — ViewModels/Services hold logic, views only render.
- Throwaway scripts go in `/tmp`, not the repo.
- Inject dependencies (`APIServiceProtocol`, `UserDefaults`) rather than reaching
  for singletons, so everything is testable.

## Commands

```bash
bash scripts/quality.sh          # full local gate: line limit + gherkin sync + tests + coverage + CRAP + build
bash scripts/install-hooks.sh    # install the pre-commit hook
python3 scripts/generate_acceptance_tests.py        # regenerate after editing .feature files
# Run tests directly:
xcodebuild test -scheme jpc.fit.native -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:jpc.fit.nativeTests -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
```

## Key facts

- **Repo:** `johnpc/jpc.fit.native`. iOS bundle id `com.johncorser.fit`.
- **CI:** `.github/workflows/quality-gates.yml` blocks PRs (build, line limit,
  unit tests + coverage, CRAP, Gherkin acceptance) and deploys to App Store Connect
  on push to `main`. Repo secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`,
  `TEAM_ID`, `TEST_EMAIL`, `TEST_PASSWORD`.
