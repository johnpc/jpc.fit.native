#!/usr/bin/env python3
"""Enforce a minimum line-coverage threshold over the app's logic files.

Reads an xccov JSON report and sums executable/covered lines for the
`jpc.fit.native` app target only (test/watch/widget targets excluded). Pure
SwiftUI view files and generated Amplify models are excluded from measurement —
they're exercised by acceptance tests, not unit tests. Fails below THRESHOLD.

Usage:
    xcrun xccov view --report --json TestResults.xcresult > coverage.json
    python3 scripts/coverage_check.py coverage.json
"""
import json
import sys

THRESHOLD = 80.0

# Files excluded from *unit* coverage: exercised by the Gherkin acceptance suite
# against the live backend, not by unit tests. This is the same set the prior CI
# excluded — pure SwiftUI views plus the Amplify-coupled Services/ViewModels that
# talk to Amplify directly (no injectable seam) — extended to the extension files
# those types were split into. Lower these by writing tests, never by adding here.
VIEW_FILES = {
    # Pure SwiftUI views / app shell
    "ContentView.swift", "MainTabView.swift", "FoodListView.swift",
    "WeightView.swift", "StatsView.swift", "SettingsView.swift",
    "AphorismsView.swift", "DatePickerTestView.swift",
    "HeaderSection.swift", "FoodSection.swift", "RemainingSection.swift",
    "HealthKitSection.swift", "QuickAddSection.swift", "ErrorSection.swift",
    "DatePickerSection.swift", "EmojiTextField.swift", "FoodFormSheet.swift",
    "QuickAddFormSheet.swift", "NotificationsSection.swift",
    "QuickAddsListSection.swift", "jpc_fit_nativeApp.swift",
    # Services/ViewModels that call Amplify/HealthKit directly (acceptance-covered)
    "HealthKitService.swift", "PhoneConnectivityManager.swift",
    "BackgroundSyncService.swift",
    "NotificationManager.swift", "NotificationManager+Scheduling.swift",
    "APIService.swift", "APIService+Parsing.swift",
    "WeightViewModel.swift", "WeightViewModel+Fetch.swift",
    "StatsViewModel.swift", "StatsViewModel+HealthKit.swift",
    "SettingsViewModel.swift", "SettingsViewModel+Fetch.swift",
    "SettingsViewModel+QuickAdds.swift",
}


def measured(name: str) -> bool:
    if "Tests" in name or "UITests" in name:
        return False
    if "watch" in name.lower() or "widget" in name.lower():
        return False
    return "jpc.fit" in name or "jpc_fit" in name


def main(path: str) -> int:
    with open(path) as f:
        data = json.load(f)

    total_lines = 0
    covered_lines = 0
    per_file = []
    for target in data.get("targets", []):
        if not measured(target.get("name", "")):
            continue
        for file in target.get("files", []):
            fpath = file.get("path", "")
            fname = fpath.split("/")[-1]
            if fname in VIEW_FILES or "AmplifyModels" in fpath:
                continue
            ex = file.get("executableLines", 0)
            cov = file.get("coveredLines", 0)
            total_lines += ex
            covered_lines += cov
            if ex > 0:
                per_file.append((fname, cov / ex * 100, cov, ex))

    pct = (covered_lines / total_lines * 100) if total_lines else 0.0

    per_file.sort(key=lambda r: r[1])
    print("Per-file coverage (lowest first):")
    for fname, fpct, cov, ex in per_file:
        flag = "⚠️ " if fpct < THRESHOLD else "   "
        print(f"  {flag}{fname:<36} {fpct:5.1f}%  ({cov}/{ex})")

    print(f"\nLogic file coverage: {pct:.1f}% ({covered_lines}/{total_lines} lines)")
    if pct < THRESHOLD:
        print(f"❌ FAIL: Coverage {pct:.1f}% is below {THRESHOLD:.0f}% threshold")
        return 1
    print(f"✅ PASS: Coverage {pct:.1f}% ≥ {THRESHOLD:.0f}%")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: coverage_check.py <coverage.json>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
