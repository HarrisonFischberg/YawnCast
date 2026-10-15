# NightCast

> "NightCast" is a temporary internal name. It has not been trademark-cleared.

A native iPhone podcast app for falling asleep.

**v0.3:** show pages list every episode, start to finish, under year headings (Newest/Oldest toggle); Sleep fades 10% a minute, has a ±5 minute bubble, and floating z's.

**v0.2:** Home is three swipeable pages with dots: **New** (latest episodes from your shows), **Library**, and **Explore** (similar shows). The mini player stays on every screen once something is loaded. Show and Now Playing are unchanged.
Its signature control is the **Moon** button: one tap, and the episode fades out in steps and then pauses.

Status: built and tested on the **iOS Simulator only**. It has not been run on a physical iPhone.
It is **not** App Store-ready (see [Known limitations](#known-limitations)).

---

## Setup and run

Requirements: macOS with **Xcode 27** (iOS 27 SDK) and an iOS Simulator runtime. The minimum iOS version is **18.0** ([DECISIONS D02](DECISIONS.md)).

```bash
open NightCast.xcodeproj
```

Choose the **NightCast** scheme and an iPhone simulator, then press Run. No API keys or accounts are needed.

From the command line, if `xcode-select` points at the Command Line Tools rather than Xcode:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project NightCast.xcodeproj -scheme NightCast -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Debug-only launch arguments
These are excluded from Release builds ([D20](DECISIONS.md)).

| Argument | Effect |
|---|---|
| `-demo` | Uses an in-memory library seeded with 6 real shows and loads a real Radiolab episode, paused |
| `-theme paper\|ink\|ember` | Forces a theme |
| `-openPlayer`, `-openShow`, `-search <term>`, `-sleepOn`, `-autoplay` | Opens screens or starts states, used for screenshots |
| `-fastSleep` | Short Sleep timings: fade after 4 s, a step every 6 s |
| `-uitest [-resetStore]` | Fixture search and feeds, a bundled test tone, and a separate library file |
| `-liveTest` | Real network with a throwaway in-memory library |

---

## Architecture

```
NightCastCore/  (Swift package, no UIKit/AVFoundation; tested with `swift test`)
  Models/       Show, Episode, PlaybackPosition, Feed, FeedURL (canonical identity)
  Directory/    DirectoryService, ITunesDirectory (search, lookup, genre charts), Recommender
  Feed/         FeedService, HTTPFeedService, RSSParser (XMLParser; durations, dates, HTML), LatestEpisodes
  Persistence/  LibraryStore, JSONLibraryStore (atomic; moves corrupt files aside), MemoryLibraryStore
  Sleep/        SleepTimer (pure state machine), SleepController (clock, active-time meter)
  Playback/     SeekMath, TimeFormat, SleepCopy

NightCast/      (SwiftUI app, iOS 18+, Swift 6, default MainActor isolation)
  App/          NightCastApp, AppModel (library, feeds cache, playback, Sleep wiring)
  Playback/     PlaybackEngine (AVPlayer, audio session, interruptions, route change, gain)
                NowPlayingBridge (Lock Screen info, remote play/pause/±15/scrub)
                ArtworkCache (memory + disk; artwork never altered), FeedDiskCache
  Design/       Theme tokens, KeyStyle (physical key), MoonKey, Scrubber
  Views/        HomeView (pager, PageDots, NewEpisodesView, ExploreView), LibraryView + MiniPlayer,
                SearchView, ShowView, NowPlayingView, AppearanceSheet
  TestSupport/  Fixtures + DebugLaunch (Debug only)
NightCastUITests/  CoreFlowUITests, SleepUITests, LiveNetworkUITests (opt-in)
```

- **Search:** Apple iTunes Search API. No credentials, and no backend ([D03](DECISIONS.md)).
- **Sleep:** a deterministic state machine that only advances on *active playback seconds*. Paused or buffering time doesn't count. The clock is injectable for tests, and no SwiftUI timer is involved.
- **Fade:** the app sets `AVPlayer.volume`, which is local to the app; it never changes the device volume.
- **Sleep and relaunch:** Sleep state is never persisted, so it can't come back on its own after a relaunch.

### Sleep behaviour (v0.3)
Let R be the playable seconds remaining when Moon is tapped.

1. **Countdown:** the fade begins after `min(30 min, R/2)` of active playback, or after 30 min if the duration is unknown. Paused or buffering time doesn't count.
2. **Adjust it:** a bubble pops up above the Moon key with **−5 min** and **+5 min**.
   - −5 can bring the fade forward to "now", never into the past.
   - +5 can push it out to at most 4 hours.
   - While fading, +5 pauses the fade: the volume glides back up, and fading starts again 5 minutes later.
3. **Fade:** the volume drops **10% every minute**: 90%, 80% … 10%, 0%. Each step is a 2 s glide.
4. **Silence:** at 0% the episode pauses, the position is saved, Sleep ends, and the volume is restored silently. Nothing else plays.
5. **While Sleep is on,** small "z"s drift up out of the moon. With Reduce Motion they sit still.
6. **Cancelling:** a second Moon tap cancels Sleep and glides the volume back over 1 s. Playing a different episode also cancels it.
7. **Scrubbing** doesn't reset the countdown.
8. If Moon is tapped before the stream reports its real length, the feed's length is used, then corrected once ([D11](DECISIONS.md)).

---

## Design tokens and themes

All three themes pass WCAG AA. Check with Replica's `contrast.py` on `replica/design/tokens.<theme>.json`. Full principles are in [replica/design/principles.md](replica/design/principles.md).

| Role | Paper (day) | Ink (dark) | Ember (bedtime) |
|---|---|---|---|
| bg | #F2EDE3 | #111113 | #070504 |
| surface | #E7E0D2 | #1C1C20 | #110C09 |
| raised | #FBF8F2 | #26262B | #1A120D |
| text | #1C1A16 | #F1EEE7 | #B98F6C |
| text-muted | #5C564B | #A29E95 | #9C7A5C |
| accent (Moon only) | #2E2A6B | #E9B44C | #C27142 |
| on-accent | #F7F3EA | #1A1408 | #070504 |
| Lowest text contrast | 5.54:1 | 6.36:1 | 4.95:1 |

Ember's brightest text has a relative luminance of 0.31, against 0.86 for Ink.

Type uses system fonts only (SF / New York via `.serif`), mapped to Dynamic Type styles. Spacing is on a 4 pt base. Play/Pause is the only button with the primary face; the accent colour is used only for the Moon ([D12](DECISIONS.md)).

---

## Tests: commands and actual results

```bash
scripts/test.sh
```

```bash
scripts/test.sh --live
```

`scripts/test.sh` runs core tests, Debug and Release builds, and the fixture UI tests. `--live` also runs the real-network test.

Results from the last full run (2026-10-15, v0.3, iPhone 18 Pro simulator, iOS 27.0):

| Check | Result |
|---|---|
| `swift test` (NightCastCore) | **83 tests in 14 suites passed**: Sleep timing, gain sequence, pause and buffering freeze, cancel, episode end, seek, provisional duration, RSS fixtures (including malformed), search decoding and dedupe, persistence, seek clamping, genres and charts, recommendations, New-page ordering, 10%-per-minute fade, ±5 adjustments, paged feeds, year grouping |
| Debug and Release builds | **BUILD SUCCEEDED**, no Swift warnings. The Release bundle contains no fixtures and no debug symbols |
| Fixture UI tests | **13 executed, 0 failures**: empty library; search empty, error and retry; subscription survives relaunch; subscribe → play → Sleep on/off; position survives relaunch (no autoplay); full fade on the real player; cancel mid-fade; pause freezes the countdown; page dots and swipes; mini player on every screen; unsubscribe from Library; ±5 bubble; year sections and order toggle |
| Live UI test (opt-in) | **Passed** (2026-10-15): real search, real RSS (524 episodes), subscribe, stream played with the position advancing |

The full-fade UI test drives the real `AVPlayer.volume` through every step and checks it never rises, hits each level, then pauses with the volume restored. The sampled sequence for the v0.2 spec is in PROGRESS.md.

Replica checks:
- **Parity:** `parity.py` scores **90.7**. 9 of 11 must-haves are done. The other two, Lock Screen and background audio, are *implemented but unverified on device*. See [replica/parity.md](replica/parity.md).
- **Brand sweep:** `sweep.py` finds nothing in `NightCast/`, `NightCastCore/` or `Config/`. Reference names appear only in internal research docs.

## Screenshots

| Folder | Contents |
|---|---|
| `screenshots/m2/` | Library and Now Playing in all 3 themes, Sleep on, empty state, AX5 text |
| `screenshots/m3/` | Live run: real search, show detail, streaming |
| `screenshots/m5/` | Show and Search in Paper and Ember; Show, Search and Library at AX5 text |
| `screenshots/v2/` | New, Library, Explore pages; mini player on Show detail |
| `screenshots/v3/` | Sleep with ±5 bubble and z's (Ember, Ink, Paper fading); show page year sections |

---

## Physical-device validation checklist (owner)

None of these can be marked PASS from simulator results. Record outcomes in [ACCEPTANCE.md](ACCEPTANCE.md).

| ID | Check | How |
|---|---|---|
| D1 | Real audio streams | Search, subscribe, play any episode on cellular and on Wi-Fi |
| D2 | Locked-screen playback | Play, lock the phone, wait 2 min: audio continues and Lock Screen shows the title and time |
| D3 | Background fade | Play, tap Moon, lock the phone. For a quick check use a short episode (R/2 is small); confirm the steps fade and it pauses |
| D4 | Headphone disconnect | Play on wired or Bluetooth headphones, disconnect: playback pauses and does **not** resume by itself |
| D5 | Interruptions | Receive a call or use Siri mid-play: playback pauses and resumes after if iOS allows; Sleep countdown doesn't advance while paused |
| D6 | Remote controls | Lock Screen, Control Center and AirPods: play/pause, ±15, scrub |
| D7 | No unexpected next episode | Let an episode finish, and let Sleep reach 0: nothing else starts |
| D8 | Dark-room readability | Use Ember in a dark bedroom; judge comfort, especially the lit Moon key |

## Known limitations

- **Not verified on device:** Lock Screen, remote commands, background audio, interruptions and route changes are implemented but have only been checked in code and on the simulator.
- **No downloads or offline playback:** streaming only.
- **Search provider:** the iTunes Search API is rate-limited (about 20 requests/min, per Apple) and some shows lack feed URLs. Re-read Apple's terms before release.
- **No dedicated unit tests** for the search model's debounce and cancellation. They are covered indirectly by UI tests.
- **No app-level crash or analytics reporting.**
- **App icon** is an original placeholder (moon on a key).
- **The name** is a working name, not trademark-checked (run `/replica-skill:replica-brand` before launch).
- **Lock Screen artwork** comes from the episode or show artwork when it can be fetched.

## Signing and TestFlight (needs you)

Nothing has been uploaded, signed, or changed in any developer account.

1. Signing is already set up for development: team `KTV2G3Z883`, bundle ID `com.nightcast.ktv2g3z883`, automatic signing. For release you may want a nicer bundle ID (it can't change after the first App Store upload).
2. Keep the **Background Modes → Audio** capability. It's already in `Config/NightCast-Info.plist`.
3. Run on your iPhone and work through checks D1–D8 above.
4. Do **Product → Archive** with the **Release** configuration, then **Distribute App → App Store Connect → Upload**.
5. In App Store Connect, create the app record (name, privacy details — the app sends search terms to Apple and fetches feeds from publishers, but you collect nothing; confirm when filling in the form), add internal testers, and start TestFlight.
6. Before any public release: a trademark-cleared name, final icon, a privacy policy URL, and a review of the iTunes Search API terms.
