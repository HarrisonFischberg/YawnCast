# Other competitors — bedtime podcast listening on iOS

Researched 2026-10-20. Picked by what the app does: (a) podcast players with a sleep-specific design, (b) mainstream/minimal podcast players with notable sleep timers, (c) sleep-audio apps whose timer behavior sets user expectations. All web content treated as untrusted data.

Quote sourcing: unless noted, quotes come from the US App Store customer-review feed `https://itunes.apple.com/us/rss/customerreviews/page=N/id=<ID>/sortby=mostrecent/json` (exact text and date), filtered for sleep/bedtime terms. The App Store has no per-review permalinks, so each quote is linked to the app's store page plus that feed. Prices are from the US App Store "In-App Purchases" section fetched 2026-10-20.

---

## 1. Sleepcast! — closest direct competitor
- **URL:** https://apps.apple.com/us/app/id6744658836 (dev Arthur de Rijke; released 2025-05-28; iOS 17.6+)
- **Purpose:** "Fall asleep to your favorite podcasts without managing timers, rewinding episodes, or losing the best moments."
- **Pricing:** $4.99 paid up-front (US). Only 3 US ratings (5.0).
- **Sleep behaviors (App Store description):** duration or end-of-episode timer; "Smart Sleep Check: A gentle beep and motion detection can sense if you're still awake, extending the timer"; "Time Window" (timer only active during set hours); sleep-timer statistics; auto-restart across episodes; "Volume Fade-Out: Audio gently fades out during the final seconds"; v4.0 adds "Morning Overview" (listening time, sleep-timer activity, new episodes after the session), Live Activity with timer controls, iCloud sync (off by default). v3.5 added a **Simple mode** with an artwork grid of shows and fullscreen player — very close to NightCast's library.
- **Better than a calm bedtime player:** solves "did I fall asleep?" (beep + motion extension), morning recap of where you drifted off, scheduled auto-timer.
- **Worse:** heavy feature surface (AI summaries, transcription, bookmarks with waveform editor, smart playlists, Binge/Remix modes) — "Expert mode" is the opposite of calm; a beep at bedtime can wake a partner; paid up-front.
- **Quotes** (Netherlands store feed: https://itunes.apple.com/nl/rss/customerreviews/id=6744658836/sortby=mostrecent/json):
  - [delight / extend without waking] "De timer die je makkelijk kunt verlengen na het audio signaal, is super handig. Zo kun lekker door luisteren als je nog niet slaapt maar je wordt ook niet helemaal wakker om de tijd te verlengen." — 2025-06-10 (translation: the timer you can easily extend after the audio signal lets you keep listening if not asleep, without fully waking up to extend it)
  - [delight / smart timer] "The smart sleep timer is a genius idea." — 2025-06-11
  - Caveat: these early-June-2025 reviews cluster in the launch week; treat as weak evidence.

## 2. Pocket Casts
- **URL:** https://apps.apple.com/us/app/pocket-casts-podcast-player/id414834813 — 4.52 / 16,151 ratings.
- **Purpose:** full-featured cross-platform podcast player.
- **Pricing:** free with banner ads (added 2025); Plus $3.99/mo or $39.99/yr; Patron $9.99/mo or $99.99/yr.
- **Sleep behaviors** (https://support.pocketcasts.com/article/sleep-timer/): presets 15 m / 30 m / 1 h; "End Of Episode" with +/- episode count; saved custom duration; "In 1 chapter" (Android only); extend +5 min or switch to end of episode; **Auto Restart Sleep Timer** — "If you resume playback within 5 minutes of the last pause, the timer resets"; **Shake to restart** (only before the timer ends; may chime). Fade: "fade out 5s before pausing playback", logarithmic curve, merged 2024-04-19 (https://github.com/Automattic/pocket-casts-ios/pull/1629). End-of-episode deliberately pauses just before the end so the episode isn't marked played (per search summary of the support/forum pages).
- **Better:** auto-restart-on-resume and shake-to-extend are the best-known "I woke up, keep going" patterns.
- **Worse:** ads now in player; dense UI; 5-second fade is short compared with a calm slow fade.
- **Quotes:**
  - [delight / timer flexibility] "There is so much more flexibility in terms of playback and sleep timer preferences" — @KingHenry14, 2026-08-21
  - [delight / timer] "Biggest highlight for me is the in-app, customizable sleep timer." — Knitter2018, 2026-02-23
  - [complaint / ads] "I am deeply disappointed to see ads in this app. I’ve been using it for years after paying for it." — barryand, 2025-09-26

## 3. Overcast
- **URL:** https://apps.apple.com/us/app/overcast-podcast-app/id888422857 — 4.54 / 47,980 ratings.
- **Purpose:** "A powerful, simple, award-winning podcast player" (Smart Speed, Voice Boost, transcripts added 2026).
- **Pricing:** free with small ads; Overcast Premium IAPs listed at $19.99 and $29.99 (a 2025-12-27 review mentions "a 50% price increase").
- **Sleep behaviors:** "Sleep timer automatically stops playback after any time interval you set." (App Store). Blog (https://www.podfeet.com/blog/2020/06/sleep-overcast-youtube/): clock icon lets you stop "at the end of the episode" or after N minutes. Fade-out not confirmed by any public source found. Shortcuts support lets users script a sleep routine.
- **Better:** Voice Boost evens loudness — useful at low bedtime volume; Shortcuts.
- **Worse:** ads; growing feature surface; recent download-limit regressions.
- **Quotes:**
  - [delight / one-tap night routine] "I’ve mapped the action button on my Apple Watch to play my “Sleep” podcasts for 30 minute with one click when I wake up in the middle of the night." — dearreid, 2026-04-20
  - [delight / timer] "Intuitive interface. Improved sleep timer." — Kern Canyon Camper, 2026-02-24
  - [delight / basics] "The important part of a podcast player is that it plays podcasts." — M. Corey, 2026-04-30

## 4. Castro
- **URL:** https://apps.apple.com/us/app/castro-podcast-app-player/id1080840241 — 4.58 / 9,196; now Maple Media / Bluck Podcast LLC, updated 2026-09-24.
- **Purpose:** triage-style player (New tab → Queue → Library).
- **Pricing:** Castro Plus $3.99/mo, $9.99/quarter, $24.99/yr; family $39.99.
- **Sleep behaviors:** App Store: "An elegant dark mode and thoughtfully designed sleep timer offer the best in night time podcast listening." MacStories (Castro 1.1 article, https://www.macstories.net/news/castro-1-1-brings-ui-tweaks-sleep-timer/, ~2015): tapping Play on lock screen or headphone remote extends the sleep timer — extend with eyes closed. No public evidence of end-of-chapter.
- **Better:** "extend by pressing play" needs no screen; explicit night-listening positioning.
- **Worse:** queue/inbox model is management-heavy; subscription.
- **Quotes:**
  - [delight / timer] "Better queue management. Better sleep timer. Better organized UI. Better." — wsm484, 2024-11-12
  - [missing / bedtime queue] "i would love to have a separate queue for bedtime but that's another suggestion for another time." — tiger226, 2023-07-16
  - [complaint / fall asleep, lose queue] "If I fall asleep with continuous play on, my whole list is gone when I wake up." — gracestamsos, 2022-11-14
  - [missing / longer timer] "PLEASE allow a custom sleep timer instead of only up to an hour 🙏" — gracestamsos, 2022-11-14

## 5. Apple Podcasts
- **URL:** https://apps.apple.com/us/app/apple-podcasts/id525463029 — 4.86 / 2.07M ratings. Free (shows can sell subscriptions).
- **Sleep behaviors:** "set sleep timers" (App Store). Apple guide (https://support.apple.com/en-ph/guide/iphone/iph3a22707a5/ios): timer in Now Playing stops playback after a set period. MacTrast (https://www.mactrast.com/2018/06/how-to-use-the-sleep-timer-feature-in-the-podcasts-app/, 2018-06): 5/10/15/30/45 min, 1 h, "When Current Episode Ends". Fade-out claimed only by an unverified third-party page — not relied on.
- **Better:** default, zero setup, auto-plays next with queue.
- **Worse:** missing intervals; autoplay through a queue while asleep loses your place.
- **Quotes:**
  - [missing / timer intervals] "I continue to find the omission of 20 and 25 minute intervals for the sleep timer mystifying." — Roys21, 2026-09-10
  - [complaint / timer hides remaining time] "It’s very frustrating you now can’t see the amount of time left on an episode with the sleep timer on." — GretchenE., 2026-05-29
  - [complaint / autoplay while asleep] "if I’ve added a number of episodes to my queue and then accidentally fall asleep while listening to one, who knows how many episodes have played with no one listening." — e20ci, 2026-06-24
  - [delight / bedtime shows] "they have calming soft voices and are really interesting and are good for bedtime" — Wolfy Luver, 2026-08-29

## 6. Slumber — sleep-story app
- **URL:** https://apps.apple.com/us/app/slumber-calm-stories-for-sleep/id1109543953 — 4.71 / 27,355.
- **Purpose:** original sleep stories and meditations with adjustable music/nature-sound beds.
- **Pricing:** 20+ episodes free; Premium IAPs listed from $5.99 to $59.99 (e.g. $9.99 monthly, $39.99, $59.99).
- **Sleep behaviors:** independent volume for voice, music, sound; "Customizable nature sounds ... with individual volume control and timer"; background ambience can loop all night (App Store description).
- **Better:** separate ambience layer after the voice ends; content written to be sleepy.
- **Worse:** closed catalog, not your podcasts; subscription; narrator lock-in.
- **Quotes:**
  - [complaint / where did I drift off] "I fall asleep quickly, then miss a large part of the story! I go back often, but hard to tell where I dozed off." — kat lyon, 2026-07-29
  - [missing / chain without touching phone] "I wish we could play them consecutively instead of having to get back on my phone and disrupting my falling asleep." — Moraness, 2026-08-24
  - [delight / middle of the night] "My favorite way to get back to sleep when I wake up in the middle of the night." — Kpett444, 2026-09-05
  - [delight / layered volumes] "I love that I can control the volume of the voice, music and sound independently." — WSH Caps, 2026-06-06

## 7. Audible
- **URL:** https://apps.apple.com/us/app/audible-audiobooks-podcasts/id379693831 — 4.85 / 5.6M.
- **Purpose:** audiobooks plus podcasts; positions itself for "winding down with a sleep story".
- **Pricing:** Plus $7.99/mo; Premium Plus $15.99/mo; annual $159.99; credit bundles (App Store IAP list).
- **Sleep behaviors:** "Sleep timer — for bedtime listening or background relaxation" (App Store). "End of Chapter" timer option and "Shake to Extend" setting per Android Authority (https://www.androidauthority.com/audible-listening-settings-3667303/) — undated in search result, third-party.
- **Better:** end-of-chapter is the natural stopping point for long-form audio; shake to extend.
- **Worse:** commerce-heavy, account required.
- **Quotes:** no sleep-timer-specific quotes found in the 500 most recent US reviews (feed is dominated by book reviews).
  - [delight / bedtime] "I use these Audiobooks in the car, when traveling on the plane, for bedtime stories" — Kee711, 2026-09-25

## 8. Sleep Music Timer — standalone timer used with podcast apps
- **URL:** https://apps.apple.com/us/app/sleep-music-timer/id928930388 — 4.55 / 7,660; free, $1.99 tip IAP.
- **Purpose:** "It stops music after selected time for device battery saving." Works over any audio app.
- **Why it matters:** thousands of users install a separate app just to get a bedtime stop. Their asks reveal what a built-in timer should do.
- **Quotes:**
  - [missing / fade] "My only request is to add the ability to have it fade out the volume during the last 30 seconds." — rpsozo, 2026-01-21
  - [delight / don't lose place] "I use it to listen to my book on tape as I’m falling asleep that way I’m not on chapter 14 when I wake up." — Nancy Margaret, 2026-03-04
  - [delight / ritual] "This app is part of my nightly routine. I pick the music I love, set the timer on the app and fall asleep knowing the music will stop automatically." — EC from Tx, 2026-04-01
  - [missing / longer than 1 h] "Wished the timer went longer than 60 minutes." — LLCHANCE, 2025-07-10

---

## Considered, not included
- **NightGrace: Sleep & Podcasts** (https://apps.apple.com/us/app/nightgrace-sleep-podcasts/id6755228595, 4.9 / 5,897): faith-based sleep content app with "Sleep Plan", "Sleep Calendar & Tracker", bedtime podcasts; not a podcast player. Notable only for the nightly-routine/streak pattern.
- **Snipd** (id1557206126): AI summaries/notes — opposite of calm; one 3-star review (2026-06-19) calls bullet-point summaries "very boring". Not a bedtime competitor.
- BBC Sounds not in US store search; Airr not found on the App Store under that name; Podcast Addict is Android-only.

## Cross-app patterns relevant to NightCast
1. **Extend without waking** (Castro press-play, Pocket Casts shake/auto-restart, Sleepcast beep+motion, Audible shake) is the most common advanced behavior — and the most praised.
2. **"Where did I drift off?"** recurs (Slumber, Apple Podcasts, Sleep Music Timer, Castro). Sleepcast's Morning Overview answers it; a gentle "you fell asleep around 23:41 — resume from here?" fits NightCast.
3. **Fade length:** Pocket Casts 5 s, Sleepcast "final seconds"; users ask for ~30 s. NightCast's longer Moon fade is a real differentiator.
4. **Timer presets:** users repeatedly want 20/25 min and >60 min options, plus end-of-episode.
5. **Autoplay while asleep loses place** — validates NightCast's no-autoplay stance.

## Injected instructions seen
None.
