#if DEBUG
import Foundation
import NightCastCore

// UI-test fixtures, used only with the `-uitest` launch argument. Production
// code paths use ITunesDirectory and HTTPFeedService.

/// Directory fake: "quiet" → one show, "nothing" → no results, "offline" → error.
struct FixtureDirectory: DirectoryService {
    static let show = Show(
        feedURL: URL(string: "https://fixtures.nightcast.invalid/quiet.xml")!,
        directoryID: 4242,
        title: "Quiet Hours",
        author: "Fixture Studio",
        artworkURL: nil
    )

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
    func fetch(_ feedURL: URL) async throws -> Feed {
        try await Task.sleep(for: .milliseconds(150))
        guard let audio = Bundle.main.url(forResource: "fixture-tone", withExtension: "m4a") else {
            throw FeedError.noEpisodes
        }
        var show = FixtureDirectory.show
        show.summary = "A fixture show used by UI tests. Each episode is a quiet tone."
        let episodes = (1...3).reversed().map { n in
            Episode(
                id: "fixture-\(n)",
                showFeedURL: feedURL,
                showTitle: show.title,
                title: "Fixture Episode \(n)",
                published: Date(timeIntervalSince1970: 1_728_000_000 + Double(n) * 86_400),
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
        let url = base.appending(path: "NightCast/uitest-library.json")
        if reset { try? FileManager.default.removeItem(at: url) }
        return JSONLibraryStore(fileURL: url)
    }
}
#endif
