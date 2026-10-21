# Back to where you drifted off            Flag: exp_drift_back   Status: PLANNED

**What changes for the user:** After Sleep fades and pauses an episode, Now Playing shows a small key under the scrubber: "Back to 41:20, where the fade began". One tap jumps there, so you hear what you slept through without hunting.
**Why (evidence):**
- "I set my sleep timer for 30 min and then the next day rewind to where I fell asleep." - r/adhdwomen, https://www.reddit.com/r/adhdwomen/comments/1e5qo7b/how_do_you_guys_sleep/ldpxax6/, 2024-07-18
- "The next night I rewind it back to roughly where I fell asleep and start again." - r/doughboys, https://www.reddit.com/r/doughboys/comments/1wkp7wd/does_anyone_else_use_the_pod_to_fall_asleep_ive/patxm8l/, 2026-09-19
- "There's even enough space on the Sleep Timer window for a "Jump Back" button that would take listeners to the last time the sleep timer was reset." - Overcast App Store US review (Mike W Perry), https://itunes.apple.com/us/rss/customerreviews/id=888422857/sortBy=mostHelpful/json, 2019-04-28
- Competitor behavior: Sleepcast! "Morning Overview" shows activity after the session, https://apps.apple.com/us/app/id6744658836
**Where to see it:** Now Playing after a Sleep fade with `-fastSleep -exp_drift_back YES`.
**Build plan:** `AppModel` records the playback position when the fade starts (countdown → fading transition) for the current episode; clears it on a different episode or after the jump. NowPlayingView shows one standard `KeyStyle` capsule below the time labels (not in the Sleep bar area, to stay clear of PRs #6/#7). Tap seeks to that position; does not start playback.
**Design / Accessibility / Tests / Screenshots:** filled in Phase 3. Tests: UI test the key appears after fade with flag on, absent with flag off; tap moves elapsed time.
**Risk / what it does not do:** In-memory only: if iOS kills the app overnight the marker is gone (no persisted-data change this cycle).
**Rollback:** delete branch evolve/001/drift-back; flag removal is one commit.
