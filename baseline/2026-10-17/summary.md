# Baseline 2026-10-17 (NightCast)

- commit: bd95e1518ea206f3a86d251fb12d6a50808e2583 (main), task branch `perf/prebuilt-faster`
- tree: source clean. The script's "DIRTY" flag came from its own `baseline/` output; `git diff` was empty and no source file was untracked.
- xcode 27.0 (27A266a), macOS 27.0.1, Apple M5
- performance device: dedicated simulator `NightCast-prebuilt`, iPhone 18 Pro, iOS 27.0, dark appearance, Large text. All performance rows are `simulator`, not device.
- data mode: fixture (`-uitest -resetStore -theme ink`), no network, bundled 90 s tone.
- build configuration for performance rows: Release.

## Headline numbers (median of 5, spread = min to max)

| Metric | Median | Spread | Config |
| --- | --- | --- | --- |
| Cold launch (XCTApplicationLaunchMetric) | 1.997 s | 1.940 to 2.132 s | simulator, Release, fixture |
| CPU time during launch | 3.097 s | 2.954 to 3.319 s | simulator, Release |
| Peak physical memory during launch | 34.5 MB | 34.4 to 34.7 MB | simulator, Release |

Raw values: `raw/perf-harness/launch-metric.log`. Harness: `raw/perf-harness/PreBuiltPerfTests.swift` (run from a throwaway copy of the project; repo source untouched).

## Build and size

- Debug build: SUCCEEDED, 5 s, 0 compiler warnings
- Release clean build: SUCCEEDED, 12 s, 0 compiler warnings (the one "warning" line is the AppIntents metadata note: `raw/warnings-Release.txt`)
- App bundle: 12 MB, universal (x86_64 + arm64 simulator slices)
- __TEXT segment: 1,347,584 bytes (x86_64) and 1,327,104 bytes (arm64)
- Source: 50 Swift files, 8,383 lines

## Tests (the project's own `scripts/test.sh`)

- Core (`swift test`): 90 of 90 passed
- UI tests (fixture mode): 19 executed, 0 failures, 488 s
- Raw: `raw/tests.log`

## BLOCKED or not captured

- Crash-free rate: BLOCKED (app is not released)
- Scroll hitch rate: BLOCKED (no scroll signposts in the app; adding them is a source change, so Phase 5 only)
- Device numbers (launch, hitches, thermals): BLOCKED (no device can be driven from this session)
- Allocations / memory high-water over a scenario: NOT captured; only launch-time peak memory above
- Main-thread hot spots: Time Profiler trace saved at `raw/time-profiler-launch.trace` for Phase 2; not analyzed in Phase 1
- Accessibility Inspector audit: NOT captured in Phase 1 (Phase 2 accessibility track)
