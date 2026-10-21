import Foundation

public struct DirectoryResult: Hashable, Identifiable, Sendable {
    public var directoryID: Int
    public var title: String
    public var author: String?
    public var artworkURL: URL?
    public var feedURL: URL
    /// Directory genres, primary first, excluding the catch-all "Podcasts" genre.
    public var genres: [Genre]

    public var id: String { FeedURL.key(feedURL) }

    public init(directoryID: Int, title: String, author: String?, artworkURL: URL?, feedURL: URL, genres: [Genre] = []) {
        self.directoryID = directoryID
        self.title = title
        self.author = author
        self.artworkURL = artworkURL
        self.feedURL = feedURL
        self.genres = genres
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

public struct Genre: Hashable, Codable, Sendable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    /// iTunes' umbrella genre that every podcast carries; useless for taste.
    public static let umbrellaID = "26"
}

public enum DirectoryError: Error, Equatable, Sendable {
    case http(status: Int)
    case rateLimited
    case badResponse
}

public protocol DirectoryService: Sendable {
    func search(_ term: String) async throws -> [DirectoryResult]
    /// Full records (feed URL, genres) for directory ids.
    func lookup(ids: [Int]) async throws -> [DirectoryResult]
    /// Directory ids of the top shows in a genre, best first.
    func topShowIDs(genreID: String, limit: Int) async throws -> [Int]
}

extension DirectoryService {
    public func lookup(ids: [Int]) async throws -> [DirectoryResult] { [] }
    public func topShowIDs(genreID: String, limit: Int) async throws -> [Int] { [] }
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

    public func lookup(ids: [Int]) async throws -> [DirectoryResult] {
        var results: [DirectoryResult] = []
        // The lookup endpoint accepts many ids per call; keep batches modest.
        for start in stride(from: 0, to: ids.count, by: 50) {
            let batch = ids[start..<min(ids.count, start + 50)]
            var components = URLComponents(string: "https://itunes.apple.com/lookup")
            components?.queryItems = [
                URLQueryItem(name: "id", value: batch.map(String.init).joined(separator: ",")),
                URLQueryItem(name: "country", value: country),
                URLQueryItem(name: "entity", value: "podcast"),
            ]
            guard let url = components?.url else { continue }
            results += try Self.decode(try await get(url))
        }
        return DirectoryResult.deduplicated(results)
    }

    public func topShowIDs(genreID: String, limit: Int) async throws -> [Int] {
        guard let url = Self.chartURL(country: country, genreID: genreID, limit: limit) else { return [] }
        return try Self.decodeChart(try await get(url))
    }

    static func chartURL(country: String, genreID: String, limit: Int) -> URL? {
        let safeGenre = genreID.filter(\.isNumber)
        guard !safeGenre.isEmpty else { return nil }
        return URL(string: "https://itunes.apple.com/\(country.lowercased())/rss/toppodcasts/limit=\(max(1, min(limit, 100)))/genre=\(safeGenre)/json")
    }

    /// Decodes Apple's legacy top-podcasts RSS JSON into directory ids, in chart order.
    /// A single entry is sent as an object rather than an array.
    public static func decodeChart(_ data: Data) throws -> [Int] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let feed = root["feed"] as? [String: Any] else { throw DirectoryError.badResponse }
        let entries: [[String: Any]]
        if let list = feed["entry"] as? [[String: Any]] {
            entries = list
        } else if let one = feed["entry"] as? [String: Any] {
            entries = [one]
        } else {
            return []
        }
        var seen = Set<Int>()
        return entries.compactMap { entry in
            guard let id = (entry["id"] as? [String: Any])?["attributes"] as? [String: Any],
                  let raw = id["im:id"] as? String, let value = Int(raw), seen.insert(value).inserted else { return nil }
            return value
        }
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 15))
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300: break
            case 403, 429: throw DirectoryError.rateLimited
            default: throw DirectoryError.http(status: http.statusCode)
            }
        }
        return data
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
                var genreIds: [String]?
                var genres: [String]?
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
                feedURL: feed,
                genres: zip(item.genreIds ?? [], item.genres ?? [])
                    .filter { $0.0 != Genre.umbrellaID }
                    .map { Genre(id: $0.0, name: $0.1) }
            )
        }
        return DirectoryResult.deduplicated(results)
    }
}
