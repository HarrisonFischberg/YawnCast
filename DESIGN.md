# YawnCast design: Lights Out

What ships now. This replaces `evolve/DESIGN.md` (recorded 2026-10-20) and the look described in
`replica/design/principles.md`; where they disagree with this file, this file and the code win.

## The idea
A cut-paper toy theatre. The six animated Scenes play full-screen behind everything and are never
changed by the UI. Everything you read or touch sits on opaque paper in the theme's own dark tones, so
words keep their contrast over any Scene. Sleep is the biggest thing on Now Playing, and the Scene's own
lights thin out as the fade runs down.

## Surfaces and shape (`YawnCast/Design/Keys.swift`, `Looks.swift`)
- One surface: `.paper(seed:fill:)`, a `PaperShape` (four slightly different corners, 12 to 18 pt,
  `seed` picks the cut). No glass, no blur, no borders. Cards, rows, keys, the search field, the
  mini player and toasts all use it.
- Two pills, both by owner request: the page menu (`LookTabs`: one `surface` capsule holding New, Library
  and Explore, with a `text` thumb that slides to the current page) and the Sleep bubble.
- Fills: `surface` for cards, rows, fields, standard keys and tabs; `raised` for things that sit on a
  card or float (cover mats, the mini player, pinned year bands, the moon well, the Sleep bubble); `text`
  for the one primary key on a screen and the page menu's thumb; `accent` only for the Moon bar and Moon key while Sleep
  is on.
- Artwork is always `Radius.artwork` (8). Only floating surfaces have a shadow: the mini player, the
  Undo toast that sits above it for a few seconds after an unsubscribe, and the Sleep bubble.
- Now Playing stands its controls on a two-layer cut-paper ground (`GroundShape`, `raised` behind `bg`).

## Colour (`Theme.swift`)
Roles are unchanged: `bg`, `surface`, `raised`, `border`, `text`, `textMuted`, `accent`, `onAccent`,
`danger`. One addition: `fadeMark`, the colour of a Scene's lights and of a lit dot in the mini player. It is the accent in every theme except
Underwater, whose deep-blue accent is too dark to read as a light; there it is `#8FE3F0`.
The flat colours (Almanac, Ember, Plum, Meadow, Dream) keep their day pages and use the same paper.
Run `python3 scripts/contrast.py` after touching a colour; it now also checks lit marks (3:1 on `bg` and
`raised`) and the dark mark outline (`text` at 0.6 on `bg`, 3:1).

## Type (`Typo` in `Theme.swift`)
Two text styles, chosen in Themes: Picture Book (Young Serif) and Sign-Off (Archivo Expanded caps). A
style changes the typeface only; shapes are the same paper in both. Every role maps to a Dynamic Type
style. `playerTitle` is 28 pt (24 in Sign-Off), centred on Now Playing. `dockTitle` is the mini player's
title. The page menu uses `headline`. The home pages have no title under it: the bright thumb is the title.

## Scene life (`YawnCast/Design/SceneLife.swift`)
On Now Playing each Scene has a few lights or creatures scattered over the sky. They replace the row of
ten fade marks (owner: no strings or rows). They are drawn in the Scene's own Canvas, behind everything,
and never behind the title (`quiet` is the title's frame; they dim to nothing around it). Each breathes
on its own 8 to 16 s cycle; nothing flashes.

| Scene | Life | Count |
|---|---|---|
| Rainforest | fireflies wandering | 9 |
| Underwater | jellyfish drifting, bells pulsing | 6 |
| Midnight | four-point stars, twinkling, fixed in place | 11 |
| City Scape | sky lanterns rising from the skyline and fading as they climb | 7 |
| Beach | soft discs of moonlight in the sea air | 8 |
| Mountain Vista, and the flat colours | none | 0 |

The meaning is kept loosely: they are all out while an episode plays or Sleep waits, they go one at a
time as the fade runs down, and none are left at lights out (or while paused with Sleep off). They are
decoration and hidden from VoiceOver; the Moon bar and the Sleep bubble give the time and the volume.
`FadeDots` (`FadeMarks.swift`) is still the ten steps as dots in the mini player.
To add a Scene's life, add a case in `SceneLife.draw` and draw it in code; no image assets.

## Sleep on Now Playing (`Looks.swift`, `MoonKey.swift`, `SleepExtras.swift`)
The Moon bar is one paper bar at the bottom: a 68 pt moon well that toggles Sleep, and the words
"Ready for bed?", "Sweet dreams" or "Lights going down" with the countdown or volume; while Sleep is on
the bar turns accent. The Sleep bubble (`SleepBubble`, at its 1.0 size: 40 pt key faces, 44 pt to tap)
pops up above the bar's right end when Sleep turns on, as −5 · 17 min · +5; −5 is disabled during the
fade; each tap floats "+5 min" / "−5 min" up. After 4 quiet seconds it tucks into a small "±5" pill
(`SleepBubblePill`) that reopens it; it stays open under VoiceOver. While Sleep is on, `FloatingZs`
rise out of the moon well, in every theme, drifting up past the skip-back key.
Transport is round, as in 1.0: play/pause an 88 pt circle, skips 64 pt circles.

## Motion (`Motion` in `Theme.swift`)
`press` (key and card press), `move` (layout, reorder, rows appearing), `slide` (the page menu's thumb,
no bounce), `pop` (the Sleep bubble, the one springy moment), `fade` (toasts, state changes in place),
`lightsOut` (0.6 s, one light going out). Scenes and their life draw at 15 fps and stop while the app is
not in front. Reduce Motion: the life holds still, scattered, and only fades; the thumb jumps; the bubble
fades; press and move animations are dropped; Scenes pause, as before. `Motion.moveUnlessReduced` is `move` for code with no view environment.
Haptics are three named impacts (`Haptic.moon`, `.transport`, `.skip` in `Theme.swift`) plus the system
`.selection` and `.success`. Every component's behaviour is listed in `docs/interaction-matrix.md`.

## Accessibility
Identifiers are unchanged (`moonKey`, `sleepCountdown`, `sleepPlus5`, `pageDot-…`, and so on). Targets are
44 pt or more. At accessibility text sizes Now Playing hides the cover, the Sleep bubble sits on its own
row above the Moon bar and stops growing at AX1, the Moon bar keeps only its countdown line while Sleep
is on (large), the page menu and
the mini player's words stop growing at AX1, and grids drop a column. Now Playing drops
to a smaller cover, then no cover, when the screen is short, and scrolls if it still does not fit.

## Screenshots
`scripts/design_capture.sh [folder]` builds Debug and captures the main screens with `-synthetic`
(invented shows, covers drawn in code, no network; `TestSupport/SyntheticSeed.swift`). The fade is real:
`-autoplay -sleepOn -fastSleep` plays a silent file and lets Sleep run.
