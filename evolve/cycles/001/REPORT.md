# Evolve cycle 001: YawnCast

Elapsed working time: about 1 h 25 min of the 7 h cap (91 min on the clock, minus a 6 min pause).
**5 READY · 0 DEFERRED · 0 ABANDONED.** One visual check is missing: the Lock Screen line (card 3) could not be seen in the Simulator.

Candidate branch: `evolve/001/candidate` in `~/projects/NightCast-evolve` (cut from `main` @ 9fbcc25, not pushed). All five are behind flags that are OFF in App Store builds.

| # | Iteration | Flag | Status | What changes | Evidence |
|---|---|---|---|---|---|
| 1 | Play again turns Sleep back on | `exp_wake_extend` | READY | Play within 10 min of Sleep's pause (AirPods, Lock Screen, app) turns Sleep back on | 3 quotes + Castro behavior |
| 2 | Back to where you drifted off | `exp_drift_back` | READY | After a fade, a "Back to 41:20, where the fade began" key on Now Playing | 3 quotes + Sleepcast behavior |
| 3 | Sleep on the Lock Screen | `exp_lock_status` | READY (visual NOT VERIFIED) | "Radiolab · Sleep on, fades in 17 min" under the episode on the Lock Screen | 3 quotes + Castro behavior |
| 4 | Moon on the mini player | `exp_mini_moon` | READY | A Moon key next to Play on the mini player | 3 quotes |
| 5 | Sleep turns on late at night | `exp_night_auto` | READY | Starting an episode 22:00-04:59 turns Sleep on, with "It’s late, so Sleep is on." | 3 quotes + Sleepcast behavior |

## Tests on the candidate
- All flags off (`scripts/test.sh`): Core 94 pass, app unit 30 pass, Debug and Release build, fixture UI tests 32 pass. The run's 15-minute cap cut off the last WakeExtend test; it was re-run below.
- After the review fixes: Core 95 pass; WakeExtend (2), DriftBack (3), NightAuto (4) UI tests pass.
- All flags on (stored overrides): the original UI suites (Accessibility, CoreFlow, HomePages, Sleep, SleepBubble, V4: 23 tests) and app unit tests (30) pass. `night_auto` can't fire there (daytime clock); NightAutoUITests covers it with `-nightHour`.

## Review (Opus) and what changed
- Fixed: drift-back missed the fade start after −5 min near the end of the countdown (no key). New Core test.
- Fixed: play-again could re-arm Sleep after a failed switch to another episode (D07).
- Changed: a re-armed Sleep no longer erases the Back key.
- Checked: flags-off paths match base; no saved-data, permission, dependency or analytics change; `-nightHour` is Debug only.

## How to test
1. Open `~/projects/NightCast-evolve` (branch `evolve/001/candidate`) in Xcode, scheme **YawnCast**, run on a simulator or your iPhone. Or:
   `xcodebuild -project YawnCast.xcodeproj -scheme YawnCast -destination 'platform=iOS Simulator,name=NightCast iPhone' build`
2. Turn experiments on or off: **Themes** (half-filled circle on Library) → scroll to the bottom → **long-press the "YawnCast 0.15 (15)" line** → Experiments. One switch per iteration, plus Turn all on / Reset.
3. Or launch with `-evolve_all YES` (all on) or `-exp_<flag> YES|NO` (one).
4. Useful: `-demo` (sample library), `-fastSleep` (short Sleep for trying the fade), `-nightHour 23` (pretend it's late, Debug only).
5. Right now the Simulator has all five switched on (stored overrides) and the candidate open.

## The cards

# Press Play again and Sleep comes back on            Flag: exp_wake_extend   Status: READY

**What changes for the user:** If Sleep has faded and paused the episode and you press Play within 10 minutes (from AirPods, the Lock Screen, the mini player or Now Playing), Sleep turns itself back on with the usual countdown. No need to find the Moon half-asleep.
**Why (evidence):**
- "My dream feature as a podcast sleeper would be, if you resume a podcast within 60 seconds (or something) of the sleep timer expiring, the timer resets." - r/pocketcasts, https://www.reddit.com/r/pocketcasts/comments/xhj9hd/id_love_a_repeat_option_for_podcasts_from_a/ip2g8vt/, 2022-09-19
- "I wish Overcast could restart the sleep timer if playback is activated within five minutes after the timer stops." - r/overcast, https://www.reddit.com/r/overcast/comments/1veca38/testflight_build_1169_transcript_search_and/p1iaxz3/, 2026-08-03
- "Helpful tip is “extend sleep timer.” If you’re still listening, just press play again and it will extend again for the same time you initially set. So good!" - Castro App Store CA review 13297722218, https://itunes.apple.com/ca/rss/customerreviews/page=1/id=1080840241/sortby=mostrecent/json, 2025-10-21
- Competitor behavior: Castro re-arms the timer when Play is pressed within 60 s of it ending, https://castro.fm/support/sleep-timer-tips
**Where to see it:** Now Playing with `-fastSleep`: turn on Sleep, let it fade and pause, press Play. The Moon is lit again and VoiceOver hears "Sleep is back on".
**Build plan:** In `AppModel`, remember the episode id and time when Sleep pauses playback (the Sleep "at zero" path). On the next transition to playing for the same episode within 10 min of active-clock time, call the existing toggle path once. Different episode or later than 10 min: nothing. Flag check at that seam only. Gentle `.sensoryFeedback(.success)` if a view can observe it cheaply; no sound.
**Design:** No new UI. Impeccable critique of copy against DESIGN.md section 10: "Sleep is back on · fade begins in 30 min" is short, plain, sentence case, no exclamation mark, matches the existing "Sleep on · fade begins in ..." pattern. Kept. One announcement only (not the usual activation line plus a second one). No extra haptic: the Moon key already fires its heavy impact when Sleep state changes (NowPlayingView.swift:97), so adding `.success` would double up. No sound.
**Accessibility:** VoiceOver hears the single announcement "Sleep is back on · fade begins in X" via the existing `announce` path. Moon key label/value (`moonKey`, "On. Fade begins in ...") unchanged. No new controls, so Dynamic Type, contrast, Reduce Motion and 44 pt targets are unaffected.
**Tests:** YawnCastUITests/WakeExtendUITests.swift, `-fastSleep`: fade out and pause, tap Play. Flag on: Moon value "On." again. Flag off: stays "Off". Both pass (about 45 s each). `swift test` in YawnCastCore: 90 tests pass. Release build succeeds.
**Screenshots:** evolve/cycles/001/shots/wake-extend-off.png and wake-extend-on.png, captured by the UI test after fade + Play (demo mode cannot play audio, so -uitest fixture mode was used). The "on" shot catches the Play glyph mid-transition; Sleep is on.
**Risk / what it does not do:** Does not react to Play after 10 min or on another episode. Doesn't persist across an app kill (in-memory only, by design: no data change). Uses wall-clock Date for the 10 min window. Adds one Core callback `SleepController.onFadedToSilence` (fires only on the fade-to-zero path) and `SleepCopy.backOn`.
**Review fix (candidate, 6d8dfae):** loading a different episode now forgets the faded episode, so returning to it within 10 min after a failed switch can't re-arm Sleep that D07 cancelled. The 10-minute cutoff itself is still not covered by a test (no injectable clock here).
**Rollback:** delete branch evolve/001/wake-extend; flag removal is one commit.

# Back to where you drifted off            Flag: exp_drift_back   Status: READY

**What changes for the user:** After Sleep fades and pauses an episode, Now Playing shows a small key under the scrubber: "Back to 41:20, where the fade began". One tap jumps there, so you hear what you slept through without hunting.
**Why (evidence):**
- "I set my sleep timer for 30 min and then the next day rewind to where I fell asleep." - r/adhdwomen, https://www.reddit.com/r/adhdwomen/comments/1e5qo7b/how_do_you_guys_sleep/ldpxax6/, 2024-07-18
- "The next night I rewind it back to roughly where I fell asleep and start again." - r/doughboys, https://www.reddit.com/r/doughboys/comments/1wkp7wd/does_anyone_else_use_the_pod_to_fall_asleep_ive/patxm8l/, 2026-09-19
- "There's even enough space on the Sleep Timer window for a "Jump Back" button that would take listeners to the last time the sleep timer was reset." - Overcast App Store US review (Mike W Perry), https://itunes.apple.com/us/rss/customerreviews/id=888422857/sortBy=mostHelpful/json, 2019-04-28
- Competitor behavior: Sleepcast! "Morning Overview" shows activity after the session, https://apps.apple.com/us/app/id6744658836
**Where to see it:** Now Playing after a Sleep fade with `-fastSleep -exp_drift_back YES`.
**Build plan:** `AppModel` records the playback position when the fade starts (countdown → fading transition) for the current episode; clears it on a different episode or after the jump. NowPlayingView shows one standard `KeyStyle` capsule below the time labels (not in the Sleep bar area, to stay clear of PRs #6/#7). Tap seeks to that position; does not start playback.
**Design:** Impeccable shape → critique → polish (scoped refinement; no PRODUCT.md, worked from evolve/DESIGN.md + code). One `.standard` `capsuleKey(depth: 3)` under the scrubber's time labels, leading-aligned with the elapsed time, `Space.m` above; content hugs (not full width) so it stays quieter than Play. Two lines: "Back to 0:05" (`Typo.headline`, monospaced digits) over "where the fade began" (`Typo.caption`, `textMuted`), `arrow.uturn.backward` glyph in `text` (no accent: accent stays Sleep's). Selection haptic on tap (same as scrub release). Appears with opacity + 6 pt rise, `spring(0.3, 0.8)`; Reduce Motion → `easeOut 0.2` opacity only. Critique kept: placement clear of the Sleep bar/bubble (PRs #6/#7); changed during polish: at accessibility sizes the capsule becomes an 18 pt continuous rounded plate spanning the width so wrapped lines don't sit in a pill. Only theme roles (raised/edge/highlight/text/textMuted), so Red Light stays warm via its own highlight; not separately screenshotted in Red Light.
**Accessibility:** identifier `driftBackKey`; label "Back to 41 minutes, 20 seconds, where the fade began" (`TimeFormat.spoken`); hint "Moves the episode there. It stays paused."; after the jump VoiceOver hears "At …" (the key disappears). Height ≥ 44 pt (asserted in UI test). Checked at AccessibilityL text size on Paper (wraps, hittable). Contrast: textMuted/text on raised are existing AA pairs.
**Tests:** Core `SleepFadeBeganTests` (4: fires once at fade start with recoverable position, cancel never reports silence, +5 during fade refires, paused time never fades) — `swift test` 94/94 green. UI `DriftBackUITests` (3, `-uitest -resetStore -fastSleep`): flag on Midnight → key after fade-and-pause, tap → scrubber value moves to the marker, key gone, still paused; flag on Paper at AccessibilityL → key hittable; flag off → key never appears during or after the fade. All 3 pass; `SleepUITests` (3) still pass. Debug and Release build.
**Screenshots:** `shots/drift-back-off.png`, `shots/drift-back-on.png` (Midnight), `shots/drift-back-on-paper-ax.png` (Paper, AccessibilityL). Captured by the UI test in `-uitest` fixture mode right after the fade paused, not `-demo` (the demo episode would need a ~30 min real fade; `-fastSleep` + fixture audio is the only way to reach the state).
**Implementation:** Core `SleepController` gains `onFadeBegan(episodeID, secondsAgo)` (fires when the countdown crosses the fade delay, with the overshoot so the position is exact) and `onFadedToSilence(episodeID)` (identical text to evolve/001/wake-extend). `AppModel` records the fade start only when the flag is on (flag read once per fade, not per tick), promotes it to `driftBack` on silence, hides it while Sleep is on, clears it on a new Sleep, a different episode, or the jump. Flag off: callbacks return early, nothing renders.
**Risk / what it does not do:** In-memory only: if iOS kills the app overnight the marker is gone (no persisted-data change this cycle). Cancelling Sleep mid-fade gives no key (you were awake). Merge note: wake-extend also assigns `sleep.onFadedToSilence` in `AppModel.init`; when both merge, combine the two closure bodies into one (Core hunk is identical).
**Review fix (candidate, 6d8dfae):** the Opus review found the fade start was missed when −5 min (or a late real duration) moved the fade delay to exactly now, so no Back key appeared. `SleepController` now reports the fade start once per fade from `sync`, `adjust` and `measuredDurationArrived`; new Core test "−5 min with under 5 min left…" passes (95/95). Also, a re-armed Sleep (play-again) no longer erases the key: it hides while Sleep is on and comes back when Sleep is off; a new fade replaces it.
**Rollback:** delete branch evolve/001/drift-back; flag removal is one commit.

# Sleep shows on the Lock Screen            Flag: exp_lock_status   Status: READY

**What changes for the user:** While Sleep is on, the Lock Screen and Control Center player shows "Sleep on · fades in 17 min" (or "Sleep on · fading") under the episode title, so you can see the Moon is set without opening the app.
**Why (evidence):**
- "I'd love to see an indicator of whether I'm in "sleep timer mode" or not on the iOS Lock Screen. Castro displayed something like that under the episode name, where the authors are listed." - Pocket Casts forum, https://forums.pocketcasts.com/forums/topic/feature-request-automatically-extend-sleep-timer/, 2023-11-28
- "the sleep timer seems to be still turned on although the color of the icon is greyed out (I.e. function is turned off)." - Pocket Casts forum, https://forums.pocketcasts.com/forums/topic/iphone-sleep-timer-problems/, 2026-02-22
- "It’s very frustrating you now can’t see the amount of time left on an episode with the sleep timer on." - Apple Podcasts App Store review, https://itunes.apple.com/us/rss/customerreviews/page=9/id=525463029/sortby=mostrecent/json, 2026-05-29
- Competitor behavior: Castro shows the timer's time remaining on the Lock Screen and in Control Center, https://castro.fm/support/sleep-timer-tips
**Where to see it:** Simulator Lock Screen (or `MPNowPlayingInfoCenter` values in a unit test) with `-exp_lock_status YES` and Sleep on.
**Build plan:** `NowPlayingBridge` gains an optional subtitle provider; when the flag is on and Sleep is not off, the artist line becomes "<show> · Sleep on, fades in N min". AppModel refreshes it on Sleep status change and once a minute while counting down (no faster).
**Design:** No new UI; one text line. Copy reuses the Moon key voice (DESIGN.md section 10): "Radiolab · Sleep on, fades in 17 min" / "Radiolab · Sleep on, fading". Impeccable critique: sentence case, no exclamation marks, bedtime wording, "fades in" mirrors "Fade begins in"; kept the middle dot already used by SleepCopy.activated. Changed during critique: minutes round up and never show seconds (a "40 sec" line would rewrite the Lock Screen every few seconds, and "0 min" reads as already faded), floor of "1 min". Kept "Sleep on" (not "Drifting off") while fading, so the line reads the same shape in both phases and the Lock Screen stays literal.
**Accessibility:** The artist line is read by iOS (Lock Screen, Control Center, CarPlay) as ordinary now-playing metadata, so VoiceOver reads the full sentence with no custom label. Text is system-rendered: Dynamic Type, contrast and Reduce Motion are the OS's. No new targets or color.
**Tests:** YawnCastTests/LockScreenSleepTextTests (5 tests: off = show only, waiting minutes and round-up, fading, string changes once a minute across 4 Hz samples, bridge artist line with provider absent (flag off) and present (flag on)): all pass. SleepUITests (3 tests) pass. Release build succeeds. Core untouched.
**Implementation:** `LockScreenSleepText` (pure), `NowPlayingBridge.artistLine` optional provider + `artistText(for:)`, AppModel `installLockStatus`/`lockStatusLine`/`refreshLockStatus` (flag read once at init; `sleep.onChange` pushes only when the minute or phase text changes; `player.onStateChange` already updates the bridge and records the pushed line). Flag off: no provider, artist = show title as before.
**Screenshots:** NOT VERIFIED. On the candidate I also tried the Simulator Lock Screen and Notification Center with an episode playing and Sleep on: this Simulator shows no Now Playing controls there, so the line could not be seen. Check on your iPhone. simctl cannot lock the device or show the Lock Screen and I did not script Device > Lock. Evidence instead: evolve/cycles/001/shots/lock-status-unit-test.log (passing unit-test lines).
**Risk / what it does not do:** Lock Screen layout may truncate long show names plus the suffix (iOS ellipsizes). Elapsed-time updates from the player already refresh the line on every state change, which is existing behavior. Lock Screen text granularity is whole minutes. No Live Activity (new target, out of scope).
**Rollback:** delete branch evolve/001/lock-status; flag removal is one commit.

# Moon on the mini player            Flag: exp_mini_moon   Status: READY

**What changes for the user:** The mini player gets a small Moon key next to Play, so Sleep is one tap from any screen without opening Now Playing.
**Why (evidence):**
- "The sleep timer should be one click." - Overcast App Store GB review, https://itunes.apple.com/gb/rss/customerreviews/id=888422857/sortBy=mostHelpful/json, 2024-07-25
- "Mine is there in the three dots menu but I want it back as a timer icon on the now playing screen. I hate having to navigate when I’m half asleep" - Spotify Community, https://community.spotify.com/forum/en/discussion/6016380/sleep-timer-on-ios-for-podcasts-gone/p2, 2024-10-27
- "Something in the settings screen to default a 15 minute sleep timer with a moon icon to click on the main screen." - r/overcast, https://www.reddit.com/r/overcast/comments/1oubjb9/feature_request_sleep_timer_on_apple_watch/nobcijd/, 2025-11-11
**Where to see it:** Any home page with an episode loaded, `-demo -exp_mini_moon YES`.
**Build plan:** In `MiniPlayerDock` add a 44 pt round key (standard role; accent role when Sleep is on, per DESIGN.md) calling `model.toggleSleep()`. Disabled when nothing is playable. (Built: the subtitle glyph is dropped when the flag is on, see Design.)
**Design:** Impeccable shape/critique/polish against DESIGN.md, in Midnight, Paper, Red Light. Key is `.roundKey` depth 3, 44 pt, 17 pt bold moon.fill like the Play glyph: standard role with accent glyph when Sleep is off, accent role with onAccent glyph when on (the only accent key, per DESIGN.md). Dropped the subtitle moon glyph with the flag on: the key now shows Sleep state at a glance and the glyph would double it and cost title width; flag off keeps it. Kept: Play stays the only primary key; title already lineLimit(1) so it truncates as before at AX sizes. Finding, not changed: in Red Light the accent face (#D9805F) and the primary Play face (#EFA084) are close in hue, so Sleep-on is told apart mainly by glyph and position; fixing needs a theme-role change, out of scope.
**Accessibility:** label "Sleep", value "On"/"Off", `.isSelected` when on, id `miniMoonKey`, large content viewer, 44 pt, disabled when no episode. Haptic: Now Playing's heavy impact is not mounted when the player is closed, so the mini key has its own, triggered by a tap counter (taps here only, so no double haptic with Now Playing). VoiceOver announcement comes from toggleSleep. Key travel respects Reduce Motion via KeyStyle. Contrast: accent glyph on raised and onAccent on accent reuse existing audited pairs. Live check at AX text sizes NOT VERIFIED (not run in simulator).
**Tests:** YawnCastUITests/MiniMoonUITests (flag on: key present, tap On, Now Playing moon agrees, tap Off; flag off: key absent) plus HomePagesUITests: 5/5 pass. Release and Debug build.
**Screenshots:** evolve/cycles/001/shots/mini-moon-off.png (flag off), mini-moon-on.png (flag on, Sleep off), mini-moon-sleep.png (Sleep on), mini-moon-paper.png / mini-moon-paper-off.png, mini-moon-redlight.png / mini-moon-redlight-off.png.
**Risk / what it does not do:** No ±5 bubble on the mini player. Touches LibraryView.swift near PR #5 (gap under mini player).
**Rollback:** delete branch evolve/001/mini-moon; flag removal is one commit.

# Sleep turns itself on late at night            Flag: exp_night_auto   Status: READY

**What changes for the user:** If you start an episode between 10 pm and 5 am and Sleep is off, Sleep turns on by itself with the usual countdown and a short note, "It’s late, so Sleep is on." One tap on the Moon turns it off.
**Why (evidence):**
- "I often forget to enable a sleep timer in the evening and when I wake up in the morning my half queue has been played." - GitHub AntennaPod #2085, https://github.com/AntennaPod/AntennaPod/issues/2085, 2016-08-02
- "if i start a podcast in a certain timerange, eg. between 23:00 and 04:00, the sleep timer is automatically activated" - Pocket Casts forum, https://forums.pocketcasts.com/forums/topic/feature-request-sleep-timer-usability/, 2026-02-11
- "Three thing I wish for are: 1) scheduled sleep timer." - Overcast App Store US review, https://itunes.apple.com/us/rss/customerreviews/id=888422857/sortBy=mostHelpful/json, 2022-07-10
- Competitor behavior: Sleepcast! "Time Window" keeps the timer active only during set hours, https://apps.apple.com/us/app/id6744658836
**Where to see it:** Play any episode with `-exp_night_auto YES` and a test hook that fakes the hour (launch argument `-nightHour 23`, Debug only).
**Build plan:** In `AppModel.play` (deliberate start or resume), if the flag is on, Sleep is off and the local hour is in 22:00-05:00, run the normal Sleep toggle and show the toast. Only once per episode load, so turning it off sticks. Fixed window (no setting, no persisted data).
**Design:** Only a toast. "It’s late, so Sleep is on." appears for about 4 s in the existing toast slot above the Moon key (same `surface` capsule, `Typo.caption`, `text` color as "Sleep off"), standing in for the countdown pill while it shows; then the pill returns. The Moon key itself already reads "Sleep on / Fade begins in N min", so nothing is hidden. No new color, token, motion or haptic (auto-arm happens before Now Playing appears, so the Sleep haptic does not fire: no surprise buzz in bed).
Impeccable (native, Assessment A only, in-context; questions skipped: builder subagent). Shape: first draft put the note in a new row above the bubble; rejected because the trailing stack sits under two Spacers, so a new row nudges the transport keys up mid-presentation. Moved it into the existing toast slot: no layout shift, one place for transient Sleep messages. Critique: copy follows DESIGN.md §10 (sentence case, curly apostrophe, no exclamation, says why in bedtime terms, not "Auto Sleep enabled"); kept the period because it is a full two-clause sentence. Considered adding "Tap the Moon to turn it off": dropped, the Moon key is directly below and labeled "Sleep on", and longer text would wrap at large sizes. Kept 4 s (vs 3 s for other toasts) because it lands while the sheet is still presenting. Polish: extracted the toast capsule into one `toastLabel` helper so both toasts are pixel-identical. Nothing else changed.
**Accessibility:** VoiceOver hears one message: `toggleSleep(announcing:)` suppresses the usual "Sleep on · fade begins in…" announcement on this path, and the app posts a single combined "It’s late, so Sleep is on. Fade begins in 24 min." 0.7 s later, after Now Playing takes focus (an announcement posted during the cover presentation is usually swallowed). The visual capsule stays `accessibilityHidden` like the existing toast; the Moon key's value ("On. Fade begins in…") is the persistent state. Contrast: `text` on `surface`, an existing AA pair. Dynamic Type: caption style scales; at accessibility sizes it wraps inside the capsule exactly like the existing "Sleep off" toast (not separately verified at AX5). Reduce Motion: opacity transition only. Targets: no new controls.
**Tests:** YawnCastTests/NightAutoTests (6, Swift Testing): window boundaries 21/22/4/5, `-nightHour` parsing (0, 23, invalid 24, missing), late start arms + note, daytime off, flag off, Sleep off sticks on resume of the same load and a different episode re-arms. YawnCastUITests/NightAutoUITests (4): flag on + `-nightHour 23` → Moon "On…"; flag on + 14 → Off; flag off + 23 → Off; flag on + 23, Moon off, pause, close player, tap the same episode again → stays Off. All pass. Regression: SleepUITests (3) and SleepBubbleUITests (2) pass. Debug build-for-testing and Release (simulator) build succeed; `strings` on the Release binary finds no "nightHour". Core not touched.
**Screenshots:** `shots/night-auto-off.png` and `shots/night-auto-on.png`: `-demo -autoplay -openPlayer -nightHour 23`, without and with `-exp_night_auto YES`, about 2 s after start (Radiolab, Midnight). Off: Moon key "Sleep / Fade out, then pause". On: note above an accent Moon "Sleep on / Fade begins in 24 min".
**Risk / what it does not do:** Sleep arms at load time, before audio is actually playing (same as tapping the Moon while it buffers; toggle accepts that and revises the delay when the real duration arrives). If the episode then fails to load, Sleep stays on for it, same as a manual tap. Only `play(_:)` (row tap, demo autoplay) auto-arms; the Play/Pause key, mini player and Lock Screen do not. "Once per load" means the first `play(_:)` inside the window; a start at 21:50 followed by re-tapping the row at 22:10 will arm. Window is fixed; changing it would need a setting (a persisted-data decision for you). Remote Lock Screen play of an already-loaded episode is not a deliberate start, so it does not auto-arm.
**Rollback:** delete branch evolve/001/night-auto; flag removal is one commit.

## Needs your decision (not built)
- Siri / Shortcuts "Start Sleep": App Shortcuts show in Release even with a flag off, so it can't be hidden from real users.
- "Until end of episode" or timer presets: breaks "One tap on Moon. No picker." (PROJECT_BRIEF).
- A Bedtime shelf in Library: changes saved library data.
- The late-night window is fixed at 22:00-04:59; choosing your own hours needs a saved setting.

## Questions
See `evolve/QUESTIONS.md`: base branch (`main`, without PRs #5, #6, #7; mini-moon touches `LibraryView.swift` near PR #5).

## Findings worth a later look
- Red Light: the accent Moon face and the primary Play face are close in hue (mini-moon card).
- DESIGN.md flags: uppercase section headers read letter by letter by VoiceOver; a few springs ignore Reduce Motion; Explore's filled accent chips go against D12.
- The Experiments line at the bottom of Themes is hard to reach at the sheet's medium height (it springs back); open the sheet fully first.

## Next up (cycle 002 backlog)
Bed lock (no Lock Screen scrubbing while Sleep is on), loudness levelling for loud ads and outros, a "recently played" row, the VoiceOver/Reduce Motion fixes above.

## Your decision
Reply with one line, for example:
`approve: wake-extend, drift-back, mini-moon / reject: night-auto (why) / change: lock-status (what)`
Approving removes the flag and makes the behavior default on an integration branch; merging to `main` waits for your yes at that moment. App Store submission is always your own step.
