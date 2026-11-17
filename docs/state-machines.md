# State machines in jpc.fit

Every "mode" the app can be in is a state machine, whether or not the code
calls it one. This catalog is the single list of them: what the states are,
which file OWNS the transitions, and how each is tested. It serves three
readers at once — the user (every row is something they can see or feel),
the developer (one place to look before adding a flag) and the agent (the
owner/test paths and the `/// StateMachine:` markers are machine-checked by
`scripts/check_state_machines.py`, part of `scripts/quality.sh` and CI, so a
renamed or deleted owner fails the gate instead of rotting here).

## The rule

**One mode, one owner.** A mode is ONE value (an enum with payloads), written
in ONE place, and every reader derives from it instead of keeping its own
copy. Concretely:

- No boolean + optional pairs that only mean something together
  (`showToast` + `toastMessage`, `isLoading` + `streakDays == nil`). Fold them
  into an enum whose cases carry their data.
- No prose as state (`authStatus = "HK: 300+1500"`). Name the states; render
  the label from the enum.
- No two presentation flags that can both be true (`showingAddFood` +
  `editingFood != nil`). One optional enum per presentation slot.
- `nil` may mean exactly one thing. If it can mean two ("not loaded" and
  "does not exist"), it is an enum (`PreferencesRecord`).
- Every transition the user can trigger has a unit test; the ones they can
  see have a Gherkin scenario.

When you find an implicit machine, add it here first (status `implicit`),
then convert it. Adding a row costs one line; it is never wrong to add one.

Status legend: `explicit` = enum state + single owner + tests, and the owner
type carries `/// StateMachine: <row name>` · `guarded` = the state is still a
plain value but every known invalid transition is rejected at its owner and
tested · `implicit` = known gap, listed so nobody re-discovers it.

The gate checks, both ways, that every `/// StateMachine:` marker in the app
and watch sources has a row of the same name here and every `explicit` row has
a marker; that cited paths exist; and that no app file declares a
`*Status/*State/*Mode: String`, more than one `show*` boolean, or a `show*`
flag next to a `*Message: String?`.

## App shell and backend

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Backend mode | live · demo — decided once at launch from `--demo` / `FIT_DEMO=1`; every seam (API, HealthKit, auth) swaps together in `AppServices.configure` | `jpc.fit.native/Core/AppMode.swift`, `jpc.fit.native/Core/AppServices.swift` | explicit | `jpc.fit.nativeTests/AppModeTests.swift` |
| Demo session | signedOut(message?) · signedIn(email) — the demo backend's sign-in; live mode delegates this to Amplify's Authenticator | `jpc.fit.native/Core/DemoSession.swift` | explicit | `jpc.fit.nativeTests/AppModeTests.swift`, `jpc.fit.nativeUITests/Features/login.feature`, `jpc.fit.nativeUITests/Features/settings.feature` |
| App lifecycle sync | scene active → HealthKit sync; background → schedule BGTask; a no-op in demo mode (Amplify is not configured there — asking it would be a precondition failure) | `jpc.fit.native/jpc_fit_nativeApp.swift` (+ `jpc.fit.native/Services/BackgroundSyncService.swift`) | implicit | — (platform glue; no seam yet) |

## Calories tab

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Food list | loading · empty · rows([Food]) — derived from the VM's one loading flag + rows; the section switches over it | `jpc.fit.native/Models/FoodListState.swift` (derived in `jpc.fit.native/ViewModels/FoodViewModel.swift`) | explicit | `jpc.fit.nativeTests/FoodViewModelTests.swift`, `jpc.fit.nativeUITests/Features/calories.feature` |
| Food sheet | nil · add · edit(Food) — one optional replaces `showingAddFood` + `editingFood`; the draft/validation/naming rules moved out of the view into `FoodDraft` | `jpc.fit.native/Models/FoodDraft.swift` (presented by `jpc.fit.native/Views/FoodListView.swift`) | explicit | `jpc.fit.nativeTests/DraftTests.swift` |
| Optimistic food write | shown(temp id) → re-keyed(server id) · rolled back + error — add/edit/delete never leave a row that looks saved when the write was lost | `jpc.fit.native/ViewModels/FoodViewModel+Mutations.swift` | guarded | `jpc.fit.nativeTests/FoodViewModelTests.swift`, `jpc.fit.nativeUITests/Features/calories.feature` |
| Food error banner | nil · message — one optional, cleared by the next fetch | `jpc.fit.native/ViewModels/FoodViewModel.swift` | guarded | `jpc.fit.nativeTests/FoodViewModelTests.swift` |
| Day fetch cancellation | in-flight fetch for day A dropped when the day changes to B (`.task(id:)` + `Task.isCancelled`) | `jpc.fit.native/ViewModels/FoodViewModel.swift` | implicit | — (needs an injectable scheduler to test) |

## Stats tab

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Streak | computing · known(days, net) · unavailable — a failed walk keeps the last known value; a failed FIRST walk is `unavailable` (used to spin forever) | `jpc.fit.native/Models/StreakState.swift` (written only by `jpc.fit.native/ViewModels/StatsViewModel+Streak.swift`) | explicit | `jpc.fit.nativeTests/StatsViewModelStreakTests.swift`, `jpc.fit.nativeTests/StateTransitionTests.swift`, `jpc.fit.nativeUITests/Features/stats.feature` |
| Day record | tracked · untracked · failed — one status instead of `tracked` + `failed` booleans | `jpc.fit.native/ViewModels/StatsViewModel.swift` (`DayStats.Status`, classified in `jpc.fit.native/ViewModels/StatsViewModel+Week.swift`) | explicit | `jpc.fit.nativeTests/StatsViewModelWeekTests.swift`, `jpc.fit.nativeTests/ViewModelTests.swift` |
| Off-screen refresh | onScreen · offScreen(stale) — decides refresh-now vs refresh-on-next-appearance for `.foodDataChanged`; replaces three view flags | `jpc.fit.native/Models/RefreshGate.swift` (driven by `jpc.fit.native/ViewModels/StatsViewModel.swift`) | explicit | `jpc.fit.nativeTests/StateTransitionTests.swift` |
| Week window | `weekEndDate` + one cancellable `weekTask`; a superseded fetch never paints under a newer label | `jpc.fit.native/ViewModels/StatsViewModel+Week.swift` | guarded | `jpc.fit.nativeTests/StatsViewModelWeekTests.swift` |

## Weight tab

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Measurement prompt | nil · weight · height — one optional replaces two alert flags and two near-identical alerts | `jpc.fit.native/Models/MeasurementPrompt.swift` (presented by `jpc.fit.native/Views/WeightView.swift`) | explicit | `jpc.fit.nativeTests/StateTransitionTests.swift`, `jpc.fit.nativeTests/WeightViewModelSaveTests.swift`, `jpc.fit.nativeUITests/Features/weight.feature` |
| Weight toast | nil · message — visible iff non-nil, auto-hidden by the owner's one timer (was `showToast` + `toastMessage` + a view-side `asyncAfter`) | `jpc.fit.native/ViewModels/WeightViewModel.swift` | explicit | `jpc.fit.nativeTests/WeightViewModelSaveTests.swift` |

## Settings tab

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Preferences record | unknown · missing · stored(Preferences) — `nil` used to mean both "fetch failed" and "no row", and a toggle after a failed fetch CREATED a duplicate row | `jpc.fit.native/Models/PreferencesRecord.swift` (written only by `jpc.fit.native/ViewModels/SettingsViewModel.swift`) | explicit | `jpc.fit.nativeTests/SettingsViewModelTests.swift`, `jpc.fit.nativeTests/StateTransitionTests.swift` |
| Quick-add sheet | nil · create · edit(item) — one optional replaces `showCreateQuickAdd` + `editingQuickAdd`; `QuickAddDraft` owns validation | `jpc.fit.native/Models/QuickAddDraft.swift` (presented by `jpc.fit.native/Views/SettingsView.swift`) | explicit | `jpc.fit.nativeTests/DraftTests.swift`, `jpc.fit.nativeTests/SettingsQuickAddTests.swift` |
| Reminders | unknown · notRequested · userDisabled · osDenied · enabled — `isEnabled` stood for four situations; "denied in iOS Settings" now shows an Open Settings shortcut instead of a dead Enable button | `jpc.fit.native/Models/ReminderState.swift` (written only by `jpc.fit.native/Services/NotificationManager.swift`) | explicit | `jpc.fit.nativeTests/NotificationManagerTests.swift` |
| Delete-account confirm | hidden · shown — a single alert flag | `jpc.fit.native/Views/SettingsView.swift` | implicit | — (one boolean, one alert; convert if a second dialog appears) |

## Quotes tab

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Quote bag | current(index?) + used[] — every quote once per cycle, then a fresh cycle | `jpc.fit.native/Models/QuoteBag.swift` (drawn by `jpc.fit.native/Views/AphorismsView.swift`) | explicit | `jpc.fit.nativeTests/StateTransitionTests.swift`, `jpc.fit.nativeUITests/Features/quotes.feature` |

## Watch

| Machine | States | Owner | Status | Tests |
| --- | --- | --- | --- | --- |
| Watch health source | unknown · unavailable · failed(reason) · measured(active, basal) · fromPhone — was an `authStatus: String` | `jpc.fit.native/Shared/WatchStatus.swift` (written by `com.johncorser.fit.watchkitapp Watch App/WatchDataManager.swift`) | explicit | `jpc.fit.nativeTests/WatchProtocolTests.swift` |
| Phone link | unknown · reachable · unreachable — was a `connectionStatus: String` | `jpc.fit.native/Shared/WatchStatus.swift` (written by `com.johncorser.fit.watchkitapp Watch App/WatchDataManager.swift`) | explicit | `jpc.fit.nativeTests/WatchProtocolTests.swift` |
| Watch wire protocol | `WatchCommand` (requestData · addFood · deleteFood · syncHealthKit) and `WatchSnapshot` — the dictionary keys live in one file compiled into both targets | `jpc.fit.native/Shared/WatchCommand.swift`, `jpc.fit.native/Shared/WatchSnapshot.swift` (used by `jpc.fit.native/Services/PhoneConnectivityManager.swift`) | guarded | `jpc.fit.nativeTests/WatchProtocolTests.swift` |
