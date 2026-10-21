# Plan

## Architecture

```
YawnCastCore (Swift package, no UIKit/AVFoundation)
  Models        Show, Episode, PlaybackPosition, Subscription
  Directory     DirectoryService protocol, ITunesDirectory (URLSession), dedupe
  Feed          FeedService, RSSParser (XMLParser), duration/date parsing
  Persistence   LibraryStore protocol, JSONLibraryStore (atomic files)
  Sleep         SleepTimer (pure state machine), SleepEffect
  Playback math SeekMath (clamp, ±15), TimeFormat

YawnCast app (SwiftUI, iOS 18+)
  Playback      PlaybackEngine (AVPlayer, gain, session, interruptions, routes)
                NowPlayingBridge (MPNowPlayingInfoCenter, MPRemoteCommandCenter)
                SleepDriver (feeds active seconds from an injectable clock into SleepTimer)
  Artwork       ArtworkCache (memory + disk, URLSession)
  UI state      LibraryModel, SearchModel, ShowModel, PlayerModel (@Observable)
  Views         LibraryView, SearchView, ShowView, NowPlayingView, AppearanceSheet
  Design        Theme tokens, Moon control, pressable button style, haptics
YawnCastUITests  launch arg `-uitest` swaps network for fixtures
```

Data flow: views → @Observable models → services. Services are protocols; tests inject fakes.

## Flows (happy-path taps)

- F01 Find & subscribe: Library → Search (1) → type → result (2) → Subscribe (3).
- F02 Play: Library → show (1) → episode (2) → plays + Now Playing opens.
- F03 Sleep: Now Playing → Moon (1). Cancel = Moon again (1).
- F04 Resume: Library mini-player play (1) or open (1) → play.
- F05 Appearance: Library → theme button (1) → pick theme (2).

## Milestones

1. **M1 Research & scope** — done (see ACCEPTANCE M1).
2. **M2 Visual direction** — Library + Now Playing prototype with 3 themes, screenshots,
   a11y review, then **stop for human approval**.
3. **M3 Vertical slice** — real search → subscribe → episodes → play → lock screen → relaunch.
4. **M4 Sleep engine** — state machine (core logic can start early; it has no UI dependency),
   then wire to `AVPlayer.volume`.
5. **M5 Polish & regression** — states, typography, UI tests, full regression.

## How /goal and /ralph-loop are used (owner types these; Claude cannot)

Sequential, never nested. One milestone each.

- **M3 via /goal** (narrow, verifiable):
  `/goal M3 vertical slice: ACCEPTANCE.md M3.1–M3.7 all PASS, verified by xcodebuild build + test output recorded in PROGRESS.md. Device checks excluded.`
- **M4 via Ralph** (bounded loop):
  `/ralph-loop "Read PROGRESS.md and ACCEPTANCE.md. Implement the highest-priority unfinished M4 item. Run swift test in YawnCastCore and xcodebuild test. Record results in PROGRESS.md. Output <promise>M4 VERIFIED</promise> only when M4.1–M4.10 are PASS by actual test output. If the same external blocker occurs 3 times, document it and stop." --max-iterations 12 --completion-promise "M4 VERIFIED"`
  Requires installing the `ralph-loop` plugin first (see PROGRESS.md).
- **M5 via Ralph** after M4 completes, same pattern, `--completion-promise "M5 VERIFIED"`.

## Prerequisites for the owner

1. Accept the Xcode license (blocking all iOS builds):
   `sudo xcodebuild -license accept` (with Xcode selected; see PROGRESS.md).
2. Optionally `sudo xcode-select -s /Applications/Xcode.app` (Claude can work around
   with `DEVELOPER_DIR` and won't change it).
3. Install an iOS Simulator runtime if none is present after (1).
4. Install ralph-loop: `/plugin install ralph-loop@claude-plugins-official`.
