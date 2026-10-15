import Foundation
import Testing
@testable import NightCastCore

@Suite("Explore categories and interests")
struct CategoryTests {
    @Test func browseCardsAreUniqueAndCoverRequestedGroups() {
        let ids = PodcastCategory.browse.map(\.id)
        #expect(Set(ids).count == ids.count)
        let names = Set(PodcastCategory.browse.map(\.name))
        for wanted in ["Sports", "Politics", "Technology", "AI", "Hobbies"] { #expect(names.contains(wanted)) }
        #expect(PodcastCategory.browse.first { $0.name == "AI" }?.source == .search("artificial intelligence"))
    }

    @Test func genreMapsToItsCardOrAPlainOne() {
        #expect(PodcastCategory.forGenre(Genre(id: "1545", name: "Sports")).symbol == "sportscourt")
        let other = PodcastCategory.forGenre(Genre(id: "9999", name: "Odd"))
        #expect(other.name == "Odd" && other.source == .genre("9999"))
    }

    @Test func interestsPutKeywordsFirstThenGenresWithoutRepeats() {
        let taste = [
            GenreWeight(genre: Genre(id: "1512", name: "Health & Fitness"), weight: 4),
            GenreWeight(genre: Genre(id: "1483", name: "Fiction"), weight: 3),
            GenreWeight(genre: Genre(id: "1512", name: "Health & Fitness"), weight: 1),
        ]
        let interests = PodcastCategory.interests(taste: taste, keywords: ["sleep": 2, "baseball": 2])
        #expect(interests.map(\.name) == ["Baseball", "Sleep", "Health & Fitness", "Fiction"])
        #expect(interests[1].source == .search("sleep stories"), "matches the Sleep card")
        #expect(interests[0].source == .search("baseball"))
    }
}

@Suite("Library order and layout")
struct LibraryOrderTests {
    func show(_ n: Int) -> Show { Show(feedURL: URL(string: "https://f.example/\(n)")!, title: "S\(n)") }

    @Test func moveDownAndUp() {
        var library = LibrarySnapshot(subscriptions: [show(1), show(2), show(3), show(4)])
        do { let moved = library.moveSubscription(id: show(1).id, onto: show(3).id); #expect(moved) }
        #expect(library.subscriptions.map(\.title) == ["S2", "S3", "S1", "S4"])
        do { let moved = library.moveSubscription(id: show(4).id, onto: show(2).id); #expect(moved) }
        #expect(library.subscriptions.map(\.title) == ["S4", "S2", "S3", "S1"])
        do { let moved = library.moveSubscription(id: show(4).id, onto: show(4).id); #expect(!moved) }
        do { let moved = library.moveSubscription(id: "missing", onto: show(1).id); #expect(!moved) }
    }

    @Test func orderAndLayoutPersist() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "nc-\(UUID().uuidString)/library.json")
        let store = JSONLibraryStore(fileURL: url)
        var library = LibrarySnapshot(subscriptions: [show(1), show(2)], libraryLayout: .list, appearanceVersion: 4)
        library.moveSubscription(id: show(2).id, onto: show(1).id)
        try store.save(library)
        let loaded = JSONLibraryStore(fileURL: url).load()
        #expect(loaded.subscriptions.map(\.title) == ["S2", "S1"])
        #expect(loaded.libraryLayout == .list)
        #expect(loaded.appearanceVersion == 4)
    }

    @Test func oldLibraryFilesStillLoad() throws {
        let json = #"{"subscriptions":[],"positions":{},"themeID":"ink"}"#
        let decoded = try JSONDecoder().decode(LibrarySnapshot.self, from: Data(json.utf8))
        #expect(decoded.themeID == "ink" && decoded.libraryLayout == nil && decoded.appearanceVersion == nil)
    }

    @Test func layoutCycles() {
        #expect(LibraryLayout.large.next == .small)
        #expect(LibraryLayout.small.next == .list)
        #expect(LibraryLayout.list.next == .large)
    }
}
