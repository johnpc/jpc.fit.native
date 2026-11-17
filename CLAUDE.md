# jpc.fit.native

A native iOS health and calorie tracker (SwiftUI, iOS 17+). Tabs for **Calories**,
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

- **Client:** SwiftUI, iOS 17+ (deployment target), Swift 5.
- **Backend:** AWS Amplify — Cognito (auth, via the Authenticator UI) and AppSync
  GraphQL (foods, weights, heights, quick adds, preferences, HealthKit cache).
  **Demo mode** (`--demo` launch argument) swaps in the in-process fake backend
  (`Services/Demo/`, `Core/DemoSession`) — no network, no account; it is what
  the acceptance suite and CI run on. See README "Demo mode".
- **Health:** HealthKit for active/basal calories and steps (behind
  `HealthStatsProviding`; demo mode returns fixed numbers, no prompt).
- **Tests:** XCTest unit tests (`jpc.fit.nativeTests`, with `MockAPIService`) +
  Gherkin acceptance tests (`jpc.fit.nativeUITests`, demo backend).
- **Operating manual:** [AGENTS.md](AGENTS.md) — no flaky tests, one owner per
  state machine ([docs/state-machines.md](docs/state-machines.md)), the fake
  backend, verification on the Mac mini.

## Architecture (the one mental model that matters)

- **Views only render.** No data transformation, fetching, or business logic in a
  `View`. Those move to a `*ViewModel` (`ObservableObject`) or a `Service`.
- **ViewModels own state + side effects.** `FoodViewModel`, `WeightViewModel`,
  `StatsViewModel`, `SettingsViewModel` are `@MainActor ObservableObject`s. They
  talk to the API through `APIServiceProtocol` so they're testable against
  `MockAPIService`. Dependencies default from `Core/AppServices` (the
  composition root), which is the only place logic meets Amplify/HealthKit.
- **`APIService` is the network layer.** It wraps Amplify GraphQL queries/
  mutations and parsing behind `APIServiceProtocol`; inject the protocol, not the
  concrete type, so unit tests run without a backend. `DemoAPIService` is the
  same protocol over in-memory tables.
- **State is an enum, not a set of flags.** A mode is ONE value written in ONE
  place; views switch over it. Every machine is a row in
  `docs/state-machines.md` with its owner and tests, gate-checked by
  `scripts/check_state_machines.py`. Before adding a boolean, an optional that
  can mean two things, or a `show*` flag, find (or add) its row.
- **Large types split by concern via extensions** — e.g. `APIService+Parsing`,
  `StatsViewModel+HealthKit`, `SettingsViewModel+Fetch`. Keeps every file small
  and single-purpose.

### Code organization (follow the existing shape)

- **`Views/`** — screens; **`Views/Components/`** — reusable subviews and sections.
- **`ViewModels/`** — `ObservableObject` state + logic, injectable deps.
- **`Services/`** — `APIService`, `HealthKitService`, `NotificationManager`, etc.
- **`Models/` / `Constants/`** — value types, the state enums, and static data.
- **`Core/`** — `AppMode`, `AppServices` (composition root), `DemoSession`, seams.
- **`Shared/`** — pure types compiled into BOTH the iOS app and the Watch app
  (the watch wire protocol and status enums).
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
- **No dead code** (`scripts/dead_code_check.py`) — unreferenced declarations fail;
  delete them (runtime entry points live in the script's `ENTRY_POINTS`).
- **No duplicated blocks** (`scripts/duplication_check.py`) — a repeated 6-line
  normalized block fails; extract a shared helper.
- **No `Any`/`AnyObject`** (`scripts/banned_types_check.py`) — `[String: Any]` is
  allowed only as Amplify/WCSession bridging; everything else needs a concrete type.
- **Halstead difficulty ≤ 20 per function** (`scripts/halstead_check.py`) — split
  dense expressions into named intermediate steps.
- **State-machine catalog in sync** (`scripts/check_state_machines.py`) — every
  `/// StateMachine:` marker has a row in `docs/state-machines.md` and vice
  versa; no `*Status: String`, no two `show*` flags per file, no `show*` flag
  next to a `*Message: String?`. Fix by modelling the enum, never by deleting
  the row.
- **Acceptance tests are always Gherkin** — real `.feature` files in
  `jpc.fit.nativeUITests/Features/`, executed by the native runner. Never ship a
  feature without its acceptance scenario. The concrete XCUITest methods are
  **generated** from the `.feature` files (`AcceptanceTests.generated.swift`); a
  gate (`scripts/generate_acceptance_tests.py --check`, in `quality.sh` and CI)
  fails if they drift, so regenerate after editing any `.feature` file.
- **Build must pass** for the app, unit, and UI-test targets.

### Honest e2e: exercise the real behavior, not just navigation

- An acceptance test must assert on **observable app behavior** (a control appears,
  the date changes, the remaining budget drops), never merely that a tab is selected.
- These run against the **demo backend** (`--demo`): deterministic seed, zero
  network, so every assertion is **strict** and every wait is a real condition
  (`waitForExistence`), never a sleep. CI runs the suite exactly once — there is
  no retry loop, and a test that fails intermittently is a race to fix, never to
  re-run, skip or loosen (AGENTS.md §1). `FIT_E2E_BACKEND=live` drives the same
  scenarios against the real backend by hand; `@demo-data` scenarios skip there.
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
- **CI:** `.github/workflows/quality-gates.yml` runs on the self-hosted Mac mini
  and blocks PRs (build, line limit, static gates, unit tests + coverage, CRAP,
  Gherkin acceptance on the demo backend) and deploys to App Store Connect on
  push to `main`. Repo secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`,
  `TEAM_ID`, `CI_KEYCHAIN_PASSWORD`. (`TEST_EMAIL` / `TEST_PASSWORD` are only for
  manual live runs.)

## Decisions log

- **2026-11-16** Implicit state machines made explicit (director: "find all the
  implicit state machines; elevate UX, DX and AX without breaking anything").
  Surveyed the whole app and watch; 22 machines catalogued in
  `docs/state-machines.md` (owner + tests per row, gate-checked by
  `scripts/check_state_machines.py`). Converted: **Streak**
  (`computing/known/unavailable` — a failed first walk used to show
  "Calculating streak..." forever), **Preferences record**
  (`unknown/missing/stored` — a toggle after a failed fetch CREATED a duplicate
  row), **Reminders** (`unknown/notRequested/userDisabled/osDenied/enabled` —
  "denied in iOS Settings" now shows an Open Settings shortcut instead of a dead
  Enable button), **Day record**, **Off-screen refresh** (three view flags →
  `RefreshGate` in the VM), **Weight toast** (one optional, VM-owned timer),
  **Measurement prompt**, **Food sheet** + `FoodDraft`, **Quick-add sheet** +
  `QuickAddDraft` (validation/naming out of the views), **Food list**, **Quote
  bag**, and on the watch **Watch health source** / **Phone link** (were
  `String`s) plus the `WatchCommand`/`WatchSnapshot` wire codec compiled into
  both targets. **Fake backend:** `AppMode` (`--demo`) + `AppServices` swap the
  API/HealthKit/auth seams to `DemoAPIService`/`DemoHealthStats`/`DemoSession`;
  `WeightViewModel` and `SettingsViewModel` now read through
  `APIServiceProtocol` (extended with weights/heights/quick-add/preferences
  writes) and are unit-covered — removed from the coverage exclusions. The
  acceptance suite runs on the demo backend with strict assertions and no
  credentials; the CI retry loop and `sleep`s are gone (no flaky tests —
  README/AGENTS.md). Verified on the Mac mini: quality gate, unit + acceptance
  suites, screenshots and a screen recording of the demo flows (see the PR).
