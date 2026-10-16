# Decisions

Format: ID · date · decision · why · revisit when.

## D01 · 2026-10-14 · Native Swift/SwiftUI, no backend
Apple frameworks cover everything required (AVFoundation, MediaPlayer, URLSession,
XMLParser). The chosen directory API needs no secret, so no backend is needed.
Revisit if a keyed directory (e.g. Podcast Index) becomes necessary.

## D02 · 2026-10-14 · Minimum iOS 18.0 (provisional)
Needs: Observation (`@Observable`, iOS 17), modern SwiftUI scroll/animation APIs,
Swift Testing, sensory feedback (`.sensoryFeedback`, iOS 17). iOS 18 keeps the
target ~one generation behind the installed Xcode 27 SDK, so most active iPhones
are covered while avoiding iOS 17-era SwiftUI bugs.
**Confirmed 2026-10-14:** SDK is iOS 27.0; iOS 18.0 target builds cleanly.

## D03 · 2026-10-14 · Search provider: Apple iTunes Search API
- Endpoint: `https://itunes.apple.com/search?media=podcast&entity=podcast&term=…&limit=…`
- Credentials: none. Nothing secret ships in the app.
- Documented: Apple "iTunes Search API" docs (Apple Services Performance Partners).
- Limits: Apple states roughly 20 calls/minute (subject to change). We debounce
  (350 ms), cancel in-flight requests, and cache recent queries in memory.
- Terms: results may be used to promote/link to content; artwork belongs to the
  publisher and is shown unmodified. Must re-read current terms before release.
- Tradeoffs: no episode data (we read RSS ourselves — required anyway); some
  entries lack `feedUrl` (filtered out and counted); rate limit is per-IP and
  undocumented in detail.
- Rejected: Podcast Index (needs key+secret → would need a backend to avoid
  embedding a secret); scraping (unlawful/fragile).
- Dedupe: by `collectionId`, then by canonical feed URL (lowercased host,
  https, no trailing slash, no fragment).

## D04 · 2026-10-14 · Persistence: Codable JSON files in Application Support
Data is small (subscriptions, episode positions, settings). Atomic file writes
behind a `LibraryStore` protocol are trivially testable with a temp directory,
avoid SwiftData migration/threading risk. Revisit if data grows (e.g. thousands
of cached episodes).

## D05 · 2026-10-14 · Playback: AVPlayer, app-local gain via `AVPlayer.volume`
`AVPlayer.volume` scales only this player's output, never system volume.
Background audio via `UIBackgroundModes: audio` with a `.playback` session —
legitimate, only while actually playing. No silent-audio keep-alive.

## D06 · 2026-10-14 · Sleep = pure state machine in NightCastCore
`SleepTimer` is a value type advanced by *active playback seconds*. The app's
`SleepDriver` measures active time with an injectable clock while the player is
playing and not buffering. No SwiftUI timer participates in correctness.
Sleep state is never persisted → can never auto-resume after relaunch.

## D07 · 2026-10-14 · Sleep edge interpretations (V1)
- Step smoothing: 2.0 s linear ramp of active playback per step.
- "At zero": the 0% step ramp completes, then pause + save + end Sleep + restore gain to B
  (silently, while paused).
- Cancel while playing: ramp back to B over 1.0 s active time. Cancel while paused:
  restore B immediately (inaudible).
- Scrubbing does not change the countdown (it counts active playback seconds, not position).
  R is captured once at activation.
- Short episodes: if the episode ends before the fade finishes, it stops normally;
  Sleep ends; gain restored.
- Deliberately starting a different episode cancels Sleep. Resuming the same episode does not.
- Duration unknown → 30 min. "Known" = finite, > 0 duration from the player (preferred)
  or the feed's `itunes:duration`.

## D08 · 2026-10-14 · Project layout: Swift package + thin Xcode app
`NightCastCore` (SPM, platform-neutral logic: models, Sleep, RSS, search, store)
is testable with `swift test` on macOS even without the iOS toolchain.
`NightCast.xcodeproj` (app + UI tests) uses Xcode folder-synchronized groups so the
project file stays small and hand-maintainable; no XcodeGen/Tuist install needed.

## D09 · 2026-10-14 · Tool usage
- Replica: recon → architect → design → build → test → diff used, adapted to iOS.
  Skipped: backend, entrepreneur, launch, deploy (not requested). Brand only before release.
- REA: not installed. Public evidence was enough for the questions we had; no
  authorized artifacts were provided. Install only if a concrete question needs it.
- /goal and /ralph-loop are user-typed slash commands; Claude cannot invoke them
  itself. Exact command text is provided in PLAN.md.

## D10 · 2026-10-14 · No 3D engine
Tactility comes from SwiftUI shapes, layered gradients used sparingly, pressed
states, springs and haptics. SceneKit/RealityKit would add weight without serving
the brief.

## D11 · 2026-10-14 · R prefers the stream's measured duration (implemented 2026-10-15)
Observed: Radiolab feed declares 31:22, stream measures 37:04 (dynamically inserted ads).
Sleep tapped before AVPlayer reports duration used the feed value → fade at 9 min instead of 11.
Rule: if Sleep activates before the measured duration is known, use the feed duration
provisionally; when the measured duration first arrives while still waiting, recompute
fadeDelay once from the corrected R (active time already elapsed is kept). Never recompute after that.

## D12 · 2026-10-14 · Hierarchy roles
Primary (text-colored face) = Play/Pause only. Accent = Moon only (plus its small indicators).
No other accent uses, to avoid competing accent colors.

## D13 · 2026-10-14 · Demo launch arguments
`-demo` uses an in-memory store seeded with six real directory shows and loads the newest real
Radiolab episode paused at 14:22. Used only for screenshots; never affects the real library.
Flags: `-theme paper|ink|ember`, `-openPlayer`, `-sleepOn`, `-autoplay`, `-fastSleep` (short fade timings for manual demo).

## D14 · 2026-10-15 · UI tests run with parallel testing off
`xcodebuild test` with default parallel clones hung (runner installed, never launched) on Xcode 27 /
iOS 27 sim. Always pass `-parallel-testing-enabled NO`.

## D15 · 2026-10-15 · Test fixtures inside the app bundle
`-uitest` swaps in FixtureDirectory / FixtureFeedService and a bundled 90 s 220 Hz tone
(`NightCast/TestSupport/fixture-tone.m4a`, generated, 311 KB). It currently ships in the app bundle;
before release, exclude `TestSupport/` from Release builds (M5).

## D16 · 2026-10-15 · Opening the player from Search
Two modal presentations can't stack from the root, so tapping an episode inside the Search sheet
closes the sheet first, then presents Now Playing (~0.45 s later).

## D17 · 2026-10-15 · What counts as "provisional" duration
R is provisional whenever the stream has not yet reported a finite duration — including when no
duration is known at all (R treated as unknown → 30 min). If a real duration then arrives while
Sleep is still waiting, D11 corrects the delay once. Live streams never report one, so they keep 30 min.

## D18 · 2026-10-15 · Sleep ticker only runs while audio plays
The 4 Hz ticker stops when playback pauses/buffers and restarts on the next play state change.
Correctness doesn't depend on it (the controller measures elapsed active time from the clock and
syncs on every transport change); this just avoids waking the app while paused.

## D19 · 2026-10-15 · xcodebuild does not exit after UI tests here
After tests finish (log shows "Test Suite 'Selected tests' passed"), `xcodebuild` keeps running and
the .xcresult isn't finalized. Scripts wait for the suite summary line, then stop xcodebuild.
Evidence is taken from the log (e.g. `GAIN-SAMPLES:` printed by the fade test).

## D20 · 2026-10-15 · Release excludes TestSupport
App target Release config sets `EXCLUDED_SOURCE_FILE_NAMES = "*/TestSupport/*"` (fixtures, tone,
DebugLaunch); the same code is also wrapped in `#if DEBUG`, and AppModel demo helpers and the
`debugGain` readout are `#if DEBUG`. Verified: Release .app has no tone file and no matching symbols/strings.

## D21 · 2026-10-15 · Accessibility-size layouts
At accessibility Dynamic Type sizes: Library uses one column, Show header and Search rows stack
vertically, the Moon key wraps its subtitle and hides its ticks. The search field alone is capped
at `.accessibility1` because it shares a row with the close key.

## D22 · 2026-10-15 · Development signing (owner-approved)
Team KTV2G3Z883, bundle ID `com.nightcast.ktv2g3z883`, automatic signing. Xcode created an
"Apple Development: Harrison Fischberg" certificate and registered device "Hphone"
(`-allowProvisioningDeviceRegistration`). The dev build is signed with the team wildcard profile
("iOS Team Provisioning Profile: *"), so no explicit App ID was needed yet; App Store distribution
will need an explicit App ID record (created when the App Store Connect app record is made).
Device install command:
`xcodebuild … -configuration Release -destination 'id=<UDID>' -allowProvisioningUpdates -allowProvisioningDeviceRegistration build`
then `xcrun devicectl device install app --device <UDID> <path to .app>`.

## D23 · 2026-10-15 · v0.2 home pages (owner request)
Pager (`TabView` page style) with custom 3-dot indicator: New · Library (default) · Explore.
Pages/dots appear only once the Library has a show, so first launch keeps one clear action.
Search is now a pushed screen (was a sheet) so the root mini player can stay visible.

## D24 · 2026-10-15 · Explore recommendations
No backend, no AI, no account. Inputs: iTunes `lookup` genres of Library shows (primary genre
weight 2, others 1), Apple's legacy per-genre top-podcast charts (top 25 for the top 3 genres),
and directory search for title keywords shared by ≥ 2 Library shows (e.g. "sleep"). Score =
genre overlap + 1.5 × keyword weight + chart-rank bonus; Library shows excluded. Rows:
"Top picks for you" (best 6), then "Because you like <genre>" (≤ 6 each, no repeats).
Grids, not horizontal carousels, to avoid fighting the pager's horizontal swipe.
Observed live: genres alone ranked self-help shows first for a sleep-podcast Library; adding
keyword affinity moved sleep-story shows to the top.

## D25 · 2026-10-15 · New page + feed disk cache
Latest 100 dated episodes from the last 30 days across Library feeds, grouped by day.
Feeds are refreshed 4 at a time once per session and saved to Caches/Feeds, so New and
Show pages render instantly (and offline) from the last copy.

## D26 · 2026-10-15 · Small additions
Long-press a Library tile → Unsubscribe; long-press an episode → Play / Mark as Played.
Accent pip on Library tiles with an unplayed episode from the last 7 days.

## D27 · 2026-10-15 · Dedicated simulator
Another project's session uses the booted "iPhone 17" simulator. NightCast tests and screenshots
now run on "iPhone 18 Pro" (`scripts/test.sh` default; override with NIGHTCAST_DEST).

## D28 · 2026-10-15 · Sleep v0.3 spec (owner request)
`SleepConfiguration.standard`: step 60 s, levels 0.9…0.0 (10 steps), still `min(30 min, R/2)` delay,
2 s glides. Full fade = 9 min + 2 s after the countdown. Old V1 numbers kept as a test-only `.v1`
config so state-machine mechanics tests stay meaningful. `-fastSleep` debug timings: 4 s delay, 3 s steps.

## D29 · 2026-10-15 · ±5 minute bubble semantics
`SleepTimer.adjust(by:)`: while waiting, moves the fade start (clamped to now…now+4 h). While fading,
+5 pauses the fade (volume glides up over the cancel ramp via a "lift", fading restarts after 5 min)
and −5 is disabled. The bubble replaces the visual "Sleep on" toast; VoiceOver still announces it.

## D30 · 2026-10-15 · Full episode history
Show pages already listed every episode in a feed. `HTTPFeedService` now also follows
`<atom:link rel="next">` pages (up to 40, loop-safe, keeps earlier pages if a later one fails).
Episodes are grouped by year with pinned headers; Newest/Oldest toggle per show page.

## D31 · 2026-10-15 · Floating Z's
Canvas + TimelineView (30 fps cap), 4 glyphs in the theme accent, drawn only while Sleep is on and the
Now Playing screen is visible; static when Reduce Motion is on. No sound. Brief's "avoid constant motion"
is overridden by the owner for this element only.

## D32 · 2026-10-15 · "Website copy"
There is no NightCast website yet; the README and in-app copy were updated instead. A Rare Creatures
site (needed for the LLC's Apple enrollment and app privacy pages) would carry the public copy later.

## D33 · 2026-10-15 · v0.4 mini player visibility (owner request)
Always shown while audio plays. When paused, a chevron (or a downward swipe) slides it away;
it returns as soon as anything plays (`isMiniPlayerHidden` resets on play).

## D34 · 2026-10-15 · Collapsible Sleep bubble
The ±5 bubble opens with Sleep, tucks into a small pill ("⏱ 11 min ⌃") after 5 quiet seconds or a tap
on its center; tapping the pill reopens it. Any ±5 tap restarts the 5-second timer.

## D35 · 2026-10-15 · Explore categories
26 Browse cards: 24 Apple genres (ids verified live against Apple's charts — several remembered ids
were wrong, e.g. 1508 is Home & Garden) plus 2 topic searches with no genre (AI → "artificial
intelligence", Sleep → "sleep stories"). Category page = genre top 50 in chart order, or search
results. "Your interests" chips (top of Explore) = shared title keywords first, then Library genres.

## D36 · 2026-10-15 · Midnight theme, default
Animated night sky (gradient, 3 slow waves, 80 deterministic twinkling stars, a few glints), ~15 fps,
frozen under Reduce Motion. Tokens in `replica/design/tokens.midnight.json`; 0 AA failures, including
text over the lightest wave. Becomes the default once (appearanceVersion 4) for users on the old
default (unset/Ink); Paper and Ember choices are kept.

## D37 · 2026-10-15 · Library layouts and reorder
Large (2 col) / Small (3 col) / List, saved with the Library; header key cycles, Settings picks.
Reorder: press-hold-drag a show onto another (draggable/dropDestination with the show id), plus
Move to Top / Move to End in the long-press menu and as VoiceOver actions. "Appearance" sheet is now
"Settings" (layout + theme).

## D38 · 2026-10-15 · Shared simulators
Another project's session has also launched apps on "iPhone 18 Pro" (status bar showed "◀ Keepsake").
Screens captured here were NightCast's; if collisions grow, create a dedicated "NightCast" simulator.

## D39 · 2026-10-15 · Themes: Scenes and Color Scapes (owner request, v0.5)
Library header keeps the one-click layout key (Large → Small → List). The second key is now a
dark/light circle labelled "Themes" and opens the Themes sheet (layout removed from it).
Scenes (animated, calm, night-time like Midnight): Midnight, Mountain Vista (violet dusk, moon at the
right edge, layered peaks, drifting mist), Beach (moon on the horizon, shimmering moon path, foam
lines, lapping shore), Rainforest (swaying canopy layers, mist, foreground leaves, blinking fireflies),
City Scape (Tokyo-style neon haze, two skyline layers with windows switching on/off, pulsing neon
signs, light rain). Color Scapes: Paper, Ember, Ink. One shared SceneRenderer (Canvas, ~15 fps,
deterministic layouts, still under Reduce Motion); theme swatches show a still frame of the scene.
Tokens `replica/design/tokens.{mountain,beach,rainforest,city}.json`: 0 AA failures incl. text over
each scene's brightest area. Moons were first placed under page titles; moved after screenshot review
so no scene puts a bright shape where text sits (Mountain: right edge; Beach: on the horizon).

## D40 · 2026-10-15 · Underwater scene and Red Light color scape (owner request, v0.6)
Scenes now 6: + Underwater (light rays from the surface, slow fish silhouettes with wagging tails,
rising bubbles, swaying kelp; coral accent). Color Scapes now 4: + Red Light (true black, red-only
interface — superseded by D41's softer warm palette; every token's blue channel was 0; key highlights and Explore card tints switch to red via
`Theme.blueFree`). Tokens `replica/design/tokens.{ocean,redlight}.json`, 0 AA failures after retuning
Red Light (first pass had small blue values and a 2.87:1 input border).
Limits, stated honestly: podcast artwork keeps its real colors (the brief forbids altering publisher
artwork), and iOS-drawn parts (status bar, keyboard, context menus, share sheets) keep system colors.
This is a red-tinted interface, not a hardware blue-light filter; iOS Night Shift / Color Filters do that.

## D41 · 2026-10-15 · v0.7 tweaks (owner request)
- Red Light softened: warm near-black with coral/terracotta text (#EFA084 / #CC8A72, accent #D9805F).
  This needs a little blue, so it's described as "Warm, low blue", not "no blue". `Theme.warmOnly`
  keeps key highlights and Explore card tints warm. 0 AA failures.
- Hidden mini player no longer disappears: it tucks into a small oval (artwork + ⌃) at the bottom;
  tap (or swipe up) restores it. Playing anything restores it too.
- Themes sheet: opens at 80% height, `.presentationContentInteraction(.scrolls)` so swipes inside always
  scroll the list, visible grabber for resizing (it was fighting between scroll and resize at half height).

## D42 · 2026-10-15 · v0.8 search in place; category page fix (owner request + bug)
- No separate Search screen. Tapping search on Library or Explore turns the header/search bar into a
  real field (+ Cancel); the page's content glides down 180 pt and fades out; results fade in where it
  was. One shared `SearchModel` in AppModel; `searchingOn` says which page is searching; changing page
  or Cancel ends it. Opening a result and coming back keeps the search (field focuses only on first open).
- Mini player tucks away while the keyboard is up (it was covering results).
- Bug (owner screenshot): a category page showed a narrow scene column with black sides for 1–3 s.
  Cause: while loading, the page's content was only as wide as its title and the scene background took
  that width. Fix: content and background fill the screen from the first frame (also on show pages), and
  loading shows placeholder tiles in the final grid instead of a spinner.
