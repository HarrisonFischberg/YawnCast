# YawnCast interaction matrix

Branch `interaction/polish`, on top of Lights Out. A bedtime app: motion is slow and sparse, haptics are
few, and nothing here changes audio, Sleep timing or background behaviour.

Tokens live in `YawnCast/Design/Theme.swift`: `Motion` (`press`, `move`, `fade`, `lightsOut`,
`moveUnlessReduced`, `undoLife`) and `Haptic` (`moon`, `transport`, `skip`; picker changes use the system
`.selection`, a confirmed save `.success`). Press styles: `KeyStyle`, `OutlineKeyStyle`, `TileStyle`,
`PressDim`, `RowStyle`. Reduce Motion drops `press` and `move`, keeps `fade`.

Status: **done** (this branch) · **there** (already in Lights Out) · **n/a** · **device** (needs a real phone).
Priority: P1 broken or missing fundamental, P2 polish, P3 nice to have.

| Component / journey | Trigger and intent | Visual response | Gesture + accessible alternative | Haptic | States, Reduce Motion | Pri | Status |
|---|---|---|---|---|---|---|---|
| Unsubscribe (Library long-press, Show page key) | Remove a show | Tile leaves; Undo toast above the mini player for 6 s (8 s with VoiceOver) | Long-press menu; visible Subscribed key on the show page; VoiceOver hears "Undo is at the bottom" | none on removal; `.success` when Undo restores it | Undo puts the show back in its old slot, saved spots kept; tapping Subscribe again also restores the slot. RM: toast fades only | P1 | done |
| Adding a show (+ on tiles and rows, Subscribe, pick-shows) | Save to Library | "Added to your library" pill; + becomes a check | Tap; VoiceOver announcement | one `.success`, from one place (`RootView`) | Was: no haptic on Explore/Category +, and a success buzz when *un*subscribing. Double tap guarded | P1 | done |
| Library reorder | Move a show | Lifted cover preview, source dims to 35%, neighbours move live | Hold and drag; "Move to Top/End" in the menu and as VoiceOver actions | `.selection` per slot crossed (no longer on add/remove) | Dropped outside: watchdog restores. RM: no slide (was ignored) | P1 | done |
| Library layout key | Large / Small / List | Grid re-flows with `Motion.move` | Tap; label says current and next | `.selection` | RM: instant (was ignored) | P1 | done |
| Scrubber | Seek | Thumb tracks the finger with no tween; grows on grab, settles on release; times update live | Drag anywhere on the 44 pt track; VoiceOver adjustable in 15 s steps | `.selection` on grab and release | A drag the system cancels now resets instead of leaving the thumb stuck (no seek). RM: no grow | P1 | done |
| Pressed states | Any tap | Keys 0.96 + dim, tiles 0.97, tags/keys on paper 0.98 + dim | n/a | none | Mini player body, search capsule, theme and text swatches, pick-shows tiles, More/Less had no pressed state; now `PressDim` | P1 | done |
| Mini player | Appears when an episode loads | Slides up from the bottom, 0.38 s | Tap opens player; Moon and Play are 44 pt keys | `Haptic.moon`, `Haptic.transport` | RM: fades (was a slide) | P2 | done |
| "Now playing" row glyph | Shows which episode plays | Speaker waves loop | n/a | none | RM: static speaker (loop was not gated) | P2 | done |
| Themes sheet note field | Type a problem report | Native field | Drag the sheet's list to put the keyboard away (Return is a new line) | none | Draft autosaved (`supportDraft`); Send disabled while gathering | P2 | done |
| Pick-shows tiles | Pick up to 10 | Check fades in; others dim at the limit | Tap; selected trait | `.selection` per pick | RM: fade kept | P3 | done |
| Moon key / Moon bar | Sleep on, off, ±5 | Bar turns accent, keys fade in, "+5 min" echo floats up, icon cross-fades | Tap; VoiceOver value and hint; countdown is its own element | `Haptic.moon` on toggle, `.selection` on ±5 | −5 disabled in the fade. RM: echo fades in place | — | there |
| Fade marks | Watch the fade | One mark goes dark per step over 0.6 s; marks drift at 15 fps | n/a; one VoiceOver element with a value | none | RM: still, cross-fade only | — | there |
| Play / pause / ±15 | Transport | Symbol replace, buffering spinner in the key | Tap; labels | `Haptic.transport` when playback actually changes; `Haptic.skip` | Disabled while previewing; error row with Retry | — | there |
| Now Playing dismissal | Close the player | Page follows the finger, shrinks slightly, springs back or closes | Pull down; Close key; VoiceOver escape | none | Cancelled drag resets. RM: no shrink | — | there |
| Page tabs + pages | New / Library / Explore | Bright tag moves; native paging | Swipe or tap a tab; selected trait | `.selection` on page change | RM: instant tab | — | there |
| Search in place | Find or filter shows | Page drifts away, results fade in a beat later; exit is quicker than entry | Tap field, Cancel, tap blank space; keyboard dismisses on scroll; Search return key | none | 350 ms debounce, stale searches cancelled, last query kept, empty/error with retry, VoiceOver result count. RM: cross-fade | — | there |
| Episode rows | Open, play, mark played | Row presses to 0.97; progress ring | Tap; long-press menu (Play, Mark as Played); same as VoiceOver actions | none | Played rows mute | — | there |
| Pull to refresh | New, Explore, Show, Category | Native | Native | native | Real counted progress ("2 of 5"); no fake delay | — | there |
| Loading / empty / error | Any list | Placeholder tiles in final layout; `StateMessage` with one action | "Try again" key | none | RM: placeholders do not pulse | — | there |
| Onboarding, first-show sheet | First run | One page slides; success symbol bounces once | Skip always visible | `.selection`, one `.success` | RM: fade, no bounce | — | there |
| Theme / text style pick | Change look | 0.35 s cross-fade; selected swatch gets a thick bright edge | Tap; selected trait | `.selection` | Colour fade only, kept under RM | — | there |
| Swipe actions on rows | Mark played, unsubscribe | — | — | — | Rows live in paging home pages, where a sideways swipe changes page; they are not `List` rows. The long-press menu and VoiceOver actions cover it | — | n/a |
| Row stagger, arcs, shared-element zoom, knob stretch | Decoration | — | — | — | Extra travel at bedtime works against the app; system sheet and cover transitions are kept native | — | n/a |
| Pinch / zoom / rotate | — | — | — | — | No zoomable content | — | n/a |
| Share, duplicate, rename | — | — | — | — | No such features in the app | — | n/a |
| Sound effects | — | — | — | — | An audio app at bedtime; UI sounds would fight the episode | — | n/a |
| Haptic feel (strength, timing, no doubles) | All of the above | — | — | — | Simulators do not play haptics | — | device |
| Reorder drag feel, pull-down feel, scrubber under a real thumb | — | — | — | — | Touch feel cannot be judged in a simulator | — | device |
