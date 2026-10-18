import Foundation
import Testing
@testable import NightCastCore

/// Characterization (pre-built, 2026-10-17): pins the bytes `JSONLibraryStore`
/// writes today. The library file is a contract with the copy on the owner's phone,
/// so any change to how saves are performed must keep these bytes identical.
@Suite("Library file format")
struct LibraryFormatTests {
    private static func snapshot() -> LibrarySnapshot {
        let feed = URL(string: "https://feeds.example.com/quiet")!
        let show = Show(feedURL: feed, directoryID: 42, title: "Quiet Hours", author: "Fixture Studio", summary: "A quiet show", artworkURL: nil)
        let episode = Episode(
            id: "quiet-1", showFeedURL: feed, showTitle: "Quiet Hours", title: "Episode 1",
            published: Date(timeIntervalSince1970: 1_760_000_000), duration: 90,
            audioURL: URL(string: "https://example.com/a.mp3")!
        )
        var snapshot = LibrarySnapshot(subscriptions: [show], lastEpisode: episode, themeID: "midnight", libraryLayout: nil, appearanceVersion: 4)
        snapshot.positions[episode.id] = PlaybackPosition(
            seconds: 31.5, duration: 90, completed: false, updatedAt: Date(timeIntervalSince1970: 1_760_000_100)
        )
        return snapshot
    }

    private static let golden = #"{"appearanceVersion":4,"lastEpisode":{"audioURL":"https:\/\/example.com\/a.mp3","duration":90,"id":"quiet-1","published":"2025-10-09T08:53:20Z","showFeedURL":"https:\/\/feeds.example.com\/quiet","showTitle":"Quiet Hours","title":"Episode 1"},"positions":{"quiet-1":{"completed":false,"duration":90,"seconds":31.5,"updatedAt":"2025-10-09T08:55:00Z"}},"subscriptions":[{"author":"Fixture Studio","directoryID":42,"feedURL":"https:\/\/feeds.example.com\/quiet","summary":"A quiet show","title":"Quiet Hours"}],"themeID":"midnight"}"#

    @Test("save writes the same bytes as before")
    func savedBytesMatchGolden() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "nc-format-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = JSONLibraryStore(fileURL: dir.appending(path: "NightCast/library.json"))
        try store.save(Self.snapshot())
        let text = try String(contentsOf: store.fileURL, encoding: .utf8)
        #expect(text == Self.golden)
    }

    @Test("load then save round-trips byte for byte")
    func roundTripIsStable() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "nc-format-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = JSONLibraryStore(fileURL: dir.appending(path: "NightCast/library.json"))
        try store.save(Self.snapshot())
        let first = try Data(contentsOf: store.fileURL)
        try store.save(store.load())
        #expect(try Data(contentsOf: store.fileURL) == first)
        #expect(store.load() == Self.snapshot())
    }
}
