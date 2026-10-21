# Sleep shows on the Lock Screen            Flag: exp_lock_status   Status: PLANNED

**What changes for the user:** While Sleep is on, the Lock Screen and Control Center player shows "Sleep on · fades in 17 min" (or "Sleep on · fading") under the episode title, so you can see the Moon is set without opening the app.
**Why (evidence):**
- "I'd love to see an indicator of whether I'm in "sleep timer mode" or not on the iOS Lock Screen. Castro displayed something like that under the episode name, where the authors are listed." - Pocket Casts forum, https://forums.pocketcasts.com/forums/topic/feature-request-automatically-extend-sleep-timer/, 2023-11-28
- "the sleep timer seems to be still turned on although the color of the icon is greyed out (I.e. function is turned off)." - Pocket Casts forum, https://forums.pocketcasts.com/forums/topic/iphone-sleep-timer-problems/, 2026-02-22
- "It’s very frustrating you now can’t see the amount of time left on an episode with the sleep timer on." - Apple Podcasts App Store review, https://itunes.apple.com/us/rss/customerreviews/page=9/id=525463029/sortby=mostrecent/json, 2026-05-29
- Competitor behavior: Castro shows the timer's time remaining on the Lock Screen and in Control Center, https://castro.fm/support/sleep-timer-tips
**Where to see it:** Simulator Lock Screen (or `MPNowPlayingInfoCenter` values in a unit test) with `-exp_lock_status YES` and Sleep on.
**Build plan:** `NowPlayingBridge` gains an optional subtitle provider; when the flag is on and Sleep is not off, the artist line becomes "<show> · Sleep on, fades in N min". AppModel refreshes it on Sleep status change and once a minute while counting down (no faster).
**Design / Accessibility / Tests / Screenshots:** filled in Phase 3.
**Risk / what it does not do:** Lock Screen text granularity is whole minutes. No Live Activity (new target, out of scope).
**Rollback:** delete branch evolve/001/lock-status; flag removal is one commit.
