# Architecture (replica-architect, adapted to native iOS)

Stack: Swift 6, SwiftUI, Observation, AVFoundation, MediaPlayer, URLSession, XMLParser.
No server, no database server, no auth (replica-architect's Postgres/auth defaults do not apply).
"Schema" = Codable models persisted as JSON (DECISIONS D04). "API" = iTunes Search (D03) + publisher RSS.
Build order (thin vertical slice first): core logic → player engine → Show → Search → Library → Now Playing polish.
Full module map: PLAN.md.
