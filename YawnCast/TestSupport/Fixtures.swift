#if DEBUG
import Foundation
import YawnCastCore

// UI-test fixtures, used only with the `-uitest` launch argument. Production
// code paths use ITunesDirectory and HTTPFeedService.

/// Directory fake: "quiet" → one show, "nothing" → no results, "offline" → error.
struct FixtureDirectory: DirectoryService {
    static let show = Show(
        feedURL: URL(string: "https://fixtures.yawncast.invalid/quiet.xml")!,
        directoryID: 4242,
        title: "Quiet Hours",
        author: "Fixture Studio",
        artworkURL: nil
    )

    /// Library show is Fiction; the chart offers two Fiction shows and one Comedy show.
    static let catalog: [DirectoryResult] = [
        DirectoryResult(directoryID: 4242, title: "Quiet Hours", author: "Fixture Studio", artworkURL: nil,
                        feedURL: show.feedURL, genres: [Genre(id: "1483", name: "Fiction")]),
        DirectoryResult(directoryID: 5001, title: "Lantern Tales", author: "Fixture Studio", artworkURL: nil,
                        feedURL: URL(string: "https://fixtures.yawncast.invalid/lantern.xml")!, genres: [Genre(id: "1483", name: "Fiction")]),
        DirectoryResult(directoryID: 5002, title: "Slow Rivers", author: "Fixture Studio", artworkURL: nil,
                        feedURL: URL(string: "https://fixtures.yawncast.invalid/rivers.xml")!, genres: [Genre(id: "1483", name: "Fiction")]),
        DirectoryResult(directoryID: 5003, title: "Loud Laughs", author: "Fixture Studio", artworkURL: nil,
                        feedURL: URL(string: "https://fixtures.yawncast.invalid/laughs.xml")!, genres: [Genre(id: "1303", name: "Comedy")]),
    ]

    func lookup(ids: [Int]) async throws -> [DirectoryResult] {
        Self.catalog.filter { ids.contains($0.directoryID) }
    }

    func topShowIDs(genreID: String, limit: Int) async throws -> [Int] {
        genreID == "1483" ? [5002, 4242, 5001] : [5003]
    }

    func search(_ term: String) async throws -> [DirectoryResult] {
        try await Task.sleep(for: .milliseconds(150))
        switch term.lowercased() {
        case let t where t.contains("offline"): throw URLError(.notConnectedToInternet)
        case let t where t.contains("nothing"): return []
        default:
            return [DirectoryResult(directoryID: 4242, title: Self.show.title, author: Self.show.author, artworkURL: nil, feedURL: Self.show.feedURL)]
        }
    }
}

/// Feed fake whose episodes play a bundled 90-second tone.
struct FixtureFeedService: FeedService {
    func fetch(_ feedURL: URL, maxPages: Int) async throws -> Feed {
        try await Task.sleep(for: .milliseconds(150))
        guard let audio = Bundle.main.url(forResource: "fixture-tone", withExtension: "m4a") else {
            throw FeedError.noEpisodes
        }
        var show = FixtureDirectory.show
        if let match = FixtureDirectory.catalog.first(where: { $0.feedURL == feedURL }) {
            show = match.show
        }
        show.feedURL = feedURL
        show.summary = "A fixture show used by UI tests. Each episode is a quiet tone."
        let episodes = (1...3).reversed().map { n in
            Episode(
                id: "\(feedURL.lastPathComponent)-\(n)",
                showFeedURL: feedURL,
                showTitle: show.title,
                title: "Fixture Episode \(n)",
                // ep 3 today, 2 yesterday, 1 two days ago; from the start of today, so it holds just after midnight
                published: Calendar.current.date(byAdding: .day, value: n - 3, to: Calendar.current.startOfDay(for: Date())),
                duration: 90,
                audioURL: audio
            )
        }
        return Feed(show: show, episodes: episodes)
    }
}

extension JSONLibraryStore {
    /// Separate file for UI tests so they never touch the real library.
    static func uiTest(reset: Bool) -> JSONLibraryStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appending(path: "YawnCast/uitest-library.json")
        if reset { try? FileManager.default.removeItem(at: url) }
        return JSONLibraryStore(fileURL: url)
    }
}
#endif
