# M2 accessibility review (Library + Now Playing prototype)

Evidence: simulator screenshots in `screenshots/m2/`, code review. VoiceOver itself was **not** run
with a screen reader (simulator Accessibility Inspector pass is still TODO) → labels verified in code only.

| Area | Result |
|---|---|
| Contrast | All three themes 0 AA failures (`contrast.py`). Lowest text pair: Ember muted on surface 4.95:1 |
| Touch targets | Icon keys 48×48 pt; ±15 keys 76 pt; play 112 pt; Moon ≥ 88 pt tall, full width; mini-player play 52 pt. All ≥ 44 pt |
| Dynamic Type | All text uses text styles. AX5 screenshots: Now Playing fits (title 2–3 lines, Moon subtitle wraps to 2 lines, fade ticks hidden). Library at AX5 captured (`library-paper-AX5.png`) |
| VoiceOver labels | Moon: label "Sleep", value Off / "On. Fade begins in …" / "On. Fading, volume N percent", hint, selected trait. Play/Pause, Back/Forward 15 seconds, Close player, Search podcasts, Appearance, themes labelled. Show tiles combine title + author |
| Scrubber | Adjustable element: value "X of Y", swipe up/down = ±15 s |
| Sleep announcements | Activation/cancel text posted as VoiceOver announcement |
| Reduce Motion | Key press springs and tile scale disabled; content transitions remain (cross-fade) |
| Artwork | Shown unmodified; hidden from VoiceOver (title is read instead) |
| Haptics | Play/pause, ±15, Moon on/off, theme select, scrub release. No sounds anywhere |

Open items (M2): run VoiceOver on simulator/device; confirm Ember comfort in a dark room (device check D8).

## v0.16 review pass (2026-10-17)

Scope: every SwiftUI view and design component as of v0.15 (Home pages, Library, Show, Search,
Explore, Category, Now Playing, Sleep bubble, Themes, mini player), all ten themes.
Method: code review, `scripts/contrast.py` (new, in-repo; reads Theme.swift directly), and
`YawnCastUITests/AccessibilityUITests` (Xcode accessibility audit + targeted assertions).

### Fixed

| Issue | Fix |
|---|---|
| Moon key subtitle at 0.8 opacity: Ember 4.48:1, under AA | 0.85 opacity → Ember 4.89:1, worst theme |
| Unselected page dots 1.9–3.1:1, under the 3:1 non-text minimum in 8 of 10 themes | 0.75 opacity → ≥ 3.33:1 everywhere |
| Now Playing is a full-screen cover; swipe-down doesn't exist for VoiceOver users | Two-finger scrub (escape) closes it |
| Mini player's moon glyph was the only sign Sleep is on | Value: "<show>, Sleep on" |
| Icon keys and mini play key keep a fixed 17 pt glyph at large sizes | Large Content Viewer (long press shows label + glyph) |
| "Episodes · 3" read with the dot | Label "3 episodes" |
| Mark as Played / Unplayed reachable only by long press | VoiceOver action on New and Show episode rows |
| Search results, empty and error states appeared silently below the field | Announced: "N shows found", "No shows found", "Couldn’t search" |
| Empty / error titles not headings | Header trait (rotor navigation) |
| Now Playing show name cut to one line at AX sizes | Two lines at AX sizes |
| Themes grid truncated names at AX sizes | One column at AX sizes; blurb wraps to 2 lines |
| Sleep bubble scales in even with Reduce Motion | Plain fade with Reduce Motion |

Contrast now covers all ten themes plus blended pairs (Moon subtitle, page dots) and primary-key
labels; 0 failures, no drift between Theme.swift and the token files. Scene art behind text was
checked separately at V5.3/V6.2 and is not re-checked by the script.

### Needs a live VoiceOver check on a real iPhone

The Simulator cannot run VoiceOver, so these are verified in code and XCUITest only:

1. Swipe through each screen: reading order of Now Playing (close, show, title, scrubber, −15, play, +15, Moon), Library tiles, Show page rows.
2. Two-finger scrub closes Now Playing and lands focus somewhere sensible (mini player).
3. Scrubber: swipe up/down moves ±15 s and the new position is spoken.
4. Sleep announcements (on, off, ±5) are spoken and don't collide with the Moon key's own value change.
5. Search announcements: spoken once per settled search, not on every keystroke while typing quickly.
6. In search mode, double-tapping blank space below results (tap-to-cancel) doesn't steal focus or end search unexpectedly.
7. Library: Move to Top / Move to End and episode Mark as Played actions appear in the actions rotor; long-press menu still works.
8. Home pages: three-finger swipe between New / Library / Explore; page dots report the selected page.
9. Large Content Viewer appears on the header icon keys and mini play key at AX sizes.
10. Ember and Red Light are comfortable in a dark room (carried over from D8).
11. Increase Contrast and Bold Text: not specifically handled; check nothing becomes unreadable.
