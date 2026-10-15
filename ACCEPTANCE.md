# Acceptance Criteria

Status labels: **PASS / FAIL / BLOCKED / NOT RUN**. A check is PASS only when
it was actually run and observed passing. Simulator results never satisfy device checks.

## M1 — Research and scope

| ID | Criterion | Status |
|---|---|---|
| M1.1 | Environment inspected; tools verified/missing recorded in PROGRESS.md | PASS |
| M1.2 | Both repos' current instructions read; command names recorded | PASS |
| M1.3 | Reference evidence + gaps recorded (`replica/recon.md`), observed vs inferred vs proposed labelled | PASS |
| M1.4 | Flows, architecture, design principles finalized (PLAN.md, `replica/architecture.md`, `replica/design/principles.md`) | PASS |
| M1.5 | `replica/features.csv` lists in-scope must/should/could + skip rows | PASS |
| M1.6 | All six tracking files exist and are current | PASS |

## M2 — Visual direction (needs Xcode)

| ID | Criterion | Status |
|---|---|---|
| M2.1 | Library + Now Playing prototype builds for iOS Simulator | PASS (xcodebuild, iPhone 17 / iOS 27.0 sim) |
| M2.2 | Three themes with tokens; `contrast.py` reports zero AA failures | PASS |
| M2.3 | Screenshots captured for each theme, default + largest accessibility text size | PASS (`screenshots/m2/`; AX5 for Paper + Ember) |
| M2.4 | Accessibility review written (VoiceOver labels, 44 pt targets, Reduce Motion) | PASS (`replica/design/accessibility-review-m2.md`; live VoiceOver run still pending) |
| M2.5 | **Human visual approval** (owner) | PASS (owner approved 2026-10-15) |

## M3 — Functional vertical slice

| ID | Criterion | Status |
|---|---|---|
| M3.1 | Search hits iTunes API; debounce, cancel, loading/empty/error/retry states | PASS (live UI test vs real API; empty/error/retry via fixture UI test. Debounce/cancel implemented, no dedicated unit test) |
| M3.2 | Search results deduplicated (unit tested) | PASS (core `swift test`) |
| M3.3 | RSS parsed into episodes; fixture tests incl. malformed feeds | PASS (core fixtures + live Radiolab feed) |
| M3.4 | Subscribe/unsubscribe persists across relaunch (unit + UI test) | PASS (core + `testSubscribePersistsAcrossRelaunch`) |
| M3.5 | Playback positions persist per episode (unit test) | PASS (core + `testPositionSurvivesRelaunch`) |
| M3.6 | Seeking clamps to [0, duration] (unit test) | PASS (core) |
| M3.7 | Lock-screen info + remote play/pause/±15 wired | NOT RUN (implemented in NowPlayingBridge; not observed — needs device check D2/D6) |

## M4 — Sleep engine (spec)

Let R = playable seconds remaining at activation.
`fadeStartAfter = duration known ? min(1800, R/2) : 1800`, in active playback seconds.
Steps relative to baseline B at F, F+180, F+360, F+540, F+720: 0.8, 0.6, 0.4, 0.2, 0.0,
each ramped over 2 s. After the 0.0 ramp: pause, save, end Sleep, restore B.

| ID | Criterion | Status |
|---|---|---|
| M4.1 | fadeStartAfter correct for long, short, unknown durations (unit) | PASS (core `swift test`) |
| M4.2 | Gain sequence deterministic at exact boundaries and mid-ramp (unit, virtual time) | PASS (core `swift test`) |
| M4.3 | Paused/buffering time does not advance countdown (unit) | PASS (core + `testPauseFreezesCountdown` on real player) |
| M4.4 | Cancel restores B (ramped while playing, immediate while paused) (unit) | PASS (core + `testCancelMidFadeRestoresVolume` on real player) |
| M4.5 | Reaching zero emits pause + end, never "play next" (unit) | PASS (core `swift test`) |
| M4.6 | Episode end during Sleep stops, ends Sleep, restores gain, plays nothing (unit) | PASS (core `swift test`) |
| M4.7 | Seek does not reset countdown (unit) | PASS (core `swift test`) |
| M4.8 | Starting a different episode cancels Sleep (unit on controller) | PASS (core `swift test`) |
| M4.9 | Sleep state is not persisted / not restored on relaunch (unit) | PASS (core `swift test`) |
| M4.11 | Fade delay corrected once when stream's measured duration differs from feed (D11) | PASS (core, 4 tests) |
| M4.10 | Sleep drives actual `AVPlayer.volume` in app build | PASS (simulator UI test, `-fastSleep` timings; observed 1.00→0.80→0.60→0.40→0.20→0.01 then pause) |

## M5 — Polish and regression

| ID | Criterion | Status |
|---|---|---|
| M5.1 | `xcodebuild build` for iOS Simulator succeeds, zero warnings in app target | PASS (Debug + Release clean builds, no Swift warnings) |
| M5.2 | `swift test` (core) all green | PASS (55/55) |
| M5.3 | UI test: search (stubbed) → subscribe → play → Sleep on → Sleep off | PASS (`testSubscribePlayAndSleepFlow`) |
| M5.4 | All screens have loading/empty/error states | PASS (Library empty; Search idle/loading/empty/error+retry; Show loading/empty/error+retry; Player buffering/error+retry) — error states for Show/Player checked in code, not by a test |
| M5.6 | Test fixtures and debug hooks excluded from Release | PASS (no tone file, no Fixture/DebugLaunch symbols, no launch-flag strings in Release binary) |
| M5.7 | Replica parity + brand sweep | PASS (parity 90.7; 2 must-haves await device checks. Sweep clean in shipping folders) |
| M5.5 | Dynamic Type up to AX5 without clipping on primary controls | PASS (screenshots: Library, Show, Search, Now Playing at AX5; layouts switch at accessibility sizes) |

## Manual / physical-device checklist (owner, on a real iPhone)

| ID | Check | Status |
|---|---|---|
| D1 | Real audio streams from a real feed | NOT RUN |
| D2 | Playback continues with screen locked | NOT RUN |
| D3 | Sleep fade progresses and pauses with screen locked | NOT RUN |
| D4 | Headphone disconnect pauses, does not resume on its own | NOT RUN |
| D5 | Phone call / Siri interruption pauses; resume behaves correctly | NOT RUN |
| D6 | Lock Screen + Control Center + AirPods play/pause/±15 work | NOT RUN |
| D7 | No next episode ever starts automatically | NOT RUN |
| D8 | Bedtime theme comfortable in a dark room | NOT RUN |

## v0.2 — Home pages, persistent mini player, Explore (owner request 2026-10-15)

| ID | Criterion | Status |
|---|---|---|
| V2.1 | Mini player stays visible on Show, Search, Library, New, Explore once an episode is loaded | PASS (`testMiniPlayerStaysOnEveryScreenOncePlaying`) |
| V2.2 | 3 page dots appear once the Library has a show; Library is the default middle page | PASS (`testPagesAppearAfterSubscribeAndSwipeBothWays`) |
| V2.3 | Swipe left from Library → Explore; swipe right → New; dots tappable | PASS (same test) |
| V2.4 | New lists Library episodes newest first, grouped by day | PASS (core `LatestEpisodes` tests + UI test) |
| V2.5 | Explore suggests shows sharing genres/keywords with the Library, never Library shows | PASS (core `Recommender` tests + fixture UI test); live quality judged by screenshot only |
| V2.6 | Unsubscribe from a Library tile; pages hide when Library empties | PASS (`testUnsubscribeFromLibraryContextMenu`) |
| V2.7 | Same on a physical iPhone | NOT RUN (owner) |

## v0.3 — Full history, Sleep 10%/min, ±5 bubble, z's (owner request 2026-10-15)

| ID | Criterion | Status |
|---|---|---|
| V3.1 | Fade drops 10% of baseline every active minute, pauses at 0 | PASS (core `TenPercentFadeTests`) |
| V3.2 | ±5 adjusts countdown; never past, cap 4 h; +5 while fading glides back up | PASS (core `SleepAdjustTests`) |
| V3.3 | Bubble appears with Sleep, ±5 changes the shown countdown, −5 disabled while fading | PASS (UI `testBubbleAddsAndRemovesFiveMinutes`) |
| V3.4 | Paged feeds followed (loop-safe, partial failure kept) | PASS (core stub tests) |
| V3.5 | Show page grouped by year, Newest/Oldest toggle | PASS (UI `testEpisodesGroupedByYearWithOrderToggle`) |
| V3.6 | Floating z's visible while Sleep is on; still with Reduce Motion | Simulator screenshots only (`screenshots/v3/`) |
| V3.7 | Same on a physical iPhone | NOT RUN (owner) |

## v0.4 — Midnight, hideable mini player, tucked bubble, layouts, reorder, Explore categories (2026-10-15)

| ID | Criterion | Status |
|---|---|---|
| V4.1 | Mini player always shown while playing; slides away by tap when paused; returns on play | PASS (`testMiniPlayerHidesWhenPausedAndReturnsOnPlay`) |
| V4.2 | ±5 bubble tucks into a pill after quiet seconds or a tap; pill reopens it | PASS (`testSleepBubbleCollapsesAndReopens`) |
| V4.3 | Midnight night-sky theme, default once; AA contrast incl. over waves | PASS (contrast.py; screenshots) — comfort in a dark room NOT RUN (owner) |
| V4.4 | Drag a Library show onto another to reorder; order persists | PASS (UI drag test + core persistence test) |
| V4.5 | Large / Small / List from header key and Settings | PASS (`testLibraryLayoutsAndReorder`) |
| V4.6 | Explore: search entry, Your interests at top, Browse categories open category pages | PASS (`testExploreSearchInterestsAndCategories`; live Sports page screenshot) |
| V4.7 | Same on a physical iPhone | NOT RUN (owner) |
