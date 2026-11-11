# YawnCast design: Lights Out

What ships now. This replaces `evolve/DESIGN.md` (recorded 2026-10-20) and the look described in
`replica/design/principles.md`; where they disagree with this file, this file and the code win.

## The idea
A cut-paper toy theatre. The six animated Scenes play full-screen behind everything and are never
changed by the UI. Everything you read or touch sits on opaque paper in the theme's own dark tones, so
words keep their contrast over any Scene. Sleep is shown as ten lights that go out one per fade step.

## Surfaces and shape (`YawnCast/Design/Keys.swift`, `Looks.swift`)
- One surface: `.paper(seed:fill:)`, a `PaperShape` (four slightly different corners, 12 to 18 pt,
  `seed` picks the cut). No glass, no blur, no borders. Cards, rows, keys, tabs, the search field, the
  mini player and toasts all use it.
- Fills: `surface` for cards, rows, fields, standard keys and tabs; `raised` for things that sit on a
  card or float (cover mats, the mini player, pinned year bands, the moon well); `text` for the one
  primary key on a screen and the current tab; `accent` only for the Moon bar and Moon key while Sleep
  is on.
- Artwork is always `Radius.artwork` (8). The mini player is the only surface with a shadow.
- Now Playing stands its controls on a two-layer cut-paper ground (`GroundShape`, `raised` behind `bg`).

## Colour (`Theme.swift`)
Roles are unchanged: `bg`, `surface`, `raised`, `border`, `text`, `textMuted`, `accent`, `onAccent`,
`danger`. One addition: `fadeMark`, the colour of a lit fade mark. It is the accent in every theme except
Underwater, whose deep-blue accent is too dark to read as a light; there it is `#8FE3F0`.
The flat colours (Almanac, Ember, Plum, Meadow, Dream) keep their day pages and use the same paper.
Run `python3 scripts/contrast.py` after touching a colour; it now also checks lit marks (3:1 on `bg` and
`raised`) and the dark mark outline (`text` at 0.6 on `bg`, 3:1).

## Type (`Typo` in `Theme.swift`)
Two text styles, chosen in Themes: Picture Book (Young Serif) and Sign-Off (Archivo Expanded caps). A
style changes the typeface only; shapes are the same paper in both. Every role maps to a Dynamic Type
style. `playerTitle` is 28 pt (24 in Sign-Off), centred on Now Playing. `dockTitle` is the mini player's
title. Page tabs use `headline`. The home pages have no title under the tabs: the bright tab is the title.

## The fade marks (`YawnCast/Design/FadeMarks.swift`)
`FadeMarks` is the strip on Now Playing between the title and the ground. The mechanic is the same in
every theme: ten marks at the same ten positions; all dark while Sleep is off; all lit while it waits;
one goes dark per fade step, left to right. VoiceOver reads one element, "Fade steps", with a value such
as "Volume 60%, 6 of 10". Only the drawing changes with the Scene (`FadeMotif`):

| Scene | The ten marks |
|---|---|
| City Scape, and the flat colours | paper lanterns on a sagging wire |
| Rainforest | fireflies, with a halo while lit |
| Underwater | jellyfish |
| Beach | little boats on the waterline, sails lit |
| Mountain Vista | tents on a ridge, lit from inside |
| Midnight | a constellation of four-point stars |

A dark mark is an outline (`text` at 0.6) filled with `bg`; a lit mark is filled with `fadeMark`. Every
mark has a `bg` keyline so it keeps its edge over a bright part of a Scene. Lit versus dark is always a
filled shape versus an outline, never colour alone. To add a Scene, add a case to `FadeMotif` and draw it
in code; no image assets. `FadeDots` is the same ten steps as dots in the mini player.

## The Moon (`Looks.swift`, `MoonKey.swift`)
One paper bar at the bottom of Now Playing. The moon well toggles Sleep; the words beside it say
"Ready for bed?", "Sweet dreams" or "Lights going down" with the countdown or volume; while Sleep is on
the bar turns accent and carries −5 and +5 (−5 is disabled during the fade). The icon is always a moon.

## Motion (`Motion` in `Theme.swift`)
`press` (key and card press), `move` (tabs, layout, reorder, rows appearing), `fade` (toasts, state
changes in place), `lightsOut` (0.6 s, one fade mark going dark). The marks drift a few points at 15 fps.
Reduce Motion: marks hold still and only cross-fade when one goes out; press and move animations are
dropped; Scenes pause, as before. Haptics are unchanged.

## Accessibility
Identifiers are unchanged (`moonKey`, `sleepCountdown`, `sleepPlus5`, `pageDot-…`, and so on) and one is
new (`fadeMarks`). Targets are 44 pt or more. At accessibility text sizes Now Playing hides the cover
and the fade marks (the Moon bar still says the volume), the Moon bar stacks its keys under its words,
the page tabs and the mini player's words stop growing at AX1, and grids drop a column. Now Playing drops
to a smaller cover, then no cover, when the screen is short, and scrolls if it still does not fit.

## Screenshots
`scripts/design_capture.sh [folder]` builds Debug and captures the main screens with `-synthetic`
(invented shows, covers drawn in code, no network; `TestSupport/SyntheticSeed.swift`). The fade is real:
`-autoplay -sleepOn -fastSleep` plays a silent file and lets Sleep run.
