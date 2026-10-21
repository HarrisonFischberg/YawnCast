# Castro: competitor research for YawnCast

Researched 2026-10-20. Every claim cites the public URL where it was seen. App Store review quotes come from Apple's public customer-reviews RSS feed for app id 1080840241. The feed URL is given per quote (with page and storefront) along with the review ID. The human-readable listing is https://apps.apple.com/us/app/castro-podcast-player/id1080840241.

Source caveat: Reddit (r/CastroPodcasts) refused every unauthenticated request (HTTP 403 or a login wall, for www., old., api. and .rss). I collected **no Reddit quotes** rather than use unverifiable search snippets. Sources used instead: App Store reviews, Hacker News (Algolia API), and the Pocket Casts forum, where former Castro users describe Castro's sleep timer.

---

## 1. Product, pricing, behaviors

### Purpose
- Castro is "the iPhone podcast player for podcast fanatics" (footer, https://castro.fm/support). It is built around triage: new episodes land in an **Inbox**, you pick some into a single **Queue**, and the rest get archived. Site copy: "Quickly scan them, pick the best, and forget the rest." (https://castro.fm/)
- Ownership: the original developers let the app decline in 2023. It went down in late 2023 and early 2024 (HN item "The Castro podcast app and its website are down", 2024-01-08, https://news.ycombinator.com/item?id=38908265). Bluck Apps (Dustin Bluck) took it over in 2024 and ships frequent updates (blog, https://castro.fm/blog/pod-seek, 2026-03-11). The same owner launched Pod Seek, a separate discovery app, on 2026-03-11 (same URL) and a Castro MCP server on 2026-06-30 (https://castro.fm/blog/castro-mcp). An Android beta is in progress (pod-seek post).

### Pricing (public pages)
- Castro Plus costs $24.99/year as an in-app purchase (https://castro.fm/ and https://apps.apple.com/us/app/castro-podcast-player/id1080840241).
- App Store IAP list: Monthly $3.99, Quarterly $9.99, Annual $24.99, Family Plan $39.99, plus "Early Supporter" variants at the same prices. One-week trial. (App Store listing URL above)
- Plus unlocks Trim Silence, Enhance Voices, Mix to Mono, sideloading via iCloud Drive, advanced chapter support, per-podcast settings, Night Mode, and 18 custom app icons (https://castro.fm/). Note that **Night Mode is paywalled**.
- The App Store "Age rating" section says "Contains advertising" (listing URL above).

### Sleep timer (most relevant)
All points below are from https://castro.fm/support/sleep-timer-tips unless another URL is given.
- **Location:** Open the player controls with the up arrow on the black player bar, then use the bar that starts with a "ZZZ" icon.
- **Presets:** "Tap 5,10,15,20,30,45 or 60 minutes". The maximum is 60 minutes, and the slider can set "a different interval".
- **Start rule:** If nothing is playing when you set the timer, the countdown starts "as soon as you press play".
- **Fade:** "When the timer expires, the audio will fade out."
- **Tap-to-extend:** "If you press play again within 60 seconds, the sleep timer will extend. A computer voice will tell you that it has been extended." Pausing and resuming with 60 seconds left also extends it. Per a CA review (quote 3), the extension equals the duration you originally set. This works from AirPods or the Lock Screen, so you never have to look at the screen.
- **Remaining time** "will be displayed in Control Centre and on the lock screen". A former user (quote 2) says the countdown appeared under the episode title in place of the author line.
- **Cancel:** Drag the slider back to 0. There is no separate cancel button.
- **History:** The sleep timer has existed since v1.1 (~2014). Then as now, you could long-press Play to reach settings and "tap Play again to extend the timer" (https://www.macstories.net/news/castro-1-1-brings-ui-tweaks-sleep-timer/).
- The App Store copy markets it as a "thoughtfully designed sleep timer" offering "the best in night time podcast listening" (listing URL above).

### Inbox / triage of new episodes
- Each podcast has a new-episode rule: **Inbox** (the default), **Queue Last**, **Queue Next**, or **Archive**. "Episodes in the queue are downloaded automatically." Archive suits story podcasts you play oldest-first. (https://castro.fm/support/auto-queue-and-auto-archive)
- **Triage from notifications:** Expand a new-episode push to get Play Now / Queue Next / Queue Last / Archive, which also works on Apple Watch. You can choose notifications for Inbox episodes, Queue episodes, or both. The app icon badge can count Inbox, Queue, or both. (https://castro.fm/support/use-push-notifications-app-icon-badge)
- **Clear all:** Long-press the Inbox or Queue icon (quote 11).
- "Continuous play" (autoplay-next) is on by default and can be turned off (quote 11).

### Playback controls
- Speeds from 0.8x to 3x (free). Plus adds Trim Silence ("10-20% time savings"), Enhance Voices, and Mono Mix. You can select or skip chapters, and playback can start from a push notification (https://castro.fm/).
- Per-podcast speed, skip-intro, and episode-limit settings are Plus-only (quote 11; quote 9 complains about the episode limit being paywalled).

### Library / episode list
- Folders. A "tiles" option shows cover art (quote 12). A 2023 redesign brought large grid shapes that some users disliked (quotes 17, 18). Users have asked for a Library grid view (quote 16). Drag-and-drop queue ordering is supported (App Store listing).

### Resume, CarPlay, Watch
- "CarPlay support makes it easy to pick up where you left off while driving" (App Store listing). One user reports resume jumping back 25-30% in CarPlay (quote 13).
- The Watch app supports playback control and queue browsing (https://castro.fm/).

### Widgets / Lock Screen / Siri / Shortcuts / Accessibility
- Widgets: v2025.11.2 made them work "even when the app isn't running"; v2026.3 made queue widget updates more efficient. v2026.3 also fixed "shortcuts weren't showing up". The listing advertises Siri support. (App Store version history, listing URL above)
- Accessibility: The listing says "The developer has not yet indicated which accessibility features this app supports." v2026.4.1 fixed a VoiceOver issue in the Now Playing chapter list (listing URL above). A VoiceOver user reports chapter-list bugs (quote 19).

---

## 2. Voice of customer (verbatim)

Format: **[type: theme]**, then the quote, then source / date / URL.
AS-US-pN means App Store US RSS page N: `https://itunes.apple.com/us/rss/customerreviews/page=N/id=1080840241/sortby=mostrecent/json`. AS-CA means the same feed under `/ca/`, page 1.

### Sleep timer and bedtime

1. **[delight: hands-free sleep-timer extend]**
   "I fall asleep to podcasts. Can you add the ability to automatically extend the sleep timer? After I run out of time and it stops playing, I'd love to just press play again on my Airpods without needing to turn over and open up my phone to set a new sleep timer."
   kellymichaelwong, Pocket Casts forum (a former Castro user, saying this was "the main reason for me using Castro"), 2023-11-28. https://forums.pocketcasts.com/forums/topic/feature-request-automatically-extend-sleep-timer/

2. **[missing: sleep-mode indicator on Lock Screen]**
   "I'd love to see an indicator of whether I'm in "sleep timer mode" or not on the iOS Lock Screen. Castro displayed something like that under the episode name, where the authors are listed."
   kellymichaelwong, same thread, 2023-11-28. (URL as above)

3. **[delight: extend sleep timer]**
   "Helpful tip is “extend sleep timer.” If you’re still listening, just press play again and it will extend again for the same time you initially set. So good!"
   App Store CA, 5 stars, "Best Podcast app!", review 13297722218, 2025-10-21. https://itunes.apple.com/ca/rss/customerreviews/page=1/id=1080840241/sortby=mostrecent/json

4. **[delight: tap earbuds to extend; missing: fade]**
   "found it incredible how unique their sleep timer extension functionality was (liked its look and feel too). It seems so obvious: just tap your earphones (Powerbeats Pro in my case) when the sleep timer comes to an end for another five minutes."
   timob3401da0115, Pocket Casts forum, 2024-01-31. https://forums.pocketcasts.com/forums/topic/feature-request-automatically-extend-sleep-timer/

5. **[complaint: reaching for the phone wakes you]**
   "requires me to wake up just a bit more to be able to reach out to the bedside table and do it."
   timob3401da0115, same thread, 2024-01-31. (URL as above)

6. **[missing: scheduled sleep timer + volume fade]**
   "They have the ability to schedule when a sleep timer is on (ie any time between 11pm and 6am). And they also offer the feature of fading the volume as the sleep timer nears the end of its time! Love that idea."
   kellymichaelwong, same thread (about Podcast Republic, as a wish for a Castro-style app), 2023-11-28. (URL as above)

7. **[complaint: queue consumed while asleep; missing: timer > 1 hour]**
   "PLEASE allow an option to not automatically  remove played episodes from queue! If I fall asleep with continuous play on, my whole list is gone when I wake up.  2nd PLEASE allow a custom sleep timer instead of only up to an hour 🙏"
   App Store US, 3 stars, "Minimal personalization features", review 9288067964, 2022-11-14. AS-US-p9

8. **[missing: separate bedtime list]**
   "i would love to have a separate queue for bedtime but that's another suggestion for another time."
   App Store US, 5 stars, "nothing better. no, not overcast.", review 10147315855, 2023-07-16. AS-US-p7

9. **[delight: sleep timer vs Overcast]**
   "Better queue management. Better sleep timer. Better organized UI. Better."
   App Store US, 5 stars, "So glad Castro is back!", review 11941327425, 2024-11-12. AS-US-p3

10. **[delight: timer prevents sleeping through episodes]**
    "you can set a sleep timer at night so you don’t wake up and all of your episodes are listened to in your sleep (that may or may not have happened to me before, lol)."
    App Store US, 5 stars, "Best podcast player! So glad it’s back!", review 11903747984, 2024-11-02. AS-US-p3

### New-episode handling / inbox

11. **[delight: per-show routing + clear all]**
    "If your queue or inbox get really full and you just want to clear everything out, you can long press the icon to clear all episodes instead of doing one by one."
    Same review 11903747984, 2024-11-02. AS-US-p3

12. **[delight: inbox curates; tiles of art]**
    "Having an inbox where I can pick and choose the episodes I want to actually add to my listening queue is a killer feature."
    App Store US, 5 stars, "The inbox is the killer feature", review 10537832068, 2023-11-01. AS-US-p6

13. **[complaint: resume position lost]**
    "Castro seems to be incapable of resuming my podcasts where I left off. I listen through Car Play and whenever I try and resume a podcast, I’m back 25-30%. Very frustrating."
    App Store US, 2 stars, "Never resumes where I left off", review 14482081299, 2026-08-28. AS-US-p1

14. **[complaint: failed download silently leaves Inbox]**
    "when there’s a downloading error, the episode in question still leaves my inbox—as if it had been successfully downloaded, which it hadn’t."
    App Store US, 2 stars, "Downloading Errors Recently", review 14322259611, 2026-07-19. AS-US-p1

15. **[complaint: silent skipping]**
    "about 1 in 10 of my queued, downloaded programs is immediately and silently skipped."
    App Store US, 3 stars, "Bugs Have Appeared", review 14309005486, 2026-07-15. AS-US-p1

16. **[missing: library grid view]**
    "Also, can we have a grid view option of our podcasts in the Library section?"
    App Store US, 4 stars, "Enjoying the improvements", review 11735983216, 2024-09-17. AS-US-p3

17. **[complaint: redesign hurt density]**
    "The big shapes, while pretty, lead to a reduced visual density and more scrolling."
    App Store US, 3 stars, "Latest update is more of a downgrade", review 9804141224, 2023-04-09. AS-US-p7

18. **[complaint: lost swipe-to-delete]**
    "No more swipe episode to delete? Really? Makes managing the queue so cumbersome."
    App Store US, 5 stars, "Huge mistake with new UI design", review 9791215449, 2023-04-05. AS-US-p8

### Accessibility, playback, trust

19. **[complaint: VoiceOver chapter list]**
    "if a podcast have chapters, I click on the name of the episode to reveal the chapters it doesn’t work and it will reverse to the beginning."
    App Store US, 5 stars, "Great podcast app, but with one serious issue", review 13845893959, 2026-03-13. AS-US-p1

20. **[missing: finer slow speeds (a11y)]**
    "Better yet a custom slider so I can adjust to 0.95 or 0.85 depending on how well my brain is doing that day."
    App Store US, 3 stars, "Amazing podcast manager", review 13183998577, 2025-09-25. AS-US-p2

21. **[complaint: basics behind paywall]**
    "putting the setting for *how many episodes to keep* behind a subscription?!"
    App Store US, 1 star, "Nickel and dimming for incredibly basic features", review 13004690385, 2025-08-11. AS-US-p2

22. **[complaint: random time jumps]**
    "Will randomly skip a random amount of time? Sometimes 15 minutes or some random time like that."
    App Store US, 4 stars, "Favorite podcast app, but has a bug!", review 13859037695, 2026-03-17. AS-US-p1

23. **[complaint: dark mode resets]**
    "the annoying reversion to light mode every 24 hours even if you have permanent dark mode."
    App Store US, 4 stars, "Updated Review", review 11770953823, 2024-09-27. AS-US-p3

24. **[complaint: server dependence]**
    "Much of Castro functions with the help of Castro’s own servers and APIs, which have now had two significant outages in the past month. These outages make the app nearly unusable"
    App Store US, 5 stars (updated), "Used to be my favorite app for podcasts", review 11764412291, 2024-09-25. AS-US-p3

25. **[delight: low decision fatigue]**
    "It uses an inbox triage model that lets me subscribe to a lot of podcasts and keep up with what they’re doing, without cluttering my queue or inducing decision fatigue."
    HN user 1123581321, 2021-04-20. https://news.ycombinator.com/item?id=26877019

26. **[delight: email-like inbox]**
    "I can't believe more podcast apps haven't caught on to how handy the email-like metaphor is for managing episodes."
    HN user aheckler, 2023-03-21. https://news.ycombinator.com/item?id=35246471

---

## 3. Ideas YawnCast could adopt

Each idea is tied to the quotes or behaviors above. All of them fit the constraints: no account, no backend, no queue, no autoplay-next.

1. **Tap-to-extend after the Moon fades (headline idea).** For a grace window after the timer pauses, a Play from AirPods or the Lock Screen (remote command) restarts the timer for the same duration with a fresh fade. Castro's window is 60 s. Quotes 1, 3, 4, and 10 suggest this is the single most-loved bedtime behavior. Quote 1 asks for a longer "couple hours" window so a mid-night wake gets a short top-up. Make the extension short and gentle, and skip Castro's "computer voice" announcement: a soft chime or silence suits someone in the dark.
2. **Sleep-timer status on the Lock Screen and Now Playing.** Show "Moon: 12 min left" in the Now Playing artist line or a Live Activity, so the user can check it without unlocking (quote 2; Castro support page).
3. **Never burn through the library while asleep.** When the Moon pauses, don't mark the episode played. Rewind a little on the next resume, since the user likely missed the last minutes (quotes 7, 10, 13). YawnCast already has no autoplay-next, so make that an explicit selling point in its copy.
4. **Rock-solid resume position.** Persist the playhead often and restore it exactly (quote 13). A small "back 30 s since you dozed" offer would also help.
5. **Optional bedtime auto-arm.** Arm the Moon automatically for playback started inside a user-set window (for example 10pm–6am). Leave it off by default (quote 6).
6. **Timer presets beyond 60 min and a quick cancel.** Castro tops out at 60 minutes and you cancel by dragging to 0 (quote 7; support page). Offer 90 and 120 minute presets, plus an "end of episode" option, alongside one-tap Moon.
7. **New-episode triage lite on the New page.** Use swipe actions to dismiss or keep, with no queue (quotes 11, 12, 18, 25). A long-press "clear all new" with an Undo toast (quote 11) fits the undo-over-confirm baseline.
8. **Keep artwork-grid density sane.** Offer a compact grid option, since redesigns with big tiles drew complaints (quotes 16, 17). YawnCast's grid already answers quote 16's request.
9. **Don't paywall night features.** Castro locks Night Mode behind Plus, and paywalled basics draw anger (quote 21). YawnCast's free, no-ads stance and its themes are a positioning angle.
10. **Offline-first trust.** Castro's server outages broke everything (quote 24). YawnCast has no backend, so say so in onboarding or the App Store copy.
11. **Fix failure states for downloads.** If a download fails, the episode stays put and shows a retry (quote 14), and episodes are never silently skipped (quote 15).
12. **VoiceOver pass on the player and Moon.** Castro's listing declares no accessibility features and has VoiceOver bugs (quote 19). YawnCast can declare an accessibility nutrition label and test the Moon timer with VoiceOver.

---

## Injected instructions seen
None. No fetched page or review contained instructions directed at the agent.
