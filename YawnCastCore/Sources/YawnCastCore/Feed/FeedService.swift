import Foundation

public protocol FeedService: Sendable {
    /// Follows up to `maxPages` pages of a paged feed. When that limit cuts the history
    /// short, `nextPageURL` is the first page left out; otherwise it is nil.
    func fetch(_ feedURL: URL, maxPages: Int) async throws -> Feed
    /// Like `fetch(_:maxPages:)`, but may return `cached` itself when the publisher says
    /// the feed has not changed since that copy.
    func fetch(_ feedURL: URL, maxPages: Int, cached: Feed?) async throws -> Feed
}

extension FeedService {
    /// Services that can't ask "has it changed?" just fetch.
    public func fetch(_ feedURL: URL, maxPages: Int, cached: Feed?) async throws -> Feed {
        try await fetch(feedURL, maxPages: maxPages)
    }

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
        try await fetch(feedURL, maxPages: maxPages, cached: nil)
    }

    public func fetch(_ feedURL: URL, maxPages: Int, cached: Feed?) async throws -> Feed {
        // "Not modified" on the first page only stands for the copy when that copy is the
        // whole history, or when the first page is all that was asked for.
        let known = cached.flatMap { $0.nextPageURL == nil || maxPages == 1 ? $0 : nil }
        guard let (data, response) = try await page(feedURL, etag: known?.etag, lastModified: known?.lastModified) else {
            if let known { return known }
            throw FeedError.http(status: 304)
        }
        // Keep the subscribed URL as identity even if the server redirected.
        var feed = try RSSParser.parse(data, feedURL: feedURL)
        feed.etag = response?.value(forHTTPHeaderField: "ETag")
        feed.lastModified = response?.value(forHTTPHeaderField: "Last-Modified")
        var episodes = feed.episodes
        var seenPages: Set<URL> = [feedURL]
        var seenEpisodes = Set(episodes.map(\.id))
        var next = feed.nextPageURL
        while let url = next, seenPages.count < maxPages, seenPages.insert(url).inserted {
            try Task.checkCancellation()
            guard let data = try? await page(url)?.0,
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

    /// Nil means 304 Not Modified, which only a request carrying `etag` or `lastModified` gets.
    private func page(_ url: URL, etag: String? = nil, lastModified: String? = nil) async throws -> (Data, HTTPURLResponse?)? {
        var request = URLRequest(url: url.httpsUpgraded, timeoutInterval: 20)
        request.setValue("application/rss+xml, application/xml;q=0.9, */*;q=0.8", forHTTPHeaderField: "Accept")
        if etag != nil || lastModified != nil {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
            // Our copy is the cache; URLSession must hand the 304 over rather than answer from its own.
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        if http?.statusCode == 304, etag != nil || lastModified != nil { return nil }
        if let http, !(200..<300).contains(http.statusCode) {
            throw FeedError.http(status: http.statusCode)
        }
        try Task.checkCancellation()
        return (data, http)
    }
}
