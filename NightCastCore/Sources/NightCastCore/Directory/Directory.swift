import Foundation

public struct DirectoryResult: Hashable, Identifiable, Sendable {
    public var directoryID: Int
    public var title: String
    public var author: String?
    public var artworkURL: URL?
    public var feedURL: URL

    public var id: String { FeedURL.key(feedURL) }

    public init(directoryID: Int, title: String, author: String?, artworkURL: URL?, feedURL: URL) {
        self.directoryID = directoryID
        self.title = title
        self.author = author
        self.artworkURL = artworkURL
        self.feedURL = feedURL
    }

    public var show: Show {
        Show(feedURL: feedURL, directoryID: directoryID, title: title, author: author, artworkURL: artworkURL)
    }

    /// Keeps the first occurrence of each directory id and each canonical feed URL.
    public static func deduplicated(_ results: [DirectoryResult]) -> [DirectoryResult] {
        var ids = Set<Int>()
        var feeds = Set<String>()
        return results.filter { result in
            guard !ids.contains(result.directoryID), !feeds.contains(result.id) else { return false }
            ids.insert(result.directoryID)
            feeds.insert(result.id)
            return true
        }
    }
}

public enum DirectoryError: Error, Equatable, Sendable {
    case http(status: Int)
    case rateLimited
    case badResponse
}

public protocol DirectoryService: Sendable {
    func search(_ term: String) async throws -> [DirectoryResult]
}

/// Apple's public iTunes Search API. No credentials. See DECISIONS.md D03.
public struct ITunesDirectory: DirectoryService {
    private let session: URLSession
    private let country: String
    private let limit: Int

    public init(session: URLSession = .shared, country: String = Locale.current.region?.identifier ?? "US", limit: Int = 30) {
        self.session = session
        self.country = country
        self.limit = limit
    }

    public func searchURL(for term: String) -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        return components?.url
    }

    public func search(_ term: String) async throws -> [DirectoryResult] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = searchURL(for: trimmed) else { return [] }
        let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 15))
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300: break
            case 403, 429: throw DirectoryError.rateLimited
            default: throw DirectoryError.http(status: http.statusCode)
            }
        }
        return try Self.decode(data)
    }

    /// Decodes a search response. Entries without a usable feed URL are dropped.
    public static func decode(_ data: Data) throws -> [DirectoryResult] {
        struct Response: Decodable {
            struct Item: Decodable {
                var collectionId: Int?
                var collectionName: String?
                var artistName: String?
                var feedUrl: String?
                var artworkUrl600: String?
                var artworkUrl100: String?
            }
            var results: [Item]
        }
        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw DirectoryError.badResponse
        }
        let results = response.results.compactMap { item -> DirectoryResult? in
            guard let id = item.collectionId,
                  let feed = item.feedUrl.flatMap(URL.init(string:)),
                  feed.scheme == "https" || feed.scheme == "http",
                  let title = item.collectionName?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty
            else { return nil }
            return DirectoryResult(
                directoryID: id,
                title: title,
                author: item.artistName,
                artworkURL: (item.artworkUrl600 ?? item.artworkUrl100).flatMap(URL.init(string:)),
                feedURL: feed
            )
        }
        return DirectoryResult.deduplicated(results)
    }
}
