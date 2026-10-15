import Foundation

public protocol FeedService: Sendable {
    func fetch(_ feedURL: URL) async throws -> Feed
}

public struct HTTPFeedService: FeedService {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(_ feedURL: URL) async throws -> Feed {
        var request = URLRequest(url: feedURL, timeoutInterval: 20)
        request.setValue("application/rss+xml, application/xml;q=0.9, */*;q=0.8", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FeedError.http(status: http.statusCode)
        }
        try Task.checkCancellation()
        // Keep the subscribed URL as identity even if the server redirected.
        return try RSSParser.parse(data, feedURL: feedURL)
    }
}
