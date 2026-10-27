import Foundation

public protocol FeedService: Sendable {
    /// Follows up to `maxPages` pages of a paged feed. When that limit cuts the history
    /// short, `nextPageURL` is the first page left out; otherwise it is nil.
    func fetch(_ feedURL: URL, maxPages: Int) async throws -> Feed
}

extension FeedService {
    public func fetch(_ feedURL: URL) async throws -> Feed {
        try await fetch(feedURL, maxPages: HTTPFeedService.maxPages)
    }
}

public struct HTTPFeedService: FeedService {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Most pages followed for a paged feed (`atom:link rel="next"`).
    public static let maxPages = 40

    /// Fetches the feed and, when the publisher pages its history, the following
    /// pages (up to `maxPages`), so the episode list runs from the first episode to
    /// the latest. A failing later page keeps what loaded.
    public func fetch(_ feedURL: URL, maxPages: Int) async throws -> Feed {
        // Keep the subscribed URL as identity even if the server redirected.
        var feed = try RSSParser.parse(try await page(feedURL), feedURL: feedURL)
        var episodes = feed.episodes
        var seenPages: Set<URL> = [feedURL]
        var seenEpisodes = Set(episodes.map(\.id))
        var next = feed.nextPageURL
        while let url = next, seenPages.count < maxPages, seenPages.insert(url).inserted {
            try Task.checkCancellation()
            guard let data = try? await page(url),
                  let more = try? RSSParser.parse(data, feedURL: feedURL) else { break }
            let fresh = more.episodes.filter { seenEpisodes.insert($0.id).inserted }
            if fresh.isEmpty { break }
            episodes += fresh
            next = more.nextPageURL
        }
        feed.episodes = Feed.sortedNewestFirst(episodes)
        feed.nextPageURL = seenPages.count >= maxPages ? next : nil
        return feed
    }

    private func page(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/rss+xml, application/xml;q=0.9, */*;q=0.8", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FeedError.http(status: http.statusCode)
        }
        try Task.checkCancellation()
        return data
    }
}
