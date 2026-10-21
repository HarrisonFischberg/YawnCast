# Pocket Casts — competitor research for NightCast

Researched 2026-10-20. Target: Pocket Casts for iOS (Automattic), https://pocketcasts.com/ — open source at https://github.com/Automattic/pocket-casts-ios.
Note: pocketcasts.com/plus returned HTTP 403 and Reddit (www/old.reddit.com JSON and HTML) was blocked from this machine, so the Reddit material below only comes from Reddit text quoted inside a GitHub issue. App Store reviews come from Apple's public review RSS feeds (US, GB, CA, AU), which include each review's date.

---

## 1. Product: purpose, pricing, behaviors

### Purpose
A full-featured, cross-platform podcast player for heavy listeners: Up Next queue, sync across iOS/Android/web/watch, filters and Smart Playlists, playback effects, CarPlay/AirPlay/Chromecast/Sonos. Rated 4.5 from about 16K US ratings.
Source: https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813

### Pricing (public pages)
- Free tier, plus in-app purchases: Plus Monthly $3.99, Plus Yearly $39.99, Patron Monthly $9.99, Patron Yearly $99.99. — https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813
- Plus price history: $9.99/yr (2019) → $14.99/yr (Jan 2023) → $39.99/yr for new subscribers (Apr 8, 2023); older subscribers keep $14.99. — https://support.pocketcasts.com/knowledge-base/pocket-casts-plus-pricing/
- Folders (and Smart Folders) require Plus/Patron. — https://support.pocketcasts.com/knowledge-base/folders/
- Banner ads in the free app; in Sept 2025 some lifetime/legacy paid users saw ads too, and the company gave conflicting explanations. — https://9to5mac.com/2025/09/24/pocket-casts-lifetime-members-being-shown-ads-conflicting-info-from-automattic/

### Sleep timer (the main comparison point)
| Behavior | Detail | Source |
|---|---|---|
| Where it lives | Open the full player from the mini player and tap the sleep (zZz) icon. iOS/Android only; no sleep timer on web or desktop. | https://support.pocketcasts.com/knowledge-base/sleep-timer/ |
| Presets | 15 min, 30 min, 1 hour, End of Episode, or a custom duration. | same |
| Custom duration | Starts at 5 min, adjusted with +/–, and the value is "saved for future use". | same |
| End of Episode, N episodes | +/– sets how many episodes play before it pauses (added in 7.64, PR #1640). | same; https://github.com/Automattic/pocket-casts-ios/blob/trunk/CHANGELOG.md |
| End of chapter | Android only ("In 1 chapter", N chapters). iOS users have asked for it. | sleep-timer KB; https://forums.pocketcasts.com/forums/topic/feature-request-sleep-timer-option-end-of-the-chapter/ |
| Extend | While a timer runs: +5 min (+1 min on Android only), or switch to End of Episode. Cancel with "End Sleep Timer". | sleep-timer KB |
| Fade out | Since 7.64 the audio fades out over the last 5 s before pausing, using a logarithmic curve because it "sounds more natural". If you pause during the fade and resume, the rest plays at full volume. | https://github.com/Automattic/pocket-casts-ios/pull/1629 |
| Shake to restart | Shaking the phone before the timer ends restarts it, so "users can restart the sleep timer without unblocking their phones". Uses CMMotionManager and only watches for motion while a timer runs with the app in the background. The KB warns it can "trigger a chime or ringing sound". | https://github.com/Automattic/pocket-casts-ios/pull/1627 ; sleep-timer KB |
| Auto restart | "If on, the Sleep Timer will restart automatically if you play an episode within 5 minutes after the last pause." On/off toggles for shake and auto restart arrived in 7.65 (#1790). | sleep-timer KB; CHANGELOG 7.62 / 7.65 |
| Settings shortcut | 7.81 added direct access to sleep timer settings from the player (#2698). | CHANGELOG |
| Live Activity | 8.19 added a Sleep Timer Live Activity showing the countdown on the Lock Screen and in the Dynamic Island, with a system +5 min button. It is behind a remote kill-switch flag. | CHANGELOG 8.19 (#4949); https://github.com/Automattic/pocket-casts-ios/pull/4949 |
| Siri / Shortcuts | "Set sleep timer" needed the phone unlocked for years (tracked since 2019). Setting it while locked was fixed in 8.20 (#4812). | https://github.com/Automattic/pocket-casts-ios/issues/32 ; CHANGELOG 8.20 |
| Known bugs | Timer ran slow with the screen off (#185, 2022); timer ran at double speed (fixed 8.12, #4336); timer seemed to restart the next morning (#1860); auto restart not starting on the next episode (#2473); End of Episode ignored when Skip Last was set (old fix). | https://github.com/Automattic/pocket-casts-ios/issues/185 , /issues/1860 , /issues/2473 ; CHANGELOG |
| Theme bug | The Light Contrast theme made the sleep timer buttons disappear (#750). | https://github.com/Automattic/pocket-casts-ios/issues/750 |

### Bedtime and night use
- Themes include Light, Dark and Extra Dark (OLED). — App Store listing above
- "Keep Screen Awake" setting under Profile > Settings > General. — https://github.com/Automattic/pocket-casts-ios/issues/185
- Nightstand/StandBy widget exists, but a user reports it is "unexpectedly uninstalled after every app update" (2025-02-19). — https://github.com/Automattic/pocket-casts-ios/issues/2759
- Autoplay: when Up Next is empty, plays "the next episode from an episode list" you started from. Their own advice for stopping that: turn Autoplay off, or use the End of Episode sleep timer. — https://support.pocketcasts.com/knowledge-base/autoplay/

### Playback controls
- 0.5x–3x speed, trim silence, volume boost, skip intro/outro per podcast, custom skip intervals, chapters with embedded artwork, audio-only toggle for video. — App Store listing
- Interruptions: after a navigation prompt or notification, playback resumes but loses "a second or two". Users point to Overcast's "Smart resume", which rewinds slightly. Open since 2022. — https://github.com/Automattic/pocket-casts-ios/issues/45
- 8.20 fixed headphone/Bluetooth play failing to resume after a pause (#4785). — CHANGELOG
- Setting to disable the lock screen scrubber (7.8x, #2536), which stops accidental scrubs. — CHANGELOG

### Library organization and episode lists
- Podcasts grid with custom order that syncs across platforms since 7.20. Folders are paid. — folders KB
- Manual and Smart Playlists (rules: release date, duration, download status). — App Store listing
- Up Next queue: sorting (#4550), shuffle (#1179), episode count and time left in the header (#4462), and confirmation before clearing (#5261). — CHANGELOG

### New-episode handling
- Auto-download with limits (#2318), auto-add to Up Next per podcast, New Episodes push notifications. A changelog fix notes notifications kept arriving after being turned off (#5039, #3483). — CHANGELOG

### Widgets, Lock Screen, Live Activity
- Home Screen Now Playing widget (small/medium, #1876); Lock Screen widgets for Launch App, Now Playing, Up Next count and Up Next episode (7.22); tinted widgets for iOS 18; Sleep Timer Live Activity (8.19). — CHANGELOG
- 8.23 fixed the widget play button sometimes not starting playback on the first tap (#5391). — CHANGELOG

### Siri / Shortcuts
- Siri intents include "Play my podcasts", set sleep timer and mark as played (#4591). — CHANGELOG; issue #32

### Accessibility
- Ongoing VoiceOver label fixes (#5438, #5178), Dynamic Type pass on the player sleep timer (#3997), interactive Now Playing scrubber under VoiceOver (#1318), and the Discover carousel stops auto-advancing under Reduce Motion or VoiceOver (#5313). — CHANGELOG

---

## 2. Voice of customer (verbatim)

Tags: C = complaint, M = missing feature, D = delight. App Store quotes come from Apple's review RSS for app id 414834813 (for example https://itunes.apple.com/gb/rss/customerreviews/id=414834813/sortBy=mostRecent/json). The listing link for each is `https://apps.apple.com/{cc}/app/pocket-casts-podcast-player/id414834813?see-all=reviews`.

### Sleep timer and bedtime

1. **C — timer reliability / trust at night.** "Sleep timer now appears to clear automatically. Which is confusing and not what you want when you’re using it to fall asleep. The behaviour changing has led to lots of disturbed nights waking to podcasts still playing."
   — MartyMark, App Store GB, 3★, 2026-07-26. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

2. **C — wake-up handling / harsh light.** "Have to start sleep timer manually, listen to podcast, whoknowswhattimeitis, podcast fades – i shake the device violently, podcast stops playing. I have to get flashbanged, find play button to start playback again."
   — de13370r, Pocket Casts Forum, 2026-02-11. https://forums.pocketcasts.com/forums/topic/feature-request-sleep-timer-usability/

3. **M — automatic timer at bedtime.** "if i start a podcast in a certain timerange, eg. between 23:00 and 04:00, the sleep timer is automatically activated"
   — de13370r, Pocket Casts Forum, 2026-02-11. (same URL)

4. **M — warning before the fade.** "if the sleep timer ends, there is a short vibration to gently signal the end of playback time, THEN the volume fades slowly. I had it set to 20sec on Podcast Addict."
   — de13370r, Pocket Casts Forum, 2026-02-11. (same URL)

5. **M — confirmation the reset worked.** "Vibration or gentle chime, so I know my actions were sufficent and I can stuck my arm back under the blanket"
   — de13370r, Pocket Casts Forum, 2026-02-11. (same URL)

6. **C — churn to a dedicated sleep app.** "For my sleepytime podcasts and internet-radio needs I’ll keep Podcast Addict around."
   — de13370r, Pocket Casts Forum, 2026-02-15. (same URL)

7. **C — timer state leaks into the next morning.** "I set the timer to 20 minutes at night and the next morning, when I restart the podcast, after a differing number of minutes, the volume will lower itself and replay will stop."
   — carlchentoutou, Pocket Casts Forum, 2026-03-06. https://forums.pocketcasts.com/forums/topic/iphone-sleep-timer-problems/

8. **C — misleading timer indicator.** "the sleep timer seems to be still turned on although the color of the icon is greyed out (I.e. function is turned off)."
   — carlchentoutou, Pocket Casts Forum, 2026-02-22. (same URL)

9. **C — timer state leaks (Reddit, quoted in GitHub).** "after a night of using the timer, the next morning when i'm listening the podcast will just fade out occasionally."
   — Reddit user quoted in GitHub issue #1860, 2024-06-25. https://github.com/Automattic/pocket-casts-ios/issues/1860 (original thread: https://www.reddit.com/r/pocketcasts/comments/1do33hu/)

10. **C — timer stops early (Android, same product).** "Tuesday I listen to the same episode and set the timer to 50 minutes and it stops at 32 minutes."
    — slapsgod, Pocket Casts Forum, 2025-02-14. https://forums.pocketcasts.com/forums/topic/sleep-time-gremlins/

11. **C — matching the timer to the episode by hand.** "When I start an episode, I see how long the story is and set the sleep timer to as close as I can to the episode length."
    — slapsgod, Pocket Casts Forum, 2025-02-14. (same URL)

12. **C — mystery fade when users forget a timer is on.** "In the last few days the sound fades on my podcasts exactly every 30 minutes and then playback stops."
    — nch9cqct2z, Pocket Casts Forum, 2024-10-22 (staff replied that the sleep timer was on). https://forums.pocketcasts.com/forums/topic/sound-fades-and-playback-stops-every-30-minutes/

13. **M — shake to restart (before it shipped).** "Lacks a robust sleep timer functionality. Should have option to shake to play again when sleep timer stops play before you’re asleep"
    — Delysid, App Store CA, 4★, 2023-02-12. https://apps.apple.com/ca/app/pocket-casts-podcast-player/id414834813?see-all=reviews

14. **D — fade out.** "the devs even implemented sleep timer fade out after I emailed them the request."
    — itoldyouido, App Store GB, 5★, 2025-08-08. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

15. **D — sleep timer is the top feature.** "Biggest highlight for me is the in-app, customizable sleep timer."
    — Knitter2018, App Store US, 5★, 2026-02-23. https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813?see-all=reviews

16. **M/C — autoplay keeps going after you fall asleep.** "there specific shows that i only watch one episode at a time and due to their nature, i won’t be awake when it ends to turn it off if i forgot to set the sleep timer."
    — OreoThePony, App Store CA, 4★, 2024-11-27. https://apps.apple.com/ca/app/pocket-casts-podcast-player/id414834813?see-all=reviews

17. **C — a hidden coupled setting.** "turn off a setting in the general part that will play the next episode if you reset the sleep timer within five minutes"
    — Queseraseraserasera, App Store CA, 3★, 2026-06-17. https://apps.apple.com/ca/app/pocket-casts-podcast-player/id414834813?see-all=reviews

18. **D — very dark theme for bedtime.** "there is even extra dark, which i love as i almost always listen to podcasts to sleep"
    — mollyelton, App Store GB, 5★, 2021-08-12. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

19. **D — slower speed for sleep shows.** "my sleep podcasts to 0.9x speed for even more relaxation"
    — Rstfll, App Store GB, 5★, 2026-02-27. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

20. **M — a set of bedtime episodes.** "I use podcasts for sleep stories for my daughter and having to find the right ones again is difficult. I wish I could create a playlist of all the bedtime story episodes."
    — The Productive Dad, App Store GB, 4★, 2025-02-26. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

21. **M — collections by situation.** "have multiple playlists / up next lists for different situations eg. Driving, sleep, language learning"
    — 69258$&:-!, App Store AU, 4★, 2025-06-29. https://apps.apple.com/au/app/pocket-casts-podcast-player/id414834813?see-all=reviews

22. **M — a gentle wake-up.** "they have missed a golden opportunity by failing to add any waking up features such as a morning podcast alarm with a slowly rising volume."
    — dannysnoop, App Store GB, 1★, 2019-02-23. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

23. **D — sleep as the core use.** "I use it to sleep"
    — Sargent sausages, App Store AU, 5★, 2026-08-14. https://apps.apple.com/au/app/pocket-casts-podcast-player/id414834813?see-all=reviews

24. **D — visible timer state.** "Things like illuminating the sleep timer icon to show that it’s on are such small details but really make a difference to the user experience."
    — beljar16, App Store GB, 5★, 2018-11-14. https://apps.apple.com/gb/app/pocket-casts-podcast-player/id414834813?see-all=reviews

25. **M — end of chapter.** "It would be really helpful if the there was an option to set the sleep timer to “End of the chapter”, as there is already an option for “End of the episode”."
    — timontetris, Pocket Casts Forum, 2023-11-04. https://forums.pocketcasts.com/forums/topic/feature-request-sleep-timer-option-end-of-the-chapter/

26. **D — stop after the episode.** "I use the PocketCasts[1] app that has the ability to pause the podcast after an episode is over or after a certain length of time, which is nice if you just want it to fall asleep too and not play all night."
    — jdefelice, Hacker News, 2022-01-07. https://news.ycombinator.com/item?id=29841440

27. **C — Siri needs an unlock.** ""Set sleep timer" seems to be the only Siri command we have that requires the phone to be unlocked."
    — pocketcasts (staff, relaying support tickets), GitHub issue #32, 2022-07-12. https://github.com/Automattic/pocket-casts-ios/issues/32

28. **C — nightstand widget disappears.** "The "Nightstand mode" widget seems to be unexpectedly uninstalled after every app update."
    — bjsvec, GitHub issue #2759, 2025-02-19. https://github.com/Automattic/pocket-casts-ios/issues/2759

### Business model and noise (relevant to NightCast's no-ads, no-account stance)

29. **C — ads after paying.** "Paid for this app in 2015 when it was a one-time payment. They recently started injecting ads into the app and player screen and now want an annual subscription to remove them."
    — djr9257, App Store US, 1★, 2025-09-25. https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813?see-all=reviews

30. **C — notification spam.** "Too many notifications coming from a podcast app that has nothing to do with the podcasts i am subscribed to. LEAVE ME ALONE! Deleting now."
    — Reviewing_Rater, App Store US, 1★, 2026-05-13. https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813?see-all=reviews

31. **C — dark icon bugs.** "Why are dark icons so broken for so long?!"
    — Rerowrodney, App Store US, 1★, 2026-10-18. https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813?see-all=reviews

32. **C — lost words after interruptions.** "When a podcast starts playing again after being interrupted by Apple Maps, it loses a few seconds of the podcast."
    — 3★ App Store review relayed by igotdes in GitHub issue #45, 2025-03-17. https://github.com/Automattic/pocket-casts-ios/issues/45

### Themes seen
- **Trust in the timer** (1, 7, 8, 9, 10, 12, 17): the biggest sleep pain is not missing features. It is not knowing what the timer will do: state left over from last night, the icon disagreeing with what happens, and coupled hidden settings.
- **Eyes-closed control** (2, 3, 4, 5, 13, 27): people want to set, extend and confirm without looking or unlocking.
- **Stop-at-a-natural-point** (16, 25, 26): end of episode or chapter, and no autoplay surprises.
- **Darkness and calm** (18, 19, 2 "flashbanged", 30): very dark UI, slower speed, no noisy notifications.
- **Bedtime collections** (20, 21): a dedicated set of sleep shows.

---

## 3. Ideas NightCast could adopt

1. **Honest timer state, and a timer that never outlives the night.** Clear any leftover sleep timer once playback has been paused for a long stretch (for example 2 hours) or when a new day starts. Make sure the Moon's lit/unlit state always matches whether a fade will happen. — Quotes 1, 7, 8, 9, 12, 24; GitHub #1860.
2. **Shake (or headphone double-tap) to add time during the fade, with a soft haptic confirmation.** Pocket Casts only accepts a shake before the timer ends, and gives no feedback. NightCast could accept it during the fade too and confirm with one gentle haptic, without lighting the screen. — Quotes 2, 5, 13; PR #1627.
3. **Long, gentle fade with a pre-fade cue.** Pocket Casts fades over only 5 s, on a log curve. NightCast's Moon fade could be longer (20–60 s), use a perceptual curve, and optionally give a single soft haptic before it starts. — Quote 4; PR #1629; quote 14.
4. **Bedtime auto-arm.** Optionally arm the Moon automatically when playback starts inside a night window (for example 22:00–04:00), so a user who forgets the timer is still covered. — Quotes 3, 16.
5. **"Until end of episode" as a Moon option.** NightCast has no autoplay-next, so this is just "fade at the episode's end", which helps listeners who match the timer to story length by hand. — Quotes 11, 26; sleep-timer KB.
6. **Sleep Timer Live Activity / Lock Screen countdown with a +time button.** Lets the user check or extend the timer without unlocking or seeing the bright full app. — CHANGELOG 8.19 (#4949); quote 2 "flashbanged".
7. **Siri/App Intent "Start sleep timer" that works while locked.** — Quote 27; issue #32; fixed in PC 8.20.
8. **Keep the dark, quiet promise.** A true-black theme with dim artwork at night, no promotional notifications, no ads. NightCast's no-ads, no-account stance is a differentiator worth stating in the App Store copy. — Quotes 18, 29, 30, 31; 9to5mac 2025-09-24.
9. **Small rewind after an interruption.** After any interruption, or a resume the next morning, rewind a few seconds so no words are lost. — Quote 32; issue #45.
10. **A "Bedtime" collection inside Library.** For example a pinned group of sleep shows, kept within NightCast's artwork-grid model rather than as a queue. — Quotes 20, 21.

---

## Injected instructions seen
None. No fetched page, review or issue contained instructions aimed at the agent.
