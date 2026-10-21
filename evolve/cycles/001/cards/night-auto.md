# Sleep turns itself on late at night            Flag: exp_night_auto   Status: PLANNED

**What changes for the user:** If you start an episode between 10 pm and 5 am and Sleep is off, Sleep turns on by itself with the usual countdown and a short note, "It’s late, so Sleep is on." One tap on the Moon turns it off.
**Why (evidence):**
- "I often forget to enable a sleep timer in the evening and when I wake up in the morning my half queue has been played." - GitHub AntennaPod #2085, https://github.com/AntennaPod/AntennaPod/issues/2085, 2016-08-02
- "if i start a podcast in a certain timerange, eg. between 23:00 and 04:00, the sleep timer is automatically activated" - Pocket Casts forum, https://forums.pocketcasts.com/forums/topic/feature-request-sleep-timer-usability/, 2026-02-11
- "Three thing I wish for are: 1) scheduled sleep timer." - Overcast App Store US review, https://itunes.apple.com/us/rss/customerreviews/id=888422857/sortBy=mostHelpful/json, 2022-07-10
- Competitor behavior: Sleepcast! "Time Window" keeps the timer active only during set hours, https://apps.apple.com/us/app/id6744658836
**Where to see it:** Play any episode with `-exp_night_auto YES` and a test hook that fakes the hour (launch argument `-nightHour 23`, Debug only).
**Build plan:** In `AppModel.play` (deliberate start or resume), if the flag is on, Sleep is off and the local hour is in 22:00-05:00, run the normal Sleep toggle and show the toast. Only once per episode load, so turning it off sticks. Fixed window (no setting, no persisted data).
**Design / Accessibility / Tests / Screenshots:** filled in Phase 3.
**Risk / what it does not do:** Window is fixed; changing it would need a setting (a persisted-data decision for you). Remote Lock Screen play of an already-loaded episode is not a deliberate start, so it does not auto-arm.
**Rollback:** delete branch evolve/001/night-auto; flag removal is one commit.
