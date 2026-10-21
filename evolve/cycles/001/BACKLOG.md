# Cycle 001 backlog

Score = evidence (0-3) + impact (0-3) + fits ~40 min (0-3) + fits YawnCast's identity (0-3). Picks avoid persisted-data changes, new permissions, new dependencies, pricing and backend.

| Idea | Flag | Ev | Imp | Fit 40m | Identity | Total | Files | Decision |
|---|---|---|---|---|---|---|---|---|
| Press Play soon after Sleep pauses → Sleep turns back on | exp_wake_extend | 3 | 3 | 3 | 3 | **12** | AppModel | **PICK** (top complaint, theme 3) |
| "Back to where the fade began" key on Now Playing after Sleep | exp_drift_back | 3 | 3 | 2 | 3 | **11** | AppModel, NowPlayingView (below the scrubber, away from the Sleep bar) | **PICK** (theme 2) |
| Sleep status on the Lock Screen / Control Center | exp_lock_status | 2 | 2 | 3 | 3 | **10** | NowPlayingBridge, AppModel hook | **PICK** (polish, theme 6) |
| Moon key on the mini player | exp_mini_moon | 3 | 2 | 3 | 3 | **11** | LibraryView (MiniPlayerDock) | **PICK** (polish, theme 5) |
| Night window: starting an episode late at night turns Sleep on | exp_night_auto | 3 | 3 | 2 | 2 | **10** | AppModel | **PICK** (bigger swing, theme 7; fixed 22:00-05:00 window, no setting, so no persisted data) |
| Bed lock: Lock Screen scrubber off while Sleep is on | exp_bed_lock | 2 | 2 | 3 | 3 | 10 | NowPlayingBridge | Next up (same file as lock status; one Lock Screen change per cycle) |
| Loudness levelling for loud ads / outros | - | 3 | 3 | 1 | 3 | 10 | PlaybackEngine (audio tap / AVAudioMix) | Next up (over 40 min; audio-path risk) |
| "Recently played" row so a slept-through episode is easy to find | - | 2 | 2 | 2 | 2 | 8 | HomeView | Next up |
| VoiceOver: uppercase headers read letter by letter; Reduce Motion gaps (from DESIGN.md) | - | 1 | 2 | 3 | 3 | 9 | Search/Themes/Home views | Next up (evidence is internal, not user quotes) |
| Soft haptic when Sleep re-arms | - | 2 | 1 | 3 | 3 | 9 | - | Folded into exp_wake_extend if cheap |
| Siri / Shortcuts "Start Sleep" (App Intent) | - | 2 | 2 | 2 | 3 | 9 | new file | **Needs your decision**: App Shortcuts show in Spotlight/Shortcuts in Release even with the flag off, so it can't be a no-op for real users |
| "Until end of episode" / presets / longer timer | - | 3 | 2 | 2 | 0 | 7 | Sleep core | **Needs your decision**: breaks "One tap on Moon. No picker." (PROJECT_BRIEF) |
| Bedtime shelf in Library | - | 2 | 2 | 1 | 2 | 7 | LibrarySnapshot | **Needs your decision**: changes persisted library data |
| Sleep Live Activity / widget | - | 2 | 2 | 0 | 3 | 7 | new extension target | Rejected this cycle: new target, well over 40 min |
| Shake to extend | - | 2 | 1 | 2 | 1 | 6 | - | Rejected: users report misfires and beeps waking them (voice-of-customer Q37-Q41) |
| Speed control / transcripts | - | 1 | 1 | - | 0 | - | - | Rejected: owner out-of-scope list |

## Mix check
Polish: exp_lock_status, exp_mini_moon (2, max 2). Top complaint: exp_wake_extend, exp_drift_back. Bigger swing: exp_night_auto (1).

## Shared files
exp_wake_extend, exp_drift_back, exp_lock_status and exp_night_auto all touch `AppModel.swift`, in separate methods. Build sequentially; integrate one at a time.
