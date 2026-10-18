# Phase 2 audit — NightCast

- Audited commit: `bd95e15` source, baseline tag `baseline/2026-10-17` (`a39e811`)
- Owner goal: **faster** first. Must not change: Sleep fade timings (10% every 40 s, 6 min), Home pages (New / Library / Explore), the theme set, on-device saved data.
- App is not released; the owner is the only user.

## Counts

| Track | critical | high | medium | low | nit |
| --- | --- | --- | --- | --- | --- |
| Performance | 0 | 0 | 3 | 3 | 0 |
| Correctness | 0 | 0 | 0 | 1 | 0 |
| Robustness | 0 | 0 | 0 | 0 | 0 |
| Accessibility | 0 | 0 | 0 | 1 | 0 |
| Design | 0 | 0 | 0 | 0 | 0 |
| Measurement | 0 | 1 | 0 | 0 | 0 |

No performance finding is high: none has a trace behind it yet, because the baseline launch had an empty library (F-007). Code-level suspicion caps them at medium.

## Baseline correction (read first)

The Release build ignores every launch argument: `NightCastApp.swift:10-15` uses `DebugLaunch` only under `#if DEBUG`. The baseline's "fixture mode" note is wrong for the Release rows. The actual condition was: **Release, empty library (fresh simulator), default Midnight theme, real directory/feed services but no network calls (nothing subscribed).** The numbers are still reproducible on the `NightCast-prebuilt` simulator as long as its library stays empty. See F-007.

## What the launch trace shows

`baseline/2026-10-17/raw/time-profiler-launch.trace`, 1 sample = 1 ms, main thread, empty library, simulator:

| Phase of launch | Main-thread ms | Whose code |
| --- | --- | --- |
| dyld loading system frameworks (`dyld4::prepareSim`) | ~195 | system, simulator-specific |
| `NightCastApp.init` → `AppModel.init` (store load, AVPlayer, NowPlaying, URLSession) | ~20 | app |
| First SwiftUI render and commit | ~100 | SwiftUI, includes ~8 ms drawing the Midnight scene |
| AttributeGraph type metadata (background thread) | ~170 | SwiftUI internals |
| Steady state after ~750 ms | ~3% of main (8 samples per 250 ms) | scene background redrawing at 15 fps |

**What this means:** with an empty library, the app's own launch code is about 20 ms. Most of the 2.0 s `XCTApplicationLaunchMetric` number is system and simulator work that code changes cannot move. Launch gains from code will only show with a populated library, where F-001 and F-002 do their work on the main thread before the first frame.

## Performance

### F-001 — Every cached feed is read and decoded on the main thread before the first frame
Track:      performance
Severity:   medium (code-level; not yet measured, see F-007)
Location:   NightCast/App/AppModel.swift:133 → :251 → :225; NightCast/Playback/FeedDiskCache.swift:15-19
Evidence:   `AppModel.init` calls `recomputeLatestFromCache()`, which calls `cachedFeed(for:)` for every subscribed show. Each call does `Data(contentsOf:)` plus a full `JSONDecoder` decode of that show's whole feed, synchronously, inside `App.init`. Cost grows with shows × episodes per feed.
Blast:      medium — AppModel init and the New page's first paint; the New page could briefly show its loading state instead of cached episodes
Fix sketch: load the disk caches off the main thread right after the first frame, then recompute `latest` on the main actor. No change to the cache files.
Verified:   re-opened all four lines, confirmed

### F-002 — The whole library is decoded, re-encoded and written on the main thread, and it only grows
Track:      performance
Severity:   medium (code-level; not yet measured)
Location:   NightCast/App/AppModel.swift:93, :445-447; NightCastCore/Sources/NightCastCore/Persistence/LibraryStore.swift:77-93, :8; NightCast/Playback/PlaybackEngine.swift:262-267
Evidence:   `store.load()` decodes `library.json` synchronously in `App.init`. Every `persist()` re-encodes the entire snapshot (`.sortedKeys`) and does an atomic write on the main thread. That happens every 5 s during playback and on every library change. `positions` keeps an entry for every episode ever played and is never pruned, so each write gets bigger over time.
Blast:      medium — every save path; the file format must stay byte-compatible
Fix sketch: move `save` to a background serial writer that coalesces to the latest snapshot. Keep the same encoder settings and file path. Pruning `positions` would change saved data, so it is excluded unless you approve it.
Verified:   re-opened all lines, confirmed the 5 s throttle (`PlaybackEngine.swift:267`)

### F-003 — A new ShowModel is built every time ShowView is re-created
Track:      performance
Severity:   medium (code-level)
Location:   NightCast/Views/ShowView.swift:81-83, :25-29, :44-58
Evidence:   `State(initialValue: ShowModel(...))` runs on every `ShowView.init`. SwiftUI keeps only the first instance, but each throwaway one still runs `cachedFeed`, `apply` and `regroup()` (year-grouping every episode), and calls `app.refreshSubscription`. `RootView`'s `navigationDestination` re-creates `ShowView` whenever `RootView` re-evaluates, for example when an episode starts and the player opens. So the extra work lands at the moment you tap play.
Blast:      low-medium — one view's model ownership
Fix sketch: create the model once, for example with `@State private var model: ShowModel?` built in `.task`/`onAppear`, or owned by the destination. Same visible behavior.
Verified:   re-opened, confirmed

### F-004 — The "new episode" dot is recomputed with URL parsing for every tile on every render
Track:      performance
Severity:   low (code-level)
Location:   NightCast/App/AppModel.swift:201-208; NightCast/Views/LibraryView.swift:83-85; NightCastCore/Sources/NightCastCore/Models/Models.swift:118-131
Evidence:   `hasNewEpisode` scans all of `latest` per show and calls `FeedURL.key` (a `URLComponents` parse) per episode. That is shows × recent-episodes parses each time the Library grid renders.
Blast:      low
Fix sketch: build a `Set` of show IDs with new episodes whenever `latest` changes; the tile does a set lookup.
Verified:   re-opened, confirmed

### F-005 — Audio and lock-screen setup happen eagerly in App.init
Track:      performance
Severity:   low (measured: ~8 ms of the ~20 ms app init in the trace)
Location:   NightCast/App/AppModel.swift:103-105
Evidence:   `PlaybackEngine()` (AVPlayer plus observers) and `NowPlayingBridge` (remote commands) appear under `AppModel.init` in the trace.
Blast:      medium — lock-screen and headphone controls depend on this setup
Fix sketch: defer until the first load. Low payoff, real risk to remote controls.
Verified:   trace frames confirmed

### F-006 — Scene backgrounds redraw continuously at 15 fps
Track:      performance
Severity:   low (measured: ~3% main thread when idle on Home, simulator)
Location:   NightCast/Design/Scenes.swift:14
Evidence:   `TimelineView(.animation(minimumInterval: 1/15))` redraws the whole Canvas while a scene theme is visible.
Blast:      high for the look — any change alters how the themes animate
Fix sketch: none proposed. The theme set must not change.
Verified:   trace samples after 750 ms are all `SceneRenderer`

## Correctness

### F-008 — Throwaway ShowModels can write the library
Track:      correctness
Severity:   low
Location:   NightCast/Views/ShowView.swift:54
Evidence:   Each discarded `ShowModel` from F-003 calls `app.refreshSubscription`, which calls `persist()` when show metadata differs, so the same write can repeat.
Blast:      low — fixed by F-003
Verified:   re-opened, confirmed

## Accessibility

### F-009 — At the largest text size the empty-Library button falls below the fold
Track:      accessibility
Severity:   low
Location:   NightCast/Views/LibraryView.swift:30, :143
Evidence:   `baseline/2026-10-17/screens/home-largest-dynamic-type-dark.png`. The button is still reachable because the screen is a `ScrollView`.
Blast:      low
Fix sketch: out of scope for a speed run
Verified:   screenshot and line confirmed

## Measurement

### F-007 — The baseline cannot measure what the speed findings change
Track:      measurement
Severity:   high (for evidence, not for users)
Location:   NightCast/App/NightCastApp.swift:10-15; NightCast/TestSupport/DebugLaunch.swift:1
Evidence:   Release ignores the fixture flags, so the Release baseline had an empty library. F-001 and F-002 cost nothing with an empty library.
Fix sketch: in Phase 4, seed the `NightCast-prebuilt` simulator's `Application Support/NightCast/library.json` and `Caches/Feeds/*.json` with realistic data, for example 30 shows with full feeds and 2,000 saved positions. Do this with a measurement script, not app code. Then retake the launch baseline in that state, and measure a show-open and a play-tap timing. Tag the retake as a second baseline.
Verified:   re-opened, confirmed

## Smoke results carried over

- S3: the 39 error lines are all system frameworks. No app finding; dropped.
- S5: became F-009.

## Not audited

- Full correctness and robustness sweep with `ios-code-audit`. Skipped because the goal is speed; its `CODE_AUDIT.md` pass costs a lot of context.
- Concurrency review beyond the files read: AppModel, PlaybackEngine, ShowView, HomeView, Scenes, LibraryStore, FeedDiskCache, NightCastApp, DebugLaunch.
- Explore, Search, Themes and Now Playing views, apart from the background usage.
- Device performance: BLOCKED, no device.
- Accessibility Inspector audit: not run.
- Design track: no findings looked for beyond the S5 screenshot.
