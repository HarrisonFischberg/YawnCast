# Tasks

Priority order. `[x]` done and verified · `[~]` in progress · `[ ]` todo · `[!]` blocked.

## M1 Research & scope
- [x] Inspect environment (macOS, Xcode, SDKs, simulators, Node, Python)
- [x] Verify Replica / REA / Ralph / /goal availability
- [x] Read replica-skill and morluto/rea instructions
- [x] Recon (replica/recon.md, features.csv) with evidence labels and gaps
- [x] Architecture, flows, design principles, 3 themes + contrast check
- [x] Tracking files

## M4-core (no Xcode needed; pulled forward) — 50 tests green
- [x] NightCastCore package skeleton + `swift test` green
- [x] SleepTimer state machine + virtual-time tests (M4.1–M4.7, M4.9)
- [x] SeekMath + TimeFormat + tests (M3.6)
- [x] RSSParser + fixtures incl. malformed (M3.3)
- [x] ITunesDirectory decode + dedupe + tests with stub URLProtocol (M3.1 logic, M3.2)
- [x] JSONLibraryStore + persistence tests (M3.4/M3.5 logic)

## M2 Visual direction
- [x] Owner: accept Xcode license
- [x] Create NightCast.xcodeproj (app + UI tests) linking NightCastCore
- [x] Theme system + PressableButton + MoonButton + Scrubber
- [x] Library prototype (grid, empty state, mini-player) with sample artwork from real feeds
- [x] Now Playing prototype
- [x] Simulator screenshots × 3 themes × (default, AX text)
- [x] Accessibility review → request human approval

## M3 Vertical slice
- [x] Visual approval (owner, 2026-10-15)
- [x] PlaybackEngine (AVPlayer, session, interruptions, route change)
- [x] NowPlayingBridge (lock screen, remote ±15) — implemented, unverified on device
- [x] Search / Show / Library wired to real services
- [x] Relaunch restores subscriptions + positions (UI tests)
- [x] Fixture mode `-uitest` + 5 UI tests; opt-in live-network UI test
- [ ] SearchModel unit tests for debounce/cancel (needs an app unit-test target)

## M4 Sleep in app
- [x] Fix: R uses feed duration if Sleep is tapped before AVPlayer reports measured duration (observed: feed 31:22 vs stream 37:04 → "9 min" instead of 11). See DECISIONS D11
- [x] SleepDriver with injectable clock → AVPlayer.volume (AppModel ticker, gated on active playback)
- [x] Sleep UI states + toast + VoiceOver announcements
- [x] Sleep UI tests on real player (full fade, cancel, pause freezes)

## M5 Polish & regression
- [x] UI tests subscribe → play → Sleep
- [x] Dynamic Type AX5 pass (Library 1-col, Show/Search stacked layouts, capped search field)
- [ ] VoiceOver live pass (labels verified in code + UI tests only)
- [x] Exclude TestSupport from Release (EXCLUDED_SOURCE_FILE_NAMES + #if DEBUG)
- [x] Search: Return key searches immediately
- [x] Replica parity + brand sweep
- [x] scripts/test.sh
- [x] Final handoff docs (README, screenshots, device checklist)

## Owner / device (not automatable)
- [ ] Device checks D1–D8 (README)
- [ ] Signing team + bundle ID, TestFlight
- [ ] Trademark-cleared name, final icon (`/replica-skill:replica-brand`)

## v0.2 (owner request 2026-10-15)
- [x] Persistent mini player on every screen
- [x] 3-dot pager: New · Library · Explore, swipe + tappable dots
- [x] New page (latest episodes by day) + feed disk cache
- [x] Explore (genres + keywords + charts), Top picks row
- [x] Unsubscribe / mark played menus, new-episode pip
- [x] UI tests for pager, mini player, unsubscribe
- [ ] Device check of v0.2 (owner)

## v0.3 (owner request 2026-10-15)
- [x] Fade 10% every minute
- [x] ±5 min bubble above Moon (adjust countdown; +5 pauses an active fade)
- [x] Floating z's while Sleep is on (still under Reduce Motion)
- [x] Full episode history: follow paged feeds; year sections; Newest/Oldest
- [x] UI tests for bubble and year sections
- [ ] Device check of v0.3 (owner)
- [ ] Rare Creatures website (owner LLC; privacy/support pages)

## v0.4 (owner request 2026-10-15)
- [x] Mini player: always while playing; tap to slide away when paused
- [x] Sleep bubble tucks into a pill; tap to reopen
- [x] Midnight night-sky theme (waves + stars), default
- [x] Library drag-to-reorder; Large / Small / List; Settings sheet
- [x] Explore: search, Your interests at top, Browse categories + category pages
- [ ] Device check of v0.4 (owner)

## v0.5 (owner request 2026-10-15)
- [x] Themes key (dark/light icon) → Themes sheet; layout stays one-click
- [x] Scenes: Midnight, Mountain Vista, Beach, Rainforest, City Scape (animated, AA contrast)
- [x] Color Scapes: Paper, Ember, Ink
- [ ] Device check of v0.5 scenes (battery/comfort at night, owner)

## v0.6 (owner request 2026-10-15)
- [x] Underwater scene (6 scenes total)
- [x] Red Light color scape (4 scapes total), blue-free tokens + key/card tints
