import CryptoKit
import Foundation
import YawnCastCore

/// Last fetched copy of each feed, so the New page and show pages appear
/// instantly (and offline) before the network refresh finishes. Nonisolated so the
/// multi-MB JSON is read and written off the main thread.
nonisolated struct FeedDiskCache: Sendable {
    private let directory: URL

    init() {
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "Feeds")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func load(_ feedURL: URL) -> Feed? {
        guard let data = try? Data(contentsOf: file(for: feedURL)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Feed.self, from: data)
    }

    func save(_ feed: Feed) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(feed) else { return }
        try? data.write(to: file(for: feed.show.feedURL), options: .atomic)
    }

    private func file(for feedURL: URL) -> URL {
        let name = SHA256.hash(data: Data(FeedURL.key(feedURL).utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name + ".json")
    }
}
