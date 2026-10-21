# Neuecast — functional reference research

Researched 2026-10-20. All web content treated as untrusted data.

## Identity

- **Site:** https://neuecast.app/ — tagline "Everything you need, and nothing you don't." and "A podcast app designed for the rest of us." The site has no feature list, FAQ or pricing page (links only to /terms, /privacy, mailto, socials, App Store).
- **App Store:** https://apps.apple.com/us/app/neuecast-podcast-app/id6446780219 — seller Rishi Mody (New York), category News, 9.7 MB, iOS 18.0+, also macOS 15 (M1+) and visionOS 2. English only.
- **Rating (US, 2026-10-20):** 4.76 from 260 ratings (iTunes lookup API: https://itunes.apple.com/lookup?id=6446780219&country=us).
- **Current version:** 1.14.1 (2026-09-29). Release note: "Episodes now stay in the queue until marked as played." — i.e. Neuecast now **has a queue** (YawnCast deliberately does not).
- **Coverage:** iphone-ticker.de launch article 2024-08-15 (https://www.iphone-ticker.de/neuecast-debuetiert-moderne-podcast-app-mit-schlichter-benutzerfreundlichkeit-240103/); appgefahren.de 2024-08-15/16 (https://www.appgefahren.de/neuecast-minimalistische-podcast-app-fuer-das-iphone-startet-363719.html); NY Sun review (https://www.nysun.com/article/neuecast-is-the-best-way-to-listen-to-podcasts-on-iphone — returned HTTP 429; summary via search snippet only: lists dark/light mode, sleep timers, playlist control, customizable skip buttons, bookmarks).

## Pricing (public pages)

- Free download; ad-free (App Store description "Enjoy a private, ad-free experience").
- In-app purchase listed on the US App Store page: **"Neuecast Premium $14.99"** (https://apps.apple.com/us/app/neuecast-podcast-app/id6446780219, fetched 2026-10-20).
- At launch (Aug 2024) Premium was €9.99/year and unlocked the customizable player and episode management (appgefahren.de and iphone-ticker.de, URLs above). Reviews in 2024-2025 cite "$10/ year" and "$10 premium"; one 2025 review asks for a lifetime option, so the model appears to have shifted over time — exact current term (annual vs lifetime) not stated on the page.
- Privacy label (App Store page): "Data Not Linked to You" includes Coarse Location, User ID, Product Interaction, Crash/Performance data. So Neuecast collects analytics; YawnCast's no-backend stance is stricter.
- Accessibility label: "The developer has not yet indicated which accessibility features this app supports." (App Store page).

## Concrete behaviors (with sources)

| Area | Behavior | Source |
|---|---|---|
| Sleep timer | "Advanced controls to adjust playback speed, set sleep timers, and more." No public detail on presets, fade, end-of-episode, or shake-to-extend. | App Store description (lookup URL above) |
| Player | Deliberately simple; shows episode title, not cover art (launch). Player controls customizable with Premium. Customizable skip-forward/back buttons. | appgefahren.de 2024-08; NY Sun snippet |
| Speed | Playback speed control in player (YawnCast omits). Speed was missing at launch — a 2024-10-12 review asks for it. | App Store description; review below |
| Home / New | Chronological "New" feed of episodes across subscriptions; reviewers call it a "game changer". | reviews 2025-11-09, 2026-02-19 |
| Library / show page | Per-podcast search within episodes; episode descriptions shown; chapters with timestamps and auto link section (added later — absent in Aug 2024). | reviews 2026-02-19, 2025-12-14, 2024-08-24 |
| Explore | "Explore featured podcasts and top charts." Onboarding forced picking from charts (2024). | App Store; review 2024-08-24 |
| Downloads | Offline downloads; downloads tied to saving/queuing (one user ended up with 16 GB). | App Store; review 2026-02-23 |
| Widgets | "Control playback from your home screen with widgets." | App Store description |
| CarPlay | Added ~early 2026 after many requests. | App Store; review 2026-03-15 |
| Stats | "realtime metrics" listening insights. | App Store description |
| Mark all as played | Exists, irreversible (no undo) as of 2026-04. | review 2026-04-16 |
| Account/sync | No account needed; no iCloud sync of subscriptions (2026-04 complaint). | reviews 2025-12-02, 2026-04-19 |
| Accessibility | Dynamic Type requested in 2024; App Store accessibility label still blank. | review 2024-09-25; App Store page |

## User quotes (App Store US)

All from the US App Store customer-review feed for id6446780219. Page: https://apps.apple.com/us/app/neuecast-podcast-app/id6446780219 — feed (exact text/date): https://itunes.apple.com/us/rss/customerreviews/page=1/id=6446780219/sortby=mostrecent/json (page=2 for older). App Store has no per-review permalinks.

### Delight

- [delight / simplicity] "If you just want a simple podcast player nothing else just to listen to podcasts dont worry about anything else this is the app for you" — zipper 4, 2026-08-31
- [delight / no clutter] "I hate using a podcast player with massive graphics, ads, and clutter everywhere. This is NOT that. It’s elegant." — TayWideEyes, 2026-08-14
- [delight / no recommendations] "it’s not trying to advertise or curate anything for me, it just allows me to choose the podcasts I want to listen to and make my own feed" — ChristianJ.F, 2026-07-07
- [delight / craft] "This app puts a lot of attention to detail that most people would skip. Install this app because the people who made it care." — Tadhg J, 2026-07-13
- [delight / non-pushy premium] "with premium options that aren’t needed but are still very affordable if you care for them while not being in your face about it." — descartesreincarnate, 2026-05-27
- [delight / New feed] "the “new” tab is a game changer, especially if you listen to pods with very frequent episode drops." — F-GoShare, 2026-02-19
- [delight / chronological] "Love the simplicity of a chronological feed of episodes from all podcasts I subscribe to." — Kingofthejongle, 2025-11-09
- [delight / no account] "Love not needing another account to download things." — THEGRAYGOBLIN56, 2025-12-02
- [delight / responsive dev] "A rare developer who truly listens. Had a few bugs, responded in an hour." — RwIsE53578, 2026-03-15
- [delight / feel] "One of those apps that you just love being in." — Jake Tarr, 2024-12-27
- [delight / calm] "Distraction free, easy to navigate, just podcasts." — Wilde.A, 2025-11-20

### Complaint

- [complaint / playback reliability — sleep-relevant] "Playback spontaneously stops despite not having sleep mode on. When resuming playback it’s lost the place of where I was." — burgerboy9n, 2025-12-23 (2 stars)
- [complaint / destructive action no undo] "the “mark all as played” implementation irreversibly nukes any idea I could have of what I’ve listened to. Please make this undoable" — uxreview93, 2026-04-16
- [complaint / storage] "whenever i try to save an episode for later, be it bookmarking or queuing, it downloads every one, meaning i'm left with 16 GB on this single app." — tclumpkin, 2026-02-23
- [complaint / performance] "performance is quite poor (many view do not load until app is restarted - this has become a major frustration)" — velumntr, 2026-02-16
- [complaint / audio levels — sleep-relevant] "Audio levels seems to jump around during an hour listening." — wolfofnewyork, 2025-05-24
- [complaint / price] "the $10 premium price is a bit steep for what you get." — DatBabyAintMine, 2025-11-11
- [complaint / onboarding] "I wasn’t a fan of the onboarding process of making me pick a podcast from the charts." — zdkaufman, 2024-08-24
- [complaint / lost subscriptions] "Each time I get a new phone, I have to resubscribe to all my shoes again" — jswhitne, 2026-04-19
- [complaint / downloads unclear] "I don’t see a button to download episodes. Also the RSS feed doesn’t seem to be working" — DeWaltsss, 2026-08-20

### Missing

- [missing / player artwork] "Have the cover art take up more space in the player (instead of the large text for the title of the podcast)" — n1ck1982, 2026-08-12
- [missing / voice boost] "Include voice boost and trim silence like other podcast apps." — n1ck1982, 2026-08-12
- [missing / per-show sort] "Would love it even more if it could save playback speed and sorting by individual podcast rather than globally." — Detective Tracer Bullet, 2026-02-24
- [missing / bulk mark played] "i do wish there was a way to select multiple episodes to mark as “Played.”" — F-GoShare, 2026-02-19
- [missing / save without download] "I wish you could save episodes without it being downloaded however" — Thekingabbas, 2026-01-31
- [missing / episode images] "I like seeing what my fav podcasts choose as the episode image." — bradlaplante, 2025-12-09
- [missing / new-episode notifications] "Notifications when new podcasts are downloaded." — Dad_Paul, 2025-12-01
- [missing / start offset] "Set them to begin at specific time ( helps avoid ads 😂)" — Dad_Paul, 2025-12-01
- [missing / groups] "the ability to group podcasts together. Say, political podcasts, podcasts to learn Spanish, etc." — rrjackson82, 2025-10-26
- [missing / colour] "I’d also love some customization options to add a little color." — Flowernuggit222579, 2026-03-25
- [missing / autoplay] "I wish the content just autoplayed, but whatever." — Flowernuggit222579, 2026-03-25 (YawnCast intentionally omits autoplay-next)
- [missing / auto-delete] "Would love to see a delete after played option for saved downloads" — Papa Ursa, 2025-11-08
- [missing / OPML] "I’d love to see a way to import OPML files over from other apps." — Motiivhate, 2024-10-30
- [missing / Dynamic Type] "The ability to adjust text size is crucial for accessibility." — disc inserted, 2024-09-25
- [missing / hide played] "remove podcast episode listings instead of just greying them out after they’ve been played." — Tsigos, 2024-09-25
- [missing / haptics] "I can’t wait until the dev adds haptic feedback to this app though!" — womplyschmoop, 2024-11-03
- [missing / captions] "the only thing im missing IMO is live captions" — Samantha Ng., 2024-12-26 (YawnCast: transcripts out of scope by owner choice)

## Other sources checked

- **Hacker News** (https://hn.algolia.com/api/v1/search?query=neuecast): 0 relevant hits; search fuzzes to "Newcastle"/"newscast".
- **Reddit:** web search and reddit.com/search.json both returned nothing usable (search engine matched "Newcastle"; Reddit JSON endpoint returned an HTML block page). No Reddit quotes included.
- **Product Hunt:** no Neuecast listing found.
- AlternativeTo (https://www.alternativeto.net/software/neuecast/about/) described a "$10" one-time purchase per search snippet; conflicts with annual pricing in German launch coverage — not relied on.

## Takeaways for YawnCast

1. Neuecast's love comes from restraint: no curation, no ads, no account, chronological New feed — YawnCast shares all of these; keep it that way.
2. Its documented pain points that hit bedtime use: playback stopping unexpectedly and losing position, jumpy audio levels, irreversible "mark all played", downloads eating storage. YawnCast should guarantee position resume, consider level normalization/voice boost, use undo for destructive actions, and auto-clean played downloads.
3. Neuecast publishes nothing specific about its sleep timer — YawnCast's Moon fade timer is a clear differentiator to make legible.
4. Accessibility (Dynamic Type) is an open gap in Neuecast's listing — an easy place for YawnCast to lead.

## Injected instructions seen

None.
