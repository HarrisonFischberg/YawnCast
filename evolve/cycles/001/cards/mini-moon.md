# Moon on the mini player            Flag: exp_mini_moon   Status: PLANNED

**What changes for the user:** The mini player gets a small Moon key next to Play, so Sleep is one tap from any screen without opening Now Playing.
**Why (evidence):**
- "The sleep timer should be one click." - Overcast App Store GB review, https://itunes.apple.com/gb/rss/customerreviews/id=888422857/sortBy=mostHelpful/json, 2024-07-25
- "Mine is there in the three dots menu but I want it back as a timer icon on the now playing screen. I hate having to navigate when I’m half asleep" - Spotify Community, https://community.spotify.com/forum/en/discussion/6016380/sleep-timer-on-ios-for-podcasts-gone/p2, 2024-10-27
- "Something in the settings screen to default a 15 minute sleep timer with a moon icon to click on the main screen." - r/overcast, https://www.reddit.com/r/overcast/comments/1oubjb9/feature_request_sleep_timer_on_apple_watch/nobcijd/, 2025-11-11
**Where to see it:** Any home page with an episode loaded, `-demo -exp_mini_moon YES`.
**Build plan:** In `MiniPlayerDock` add a 44 pt round key (standard role; accent role when Sleep is on, per DESIGN.md) calling `model.toggleSleep()`. Disabled when nothing is playable. Keep the existing small moon glyph in the subtitle.
**Design / Accessibility / Tests / Screenshots:** filled in Phase 3 (check AX sizes so the title still fits).
**Risk / what it does not do:** No ±5 bubble on the mini player. Touches LibraryView.swift near PR #5 (gap under mini player).
**Rollback:** delete branch evolve/001/mini-moon; flag removal is one commit.
