# NightCast UI/UX review

2026-10-19 · `main` at 021b33e · iPhone 18 Pro Simulator, iOS 27.0 · before screenshots in [before/](before/)

Method: design review only (detector not applicable, native platform). Code read from `NightCast/Views` and `NightCast/Design`. Draft PRs #5 (mini player gap) and #6 (Sleep copy) are not on `main`, so the screenshots show the older behaviour for both.

## Inventory

| Platform | Exists | Surfaces |
|---|---|---|
| iOS app (SwiftUI, iPhone, portrait only) | Yes | Home pager (New, Library, Explore), Search (in place), Show detail, Category, Now Playing, Sleep bubble, Themes sheet, mini player |
| macOS app | No | |
| Safari / Chrome extension | No | |
| Web | No (a marketing site lives elsewhere, not in this repo) | |

States captured: default, Sleep on, Sleep fading (Ember), empty library, search results, search error (offline), no results, category loading placeholders, list layout, 4 Color Scapes plus Midnight, AX5 Dynamic Type, and system light appearance (the app keeps its own theme, so system light and dark look the same).

## Critique (Nielsen, 0 to 4)

| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Sleep status is excellent on Now Playing, but once you leave it the only sign is a tiny moon glyph in the mini player, which also has no progress |
| 2 | Match with the real world | 3 | "Scenes" vs "Color Scapes" is app-speak; "EPISODES · 525" and "2026 · 85 episodes" stack two counts |
| 3 | User control and freedom | 3 | Swipe down, Cancel, ±5 all good; Mark as Played only by long press |
| 4 | Consistency and standards | 2 | Accent rule ("Moon only") broken on Explore chips and New pips; three header patterns; flat themes and animated scenes feel like two products |
| 5 | Error prevention | 3 | Unsubscribe is one tap from a filled-looking button |
| 6 | Recognition rather than recall | 2 | Three pages marked only by dots; layout and theme keys are unlabelled icons |
| 7 | Flexibility and efficiency | 3 | Layouts, reorder, ±5; no quick "resume last" from the lock-in moment |
| 8 | Aesthetic and minimalist design | 2 | Starfield, waves and scene art run behind every list and over artwork; the mini player covers the last row everywhere |
| 9 | Error recovery | 3 | "Couldn't search / Try again" is plain and actionable |
| 10 | Help and documentation | 3 | Moon subtitle explains itself; nothing explains ±5 or the tucked pill |
| | **Total** | **27/40** | **Acceptable** (one point short of Good) |

**Design specificity.** The Moon key, the fade ticks and the floating z's are genuinely authored for this product, and the physical-key language is consistent. Everything around them is the sleep-app category default: deep navy, stars, a crescent moon, a soft wave horizon. Cover the name and it could be any of a dozen sleep or meditation apps. The ten themes multiply that rather than fix it; they are skins on one layout, not a point of view.

**What's working**
- The Moon key is a real signature: big, thumb-zone, stateful (Ready, On, Fading with lit ticks) and fully described to VoiceOver.
- Restraint on Now Playing: no large art, no speed, no queue. The brief's "nothing else" holds.
- Empty and error states are written like a person ("Nothing on the nightstand yet.").

**Priority issues**

1. **[P1] The mini player sits on top of content on every scrolling screen.** Last-row titles are cut on Library, New, Show and Explore (see `01`, `02`, `03`, `04`). Fix: reserve a bottom inset equal to the player's height (draft PR #5 does part of this) and fade the content under it. `/impeccable layout`
2. **[P1] The accent is spent everywhere, so the Moon stops being special.** Explore's eight "Your interests" chips are solid accent (`ExploreView.swift:155`), the New pip is accent (`LibraryView.swift:217`), Sleep z's are accent. On Explore the brightest thing on screen is a filter, not the product's signature. Fix: neutral chips, accent back to the Moon alone. `/impeccable colorize`
3. **[P1] Search field balloons at AX5.** At the largest text size the Library search placeholder wraps to four lines in a 200 pt pill and pushes the grid below the fold (`22-library-AX5`). Fix: one-line placeholder ("Search") at accessibility sizes. `/impeccable adapt`
4. **[P2] The night-sky backdrop competes with content.** Stars twinkle over show titles and artwork, waves cut through lists, and the same scene runs on every screen, at 15 fps, at bedtime. Fix: give the backdrop to Now Playing only and keep lists on a still ground. `/impeccable quieter`
5. **[P2] Show detail has five stacked levels before the first episode.** Title, Subscribed button (looks like a primary action though it is a done state), description, "EPISODES · 525" plus sort chip, then "2026 · 85 episodes". Fix: Subscribed becomes a quiet toggle, one count, sort in the section header. `/impeccable distill`

**Persona red flags**
- **Casey (one-handed, half asleep):** page dots at the very top are the only navigation; reaching Explore means a horizontal swipe that also scrubs through artwork rows. The ±5 pill collapses after 5 s, so a slow reader loses it.
- **Sam (VoiceOver, large text):** labels are thorough, but the Now Playing title is a fixed 36 pt below AX sizes, 21 glyph sizes are hard-coded, and the AX5 search pill is unusable.
- **The bedtime listener (from PRODUCT.md):** the default theme is bright navy with white text and a lit yellow key; Ember and Red Light, the themes actually built for a dark room, are buried in a ten-option sheet.

**Minor observations**
- Now Playing leaves a large empty band between the title and the scrubber, and puts two readouts of one fact (z's on the left, "17 min" pill on the right).
- The "Subscribed" capsule on Show and the "Find a podcast" capsule on empty Library share a style although one is a state and one is an action.
- Category loading placeholders are good; the transition from placeholder to art has no fade.

**Questions to consider**
- What if the app got darker and quieter as the night went on, instead of the user picking a theme?
- Does a bedtime app need a starfield at all, or is the darkness itself the brand?
- What if the Moon key's fade steps were the visual system, not just five ticks in its corner?

## Audit (native)

| # | Dimension | Score | Key finding |
|---|---|---|---|
| 1 | Accessibility | 3 | Labels, values, announcements and Reduce Motion are thorough; AX5 search pill and 21 fixed glyph sizes |
| 2 | Performance | 3 | Scene backdrops redraw a Canvas at 15 fps behind every screen, all night if the app stays open |
| 3 | Appearance and theming | 2 | Ten hand-tuned hex palettes; no semantic colours; system appearance and Increase Contrast are ignored |
| 4 | Platform conformance | 3 | Custom pager instead of a tab bar, hidden nav bar with a custom back key (edge swipe still works), custom search field instead of `.searchable` |
| 5 | Adaptivity | 3 | iPhone portrait only by design; keyboard handling is good (player rides above it) |
| | **Total** | **14/20** | **Good** |

**Platform conformance verdict:** passes as native. Edge-swipe back works, SF Symbols throughout, sheets and full-screen cover used correctly. The departures (pager, physical keys) are deliberate and mostly earn their place; the pager is the one that costs discoverability.

**Findings**
- [P1] AX5 search placeholder wraps to four lines · `SearchView.swift:304` · Accessibility · `/impeccable adapt`
- [P1] Mini player overlaps scroll content · `NightCastApp.swift:48` overlay with no inset · Conformance · `/impeccable layout`
- [P2] Now Playing title fixed at 36 pt outside AX sizes · `NowPlayingView.swift:39` · Accessibility · `/impeccable typeset`
- [P2] Scene Canvas at 15 fps behind lists · `Scenes.swift:14` · Performance · `/impeccable optimize`
- [P2] App forces its own colour scheme, ignores system appearance and Increase Contrast · `NightCastApp.swift:23` · Theming · `/impeccable colorize`
- [P3] Unlabelled icon keys (layout, theme) rely on Large Content Viewer · `LibraryView.swift` · Accessibility · `/impeccable clarify`

**Positive findings:** sensory feedback on every key, VoiceOver escape closes Now Playing, announcements for search results, contrast script in CI covering all ten themes.

## Recommended order

1. `/impeccable layout` for the mini player inset (merge or finish PR #5).
2. `/impeccable colorize` to return the accent to the Moon alone.
3. `/impeccable adapt` for AX5 search.
4. Pick a refresh direction (see [index.html](index.html)); most of issues 4 and 5 are solved by the direction rather than patched.
5. `/impeccable polish` last.
