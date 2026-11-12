# YawnCast Design System

> Superseded: the design that ships is described in `DESIGN.md` at the repo root (Lights Out). This file is kept as a record.

Recorded from the shipped code on branch `evolve/001/base` (2026-10-20). The code wins over
older docs: where `DECISIONS.md` or `replica/design/principles.md` disagree with the build, this
file describes the build and says where they differ. Paths are relative to the repo root.

## 1. Identity and tone

- One person in bed, tired, in the dark, falling asleep to a podcast (PROJECT_BRIEF.md:59-62).
  The app is "a carefully designed physical listening object: simple, bold, tactile" (PROJECT_BRIEF.md:7-8).
- Controls are **physical keys**: a face sitting on a visible edge that sinks when pressed. The look comes
  from SwiftUI shapes, springs and haptics only. No 3D engine, no images for chrome (DECISIONS.md D10).
- The signature control is the **Moon (Sleep) key**: one tap, no picker. Everything else stays quiet so it
  can stand out.
- Calm by default: dark night themes, slow animated scenes, no UI sounds anywhere (principles.md).
- Permanently out of scope (PROJECT_BRIEF.md:28-32): onboarding, accounts, social, ads, monetization,
  AI summaries, queue manager, autoplay-next, playback speed in the main player, large artwork on Now
  Playing, waveforms, transcripts. Explore is the one owner-approved exception to "no recommendations".
  It is non-AI and account-free (D24).

## 2. Color

### Roles (`Theme`, YawnCast/Design/Theme.swift:5-29)
| Role | Use |
|---|---|
| `bg` | Screen background (flat themes) and the base under scenes |
| `surface` | Recessed areas: search field, scrubber track, Moon well when off, list plates |
| `raised` | Standard key faces, mini player plate, Sleep bubble, scrubber thumb |
| `border` | 1 pt hairlines on raised plates, artwork, cards |
| `text` / `textMuted` | Primary text / secondary text (show names, captions, section headers, times) |
| `accent` / `onAccent` | Sleep, plus small "yours/new" markers (see the accent rule below) |
| `danger` | Playback errors |
| `edge` | The visible side of a standard key |
| `highlight` | The lit top lip on key faces |
| `shadowOpacity` | Key/plate shadow strength (0.12 Paper to 0.7 Red Light) |
| `scene` | Animated background, `nil` for flat Color Scapes |
| `warmOnly` | Red Light: decorations and highlights must stay warm |

### Themes (Theme.swift:31-134)
Ten themes. **Scenes** (animated): Midnight (default), Mountain Vista, Beach, Rainforest, Underwater (`ocean`),
City Scape. **Color Scapes** (flat): Paper (the only light theme), Ember, Ink, Red Light. Read the theme from the
environment (`@Environment(\.theme)`, Theme.swift:153-162). The app follows the chosen theme, not the system
appearance. Never hard-code hex values in views. Every color comes from a theme role.

| Theme | bg | raised | text | textMuted | accent |
|---|---|---|---|---|---|
| Midnight | #0A1430 | #1E2F60 | #EEF2FF | #A9B7DD | #F4CF7B |
| Paper | #F2EDE3 | #FBF8F2 | #1C1A16 | #5C564B | #2E2A6B |
| Ember | #070504 | #1A120D | #B98F6C | #9C7A5C | #C27142 |
| Red Light | #0B0504 | #24130E | #EFA084 | #CC8A72 | #D9805F |
(Other themes: Theme.swift:42-101, 112-119.)

### AA contrast rule (scripts/contrast.py:9-38)
- Text pairs need **4.5:1**: text and textMuted on bg, surface and raised; `bg` on `text` (primary keys);
  `onAccent` on `accent`; `danger` on `bg`.
- Non-text pairs need **3:1**: accent glyphs on bg/raised, scrubber fill against track.
- Scene themes must also pass over each scene's brightest area (D36, D39). Scenes keep bright shapes
  (moons) away from where text sits.
- Opacity counts. The Moon subtitle uses 0.85 because 0.8 dropped Ember to 4.48:1 (MoonKey.swift:25-26).
- Any new theme or token: mirror it in `replica/design/tokens.<id>.json` and run `python3 scripts/contrast.py`.

### Red Light: low blue, not "no blue" (D40, D41)
- `warmOnly = true` (Theme.swift:28-29, 90). Key highlights use the theme's warm highlight, not white
  (Keys.swift:78). Explore card tints switch from rainbow hues to `accent` (ExploreView.swift:167-168).
- Never introduce cool or rainbow color in Red Light. Any new decorative hue needs a `warmOnly` branch.
- Blurb is "Warm, low blue". Don't claim "no blue". Publisher artwork and iOS-drawn chrome keep their colors.

### Accent rule (as built)
`accent` belongs to Sleep: the Moon key face when on (`KeyRole.accent`, Keys.swift:9-10), the moon glyph
(MoonKey.swift:100), floating Z's (SleepExtras.swift:146,155), the moon in the mini player (LibraryView.swift:286).
It is also used for small markers: the new-episode pip (D26, LibraryView.swift:210-217), the "In your Library"
check (ExploreView.swift:272), the category page icon (ExploreView.swift:219), and the global tint
(App/YawnCastApp.swift:24). New features use accent only at glyph or dot size.

## 3. Typography (`Typo`, Theme.swift:164-174)
System fonts only (SF, SF Rounded, New York via `.serif`). Every style maps to a Dynamic Type text style.

| Token | Definition | Use |
|---|---|---|
| `display` | largeTitle, serif, bold | Page titles ("Library", category name) |
| `playerTitle` | title, serif, bold | State message titles, big headings |
| `title` | title3, rounded, semibold | Moon key title |
| `headline` | headline, rounded, semibold | Row titles, key labels, chips, ±5 min |
| `body` | body, default | Descriptions, messages |
| `caption` | footnote, rounded, medium | Secondary lines, countdown text |
| `eyebrow` | caption, rounded, bold, used with `.tracking(1.2)` uppercase | Section headers only (see below) |
| `digits` | subheadline, rounded, semibold, monospacedDigit | Times, counts |

Serif is for titles. Rounded is for controls and metadata. Use `.monospacedDigit()` plus
`.contentTransition(.numericText())` on any number that changes live.
Section headers (`eyebrow`) label real content: day groups (HomeView.swift:133-140), "Episodes · N"
(ShowView.swift:189-195), search sections and theme groups. They carry `.accessibilityAddTraits(.isHeader)`.
Uppercase the string with `.uppercased()` and give it a mixed-case `accessibilityLabel`, as ShowView does,
because `.textCase(.uppercase)` makes VoiceOver spell words letter by letter (ShowView.swift:189-190).

## 4. Spacing (`Space`, Theme.swift:176-185)
4 pt base: `xs` 4, `s` 8, `m` 12, `l` 16, `xl` 20, `xxl` 24, `xxxl` 32, `huge` 48.
Screen side margins are `xxl` (StateMessage, SearchView.swift:420). Grid gutters are `xl` for show grids
and `m` for cards and theme swatches (ExploreView.swift:12-16, ThemesSheet.swift:12). Stacks inside a
component use `s`/`m`. Section breaks use `xxl`. Scroll views reserve about 82 pt at the bottom for the
floating mini player (D44).

## 5. Shape and depth
All rounded rectangles use `style: .continuous`. Radii by element:
- 7: mini player artwork (LibraryView.swift:277)
- 10: list-row artwork (SearchView.swift:342, HomeView.swift:179, LibraryView.swift:182)
- 12: Library grid artwork (LibraryView.swift:97)
- 14: loading placeholder tiles (SearchView.swift:382, ExploreView.swift:347)
- 16: Show header artwork and Library list plates (ShowView.swift:114, LibraryView.swift:202)
- 18: cards and theme swatches (ExploreView.swift:190, ThemesSheet.swift:79-103)
- 22: the mini player plate (LibraryView.swift:319)
- Capsule: keys, search bar, Sleep bubble and pill, interest chips

Depth: a standard key has a 4 pt edge, a small toolbar key 3 pt, and Play/Pause and Moon 6 pt. The face
travels `depth - 1` when pressed and the soft shadow tightens (Keys.swift:24-49). Floating plates
(mini player, bubble) get `raised` fill, a 1 pt `border` stroke and a soft black shadow at
`theme.shadowOpacity`. There are no hard offset shadows.

## 6. Components

### KeyStyle family (YawnCast/Design/Keys.swift)
- `KeyRole` (Keys.swift:4-11):
  - `.standard`: `raised` face. The default for every key.
  - `.primary`: `text`-colored face with a `bg` label. Use it for the **one main action on a screen**:
    Play/Pause (NowPlayingView.swift:181, mini player LibraryView.swift:308), Subscribe while not subscribed
    (ShowView.swift:142), "Find a podcast" (LibraryView.swift:147), the retry action in `StateMessage`
    (SearchView.swift:414).
  - `.accent`: reserved for the Moon key while Sleep is on (MoonKey.swift:41). Nothing else.
- `.roundKey(role, depth:)` / `.capsuleKey(role, depth:)` (Keys.swift:83-93) are the only button chrome.
  Disabled keys drop to 45% opacity (Keys.swift:47).
- `IconKey` (Keys.swift:95-114): a 48 pt round toolbar key with a 17 pt bold SF Symbol. It needs a text
  `label` and shows the Large Content Viewer at accessibility sizes. Used for layout, themes and close.
- Transport sizes (NowPlayingView.swift:157-200): ±15 keys are 76 pt, Play/Pause is 112 pt, the mini Play key is 44 pt.

### Signature and player pieces
- `MoonKey` (MoonKey.swift): a capsule at least 88 pt tall with a 60 pt recessed well, a title and subtitle,
  and five fade ticks.
- `SleepAdjustBubble` and `CollapsedSleepPill` (SleepExtras.swift:5-115): raised capsule, 44 pt targets,
  monospaced digits. `FloatingZs` (SleepExtras.swift:128+) draws at 30 fps and is still under Reduce Motion.
- `Scrubber` (Scrubber.swift): a 10 pt track, a 28 pt thumb and a 44 pt hit height. The seek commits on
  release. VoiceOver steps 15 s.
- `ScreenBackground` / `SceneBackground` / `ScenePreview` (Scenes.swift:9-48): every screen sits on the
  theme's scene or flat `bg`. Scenes are Canvas drawings at about 15 fps with deterministic layouts.

### Sheets, lists, states
- Sheets are small and tall: Themes opens at `.fraction(0.8)` and `.large`, uses
  `.presentationContentInteraction(.scrolls)` and shows a visible grabber (LibraryView.swift:71-77, D41).
  Now Playing is a `fullScreenCover` with a clear background that closes on a downward swipe
  (NowPlayingView.swift:125, D44). Don't stack modals (D16).
- Collections use `LazyVGrid`, not carousels, so they don't fight the horizontal pager (D24). Columns drop at
  accessibility sizes: 2 to 1, and 3 to 2 (LibraryView.swift:17-21).
- Remote-backed lists have `.refreshable`. Rows have `.contextMenu` (Play / Mark as Played, Move to Top / End,
  Unsubscribe). Library reorder is live drag with a spring and a selection haptic (D37, D44).
- Empty, error and idle states all use `StateMessage` (SearchView.swift:388-423): a muted symbol, a
  `playerTitle` title, a `body` message, and at most one primary action. Loading shows placeholder tiles in the
  final grid, not a spinner (D42).

## 7. Motion
- Springs ≤ 0.35 s response:
  - Key press: `spring(0.18, 0.7)` (Keys.swift:48)
  - Page change: `spring(0.3, 0.8)` (HomeView.swift:44)
  - Bubble: `spring(0.3, 0.75)`; Sleep on/off: `spring(0.35, 0.7)` (NowPlayingView.swift:108-109)
  - Reorder and layout: `spring(0.35, 0.8–0.85)` (LibraryView.swift:53-55)
- Eased fades:
  - Disclosure and sort: `easeOut 0.2` (ShowView.swift:150,200)
  - Theme swap: `easeInOut 0.35` (ThemesSheet.swift:58)
  - In-place search: `smooth 0.42`, with a 0.16 s staggered layer (AppModel.swift:180, SearchView.swift:116-149, D43)
- Symbols use `.contentTransition(.symbolEffect(.replace))`. The moon uses `.symbolEffect(.bounce)` on toggle.
- **Reduce Motion:**
  - Key travel animation is nil.
  - Scenes pause on a fixed frame (Scenes.swift:14-16).
  - Z's are static.
  - Search becomes a cross-fade only.
  - The player pull-down doesn't scale (NowPlayingView.swift:223).
  - The bubble uses an opacity transition (NowPlayingView.swift:140).
  - Looping pulses don't start (ExploreView.swift:355).
  - Any new motion must branch on `accessibilityReduceMotion`.
- Constant motion is allowed only in scene backgrounds and the Z's (D31).

## 8. Haptics (`.sensoryFeedback`, never UIKit generators)
| Event | Feedback | Where |
|---|---|---|
| Sleep on/off | `.impact(.heavy, 0.8)` | NowPlayingView.swift:97 |
| Play/Pause | `.impact(.medium)` | NowPlayingView.swift:187, LibraryView.swift:315 |
| ±15 skip | `.impact(.light)` | NowPlayingView.swift:199 |
| Subscribe | `.success` | ShowView.swift:147 |
| ±5 min, page, theme, layout, reorder, scrub release | `.selection` | NowPlayingView.swift:115, HomeView.swift:26, ThemesSheet.swift:29, LibraryView.swift:54,125, Scrubber.swift:78 |
Use haptics on meaningful state changes only. There are no sounds anywhere.

## 9. Accessibility conventions
- Every interactive or testable element gets a camelCase `accessibilityIdentifier`, for example `moonKey`,
  `playPause`, `miniPlayer`, `scrubber`, `subscribeKey`, `searchField`, `retryKey`, `themesKey`, `layoutKey`,
  `closePlayer`. Repeated items use a kebab prefix plus a stable key: `theme-\(id)`, `category-\(name)`,
  `pageDot-\(title)`. UI tests depend on these.
- Icon-only keys always get `accessibilityLabel` in plain words ("Back 15 seconds"). Use a hint only when the
  result isn't obvious ("Fades the episode out, then pauses."). Live controls expose `accessibilityValue`
  with spoken times (`TimeFormat.spoken`), and toggles add `.isSelected`.
- Custom controls use `.accessibilityAdjustableAction` (Scrubber.swift:82-88). Decorative glyphs are hidden.
- Dynamic Type: branch on `typeSize.isAccessibilitySize`. At those sizes, grids drop to one column, header and
  search rows stack, line limits grow (1 to 2, 2 to 4), and the Moon wraps its subtitle and hides its ticks
  (D21, MoonKey.swift:29-39). Use `.minimumScaleFactor(0.7–0.85)` only as a backstop. Cap a style with
  `.dynamicTypeSize(...)` only when it shares a row with a fixed key (search field, SearchView.swift:325).
- Targets are at least 44 pt (bubble steps, pill, scrubber, chips, mini Play key).

## 10. Copy voice
Short, plain, warm, sentence case, no exclamation marks. Use the curly apostrophe and the real ellipsis (…).
Talk about bedtime, not features. Examples from the code:
- Empty: "Nothing on the nightstand yet." / "Find a show you like to fall asleep to. It will live here."
- Quiet: "All quiet". "Nothing new from your shows in the last 30 days."
- Sleep: "Sleep" / "Fade out, then pause"; "Sleep on" / "Fade begins in 11 min"; "Drifting off" / "Volume 60%"
- Errors that say what to do: "Couldn’t reach your shows. Check your connection and pull to try again."
- Progress: "Checking your shows…", "Finding shows you might like…"
- Honest privacy: "YawnCast has no server and keeps your library on this iPhone."
- Search placeholder: "Search your shows or find new ones"

## 11. Do / Don't for new features
Do:
- Build controls from `KeyStyle`/`IconKey` and plates from `raised` + `border` + soft shadow.
- Use only theme roles, `Typo`, and `Space` tokens. Check new color pairs with `scripts/contrast.py`.
- Give every new screen loading tiles, a `StateMessage` empty and error state, and pull-to-refresh where data is remote.
- Add an identifier, a label, an accessibility-size layout and a Reduce Motion branch with each feature.
- Test new visuals on Midnight, Paper and Red Light, the three hardest cases.

Don't:
- Don't add a second primary key on a screen or any other `.accent` key face.
- Don't use accent fills larger than a glyph or dot.
- Don't add cool or rainbow tints without a `warmOnly` fallback.
- Don't put bright scene shapes behind text.
- Don't add decorative uppercase labels above titles. `eyebrow` is for section headers.
- Don't add spinners where a placeholder fits, confirm dialogs where undo fits, or UI sounds.
- Don't add anything on the out-of-scope list (section 1), and don't add constant motion outside scenes and the Z's.
