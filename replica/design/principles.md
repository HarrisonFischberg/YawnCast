# Design principles and themes

All visual decisions here are **original [P]**. No screenshots of reference apps were
available, so nothing below claims to reproduce a measured reference layout.

## Principles drawn from stated Not Boring values → how NightCast applies them

| Stated value (source: notbor.ing, reviews) | NightCast application |
|---|---|
| One thing exceptionally well | One job: fall asleep to a podcast. Three screens. One signature control. |
| Physical, tactile controls (Camera's dials/shutter) | Oversized transport keys with a visible "travel" (pressed state sinks 2 pt, shadow tightens), crisp haptic on press. Moon is a big round key with a recessed face, not a FAB. |
| Haptics + motion with purpose | `.sensoryFeedback` on play/pause, ±15, Moon on/off. Springs ≤ 0.35 s. Reduce Motion → crossfades only. |
| Personalization (skins) | Three coordinated themes, chosen in a tiny sheet. No per-color pickers. |
| No sounds in Sleep mode | Brief requires silence; NightCast has no UI sounds at all. |

## Hierarchy on Now Playing (top → bottom)
1. Episode title — large, expressive (rounded serif-ish display via system `.serif` design at bold weight), up to 3 lines, show name small above.
2. Scrubber — thick 8 pt track, 28 pt thumb, elapsed left / remaining right in monospaced digits.
3. Transport row — −15 · Play/Pause (largest, 96 pt) · +15 (72 pt).
4. Moon key — full-width-ish pill (≥ 72 pt tall) set apart in its own "plate", status text inside it
   ("Sleep" / "Fade in 30 min" / "Fading · 60%"). Bottom of screen = thumb zone in bed.
5. Close (chevron down) top-left, 44 pt.

## Library
Two-column artwork grid, 20 pt gutters, artwork with 14 pt continuous corners and a hairline
border so dark artwork reads on dark themes. Large left-aligned "Library" wordmark title.
Search key and Appearance key top-right, 44 pt. Mini-player is a raised plate pinned to the
bottom: title, play/pause key, tap to open.

## Type
System font family (SF Pro / New York via `.serif` design) — no licensed fonts.
Display 34/40 bold serif; Title 22/28 semibold; Body 17/22; Caption 13/18; digits monospaced.
All styles map to Dynamic Type text styles so they scale.

## Spacing / shape
4 pt base: 4, 8, 12, 16, 20, 24, 32, 48. Radius: 10 (rows), 14 (artwork), 22 (plates), capsule (keys).
Depth: one shadow style for raised keys only (y 2, blur 0 hard edge + y 6 blur 12 soft, low opacity).
Pressed: offset y +2, hard shadow removed.

## Themes (tokens: `tokens.<theme>.json`, contrast: all AA PASS via replica contrast.py)

| role | Paper (day) | Ink (dark) | Ember (bedtime) |
|---|---|---|---|
| bg | #F2EDE3 | #111113 | #070504 |
| surface | #E7E0D2 | #1C1C20 | #110C09 |
| raised | #FBF8F2 | #26262B | #1A120D |
| border | #D6CDBA | #2E2E34 | #22170F |
| text | #1C1A16 | #F1EEE7 | #B98F6C |
| text-muted | #5C564B | #A29E95 | #9C7A5C |
| accent (Moon) | #2E2A6B indigo | #E9B44C amber | #C27142 ember |
| on-accent | #F7F3EA | #1A1408 | #070504 |
| danger | #A33224 | #F07A68 | #C96E55 |

Lowest-contrast text pair per theme: Paper 5.54:1, Ink 6.36:1, Ember 4.95:1 (all ≥ 4.5 AA).

**Ember is genuinely low-luminance:** brightest text has relative luminance 0.31 vs Ink's 0.86
(~64% less emitted light), all tokens warm with blue the weakest channel, near-black bg. Publisher
artwork is shown unmodified in every theme (no tint, filter, or opacity change).
Re-run: `python3 ~/.claude/plugins/marketplaces/replica-skill/replica-design/contrast.py replica/design/tokens.ember.json`
