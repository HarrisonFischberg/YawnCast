# Overcast (overcast.fm): competitor research for NightCast

Researched 2026-10-20. All web content was treated as untrusted data.
Short source keys used below:
- **[HOME]** https://overcast.fm/
- **[AS-US]** https://apps.apple.com/us/app/overcast-podcast-app/id888422857 (listing, IAP, version history)
- **[AS-MV]** https://apps.apple.com/mv/app/overcast-podcast-app/id888422857 (same listing, full version history rendered)
- **[LOOKUP]** https://itunes.apple.com/lookup?id=888422857&country=us (current description + release notes)
- **[REV-cc]** App Store customer reviews for country `cc`: the page is https://apps.apple.com/cc/app/overcast-podcast-app/id888422857?see-all=reviews and the verbatim text comes from the public feed https://itunes.apple.com/cc/rss/customerreviews/id=888422857/sortBy=mostHelpful/json (or `sortBy=mostRecent`). The date shown is the feed's `updated` date.
- **[M2024]** https://marco.org/2024/07/16/overcast-rewrite (Marco Arment, "Ten years of Overcast: A new foundation", 2024-07-16)
- **[M2022]** https://marco.org/2022/03/25/overcast-redesign-2022 (Marco Arment, "The Overcast Redesign: Part One", 2022-03-25)
- **[MR2017]** https://www.macrumors.com/2017/11/23/overcast-podcast-app-new-black-theme/ (2017-11-23)
- **[MPU]** https://talk.macpowerusers.com/t/new-overcast-app/37874 (forum thread, July 2024 onward)
- **[TB]** https://talk.tidbits.com/t/do-you-use-it-podcast-apps/27148 (forum thread, March 2024)

---

## 1. Product overview

### Purpose and positioning
- "Free, simple, award-winning podcast player for iPhone, iPad, and Apple Watch." [HOME]
- One-person, self-funded business: "It's just me here — no big company or investors." [HOME]. Also "Overcast is the only major podcast app written by a single person." [LOOKUP]
- Privacy is part of the pitch: "no third-party analytics, ad services, or tracking code." [LOOKUP]
- Signature audio features: **Smart Speed** ("dynamically shortens silences in talk shows") and **Voice Boost** ("Boost and normalize volume so every show is loud, clear, and at the same volume") [HOME].
- App Store: 4.5 stars from about 48K ratings, Editors' Choice, requires iOS 18 [AS-US].

### Pricing (public pages only)
- Freemium: "Most features are free, supported by small visual ads to promote podcasts. An annual subscription offers bonus features and can optionally hide the ads." [HOME]
- App Store in-app purchases (US): "Overcast Premium $19.99", "Overcast Premium $29.99", "Overcast Premium $29.99" [AS-US]. The page does not say which tier each price belongs to.
- One review mentions "a 50% price increase" at renewal (REV-us, "Time to say goodbye", 2025-12-27).
- Premium-only features named in release notes: Listening Stats, 48-hour History and Undo (2024.11.1), Smart Complete, Chapter preselection, and Premium audio effects such as EQ and noise reduction (2026.8) [AS-MV].

### Sleep timer: concrete behaviors
| Behavior | Detail | Source |
|---|---|---|
| Any interval | "Sleep timer automatically stops playback after any time interval you set." | [LOOKUP] |
| End of episode | Added in 4.0.1: "a new sleep timer option that stops playback at the end of the currently playing episode" | [MR2017] |
| End of chapter | Added in the 2024 rewrite: "the ability to stop after the current chapter when using the sleep timer" (webwalrus, 2024-07-16) | [MPU] /11 |
| Fade-out | Added in 2026.8 (11 Aug 2026): "Sleep Timer now fades out at the end". Before that, users said it cut off abruptly (see the Sundaysnooze quote in section 2). | [AS-MV] |
| Fade can be disabled | 2026.10 (9 Oct 2026): "Sleep Timer fade-out can now be disabled under Nitpicky Details" | [LOOKUP] |
| Timer re-arms after it expires | A user reports that if the timer expires and you press play again from the Lock Screen, "it plays with the sleep timer again rather than infinitely" (Dkellam, 2024-08-08) | [REV-au] |
| Remembers last duration | "saving the previously-used timer length" (Stanley Omar, 2024-07-25). A 2019 review says the app shows "the last sleep time a user set as a button" | [REV-ca], [REV-us] |
| Shows end clock time | "Timers (that show a clock time for when they're are ending)" (Dan_John2442, 2019-08-03) | [REV-gb] |
| Placement history | The 2024 rewrite moved the timer behind a menu, which drew a wave of complaints. A dedicated button was later restored: "EDIT: The sleep timer button has been added back in the latest "bug fixes" update." (CMTmd14, 2024-08-30) | [REV-us] |
| Custom duration lost and then partly restored | "You can no longer set a custom sleep timer." (2024-07-31). Later: "moved the sleep timer back with proper functionality" (2025-04-01) | [REV-gb], [REV-ca] |
| Shake to extend | **Not confirmed.** No Overcast or marco.org source mentions it. A Tidbits user says extending the timer in Overcast means "you have to open your eyes" (2024-03-19) | [TB] /41 |
| Rewind on wake | **No dedicated "jump back to where I fell asleep" control was found.** The nearest feature is Premium "48-hour History and Undo: Accidentally seek too far, leave your phone playing overnight, or delete the wrong episode…? Just undo it!" (2024.11.1) | [AS-MV] |
| Siri/Shortcuts | Shortcuts to start or cancel the sleep timer exist. They were missing right after the rewrite and came back in build 2024.7.2 (1012), "Added Intents/Shortcuts support" | [MPU] /77, [REV-ca] Mickers |

### Other playback, bedtime, and library behaviors
- **Smart Resume**: rewinds a little after a pause. 2024.11: "Adjusted Smart Resume to go back less time after short interruptions." 2025.10: "Fixed 3-second skip after pauses when Smart Resume is disabled" [AS-MV].
- **Lock Screen**: 2025.6: "Disabled Lock Screen time-slider by default to reduce accidental seeking" [AS-MV]. This protects against accidental seeks in bed.
- **Headphone safety**: 2025.8.1: "Fixed not always pausing when headphones are disconnected" [AS-MV].
- **Playback speed**: steps of 0.1 from 0.5 to 3.0 (2025.9.1), speeds up to 5X (2026.7.1), "recent-speed suggestions" (2025.10) [AS-MV].
- **Skip intro/outro per podcast**: one user uses it "which I use for sleeping so the music doesn't wake me up" (Nifer900, 2024-09-23) [REV-us].
- **Playlists**: "custom Playlists with smart filters and per-podcast priorities" [LOOKUP]. Playlists have colors, SF Symbol icons, and drag-and-drop reordering. Podcasts can be pinned and reordered [M2022].
- **Mark as Played**: "By far, Overcast's most-requested feature" was added as a checkmark button and a left swipe action [M2022].
- **New-episode handling**: "optional notifications when new episodes arrive" [LOOKUP]. Recent episodes sit at the top of Home and can be long-pressed for options (2025.11) [AS-MV]. Episode Limits were made strict in 2026.8 ("episodes beyond the limits you've set will be deleted!") and rolled back in 2026.8.1 ("Everyone hated the new episode-limit strictness, so it's gone!") [AS-MV].
- **Smart Complete (Premium)**: "Marks episodes complete with less than 5 minutes left if you haven't listened in 48 hours" (2026.8) [AS-MV].
- **Add without following**: "Adding a single episode no longer auto-follows the podcast" (2025.8.1) [AS-MV].
- **Streaming was dropped in the 2024 rewrite** ("Streaming… Downloading episodes completely before they begin playback is much more reliable") and later restored [M2024], [AS-MV] 2025.11.1.
- **Widgets/CarPlay/Watch**: widgets exist (2025.8.1 and 2025.9.2 notes fix widget artwork and colors). Per-episode artwork is "not in playlists or widgets, so you can still identify the podcasts there" (2025.11.2). Watch app has standalone playback, and CarPlay is supported [LOOKUP], [AS-MV].
- **Accessibility**: the rewrite was pitched as "more accessible" [M2024]. 2025.9.2 added "Layout improvements for small screens and large fonts" and "Improved handling of the Button Shapes accessibility option". 2025.10 gave the now-playing bottom controls "larger touch areas" [AS-MV]. The App Store accessibility label section says "The developer has not yet indicated which accessibility features this app supports." [AS-US]. VoiceOver users were confused when the chapters button moved after the rewrite [MPU] /21.
- **Transcripts** shipped 2026.4.1 (NightCast deliberately skips this) [AS-MV].

---

## 2. Voice of customer (verbatim)

Reddit note: reddit.com and old.reddit.com JSON endpoints refused fetches from this environment (HTML block page and a tool refusal), so there are **no Reddit quotes**. Every quote below was copied exactly from the source listed.

### Sleep timer: access and taps (mostly after the July 2024 rewrite)
1. **[complaint: timer buried]** "The sleep timer, which I used daily, is now hidden away behind multiple taps and is very difficult to enable." (Mickers, "Latest update not great", 2/5) [REV-ca], 2024-07-19
2. **[complaint: night-time contrast]** "Also, the white text on blue circles is very difficult to read, especially on low brightness (typically I'm setting a sleep timer while half asleep, so I don't want a bright screen)." (Capn Stoobie, "New sleep timer is clunky", 3/5) [REV-au], 2024-09-22
3. **[complaint: night-time contrast]** "The sleep time instead of having a simple scroll wheel to choose the time quickly we now have orange dots that are difficult to see at night possibly due to bad colour contrast." (kewined, 2/5) [REV-gb], 2024-07-17
4. **[complaint: one-tap expectation]** "The sleep timer should be one click." (Disae, "Latest update is a backward step", 3/5) [REV-gb], 2024-07-25
5. **[complaint: custom duration lost]** "This app stood head and shoulders over other podcast apps for one reason alone: a customizable timer, not just a few preset times to choose from." (ddddd_ddddd, "Terrible redesign", 3/5) [REV-us], 2024-12-13
6. **[complaint: can't add time quickly]** "Mainly disappointed that quick access to "sleep" timer and ability to easily adjust sleep time now requires opening extra menu levels … so you can't quickly "add" time to sleep timer,… my most used feature …." (grant-brisbane, 5/5) [REV-au], 2024-07-28
7. **[complaint: half-asleep friction]** "I then have to wake up properly to do something that I could do while half asleep." (Wynkel059, "I don't like the new update", 2/5) [REV-au], 2024-07-26
8. **[complaint: bedtime taps]** "Way too many clicks just to play something at night and use the sleep feature." (MartyMark, "Rewrite has gone too far", 1/5) [REV-gb], 2024-08-07
9. **[complaint: old UI, night mode glare]** "The sleep timer durations move around, so it takes 7 presses and some squinting to set a 25-minute timer. By this time my retinas are seared because the UI for that is white even in night mode." (Hacker News) https://news.ycombinator.com/item?id=14385736, 2017-05-21
10. **[complaint: regression]** "The extra taps and overall interface for the sleep timer (which I use every night) is a regression in its current form." (Jezmund_Berserker) [MPU] https://talk.macpowerusers.com/t/new-overcast-app/37874/46, 2024-07-18

### Sleep timer: fade, extend, wake-up recovery
11. **[missing: gentle fade]** "My first test of a podcast app is to check if sleep timer cuts audio abruptly or fades it down gently." and "Note to developers: when you fix this, fade it down very gently." (Sundaysnooze, "Sleep timer does not fade out", 2/5) [REV-au], 2023-03-05
12. **[missing: eyes-closed extend]** "The critical difference between Overcast's and Castro's sleep timer UX is, you have to open your eyes to extend the timer in Overcast, but you can do it with your eyes closed (without touching your phone at all ) in Castro." (Alderete) [TB] https://talk.tidbits.com/t/do-you-use-it-podcast-apps/27148/41, 2024-03-19
13. **[missing: auto-reset plus jump back]** "There's even enough space on the Sleep Timer window for a "Jump Back" button that would take listeners to the last time the sleep timer was reset." (Mike W Perry, "The best gets even better", 5/5) [REV-us], 2019-04-28
14. **[missing: find where I fell asleep]** "There have been times when I've fallen asleep while it was playing and woken up an hour or two later with it still playing." and "Finding where in that time I felt asleep is a nuisance." (Mike W Perry, same review) [REV-us], 2019-04-28
15. **[missing: resume spot]** "What makes it funny is I will be listening a single episode for weeks sometime, often listening the same parts over and over again simply because I can't precisely start today where I fell asleep yesterday." (Hacker News) https://news.ycombinator.com/item?id=48706422, 2026-06-28
16. **[missing: reclaim missed part]** "because, often I listen to a podcast in bed, fall asleep, and I want to reclaim it and hear the bit I missed." (reubster73, "Very, very good… almost perfect", 5/5) [REV-gb], 2023-02-18
17. **[pain: false "played"]** "I love that "mark as played" is a toggle, to easily mark things un-played for when I accidentally fall asleep listening and end up with six podcasts marked played that I have no memory of!" (Yesh Medicinebird, 5/5) [REV-us], 2022-03-31
18. **[missing: timer counts listening time]** "i wish the sleep timer counted down the minutes the podcast is playing, instead of just the real-time minutes that go by" (DylanAilDon, "simple and clean", 4/5) [REV-us], 2021-08-31
19. **[missing: scheduled timer]** "Three thing I wish for are: 1) scheduled sleep timer." (nicotunes, 5/5) [REV-us], 2022-07-10
20. **[bug: timer stops early]** "Ie set the timer to 15mins, but it stops playing after 6." (Azza 3886, "Good but not great", 3/5) [REV-au], 2022-05-12

### Bedtime listening: delights and routines
21. **[delight: re-arm from Lock Screen]** "My favourite "nice touch" feature: if you have a sleep timer on, it expires, then you hit play again from the lock screen, it plays with the sleep timer again rather than infinitely." and "Great when you're half asleep." (Dkellam, "2024 Update is all class", 5/5) [REV-au], 2024-08-08
22. **[delight: end of episode]** "I almost complained because I use the sleep timer to stop after current episode 95% of the time." (SpecialKen, "Great rewrite", 5/5) [REV-ca], 2024-07-16
23. **[delight: remembered length]** "Having the sleep timer right up front, along with it saving the previously-used timer length, was the best thing about the play screen apart the 30 second skip buttons." (Stanley Omar, "Why change the sleep timer?", 3/5) [REV-ca], 2024-07-25
24. **[delight: one-click night routine]** "I've mapped the action button on my Apple Watch to play my "Sleep" podcasts for 30 minute with one click when I wake up in the middle of the night." (REV-us, "Deserves an extra star", 5/5), 2026-04-20
25. **[routine: boring content]** "Now if I'm a bit wound up, I put on some wireless headphones and listen to some really boring or non-consequential podcast with a sleep timer on Overcast." (Hacker News) https://news.ycombinator.com/item?id=32299039, 2022-07-31
26. **[routine: re-listening]** "I've found that listening to old podcasts is a great way to drift off to sleep." (Bobothefool, 5/5) [REV-au], 2024-08-10
27. **[delight: intro skip for sleep]** "I have always been a huge fan of this app all due to all the customization in the features, especially being able to edit out the intros and outros which I use for sleeping so the music doesn't wake me up." (Nifer900, 2/5) [REV-us], 2024-09-23
28. **[missing: headphone tap for next]** "If I haven't fallen asleep and want to listen to the next episode, I would simply click once on my headphones instead of picking up my iPhone." (Nkhz, "Key feature missing!", 4/5) [REV-au], 2024-10-02
29. **[complaint: reaching for the phone]** "As I listen at night, to help with sleep problems and pain, I have to now got to reach over, open the app again and select the next pod to play." (AlexJBerry, "Redesign is form over function?", 3/5) [REV-gb], 2024-08-11
30. **[missing: bedtime folder]** "I'd love to folder ones I listen to at bedtime." (Raw_24, "Way better than Apple", 3/5) [REV-us], 2021-07-17

### General (non-sleep) themes
31. **[complaint: storage/limits]** "For podcasts with daily episodes, this is an absolute nightmare." (REV-us, "New update ruined app :/", 1/5), 2026-08-20
32. **[complaint: reorder not kept]** "The two main ways the update has degraded the user experience are download failures and not retaining user changes to the order in custom playlists." (REV-us, "Worse since major update", 3/5), 2026-06-16
33. **[delight: privacy/small dev]** "Audio quality is great and I trust in the data privacy." (REV-us, "A great app for podcasts", 5/5), 2026-01-28
34. **[complaint: subscription fatigue]** "I cannot justify yet another subscription renewal for an app that I can basically do without." (REV-us, "Time to say goodbye", 4/5), 2025-12-27
35. **[complaint: playlists hard]** "I could never quite master Overcast's playlists and smart playlists, but did love its exceptional polish and just how tiny and privacy focused the app is." (Hacker News) https://news.ycombinator.com/item?id=24412591, 2020-09-08

**Theme tally (sleep-related quotes):** timer buried or too many taps (1, 4, 6, 7, 8, 10, 29); night-time readability and glare (2, 3, 9); extending or controlling the timer eyes-closed or hands-free (6, 12, 28); recovering the spot where you fell asleep (13 to 17); gentle fade (11); remembered or one-tap defaults (21 to 24).

---

## 3. Ideas NightCast could adopt

1. **Keep the Moon one tap, on the main player, always.** Overcast's biggest backlash came from hiding the timer behind a menu (quotes 1, 4, 7, 8, 10), and Overcast eventually restored the button. Guard this with a test or design rule so NightCast never regresses.
2. **"Where I fell asleep" marker and a one-tap jump back.** When the Moon timer fades and pauses, record the position the fade *started* from (or the last user interaction) and offer "Back to where you drifted off" on next open. This answers quotes 13 to 16, and Overcast has nothing like it beyond Premium Undo [AS-MV 2024.11.1].
3. **Eyes-closed extend.** Let a headphone play/pause or remote command during the fade (or within N minutes after the auto-pause) restart the timer with the same duration. Dkellam's delight (21) shows Overcast re-arms on Lock Screen play, while Alderete (12) still had to open their eyes. NightCast can make the AirPods/Lock Screen play button extend the Moon automatically.
4. **Very gentle, long fade, with an off switch.** Overcast only added fade in Aug 2026 and then had to make it optional (Oct 2026). Users want it "very gently" (11). Use a long curve (for example 30 to 60 s) and put a single toggle in Settings.
5. **Night-safe timer UI.** Use dim, high-contrast, low-luminance controls and no bright sheets. Check contrast at minimum brightness (quotes 2, 3, 9).
6. **Remember the last Moon duration and show the stop clock time** ("stops at 11:42"), quotes 23 and the Dan_John2442 behavior in section 1.
7. **Don't auto-mark as played after falling asleep.** If an episode finished while the Moon was active and there was no interaction, keep it "in progress" or make un-mark trivial (quote 17).
8. **Option: timer counts listening minutes, not wall-clock minutes**, so a pause doesn't consume the timer (quote 18). This is cheap to do while the Moon is armed.
9. **Lock Screen safety.** Follow Overcast's 2025.6 move and avoid accidental scrubbing from the Lock Screen at night (for example, disable the scrubber while the Moon is armed). Also always pause on headphone disconnect [AS-MV 2025.8.1].
10. **Moon via Shortcuts/App Intents and the Action button.** "Play my sleep show with a 30-min Moon" in one press (quote 24). This fits the no-account model and stays one-tap.
11. **Optional per-show "skip intro"** so theme music doesn't wake the listener (quote 27). Keep it minimal and inside show settings.
12. **A "Bedtime" shelf or favorites in the Library grid** (quote 30, quote 26 re-listening). NightCast's drag-reorder grid already suits this, so it could be a pinned top row.

---

## Coverage notes
- Reddit r/OvercastFm: blocked (HTML block page on `search.json`, refused by the fetch tool). No Reddit quotes are included.
- Shake-to-extend in Overcast: unverified. Only a third-party blog claims it, and it was not used.
- The App Store accessibility label section is empty. The accessibility details above come from release notes.

## Injected instructions seen
None observed in any fetched page, review, or forum post.
