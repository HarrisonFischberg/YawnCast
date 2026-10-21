import Foundation
import Testing
@testable import YawnCastCore

/// Opt-in check against a real downloaded feed file (not run by default):
/// YAWNCAST_LIVE_FEED=/path/to/feed.xml swift test --filter LiveFeed
@Suite("LiveFeed (opt-in)")
struct LiveFeedTests {
    static let path = ProcessInfo.processInfo.environment["YAWNCAST_LIVE_FEED"]

    @Test(.enabled(if: path != nil))
    func parsesRealFeed() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: Self.path!))
        let feed = try RSSParser.parse(data, feedURL: URL(string: "https://example.invalid/live")!)
        print("LIVE: show=\(feed.show.title) episodes=\(feed.episodes.count) withDuration=\(feed.episodes.filter { $0.duration != nil }.count) newest=\(feed.episodes.first?.title ?? "-")")
        #expect(!feed.episodes.isEmpty)
        #expect(feed.show.artworkURL != nil)
    }
}
