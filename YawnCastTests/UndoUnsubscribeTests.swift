import Foundation
import YawnCastCore
import Testing
@testable import YawnCast

/// Unsubscribe offers Undo, and Undo puts the show back where it was.
@MainActor
struct UndoUnsubscribeTests {
    private static func show(_ n: Int) -> Show {
        Show(feedURL: URL(string: "https://fixtures.yawncast.invalid/undo-\(n).xml")!, title: "Show \(n)")
    }

    private func model() -> AppModel {
        let model = AppModel(store: MemoryLibraryStore(), directory: FixtureDirectory(), feeds: FixtureFeedService())
        for n in 1...3 { model.toggleSubscription(Self.show(n)) }
        return model
    }

    @Test func undoRestoresTheShowToItsSlot() {
        let model = model()
        model.unsubscribe(Self.show(2))
        #expect(model.library.subscriptions.map(\.title) == ["Show 1", "Show 3"])
        #expect(model.unsubscribed?.show.title == "Show 2")
        model.undoUnsubscribe()
        #expect(model.library.subscriptions.map(\.title) == ["Show 1", "Show 2", "Show 3"])
        #expect(model.unsubscribed == nil)
    }

    @Test func subscribingAgainCountsAsUndo() {
        let model = model()
        model.toggleSubscription(Self.show(1))
        model.toggleSubscription(Self.show(1))
        #expect(model.library.subscriptions.map(\.title) == ["Show 1", "Show 2", "Show 3"])
        #expect(model.unsubscribed == nil)
    }

    @Test func undoAfterTheLastShowLeftIsStillSafe() {
        let model = model()
        model.unsubscribe(Self.show(3))
        model.unsubscribe(Self.show(1)) // replaces the first offer
        model.undoUnsubscribe()
        #expect(model.library.subscriptions.map(\.title) == ["Show 1", "Show 2"])
        model.undoUnsubscribe() // nothing left to undo
        #expect(model.library.subscriptions.count == 2)
    }
}
