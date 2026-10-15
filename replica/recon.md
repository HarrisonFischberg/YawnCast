# Recon map (replica-recon, adapted to native iOS)

Labels: **[O]** observed in a public source · **[I]** interpretation · **[P]** our proposed design.

## Scope
- App: Neuecast (iOS). Slice: subscribe → episodes → play → sleep. For: owner's own app.
- Evaluate against THIS brief, not Neuecast parity. Different layouts are intentional.

## Sources
| source | url | what it gave |
|---|---|---|
| Neuecast marketing site | https://neuecast.app/ | [O] Tagline "A podcast app designed for the rest of us"; positioning "Everything you need, and nothing you don't"; two unlabelled phone images; dev Rishi Mody, © 2024 |
| Neuecast App Store listing | https://apps.apple.com/app/id6744658836 (linked from search; content not retrieved) | gap |
| appgefahren.de / iphone-ticker.de reviews | https://www.appgefahren.de/neuecast-minimalistische-podcast-app-fuer-das-iphone-startet-363719.html | [O] (secondary, via search summary) adjustable speed, sleep timer exist. No fade behaviour described |
| Not Boring bundle | https://apps.apple.com/us/app-bundle/not-boring-apps/id1847738447 | [O] 6 apps: Weather, Calculator, Timer, Camera, Habits, Vibes; "2x Apple Design Awards" |
| notbor.ing/llms.txt | https://notbor.ing/llms.txt | [O] "one thing exceptionally well"; 3D, animation, physics, haptics, sound; skins; Camera has 3D interface + manual controls; Timer swipe-based, glanceable |
| Third-party Camera reviews | https://coolcuration.com/not-boring-camera-app-review-uk | [O] (secondary) physical dials, knurled dial, shutter that clicks and buzzes, SceneKit lighting |

## Evidence gaps (recorded honestly)
- No screenshots or recordings of Neuecast or any Not Boring app were captured or provided.
  `replica/screens/` is empty. **No precise visual observations are claimed** (no measured
  colours, sizes, spacing).
- App Store URLs do not give binary or runtime access; none attempted.
- REA was not used: no authorized local artifacts exist, and the public website has nothing
  interaction-specific to analyze.
- Therefore the NightCast visual design is an **original design [P]** guided by stated
  principles, not by measured layouts.

## Screens [P]
| ID | screen | how you get there | purpose | states |
|---|---|---|---|---|
| S01 | Library | launch | subscribed shows grid | empty, filled, loading artwork, mini-player shown/hidden |
| S02 | Search | Library search button | find shows | idle, typing/debouncing, loading, results, no results, error+retry, offline |
| S03 | Show detail | tap show (Library or Search) | info, subscribe, episodes | loading feed, loaded, feed error+retry, empty feed, unsubscribed preview |
| S04 | Now Playing | tap episode / mini-player | control playback + Sleep | playing, paused, buffering, error, sleep armed, sleep fading |
| S05 | Appearance sheet | Library theme button | pick theme | — |

## Flows
F01–F05 in PLAN.md. Happy path to "asleep with fade": search 1 + result 1 + subscribe 1 + episode 1 + moon 1 = **5 taps** from empty app.

## Components [P]
PressableButton (pressed depth + haptic), MoonButton, TransportButton (±15, play/pause),
Scrubber (accessible adjustable), ArtworkTile, EpisodeRow (progress ring), MiniPlayer,
SearchField, StateView (loading/empty/error), Toast (sleep status).

## Inferred data model [I]
```
Show        id (feed URL canonical), directoryId?, title, author, summary, artworkURL, feedURL
Episode     id (guid || enclosure URL), showId, title, published, duration?, audioURL, summary
Position    episodeId, seconds, duration?, completed, updatedAt
Library     subscriptions [Show], positions [episodeId: Position], lastEpisodeId?, themeId
```
Confidence: high (standard RSS/podcast namespace).

## Cannot / will not clone
Neuecast branding, copy, artwork, icons; Not Boring skins, 3D models, sounds, layouts;
any proprietary implementation. Licensed podcast content is streamed from publishers, never stored or rehosted.

## Size
M. Hard parts: Sleep correctness in background; audio session edge cases; RSS variety.
