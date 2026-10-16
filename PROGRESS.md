# Progress log

Newest first. Each entry: what changed, what was verified (actual output), blockers.

## 2026-10-15 — Session 10: v0.10 6-minute fade, always-on smaller player, swipe-down, live reorder, site copy

- D44. **Verified (actual output, `scripts/test.sh`):** core 90/90; Debug + Release BUILD SUCCEEDED; UI 18/18
  (new: player always stays incl. while typing; swipe down closes Now Playing).
- Site edits committed and pushed in studio-site (see below for deploy check).

## 2026-10-15 — Session 9: v0.9 smooth search transition; player shrinks while typing

- D43. Frame-checked via simulator screen recording (50 ms frames): first fix attempt showed the page cutting
  out in one frame (its animation didn't run inside the pager) → driven by one explicit transaction;
  second showed the two layers overlapping mid-fade → page fades in 0.18 s, search waits 0.16 s.
- **Verified (actual output, `scripts/test.sh`):** core 90/90; Debug + Release BUILD SUCCEEDED; UI 17/17.
- Frame strips: `screenshots/v9/`.

## 2026-10-15 — Session 8: v0.8 search in place; category page fix

- D42. **Verified (actual output):** `scripts/test.sh` → core 90/90; Debug + Release BUILD SUCCEEDED; UI 17 executed,
  0 failures. Live network test (real search → subscribe → stream, now via in-place search): passed.
- Category page at 1 s after opening: full width, placeholder tiles → then shows (`screenshots/v8/`).

## 2026-10-15 — Session 7: v0.7 softer Red Light, tucked player oval, smoother Themes sheet

- D41. **Verified (actual output, `scripts/test.sh`):** core 90/90; Debug + Release BUILD SUCCEEDED;
  UI tests 17 executed, 0 failures (mini player test now checks the oval and restoring from it).
- Screenshots: `screenshots/v7/`.

## 2026-10-15 — Session 6: v0.6 Underwater + Red Light

- Underwater scene and Red Light color scape (D40). Red Light retuned to blue = 0 and AA after a first
  failing pass; key highlights and Explore card tints follow `Theme.blueFree`.
- **Verified (actual output):** core 90/90; Debug + Release BUILD SUCCEEDED; full UI run 16/17 — the failure
  was a test race (one sample taken after the restore-to-1.0 but before the button said "Play"); test now
  stops at the quietest sample; Sleep suite + Themes test rerun: 4/4 passed.
- Screenshots: `screenshots/v6/`.

## 2026-10-15 — Session 5: v0.5 Themes (Scenes + Color Scapes)

- Four new animated scenes + shared renderer; Themes sheet; Themes key; layout key unchanged (D39).
- Screenshot review caught moons under page titles/show labels → moved (Mountain: right edge; Beach: horizon).
- **Verified (actual output):** core 90/90; Debug + Release BUILD SUCCEEDED; UI full run 16/17 passed, the
  one failure was the test not scrolling to Color Scapes in a half-height sheet → test fixed, rerun alone: passed.
- Screenshots: `screenshots/v5/`. Not verified on device (V5.5).

## 2026-10-15 — Session 4: v0.4 Midnight, mini player, bubble pill, layouts, reorder, Explore categories

- Midnight theme (default, D36), hideable mini player (D33), bubble pill (D34), Library layouts +
  drag reorder (D37), Explore search / interests / 26 Browse categories / category pages (D35).
- Verified genre ids live before use; three remembered ids were wrong.
- Fixed after test failure: compact tiles' VoiceOver label dropped the author.
- **Verified (actual output, `scripts/test.sh`, iPhone 18 Pro sim):** core 90/90; Debug + Release BUILD
  SUCCEEDED; UI tests 17 executed, 0 failures (real drag-to-reorder included).
- Note: press-and-hold tests now wait ~60 s for XCUITest's "animations complete" signal (drag + context
  menu share the gesture); they pass. Script timeout raised to 15 min.
- Screenshots: `screenshots/v4/`. Not verified on device (V4.7).

## 2026-10-15 — Session 3: v0.3 full history, Sleep 10%/min, ±5 bubble, z's

Owner request: entire episode list by year; floating z's; ±5 min bubble above Moon; 10% drop per minute.
- Fade: `SleepConfiguration.standard` now 60 s steps, 0.9…0.0 (D28). Old numbers kept as test-only `.v1`.
- `SleepTimer.adjust(by:)` with lift glide; `SleepController.adjust`; bubble UI (D29).
- Paged feed following + year grouping, pinned year headers, Newest/Oldest toggle (D30).
- Floating z's: Canvas/TimelineView, static under Reduce Motion (D31).
- No website exists; README/in-app copy updated (D32).
- **Verified (actual output, `scripts/test.sh`, iPhone 18 Pro sim):** core 83/83; Debug + Release BUILD SUCCEEDED;
  UI tests 13 executed, 0 failures (new: ±5 bubble, year sections/order).
- Screenshots: `screenshots/v3/`.
- Not verified: real paged feed in the wild (none of the sample feeds page); device check V3.7.

## 2026-10-15 — Session 2: v0.2 home pages, persistent mini player, Explore

Owner request: mini player always visible once playing; 3-dot pager New · Library · Explore with swipe;
Explore recommends similar shows. Plus my additions: feed disk cache, unsubscribe/mark-played menus,
new-episode pip, keyword affinity for Explore.
- **Verified (actual output, `scripts/test.sh --live`, iPhone 18 Pro sim):** core 70/70; Debug + Release
  BUILD SUCCEEDED; UI tests 11 executed, 0 failures; live network test passed.
- Live Explore check: genres alone surfaced self-help shows for a sleep Library; keyword affinity fixed
  it (Top picks: Calm History, Sleep and Sorcery, Lights Out Library, Just Sleep). Screenshots: `screenshots/v2/`.
- Found: another session drives the "iPhone 17" simulator → moved to "iPhone 18 Pro" (D27).
- Not verified on device yet (V2.7).

## 2026-10-15 — Session 1e: M5 polish, Release hygiene, handoff

- Release excludes TestSupport (D20). Verified by inspecting the Release .app and binary.
- AX5 fixes after screenshots (D21). Search Return key searches immediately.
- Replica: `parity.py` 90.7 (`replica/parity.md`), brand `sweep.py` clean on NightCast/, NightCastCore/, Config/.
- `scripts/test.sh [--live]` added (handles serial UI tests and the xcodebuild hang).
- README.md handoff: setup, architecture, tokens, test results, device checklist, limitations, TestFlight steps.
- **Verified (actual output):** `swift test` 55/55; Debug + Release clean builds, no Swift warnings;
  UI tests 8 executed, 0 failures.
- Screenshots: `screenshots/m5/`.
- Still open: live VoiceOver pass; all device checks D1–D8; signing/TestFlight (owner).

## 2026-10-15 — Session 1d: M4 Sleep engine connected to the real player

- D11 fixed: `SleepTimer.reviseFadeDelay(remaining:)` + `SleepController.measuredDurationArrived`.
  PlaybackEngine reports the stream's measured duration once per item; AppModel forwards it.
  Revision happens once, only while waiting, never schedules the fade in the past.
- Ticker now runs only while audio actually plays (D18). `appliedGain` mirrors AVPlayer.volume;
  test-only `debugGain` readout under `-uitest`.
- **Verified (actual output):**
  - `swift test` → 55 tests in 8 suites passed (4 new D11 tests: 31:22 feed vs 37:04 stream → 681 s).
  - Clean `xcodebuild build` → BUILD SUCCEEDED, no Swift warnings.
  - UI tests (fixture mode, real AVPlayer), `-parallel-testing-enabled NO -skip-testing:NightCastUITests/LiveNetworkUITests`
    → Executed 8 tests, 0 failures (CoreFlow 5 + Sleep 3).
  - Full fade on the real player (`-fastSleep`: 4 s delay, 6 s steps, 1 s glides), AVPlayer.volume sampled every 0.5 s:
    `1.00 ×8, 0.91, 0.80 ×9, 0.77, 0.67, 0.60 ×9, 0.57, 0.41, 0.40 ×10, 0.31, 0.21, 0.20 ×9, 0.11, 0.01` → paused,
    Sleep off, volume restored to 1.00, same episode still loaded, nothing else played.
- Not verified (simulator can't prove): fade with screen locked/backgrounded, interruptions and route
  changes during Sleep, real 30-min timings → device checks D3–D5, D7.

## 2026-10-15 — Session 1c: M3 vertical slice

Owner approved the M2 visual direction. M3 was done directly in-session at the owner's request
(no `/goal` was run; that command is owner-typed).

- Added SearchView/SearchModel (350 ms debounce, cancellation, in-memory cache, idle/loading/
  results/empty/error+retry, offline and rate-limit messages), ShowView/ShowModel (artwork, title,
  description with More, Subscribe/Subscribed key, episode rows with date · duration · time left,
  progress ring, pull to refresh, loading/empty/error), NavigationStack from Library and Search,
  feed cache with shared in-flight requests.
- Fixture mode `-uitest` (fake directory/feeds, bundled tone, separate store file, `-resetStore`).
- **Verified (actual output):**
  - `cd NightCastCore && swift test` → 51 tests in 7 suites passed (LiveFeed is opt-in).
  - `xcodebuild … -parallel-testing-enabled NO -only-testing:NightCastUITests/CoreFlowUITests test`
    → Executed 5 tests, 0 failures: empty library, search empty/error/retry, subscribe persists
    across relaunch, subscribe→play→Sleep on/off, position survives relaunch (no autoplay).
  - `TEST_RUNNER_NIGHTCAST_LIVE=1 … -only-testing:NightCastUITests/LiveNetworkUITests test` → passed:
    real iTunes search "nothing much happens" → real Megaphone RSS (524 episodes) → subscribe →
    real stream played and position advanced. Screenshots: `screenshots/m3/live-*.png`.
- Issues hit: parallel-clone UI test hang (D14); simulator keyboard injection via the panel tool
  did not reach the text field, so live verification used XCUITest instead.
- Not verified: Lock Screen / remote commands, background audio, interruptions, route change
  (simulator can't prove these; device checklist D1–D7).

## 2026-10-14 — Session 1b: M2 prototype built, awaiting visual approval

- Owner accepted the Xcode license. `xcodebuild -showsdks`: iOS 27.0 + iOS Simulator 27.0.
  Runtime iOS 27.0 present; iPhone 17 simulator booted. No download needed.
- `NightCast.xcodeproj` hand-written (folder-synchronized groups, local package `NightCastCore`).
  Settings: iOS 18.0, Swift 6, default MainActor isolation, background mode `audio`.
- Built: Theme (3), KeyStyle (physical key), MoonKey, Scrubber, ArtworkCache, PlaybackEngine
  (AVPlayer, session, interruptions, route change), NowPlayingBridge (lock screen + remote ±15),
  AppModel (persistence, Sleep wiring, 4 Hz ticker), LibraryView + MiniPlayer, NowPlayingView,
  AppearanceSheet. Search/Show are labelled placeholders until approval.
- Original app icon generated with CoreGraphics (no third-party assets).
- **Verified:** `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17' build` ->
  BUILD SUCCEEDED, no Swift warnings (only Apple's AppIntents metadata notice).
  App launched with real directory shows + real Radiolab feed; artwork loaded from the network.
- Screenshots: `screenshots/m2/` - library/player x paper/ink/ember, sleep-on (ink, ember),
  empty library (ember), AX5 (paper library + player, ember sleep-on).
- Fixed after inspecting screenshots: grid rows misaligned (top alignment); Moon subtitle
  truncated at AX5 (wraps, ticks hidden).
- Found: fade delay used feed duration (31:22) vs real stream (37:04) -> D11, M4 task.
- Not done: audio playback not exercised in this pass (demo loads paused); VoiceOver not run live.

## 2026-10-14 — Session 1: M1 complete, core logic pulled forward

### Environment (verified by command output)
| Item | Finding |
|---|---|
| macOS | 27.0.1 (26A434), arm64 |
| Xcode | `/Applications/Xcode.app` = Xcode 27.0 (27A266a) |
| Active developer dir | `/Library/Developer/CommandLineTools` (not Xcode). Worked around with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; system setting not changed |
| Xcode license | **NOT ACCEPTED** → `xcodebuild -showsdks`, `simctl`, iOS builds all refuse to run. **BLOCKER (owner action, needs sudo)** |
| iOS Simulator runtimes | None found under CoreSimulator Profiles/Runtimes (could not query `simctl` until license accepted). Likely needs a runtime download |
| Swift | 6.4 (CLT). `swift build` / `swift test` work for macOS targets → core logic testable now |
| Node / Python | Node 23.8.0, Python 3.9.6 |
| Git | Repo initialized this session (no commits yet) |
| Project | Folder was empty at start |

### Tools (verified)
| Tool | Status | Exact names |
|---|---|---|
| Replica | **Installed** (plugin `replica-skill@replica-skill` v1.0.0, user scope) | `/replica-skill:replica-recon`, `…:replica-architect`, `…:replica-design`, `…:replica-build`, `…:replica-test`, `…:replica-diff`, `…:replica-brand` (also backend/entrepreneur/launch/deploy — not used) |
| REA | **Not installed** (`rea` absent, no MCP). Install: `npx rea-agents setup` (adds MCP server + skill to agent config, with backups). Requires Node 22.19+/24.11+/26+; **installed Node 23.8 is not in REA's supported list** |
| Ralph loop | **Available in marketplace, not installed** (`claude-plugins-official/plugins/ralph-loop`). Install: `/plugin install ralph-loop@claude-plugins-official`. Commands: `/ralph-loop "<prompt>" --max-iterations N --completion-promise "<text>"`, `/cancel-ralph`. Config change: registers a **Stop hook** that blocks session exit and re-feeds the prompt while `.claude/ralph-loop.local.md` exists |
| /goal | **Not verified.** Claude Code 2.1.299 is installed; Claude cannot invoke or list built-in slash commands from inside the session. Owner: type `/goal` once to confirm it exists |

Both /goal and /ralph-loop are user-typed; Claude never claims they ran unless the owner ran them.

### Replica skills applied
- recon → `replica/recon.md`, `replica/features.csv` (evidence-labelled; gaps recorded)
- architect → `replica/architecture.md` + PLAN.md (iOS-adapted; no auth/DB server)
- design → `replica/design/tokens.{paper,ink,ember}.json`, `principles.md`;
  `contrast.py` run on all three: **0 AA failures** (Ember first failed 7 pairs → retuned → pass)

### Reference research
- Neuecast site: tagline/positioning only; no feature detail. App Store page not retrieved.
- Not Boring: bundle listing + notbor.ing/llms.txt + third-party reviews → principles.
- **Gap:** no screenshots/recordings of either reference. No visual measurements claimed.
  REA not used (no authorized artifacts; nothing interaction-specific on public pages).

### Code: `NightCastCore` (Swift package)
Models, SleepTimer + SleepController, RSSParser + HTTPFeedService, ITunesDirectory,
JSONLibraryStore, SeekMath/TimeFormat/SleepCopy.

### Verification (actual results)
- `cd NightCastCore && swift test` → **50 tests in 6 suites passed** (macOS host, Swift Testing).
- Live check: iTunes Search `term=radiolab` → HTTP 200, 4 results, all with feed URLs.
  Real Radiolab RSS (4.9 MB) parsed by `RSSParser`: **674 episodes, 674 with duration**
  (`NIGHTCAST_LIVE_FEED=… swift test --filter LiveFeed` → passed).

### Blockers
1. Xcode license: resolved by owner.
2. Simulator runtime: present.

### Next
After license: create `NightCast.xcodeproj`, build Library + Now Playing prototype (M2),
capture screenshots, request visual approval.
