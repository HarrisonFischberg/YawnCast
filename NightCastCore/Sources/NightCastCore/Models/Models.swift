import Foundation

/// A podcast show. Identity is the canonical feed URL, so the same show found
/// through search and through a stored subscription compares equal.
public struct Show: Codable, Hashable, Identifiable, Sendable {
    public var feedURL: URL
    public var directoryID: Int?
    public var title: String
    public var author: String?
    public var summary: String?
    public var artworkURL: URL?

    public var id: String { FeedURL.key(feedURL) }

    public init(
        feedURL: URL,
        directoryID: Int? = nil,
        title: String,
        author: String? = nil,
        summary: String? = nil,
        artworkURL: URL? = nil
    ) {
        self.feedURL = feedURL
        self.directoryID = directoryID
        self.title = title
        self.author = author
        self.summary = summary
        self.artworkURL = artworkURL
    }
}

public struct Episode: Codable, Hashable, Identifiable, Sendable {
    /// RSS `guid` when present, otherwise the enclosure URL.
    public var id: String
    public var showFeedURL: URL
    public var showTitle: String
    public var title: String
    public var published: Date?
    /// Duration from the feed, if it declared one. The player's measured
    /// duration takes precedence once known.
    public var duration: TimeInterval?
    public var audioURL: URL
    public var summary: String?
    public var artworkURL: URL?

    public init(
        id: String,
        showFeedURL: URL,
        showTitle: String,
        title: String,
        published: Date? = nil,
        duration: TimeInterval? = nil,
        audioURL: URL,
        summary: String? = nil,
        artworkURL: URL? = nil
    ) {
        self.id = id
        self.showFeedURL = showFeedURL
        self.showTitle = showTitle
        self.title = title
        self.published = published
        self.duration = duration
        self.audioURL = audioURL
        self.summary = summary
        self.artworkURL = artworkURL
    }
}

public struct PlaybackPosition: Codable, Hashable, Sendable {
    public var seconds: TimeInterval
    public var duration: TimeInterval?
    public var completed: Bool
    public var updatedAt: Date

    public init(seconds: TimeInterval, duration: TimeInterval?, completed: Bool = false, updatedAt: Date = Date()) {
        self.seconds = seconds
        self.duration = duration
        self.completed = completed
        self.updatedAt = updatedAt
    }

    /// 0...1 when duration is known.
    public var fraction: Double? {
        if completed { return 1 }
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        return min(1, max(0, seconds / duration))
    }
}

public struct Feed: Sendable, Equatable {
    public var show: Show
    public var episodes: [Episode]

    public init(show: Show, episodes: [Episode]) {
        self.show = show
        self.episodes = episodes
    }
}

public enum FeedURL {
    /// Stable identity key for a feed URL: scheme-insensitive, lowercased host,
    /// no fragment, no trailing slash. Used for de-duplication and storage keys.
    public static func key(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.scheme = nil
        components.fragment = nil
        components.host = components.host?.lowercased()
        if components.port == 80 || components.port == 443 { components.port = nil }
        var path = components.path
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
        components.path = path
        var key = components.string ?? url.absoluteString
        if key.hasPrefix("//") { key.removeFirst(2) }
        return key
    }
}
