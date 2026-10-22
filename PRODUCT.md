# Product

<!-- impeccable:product-schema 1 -->

> Written by `/impeccable init` on 2026-10-19 from the repo's own record (PROJECT_BRIEF.md, README.md, DECISIONS.md, replica/design/). The owner was not interviewed for this file; every line below is taken from those documents, and lines marked *(inferred)* are my reading of them, not the owner's words.

## Platform

ios

## Users

One person listening in bed, tired, in the dark, wanting to fall asleep to a podcast without the audio running all night or skipping to the next episode. They use the phone one-handed, often with eyes half closed, at the end of the day.

## Product Purpose

NightCast is a native iPhone podcast player for falling asleep. Its job is to let someone pick a show, start an episode, and hand the ending over to the app: one tap on the Moon key, and the episode fades out in steps and pauses, saving the position. Success is the listener drifting off and waking to the episode paused where they left it, never a different episode playing.

## Positioning

"Everything you need, nothing you don't" for bedtime listening. The mechanism no general podcast app copies: a single-tap Sleep that counts only active playback time, fades app-local volume in 10% steps every 40 seconds, and then pauses, with a ±5 minute adjust bubble and no picker.

## Operating Context

- Bed, lights off or low, phone held close to the face; bright UI is a cost, not a neutral choice *(inferred from Ember and Red Light themes and device check D8)*.
- Sessions are short and habitual: open, resume or pick, tap Moon, put the phone down.
- Daytime visits happen too: browsing Explore, subscribing, reordering the library.

## Capabilities and Constraints

- Home is three swipeable pages with dots: **New** (latest episodes from your shows), **Library** (artwork grid, Large / Small / List, drag to reorder), **Explore** (search, Your interests, Browse categories).
- Show detail: artwork, title, description, Subscribe, every episode under year headings with Newest/Oldest.
- Now Playing: show name, episode title, scrubber, −15 / play-pause / +15, Moon key with ±5 bubble and floating z's. Swipe down to close.
- A mini player stays on every screen once something is loaded; it can be slid into a small oval when paused.
- Themes sheet: six animated Scenes (Midnight default, Mountain Vista, Beach, Rainforest, City Scape, Underwater) and four Color Scapes (Paper, Ink, Ember, Red Light).
- Search: Apple iTunes Search API, no accounts, no backend. Streaming only, no downloads.
- iOS 18+, SwiftUI, Swift 6. System fonts only.
- Permanently out of scope unless the owner changes it: onboarding, accounts, social, ads, monetization, AI summaries, queue manager, autoplay-next, speed control in the main player, large artwork on Now Playing, waveforms, transcripts.
- The name "NightCast" is a temporary working name, not trademark-cleared.

## Brand Commitments

- The **Moon key** is the signature control; the accent colour belongs to it alone.
- Tactile, physical-object feel: keys with visible travel, haptics on press, no UI sounds.
- Publisher artwork is shown unmodified in every theme.
- Owner's copy decisions: Sleep key reads "Ready for bed?" before tapping and "Sweet dreams" with a small heart and "Fade in X minutes." after.
- Design-philosophy references (spirit only, nothing copied): Neuecast for scope, Not Boring apps for tactility and personalization.

## Evidence on Hand

- Real show artwork and feeds via the iTunes directory; `-demo` seeds six real shows.
- Screenshot history in `screenshots/` (m2 through v10).
- Contrast tooling: `scripts/contrast.py`, token files in `replica/design/`.
- No reviews, testimonials, or usage data exist; nothing should claim them.

## Product Principles

1. One job: falling asleep to a podcast. Every screen earns its place against that.
2. Bedtime first: the darkest, calmest rendering is the default, and nothing glares.
3. Physical, not flat: controls feel like keys you press, with travel and haptics.
4. The listener never loses their place and never gets surprised by audio.
5. Personal without being fiddly: pick a world, not a colour picker.

## Accessibility & Inclusion

- WCAG AA contrast in every theme, checked by `scripts/contrast.py`.
- Dynamic Type through AX5 with stacked layouts; VoiceOver labels, values, and announcements for Sleep; Reduce Motion swaps springs for fades.
- A live VoiceOver pass on a real iPhone is still open (TASKS.md).
