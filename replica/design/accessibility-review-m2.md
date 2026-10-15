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

Open items: run VoiceOver on simulator/device; confirm Ember comfort in a dark room (device check D8).
