# NightCast app profile (cycle 001, base = main @ 9fbcc25)

Calm iPhone podcast player for falling asleep. SwiftUI, iOS 18+, no account, no backend.
Search = Apple iTunes Search API; feeds fetched straight from publishers; streaming only.

## Screens (seen in the Simulator with `-demo`, 2026-10-21)
- **Home pager** (3 dots): **New** (latest episodes from Library shows grouped Today / weekday, play ring shows progress, pull to refresh, long-press menu Play / Mark as Played), **Library** (artwork grid Large / Small / List, drag reorder, long-press menu incl. move to top/end and unsubscribe, new-episode pip), **Explore** ("Your interests" chips, top picks by genre, Browse categories, pull to refresh).
- **Search** in place on Library/Explore (filters your shows + finds new ones).
- **Show detail**: artwork, description, Subscribe, episodes by year, Newest/Oldest, pull to refresh, long-press menu.
- **Now Playing** (full-screen cover, swipe down to close): show eyebrow, serif title, scrubber, -15 / play / +15 keys, big Sleep bar ("Sleep on · Fade begins in 17 min"), ±5 min bubble, floating z's.
- **Mini player** floats on every screen once something is loaded.
- **Themes sheet**: 6 animated Scenes + 4 Color Scapes, with the version line at the bottom. Cycle 001's five features are always on (no flags).
- Shots: `cycles/001/shots/base-nowplaying.png`, `base-new.png`.

## Sleep (signature)
One tap on Moon. Countdown = min(30 min, remaining/2) of active playback, then volume steps down 10% every 40 s (6 min), then pause and save position. ±5 min bubble. VoiceOver announcements. Never plays the next episode. Logic in `NightCastCore/Sleep/`, glue in `AppModel.toggleSleep`.

## System integration today
- Lock Screen / Control Center via `NowPlayingBridge`: play, pause, ±15, scrub. Next/previous/rate disabled.
- No widgets, no Live Activity, no App Intents / Siri / Shortcuts, no Control Center control, no CarPlay.
- No downloads (streaming only), no queue, no autoplay-next, no speed control (owner: out of scope).
- No "rewind on resume after sleep", no shake-to-extend, no end-of-episode sleep mode.

## Owner's out-of-scope list (PROJECT_BRIEF.md) - ideas here need Harold's decision
Onboarding, accounts, social, recommendations (Explore excepted), ads, monetization, AI summaries, queue manager, autoplay-next, playback speed in main player, large artwork on Now Playing, waveforms, transcripts.

## Not exercised this cycle
Real audio output and Lock Screen on a device; AirPods route changes; long-running fade (covered by existing UI tests with `-fastSleep`).

## In-flight work not in base (open PRs)
- PR #5 gap under mini player; PR #6 Sleep button copy ("Ready for bed?" / "Sweet dreams"); PR #7 Themes "Scenes" + Sleep chip/timeline redesign. Iterations should avoid the Sleep bar's visuals to keep those PRs mergeable.
