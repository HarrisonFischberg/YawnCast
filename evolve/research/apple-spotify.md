# Competitor research: Apple Podcasts and Spotify (podcasts)

Researched 2026-10-20. Sources are public pages only. Reddit was not reachable (search JSON returned an HTML block page), so Voice of Customer comes from App Store review feeds, the Spotify Community forum, and Hacker News.

App Store review quotes come from Apple's public customer-review RSS feed. Each one links to the exact feed page it appeared on: `https://itunes.apple.com/us/rss/customerreviews/page=N/id=<id>/sortby=mostrecent/json`. Apple Podcasts is id 525463029 and Spotify is id 324684580. The human-readable listings are https://apps.apple.com/us/app/apple-podcasts/id525463029 and https://apps.apple.com/us/app/spotify-music-and-podcasts/id324684580. Dates are the review's `updated` date.

---

## 1. Apple Podcasts

**Purpose.** It is Apple's free, preinstalled app for finding, following and playing audio and video podcasts. It runs on iPhone, iPad, Mac, Watch, TV, Vision Pro, HomePod and the web. https://www.apple.com/apple-podcasts/

**Pricing.** The app is free and "millions of shows are free." Creators can sell premium monthly or annual show subscriptions at prices they set, as in-app purchases. Subscriptions can be shared with up to five family members. https://www.apple.com/apple-podcasts/

### Behaviors

| Area | Behavior | Source |
|---|---|---|
| Sleep timer | The sleep timer lives in the Now Playing screen: "Set a sleep timer: Tap [icon], then choose an option." You have to open the full player first, because it is not on the MiniPlayer. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios |
| Sleep timer | Presets run from 5 minutes to 1 hour, plus "when current episode ends." This comes from a third-party guide based on an older iOS. | https://www.mactrast.com/2018/06/how-to-use-the-sleep-timer-feature-in-the-podcasts-app/ |
| Sleep timer | The timer appears only after an episode has started. | https://iphonelife.com/content/how-to-use-sleep-timer-your-iphones-podcast-app-ios-11 |
| Sleep timer | The timer is greyed out when you AirPlay to a HomePod, and a timer you set first is cancelled at the handoff. | https://discussions-kr-prz.apple.com/thread/252057007 |
| Sleep timer (gap) | Reviewers say the time left on the episode is hidden while the timer runs, and that there are no 20 or 25 minute presets (VOC #A1, #A2). | App Store feed, below |
| Playback | Skip back 15 s and forward 30 s, with intervals you can change in Settings > Apps > Podcasts. Speed runs from 0.5x to 3x with a dial in 0.1x steps. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios ; https://www.macrumors.com/guide/ios-26-podcasts |
| Playback | "Enhance Dialogue" uses on-device ML to reduce background noise. It sits in the speed menu and can be saved per show. | https://podcasters.apple.com/support/5549-iOS-26-whats-new-for-apple-podcasts |
| Playback | Volume: "Touch and hold the volume bar, then slide your finger left or right." Scrub: drag the slider. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios |
| Chapters | You can jump between chapters from the player, the slider or the transcript. From iOS 26.2, AI-generated chapters appear when the creator supplies none. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios ; https://9to5mac.com/2025/12/14/ios-26-2-new-features-iphone/ |
| Video | Video episodes open straight into Now Playing unless video is turned off. Picture in Picture and a Turn Video Off/On toggle are available. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios |
| Queue | Play Next and Add to Queue exist. Drag to reorder, swipe left to Remove, and Clear removes everything. A "Continue Playing" section adds more episodes of a show you have binged after your queue. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios |
| Resume | Home has a "Recently Played" section. The MiniPlayer can pause, resume and skip. | https://support.apple.com/guide/iphone/play-podcasts-iph3a22707a5/ios |
| Library | Library contains Shows (Followed and All), Channels, Categories, Saved, Downloaded, Latest Episodes (with an adjustable retention window) and Stations (rule-based playlists). | https://support.apple.com/guide/iphone/organize-your-podcast-library-iph4003ecb12/27/ios/27 |
| Episode list | Each show has its own Episode Order setting (newest or oldest first). Episodes are marked played or unplayed by swiping right. "Hide Played Episodes" works per show or for all shows. | https://support.apple.com/guide/iphone/organize-your-podcast-library-iph4003ecb12/27/ios/27 |
| New episodes | New episodes from followed shows download automatically. Each show has an "Automatically Download" limit, plus a separate Download Video toggle. | https://www.apple.com/apple-podcasts/ ; https://support.apple.com/guide/iphone/organize-your-podcast-library-iph4003ecb12/27/ios/27 |
| Downloads | Download an episode by swiping left. Saving an episode also downloads it (setting: "Download When Saving"). Video episodes download as audio only by default. You can remove all downloads per show or globally. | https://support.apple.com/guide/iphone/download-save-and-remove-podcasts-iph8615288a4/27/ios/27 |
| Lock Screen | The 2026 release shows full-screen artwork on the Lock Screen, which a reviewer hated (VOC #A9). Chapter titles replace the episode title on the Lock Screen and MiniPlayer (VOC #A10). | App Store feed, below |
| CarPlay | CarPlay offers play, pause, back 15, forward 30 and speed. Steering-wheel controls and CarPlay Dashboard also work. | https://support.apple.com/guide/iphone/play-podcasts-iph3299830d8/27/ios/27 |
| Siri | You can control playback with Siri, including in CarPlay. | https://www.apple.com/apple-podcasts/ |
| Accessibility | Transcripts can be read along, searched, and tapped to jump to that point (select languages only). | https://www.apple.com/apple-podcasts/ |
| Widgets / Live Activity | Apple's public pages describe no Podcasts widget and no Live Activity. | https://www.apple.com/apple-podcasts/ |

---

## 2. Spotify (podcast experience)

**Purpose.** Spotify is a combined music, podcast, audiobook and video app. Podcasts are one tab of a larger catalog. https://support.spotify.com/us/article/podcasts-and-shows/

**Pricing (US).** Free (ad-supported). Premium Individual is $12.99/mo, Student $6.99/mo, Duo $18.99/mo and Family $21.99/mo. https://www.spotify.com/us/premium/

On the free tier "you can only download podcasts," while Premium can download everything. https://support.spotify.com/us/article/listen-offline/

Premium removes Spotify's own ads from video podcasts, but creator-read sponsorships remain. https://support.spotify.com/us/article/podcasts-and-shows/

### Behaviors

| Area | Behavior | Source |
|---|---|---|
| Sleep timer | A moon icon sits in Now Playing. Presets are End of episode/track, 5, 10, 15, 30 and 45 minutes, and 1 hour, according to a third-party guide. | https://routenote.com/blog/timer-for-spotify/ |
| Sleep timer | The longest preset is 1 hour, and there is no custom time and no "after N episodes." | https://community.spotify.com/t5/Live-Ideas/Feature-Request-Expanded-Sleep-Timer-Options-for-Podcasts-amp/idi-p/7531360 |
| Sleep timer | In 2024 the podcast timer moved from a Now Playing icon into the three-dot menu (VOC #S9). | https://community.spotify.com/forum/en/discussion/6016380/sleep-timer-on-ios-for-podcasts-gone/p2 |
| Sleep timer | The timer is greyed out over Spotify Connect, which a moderator called "expected behavior." The workaround is to set it on the phone first and then switch device. | https://community.spotify.com/t5/Android/Sleep-timer-not-working-with-podcasts/m-p/5469181 |
| Sleep timer | You can start it by voice: "'Set a sleep timer'" is an example command in Talk to Spotify (beta, Premium, 18+). | https://support.spotify.com/us/article/talk-to-spotify/ |
| Sleep timer (bug) | For years users have reported "End of episode" repeating the same episode, moving to a different one, or playing the whole playlist (VOC #S1 to #S6). Moderators suggest turning off "Autoplay similar content" and crossfade. | Community threads, below |
| Playback | Skip forward or back 15 s and a speed control. | https://support.spotify.com/us/article/podcasts-and-shows/ |
| Autoplay | "When you reach the end of an album, playlist, or selection of songs, Spotify automatically plays similar songs so the music never stops." The setting is a toggle under Settings > Playback. | https://support.spotify.com/us/article/autoplay/ |
| Transitions | Crossfade, Automix and Gapless are Premium settings. None of them can be set over Connect. | https://support.spotify.com/us/article/tracks-transitions/ |
| Queue | Tap and hold to drag-reorder, swipe left to remove, and Clear empties the queue. Desktop asks you to confirm Clear. | https://support.spotify.com/us/article/play-queue/ |
| Library | Following a show saves it under Your Library > Podcasts, and "New episodes then automatically save." Individual episodes are saved to a "Your Episodes" playlist. Latest episodes are under Home > Podcasts > Following. | https://support.spotify.com/us/article/podcasts-and-shows/ |
| Downloads | Downloads use Wi-Fi by default, with a "Downloads over cellular" toggle. You must go online every 30 days or downloads are lost. Offline Mode greys out anything not downloaded. | https://support.spotify.com/us/article/listen-offline/ |
| Lock Screen widget | The iPhone Lock Screen widget (iOS 16+) only launches the app. If it shows greyed out, check the "Devices Lock Screen" setting. | https://support.spotify.com/us/article/spotify-iphone-widget/ |
| CarPlay | CarPlay, Android Auto, Bluetooth and Connect are supported. Spotify asks you to "Set up Spotify before you drive." | https://support.spotify.com/us/article/spotify-in-the-car/ |
| Siri | Siri can play podcasts, skip, pause and change volume ("...on Spotify"). | https://support.spotify.com/us/article/siri/ |
| Transcripts | Podcast transcripts appear in the desktop Now Playing view. | https://support.spotify.com/us/article/now-playing/ |

---

## 3. Voice of customer (verbatim)

Tags: **C** = complaint, **M** = missing feature, **D** = delight.

### Apple Podcasts, App Store reviews (feed id 525463029)

- **#A1 [M] sleep timer presets.** "Additionally I continue to find the omission of 20 and 25 minute intervals for the sleep timer mystifying. Just add them already."
  Roys21, 2026-09-10, https://itunes.apple.com/us/rss/customerreviews/page=3/id=525463029/sortby=mostrecent/json
- **#A2 [C] sleep timer hides time left.** "It’s very frustrating you now can’t see the amount of time left on an episode with the sleep timer on. Change it back please."
  GretchenE., 2026-05-29, https://itunes.apple.com/us/rss/customerreviews/page=9/id=525463029/sortby=mostrecent/json
- **#A3 [M] timer too short / end of queue.** "I would really appreciate it if the timer had a “End of Queue” option. 1 hour as the longest option is too short, and “End of episode” doesn’t apply when I have 3+ hours of multiple episodes queued up."
  Constant_Listener, 2026-05-14, https://itunes.apple.com/us/rss/customerreviews/page=10/id=525463029/sortby=mostrecent/json
- **#A4 [M] fell asleep and lost track.** "if I’ve added a number of episodes to my queue and then accidentally fall asleep while listening to one, who knows how many episodes have played with no one listening. Plus, now I can’t find which episodes I missed because they appear as played rather than unplayed."
  e20ci, 2026-06-24, https://itunes.apple.com/us/rss/customerreviews/page=7/id=525463029/sortby=mostrecent/json
- **#A5 [C] video at night.** "This used to be an app where I could go without the risk of getting hooked into watching a video so I could allow it late at night without the risk of getting hooked and staying up late. Do not like the addition of video."
  sebdevil, 2026-07-21, https://itunes.apple.com/us/rss/customerreviews/page=5/id=525463029/sortby=mostrecent/json
- **#A6 [C] accidental Lock Screen touches.** "Don’t you dare touch the lock screen, or your podcast will move forwards, or backwards, and you’ll have no control over that at all.  Please please please Apple add some kind of lock functionality so I won’t accidentally skip around on my podcasts!"
  Jason of the JSA, 2026-06-10, https://itunes.apple.com/us/rss/customerreviews/page=8/id=525463029/sortby=mostrecent/json
- **#A7 [C] resume lost.** "If I pause a podcast and come back later, it often restarts from the beginning instead of resuming where I left off, causing me to lose my place."
  Loaguti, 2026-07-06, https://itunes.apple.com/us/rss/customerreviews/page=6/id=525463029/sortby=mostrecent/json
- **#A8 [C] finding your place again.** "Why can’t I just leave the episodes open to where I left it? Every single time I have to find the episode I was listening so I can find the next episode after it."
  Johnny b cool, 2026-06-14, https://itunes.apple.com/us/rss/customerreviews/page=8/id=525463029/sortby=mostrecent/json
- **#A9 [C] Lock Screen artwork.** "Absolutely HATE the new full screen image on the lock screen. I want to see my clock and other widgets on my lock screen at all times"
  Ken52061, 2026-08-30, https://itunes.apple.com/us/rss/customerreviews/page=3/id=525463029/sortby=mostrecent/json
- **#A10 [C] chapter title replaces episode name.** "please please please change it back to show the episode name instead of the bogus chapter title on the small tile at the bottom of the screen and on the lock screen."
  Lemonx97, 2026-08-03, https://itunes.apple.com/us/rss/customerreviews/page=5/id=525463029/sortby=mostrecent/json
- **#A11 [C] AI chapters spoil stories.** "these “chapters” have spoiled so many plots, as it pops up on CarPlay every time a new “chapter” begins, so there’s no way to ignore it."
  lilac_lavender, 2026-05-27, https://itunes.apple.com/us/rss/customerreviews/page=9/id=525463029/sortby=mostrecent/json
- **#A12 [C] downloads deleted.** "Plenty of room, Background Refresh off, just stoppp!!! I downloaded the episodes for a reason!"
  BothAlionas, 2026-10-17, https://itunes.apple.com/us/rss/customerreviews/page=1/id=525463029/sortby=mostrecent/json
- **#A13 [C] new episodes not downloading.** "I’m now having to manually check every podcast I’m following just to see if there is anything new because nothing is downloading"
  Nateaallen, 2026-10-15, https://itunes.apple.com/us/rss/customerreviews/page=1/id=525463029/sortby=mostrecent/json
- **#A14 [C] unwanted autoplay.** "nothing will stop this app from playing automatically. Please add an auto play switch in the settings."
  TnRPhotography2018, 2026-09-26, https://itunes.apple.com/us/rss/customerreviews/page=2/id=525463029/sortby=mostrecent/json
- **#A15 [C] queue adds things.** "Stop. Adding. Shows. To. My. Queue."
  pled3i, 2026-09-06, https://itunes.apple.com/us/rss/customerreviews/page=3/id=525463029/sortby=mostrecent/json
- **#A16 [D] sleep use.** "I’ve had this so I can sleep but i’ve been using it a lot more for than that I love this app so much I use every day"
  milesogden, 2026-06-06, https://itunes.apple.com/us/rss/customerreviews/page=8/id=525463029/sortby=mostrecent/json

### Spotify, Community forum and App Store

- **#S1 [C] end-of-episode loops.** ""Sleep timer - End of episode" will just make same podcast episode repeat, again & again (seemingly endlessly)."
  Spotify Community, 2025-04-01, https://community.spotify.com/t5/Other-Podcasts-Partners-etc/Sleep-timer-End-of-episode/td-p/6893858
- **#S2 [C] white noise not shutting off.** "I use a white noise podcast to fall asleep every night and have always turned the “end of episode” sleep timer on so the episode doesn’t end and wake me with the intro into the next episode, but recently it has been cycling right back to the beginning of the episode and not shutting off."
  Spotify Community, 2023-03-30, https://community.spotify.com/t5/iOS-iPhone-iPad/Spotify-not-shutting-off-at-end-of-podcast-episode/td-p/5530499
- **#S3 [C] wakes up to a different episode.** "I set my iPhone on charger for the night with the episode I selected and turn on sleep timer for end of episode. When I wake up in the middle of the night it’s still playing and on a different episode entirely."
  Spotify Community, 2022-12-04, https://community.spotify.com/t5/Android/Sleep-timer-not-working-with-podcasts/m-p/5469181
- **#S4 [C] plays whole playlist.** "It just plays the full playlist instead of stopping."
  Spotify Community, 2022-12-16, https://community.spotify.com/t5/Android/Sleep-timer-not-working-with-podcasts/m-p/5469181
- **#S5 [C] timer ignored.** "episodes keep playing even though I set the timer to stop playing after the episode or an hour."
  Spotify Community, 2020-12-01, https://community.spotify.com/t5/Android/Sleep-timer-not-working-with-podcasts/m-p/5469181
- **#S6 [C] churn over the timer.** "Nearly 18 months later still no fix, I gave up on Spotify for podcasts months ago"
  Spotify Community, 2022-04-10, https://community.spotify.com/t5/Android/Sleep-timer-not-working-with-podcasts/m-p/5469181
- **#S7 [C] next episode's loud ad wakes you.** "Please bring this feature back!! I need it to fall asleep. As someone in the thread mentioned, a next podcast episode will play with a loud ad that wakes me up 😞"
  Spotify Community, 2024-04-22, https://community.spotify.com/forum/en/discussion/6016380/sleep-timer-on-ios-for-podcasts-gone/p2
- **#S8 [D/C] timer as a "reverse alarm".** "I fall asleep to white noise, and I use it as a reverse alarm. I wake up when it turns off. Now, it goes to the next episode which always starts with an ad."
  Spotify Community, 2024-04-19, https://community.spotify.com/t5/iOS-iPhone-iPad/sleep-timer-on-iOs-for-podcasts-gone/td-p/6016380
- **#S9 [C] timer buried in a menu.** "Mine is there in the three dots menu but I want it back as a timer icon on the now playing screen. I hate having to navigate when I’m half asleep"
  Spotify Community, 2024-10-27, https://community.spotify.com/forum/en/discussion/6016380/sleep-timer-on-ios-for-podcasts-gone/p2
- **#S10 [D] nightly reliance.** "Same here, I’ve been using it every night for years and have become reliant on it so I’m keen to get it back."
  Spotify Community, 2024-04-19, https://community.spotify.com/t5/iOS-iPhone-iPad/sleep-timer-on-iOs-for-podcasts-gone/td-p/6016380
- **#S11 [D] calming racing thoughts.** "I use a podcast at night to stop my thoughts from running ramped."
  Spotify Community, 2024-04-21, https://community.spotify.com/forum/en/discussion/6016380/sleep-timer-on-ios-for-podcasts-gone/p2
- **#S12 [M] longer, custom and N-episode timers.** "Multi-Episode Timers: An option to stop playback after a set number of episodes (e.g., "Stop after 2 episodes" or "Stop after 3 episodes" ), which is especially helpful for shorter 15–20 minute shows."
  Spotify Community idea, 2026-08-14, https://community.spotify.com/t5/Live-Ideas/Feature-Request-Expanded-Sleep-Timer-Options-for-Podcasts-amp/idi-p/7531360
- **#S13 [M] the same idea, on the bedtime pain.** "without the hassle of waking up mid-night to reset a timer or having audio play through the entire night."
  Spotify Community idea, 2026-08-14, https://community.spotify.com/t5/Live-Ideas/Feature-Request-Expanded-Sleep-Timer-Options-for-Podcasts-amp/idi-p/7531360
- **#S14 [D] workaround: a one-episode playlist.** "I added the single episode to a new playlist called "SLEEP" and then in my library I play the playlist. The episode will end and nothing will play after it."
  Spotify Community, 2022-12-06, https://community.spotify.com/t5/Android/Sleep-timer-not-working-with-podcasts/m-p/5469181
- **#S15 [C] resume position lost.** "On occasion, the app does not save the spot that I stopped listening to a specific podcast. So when I go back to listen, I have to fast forward to get to the spot I left off"
  Mweb819, App Store, 2026-10-19, https://itunes.apple.com/us/rss/customerreviews/page=1/id=324684580/sortby=mostrecent/json

### Hacker News

- **#H1 [C] general UX.** "the apple podcast player is truly horrendous to use."
  jaffa2, 2026-07-09, https://news.ycombinator.com/item?id=48843204

That is 32 quotes in all. The strongest theme across both apps: **after the timer fires, something else starts**, whether the next episode, an ad, or a loop (#S1 to #S8, #A3, #A4, #A14). The second theme is **the timer is hard to reach or read half-asleep** (#A2, #S9).

---

## 4. Ideas YawnCast could adopt

1. **"End of episode" that is guaranteed to stop.** YawnCast already has no queue and no autoplay-next. Make that a promise you can see: after an end-of-episode stop, never start anything else, and never let an intro or ad from another episode play. Say it plainly in the timer sheet ("Stops and stays stopped"). Evidence: #S1 to #S8, #S14.
2. **Keep the Moon on the main player, one tap, always.** Never move it into an overflow menu, and never hide it behind "start an episode first." Evidence: #S9; Apple's timer is only in full Now Playing and appears only after playback starts (iPhone Life).
3. **Show time left on both the timer and the episode while the timer runs.** Use large, dim, glanceable text. Evidence: #A2.
4. **Fill in the preset gaps and allow longer sessions.** Add 20 and 25 minute presets and something over 1 hour (90 or 120 min). Consider "after N episodes" only if it fits the no-queue model, for example "this episode + 1". Evidence: #A1, #A3, #S12, #S13.
5. **A "fell asleep" marker.** When a fade-out ends playback, save the position and keep the episode **unplayed**, then offer a "you dozed off at 23:14, jump back?" resume next time. Evidence: #A4, #A7, #A8, #S15.
6. **A bedtime Lock Screen lock.** Offer a way to stop stray touches from scrubbing or skipping, for example a Now Playing that only reports remote commands for play/pause and leaves skip off, or a "bed mode" with skip disabled. Evidence: #A6.
7. **A calm Lock Screen and Live Activity.** Keep the episode title, never an AI chapter title. Use small art, not full-screen artwork. A Live Activity could show the Moon countdown. Evidence: #A9, #A10, #A11; Spotify's widget only launches the app (support page).
8. **Audio-only by design.** YawnCast's "no video at night" is a selling point, so state it on the Explore page and onboarding. Evidence: #A5.
9. **Downloads that never vanish.** Never auto-delete an unplayed download, and show storage plainly. Evidence: #A12, #A13.
10. **Never auto-play on connect.** Bluetooth or CarPlay connections should not start playback. YawnCast can state this as a guarantee. Evidence: #A14, #A15.
11. **A Siri / Shortcuts "Start sleep timer" intent.** Both rivals let you start a sleep timer by voice (Spotify's "Set a sleep timer"). An App Intent for the Moon timer would work in the dark without unlocking. Source: https://support.spotify.com/us/article/talk-to-spotify/
12. **Sleep timer that works over AirPlay.** Both rivals grey out or cancel the timer when audio goes to a HomePod or Connect speaker. YawnCast's fade-and-pause should keep working when routed to AirPlay. Evidence: the Apple HomePod thread and the Spotify Connect moderator reply (section 1 and 2 tables).

---

## Injected instructions seen

None. No page contained text directed at the agent.
