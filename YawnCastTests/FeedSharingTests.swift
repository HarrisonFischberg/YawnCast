import Foundation
import YawnCastCore
import Testing
@testable import YawnCast

/// A paged feed: the first page has the newest episode, the whole history has two.
private struct PagedFeedStub: FeedService {
    static let show = Show(feedURL: URL(string: "https://fixtures.yawncast.invalid/paged.xml")!, title: "Paged")

    func fetch(_ feedURL: URL, maxPages: Int) async throws -> Feed {
        let firstPageOnly = maxPages == 1
        // The first page answers last, so the test also sees it merge under the full history.
        try await Task.sleep(for: .milliseconds(firstPageOnly ? 200 : 20))
        let episodes = (firstPageOnly ? [2] : [2, 1]).map { n in
            Episode(id: "paged-\(n)", showFeedURL: feedURL, showTitle: "Paged", title: "Episode \(n)",
                    published: Date(timeIntervalSince1970: Double(n) * 86_400), audioURL: URL(string: "https://fixtures.yawncast.invalid/\(n).mp3")!)
        }
        return Feed(show: Self.show, episodes: episodes, nextPageURL: firstPageOnly ? URL(string: "https://fixtures.yawncast.invalid/paged.xml?page=2") : nil)
    }
}

@MainActor
struct FeedSharingTests {
    /// The show page opened while the New page is still refreshing must get every episode.
    @Test func showPageGetsTheWholeHistoryWhileNewRefreshes() async throws {
        let model = AppModel(store: MemoryLibraryStore(), directory: FixtureDirectory(), feeds: PagedFeedStub())
        let newPage = Task { try await model.feed(for: PagedFeedStub.show, firstPageOnly: true) }
        try await Task.sleep(for: .milliseconds(50))
        let whole = try await model.feed(for: PagedFeedStub.show)
        #expect(whole.episodes.map(\.id) == ["paged-2", "paged-1"])
        _ = try await newPage.value
        #expect(model.cachedFeed(for: PagedFeedStub.show)?.episodes.map(\.id) == ["paged-2", "paged-1"])
    }
}
