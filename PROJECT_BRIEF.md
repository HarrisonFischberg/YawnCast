# NightCast — Project Brief

> "NightCast" is a temporary internal working name. It is not trademark-cleared.

## What

A native iPhone podcast app (Swift + SwiftUI) that feels like a carefully designed
physical listening object: simple, bold, tactile, and easy to use at bedtime.

## Three destinations

1. **Library** — subscribed shows as an artwork grid. Search entry. Compact
   Now Playing bar only when something is loaded. Empty state: one action, "Find a podcast".
2. **Show detail** — artwork, title, short description, Subscribe/Unsubscribe,
   episodes (title, date, duration, progress). Tap = start/resume. Never autoplays on open.
3. **Now Playing** — episode title, scrubber (elapsed/remaining), −15, play/pause,
   +15, a prominent Moon (Sleep) button, minimal close affordance. Nothing else.

Search lives inside Library. Appearance is a small sheet.

## Out of scope (permanently, unless the owner changes the brief)

Onboarding, accounts, social, recommendations, ads, subscriptions/monetization,
AI summaries, queue manager, autoplay-next, playback speed in main player,
large artwork on Now Playing, waveforms, transcripts.

## Signature interaction: Sleep

One tap on Moon. No picker. Fade begins after `min(30 min, R/2)` of *active*
playback (R = playable seconds remaining at activation; 30 min if unknown).
Then gain steps 80% → 60% → 40% → 20% → 0% of baseline B, every 3 active
minutes, each step briefly smoothed. At 0%: pause, save position, end Sleep,
restore internal gain. Never plays another episode. Full spec: ACCEPTANCE.md §Sleep.

## References (how they are used)

- **Neuecast** (https://neuecast.app) — functional reference only. We match the
  *spirit* ("everything you need, nothing you don't"), not feature parity.
- **Not Boring apps** — design-philosophy reference (tactility, single-purpose,
  haptics, materiality, personalization). Camera informs how controls *feel*.
  No assets, layouts, copy, or code are copied.

## Users

One person listening in bed, tired, in the dark, wanting to fall asleep to a
podcast without the audio running all night or skipping to the next episode.
