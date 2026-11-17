# AGENTS.md — how agents (and humans) work in jpc.fit

Read [CLAUDE.md](CLAUDE.md) first: it is the charter, the architecture and the
quality gates. This file is the operating manual on top of it.

## 1. There is no such thing as a flaky test

A test that passes sometimes is a failing test. When a unit test, a Gherkin
scenario or a gate fails intermittently:

1. **Do not re-run to green.** CI runs the acceptance suite once — the retry
   loop was deleted on purpose. Pull the `.xcresult` artifact and find the race.
2. **Fix the race, not the symptom.** Wait on a real condition — an element
   exists (`waitForExistence`), an expectation is fulfilled, an awaited task
   finishes — never on `sleep`, `DispatchQueue.asyncAfter`, a longer timeout or
   a "settle" delay. If the race is in the app, fix the app.
3. **Pin it.** Put the deterministic wait in the shared harness
   (`jpc.fit.nativeUITests/StepDefinitions*.swift`) so every scenario inherits
   it; add a unit test when the race is in logic.
4. **Never loosen.** No raised timeouts "to be safe", no `XCTSkip` to hide a
   failure, no quarantine, no `continue-on-error`. The gate stays; the code
   moves. The same applies to every threshold in `scripts/`.

What makes this possible — keep these seams intact:
- `APIServiceProtocol` (every ViewModel), `HealthStatsProviding`,
  `AuthServiceProtocol`, `NotificationCenterProviding`: unit tests use
  `jpc.fit.nativeTests/Mocks/*`, never the framework.
- The acceptance suite launches the app with `--demo` (`E2EBackend`), so it
  runs on the in-process `DemoAPIService` with a deterministic seed. A scenario
  that asserts on seed numbers is tagged `@demo-data`.

## 2. State machines: one mode, one owner

Every mode the app can be in is a row in
[docs/state-machines.md](docs/state-machines.md): its states, the ONE file
that owns the transitions, and its tests. `scripts/check_state_machines.py`
(in `quality.sh` and CI) fails when a cited owner or test goes missing, when a
`/// StateMachine: <row>` marker and its row disagree, or when a new implicit
machine appears (a `*Status: String`, two `show*` booleans in one file, a
`show*` flag next to a `*Message: String?`).

Before adding a boolean, an optional that means two things, or a second
`show*` flag, ask: which machine is this part of? Add the case to its enum and
the transition to its owner. If the machine is not in the catalog, add a row
(status `implicit`) first, then convert.

## 3. The fake backend

`Core/AppMode` picks `live` or `demo` once at launch; `Core/AppServices`
swaps the API, HealthKit and auth seams together. `Services/Demo/` is the
backend: `DemoSeed` (data generated around "now"), `DemoAPIService` (the full
protocol over in-memory tables), `DemoHealthStats` (fixed burn), and
`Core/DemoSession` (sign-in with any non-blank credentials). Nothing downstream
is special-cased. Seed numbers the acceptance suite depends on: today 500 cal
eaten / 2170 burned (remaining 1670), streak 13, weight 182 lbs, quick adds
Coffee / Salad / Pizza slice.

The live backend is only ever driven by hand:
`FIT_E2E_BACKEND=live TEST_EMAIL=… TEST_PASSWORD=…`.

## 4. Verification happens on the Mac mini

The Mac mini (`johns-Mac-Mini.local`, user `john`) is the CI runner and the
box with Xcode and the iOS Simulator (`iPhone 17 Pro`). Treat it as shared CI
infrastructure: no `sudo`, no global installs, never touch
`~/actions-runner-*/_work` or `~/ci-cache`, check `pgrep -fl Runner.Worker ||
echo idle` before a long run, run long commands detached (`nohup … >
/tmp/x.log`) and read the log.

```sh
# sync the work tree (never .git / build output)
rsync -az --delete --exclude .git --exclude DerivedData --exclude build \
  --exclude TestResults.xcresult --exclude coverage.json ./ john@johns-Mac-Mini.local:~/repo/jpc.fit.native/

# on the mini: gate, acceptance suite, and LOOK at the result
bash scripts/quality.sh
xcodebuild test -scheme jpc.fit.native -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:jpc.fit.nativeUITests/AcceptanceTests
xcrun simctl launch booted com.johncorser.fit --demo
xcrun simctl io booted screenshot /tmp/calories.png
xcrun simctl io booted recordVideo /tmp/flow.mp4      # Ctrl-C (SIGINT) to stop
```

A UI change is not done until you have looked at it: take the screenshots or
the recording of the real app flow, judge the UX honestly, and attach them to
the PR. Commit and push from your own machine (the mini has no `gh` and no
git identity).
