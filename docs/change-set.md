# Approved change set

- Approved: 2026-10-17, by the owner, in chat:
  > "Yes, I approve the change set as listed: F-007, F-001, F-003, F-004, F-002, including the brief New-page loading moment from F-001."
- Baseline: `baseline/2026-10-17`. F-007 adds a second, populated-library baseline before any code change.

## Approved, in order

| Order | ID | Fix | Measurement | Blast |
| --- | --- | --- | --- | --- |
| 1 | F-007 | Seed the `NightCast-prebuilt` simulator with a realistic library (~30 shows with full feed caches, ~2,000 positions) via a measurement script, retake the launch baseline, tag it | cold launch, median of 5, Release, simulator | none (no app code) |
| 2 | F-001 | Load feed disk caches off the main thread after the first frame, then recompute `latest` on the main actor | cold launch on the populated library, median of 5 | medium |
| 3 | F-003 | Build `ShowModel` once per show page, not on every `ShowView.init` | main-thread ms under `ShowModel` during "open show, tap play", Time Profiler, 5 runs | low-medium |
| 4 | F-004 | Precompute the set of shows with a new episode when `latest` changes | main-thread ms under `hasNewEpisode` during a Library render, 5 runs | low |
| 5 | F-002 | Move `library.json` saves to a background serial writer that coalesces; identical encoder settings and path; flush on backgrounding | main-thread ms under `save` per minute of scripted playback, 5 runs | high (persisted-data path) |

## Approved behavior change

- F-001: the New page may show its loading state briefly at launch before the cached episodes appear. Recorded in `docs/behavior-changes.md`.

## Excluded, with reasons

- F-005: payoff about 8 ms; risks lock-screen and headphone controls.
- F-006: any change alters theme animation; the theme set must not change.
- F-008: resolved by F-003.
- F-009: accessibility, not speed; still reachable by scrolling.
- Pruning saved `positions`: changes persisted data; not approved.

## Constraints carried into Phase 4 and 5

- `library.json` and `Caches/Feeds/*.json` stay byte-compatible: same encoders, keys, date strategy, path.
- Sleep fade timings, the Home pages, and the theme set do not change.
- Each fix is kept only if its after median beats the baseline median by more than the spread.
