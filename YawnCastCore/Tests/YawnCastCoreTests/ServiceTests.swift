import Foundation
import Testing
@testable import YawnCastCore

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

let feedURL = URL(string: "https://feeds.example.com/quiet")!

@Suite("RSSParser fixtures")
struct RSSParserTests {
    @Test func standardFeed() throws {
        let feed = try RSSParser.parse(fixture("standard.xml"), feedURL: feedURL)
        #expect(feed.show.title == "Quiet Hours")
        #expect(feed.show.author == "Fixture Studio")
        #expect(feed.show.summary == "Slow conversations for late nights & early mornings.")
        #expect(feed.show.artworkURL?.absoluteString == "https://example.com/art.jpg")
        #expect(feed.episodes.map(\.id) == ["qh-002", "qh-001"])
        let two = feed.episodes[0]
        #expect(two.duration == 3723)
        #expect(two.audioURL.absoluteString == "https://cdn.example.com/qh-002.mp3")
        #expect(two.published == Date(timeIntervalSince1970: 1728421200))
        #expect(two.artworkURL?.absoluteString == "https://example.com/art.jpg")
        let one = feed.episodes[1]
        #expect(one.duration == 2723)
        #expect(one.published != nil)
        #expect(one.artworkURL?.absoluteString == "https://example.com/ep1.jpg")
        #expect(one.showTitle == "Quiet Hours")
    }

    @Test func messyFeedSkipsUnplayableAndToleratesBadFields() throws {
        let feed = try RSSParser.parse(fixture("messy.xml"), feedURL: feedURL)
        #expect(feed.show.title == "Messy Feed")
        #expect(feed.show.artworkURL == nil)
        let ids = feed.episodes.map(\.id)
        // Newest dated first; undated last in feed order.
        #expect(ids == ["m-4", "https://cdn.example.com/m-1.mp3", "m-2"])
        let noGuid = feed.episodes[1]
        #expect(noGuid.duration == 2730)
        #expect(noGuid.published != nil)
        let garbage = feed.episodes[2]
        #expect(garbage.duration == nil)
        #expect(garbage.published == nil)
        #expect(garbage.audioURL.absoluteString == "https://cdn.example.com/m-2.mp3")
        #expect(feed.episodes[0].title == "Untitled episode")
    }

    @Test func malformedXMLThrows() throws {
        #expect(throws: FeedError.self) { try RSSParser.parse(fixture("malformed.xml"), feedURL: feedURL) }
    }

    @Test func nonRSSDocumentThrows() throws {
        #expect(throws: FeedError.self) { try RSSParser.parse(fixture("not-rss.html"), feedURL: feedURL) }
        #expect(throws: FeedError.self) { try RSSParser.parse(Data(), feedURL: feedURL) }
    }

    @Test("Duration formats", arguments: [
        ("1:02:03", 3723.0), ("45:30", 2730.0), ("2723", 2723.0), ("90.5", 90.5), (" 05:00 ", 300.0),
    ])
    func durations(raw: String, expected: Double) {
        #expect(RSSDuration.parse(raw) == expected)
    }

    @Test("Bad durations are unknown", arguments: ["", "0", "abc", "1:2:3:4", "-5", "1:-2"])
    func badDurations(raw: String) {
        #expect(RSSDuration.parse(raw) == nil)
    }

    @Test func htmlStripping() {
        #expect(HTMLText.plain("<p>A &amp; B</p><p>C</p>") == "A & B\n\nC")
        #expect(HTMLText.plain("Hi<br/>there") == "Hi\nthere")
    }
}

@Suite("Network services (iTunes Search, feeds)", .serialized)
struct NetworkServiceTests {
    @Test func decodeDropsMissingFeedsAndDeduplicates() throws {
        let results = try ITunesDirectory.decode(fixture("itunes-search.json"))
        // 101 dup id dropped; 102 same canonical feed as 101 dropped; 103 has no feed.
        #expect(results.map(\.directoryID) == [101, 104])
        #expect(results[0].artworkURL?.absoluteString == "https://example.com/600.jpg")
        #expect(results[1].artworkURL?.absoluteString == "https://example.com/m100.jpg")
        #expect(results[0].show.directoryID == 101)
    }

    @Test func badJSONIsBadResponse() {
        #expect(throws: DirectoryError.badResponse) { try ITunesDirectory.decode(Data("nope".utf8)) }
    }

    @Test func searchURLIsEncoded() throws {
        let url = try #require(ITunesDirectory(country: "US").searchURL(for: "night & day"))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "term", value: "night & day")))
        #expect(items.contains(URLQueryItem(name: "media", value: "podcast")))
        #expect(url.absoluteString.contains("night%20%26%20day"))
    }

    @Test func emptyTermMakesNoRequest() async throws {
        let results = try await ITunesDirectory(session: .stubbed).search("   ")
        #expect(results.isEmpty)
    }

    @Test func httpErrorsMap() async throws {
        StubURLProtocol.respond(status: 429, body: Data())
        await #expect(throws: DirectoryError.rateLimited) { try await ITunesDirectory(session: .stubbed).search("x") }
        StubURLProtocol.respond(status: 500, body: Data())
        await #expect(throws: DirectoryError.http(status: 500)) { try await ITunesDirectory(session: .stubbed).search("x") }
        StubURLProtocol.respond(status: 200, body: try fixture("itunes-search.json"))
        let results = try await ITunesDirectory(session: .stubbed).search("quiet")
        #expect(results.count == 2)
    }

    @Test func feedURLKeys() {
        #expect(FeedURL.key(URL(string: "https://Feeds.Example.com/quiet/")!) == FeedURL.key(URL(string: "http://feeds.example.com/quiet")!))
        #expect(FeedURL.key(URL(string: "https://a.com/x#frag")!) == FeedURL.key(URL(string: "https://a.com/x")!))
        #expect(FeedURL.key(URL(string: "https://a.com/x?id=1")!) != FeedURL.key(URL(string: "https://a.com/x?id=2")!))
    }

    static func page(_ ids: [Int], next: String?) -> Data {
        let link = next.map { #"<atom:link rel="next" href="\#($0)"/>"# } ?? ""
        let items = ids.map { i in
            "<item><title>E\(i)</title><guid>e\(i)</guid><pubDate>\(i < 100 ? "Mon, 0\(i % 9 + 1) Jan 2018 10:00:00 +0000" : "Tue, 01 Oct 2024 10:00:00 +0000")</pubDate><enclosure url=\"https://cdn.example.com/\(i).mp3\" type=\"audio/mpeg\"/></item>"
        }.joined()
        return Data(#"<?xml version="1.0"?><rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom"><channel><title>Paged</title>\#(link)\#(items)</channel></rss>"#.utf8)
    }

    @Test func pagedFeedFollowsNextLinksAndStopsOnLoops() async throws {
        StubURLProtocol.respond(status: 404, body: Data())
        StubURLProtocol.route([
            "https://feeds.example.com/quiet": (200, Self.page([101, 102], next: "/quiet?page=2")),
            "https://feeds.example.com/quiet?page=2": (200, Self.page([3, 4], next: "https://feeds.example.com/quiet?page=3")),
            "https://feeds.example.com/quiet?page=3": (200, Self.page([1, 2], next: "https://feeds.example.com/quiet")), // loops back
        ])
        let feed = try await HTTPFeedService(session: .stubbed).fetch(feedURL)
        #expect(Set(feed.episodes.map(\.id)) == ["e101", "e102", "e1", "e2", "e3", "e4"])
        #expect(feed.episodes.first?.id.hasPrefix("e10") == true, "newest first across pages")
        #expect(feed.nextPageURL == nil)
    }

    @Test func pagedFeedKeepsFirstPageWhenALaterPageFails() async throws {
        StubURLProtocol.respond(status: 500, body: Data())
        StubURLProtocol.route(["https://feeds.example.com/quiet": (200, Self.page([101], next: "/quiet?page=2"))])
        let feed = try await HTTPFeedService(session: .stubbed).fetch(feedURL)
        #expect(feed.episodes.map(\.id) == ["e101"])
    }

    @Test func feedFetchParsesAndMapsHTTPErrors() async throws {
        StubURLProtocol.respond(status: 404, body: Data())
        await #expect(throws: FeedError.http(status: 404)) { try await HTTPFeedService(session: .stubbed).fetch(feedURL) }
        StubURLProtocol.respond(status: 200, body: try fixture("standard.xml"))
        let feed = try await HTTPFeedService(session: .stubbed).fetch(feedURL)
        #expect(feed.episodes.count == 2)
        #expect(feed.show.feedURL == feedURL)
    }
}

@Suite("Persistence")
struct PersistenceTests {
    func tempStore() -> JSONLibraryStore {
        let dir = FileManager.default.temporaryDirectory.appending(path: "yawncast-tests-\(UUID().uuidString)")
        return JSONLibraryStore(fileURL: dir.appending(path: "library.json"))
    }

    let show = Show(feedURL: feedURL, directoryID: 1, title: "Quiet Hours", artworkURL: URL(string: "https://example.com/a.jpg"))

    @Test func missingFileIsEmpty() {
        #expect(tempStore().load() == .empty)
    }


    @Test func subscriptionsAndPositionsSurviveRelaunch() throws {
        let store = tempStore()
        var snapshot = store.load()
        snapshot.subscribe(show)
        snapshot.subscribe(show) // idempotent
        snapshot.positions["qh-001"] = PlaybackPosition(seconds: 1234.5, duration: 2723, updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        snapshot.themeID = "ember"
        try store.save(snapshot)

        let relaunched = JSONLibraryStore(fileURL: store.fileURL).load()
        #expect(relaunched == snapshot)
        #expect(relaunched.subscriptions.count == 1)
        #expect(relaunched.positions["qh-001"]?.seconds == 1234.5)
        #expect(relaunched.isSubscribed(show))
    }

    @Test func unsubscribeMatchesCanonicalFeed() throws {
        var snapshot = LibrarySnapshot()
        snapshot.subscribe(show)
        let sameShowOtherURL = Show(feedURL: URL(string: "http://FEEDS.example.com/quiet/")!, title: "Quiet Hours")
        #expect(snapshot.isSubscribed(sameShowOtherURL))
        snapshot.unsubscribe(sameShowOtherURL)
        #expect(snapshot.subscriptions.isEmpty)
    }

    @Test func corruptFileIsMovedAsideNotLost() throws {
        let store = tempStore()
        try FileManager.default.createDirectory(at: store.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: store.fileURL)
        #expect(store.load() == .empty)
        let aside = store.fileURL.deletingPathExtension().appendingPathExtension("corrupt.json")
        #expect(FileManager.default.fileExists(atPath: aside.path))
    }
}

@Suite("Seek math and formatting")
struct PlaybackMathTests {
    @Test func clamping() {
        #expect(SeekMath.clamp(-5, duration: 100) == 0)
        #expect(SeekMath.clamp(150, duration: 100) == 100)
        #expect(SeekMath.clamp(150, duration: nil) == 150)
        #expect(SeekMath.clamp(.nan, duration: 100) == 0)
        #expect(SeekMath.clamp(50, duration: .infinity) == 50)
        #expect(SeekMath.skip(from: 10, by: -15, duration: 100) == 0)
        #expect(SeekMath.skip(from: 95, by: 15, duration: 100) == 100)
        #expect(SeekMath.skip(from: 30, by: 15, duration: 100) == 45)
    }

    @Test func resume() {
        #expect(SeekMath.resumeTime(saved: nil, duration: 100) == 0)
        #expect(SeekMath.resumeTime(saved: PlaybackPosition(seconds: 40, duration: 100), duration: 100) == 40)
        #expect(SeekMath.resumeTime(saved: PlaybackPosition(seconds: 90, duration: 100), duration: 100) == 0)
        #expect(SeekMath.resumeTime(saved: PlaybackPosition(seconds: 40, duration: 100, completed: true), duration: 100) == 0)
        #expect(SeekMath.resumeTime(saved: PlaybackPosition(seconds: 4000, duration: nil), duration: nil) == 4000)
    }

    @Test func remaining() {
        #expect(SeekMath.remaining(position: 30, duration: 100) == 70)
        #expect(SeekMath.remaining(position: 300, duration: 100) == 0)
        #expect(SeekMath.remaining(position: 30, duration: nil) == nil)
    }

    @Test func formatting() {
        #expect(TimeFormat.clock(723) == "12:03")
        #expect(TimeFormat.clock(3723) == "1:02:03")
        #expect(TimeFormat.remaining(722.2) == "-12:03")
        #expect(TimeFormat.duration(3723) == "1 hr 2 min")
        #expect(TimeFormat.duration(2700) == "45 min")
        #expect(TimeFormat.duration(3600) == "1 hr")
        #expect(TimeFormat.sleepDelay(1800) == "30 min")
        #expect(TimeFormat.sleepDelay(40) == "40 sec")
        #expect(TimeFormat.sleepDelayLong(1800) == "30 minutes")
        #expect(TimeFormat.sleepDelayLong(60) == "1 minute")
        #expect(TimeFormat.sleepDelayLong(40) == "40 seconds")
        #expect(TimeFormat.sleepDelayLong(0.5) == "1 second")
        #expect(SleepCopy.status(.fading(level: 0.6)) == "Fading · 60%")
        #expect(SleepCopy.status(.waiting(untilFade: 600)) == "Fade in 10 min")
    }
}
