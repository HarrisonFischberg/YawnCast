import Foundation
import YawnCastCore
import Testing
@testable import YawnCast

/// Directory fake. Each term answers from `responses` (default: no results). A term in
/// `held` waits until `release(_:)` so a test can act while that search is in flight.
final class StubDirectory: DirectoryService, @unchecked Sendable {
    private let lock = NSLock()
    private var _terms: [String] = []
    private var responses: [String: Result<[DirectoryResult], Error>] = [:]
    private var held: Set<String> = []
    private var waiting: [String: CheckedContinuation<Void, Never>] = [:]

    var terms: [String] { lock.withLock { _terms } }

    func answer(_ term: String, with result: Result<[DirectoryResult], Error>) {
        lock.withLock { responses[term] = result }
    }

    func hold(_ term: String) {
        lock.withLock { _ = held.insert(term) }
    }

    func release(_ term: String) {
        let continuation = lock.withLock {
            held.remove(term)
            return waiting.removeValue(forKey: term)
        }
        continuation?.resume()
    }

    func search(_ term: String) async throws -> [DirectoryResult] {
        let isHeld = lock.withLock {
            _terms.append(term)
            return held.contains(term)
        }
        if isHeld {
            await withCheckedContinuation { continuation in
                let releasedAlready = lock.withLock {
                    guard held.contains(term) else { return true }
                    waiting[term] = continuation
                    return false
                }
                if releasedAlready { continuation.resume() }
            }
        }
        return try lock.withLock { responses[term] ?? .success([]) }.get()
    }

    func lookup(ids: [Int]) async throws -> [DirectoryResult] { [] }
    func topShowIDs(genreID: String, limit: Int) async throws -> [Int] { [] }
}

func show(_ id: Int, _ title: String) -> DirectoryResult {
    DirectoryResult(directoryID: id, title: title, author: "Fixture Studio", artworkURL: nil,
                    feedURL: URL(string: "https://fixtures.yawncast.invalid/\(id).xml")!)
}

/// Polls on the main actor until `condition` holds; records an issue on timeout.
@MainActor
func waitUntil(timeout: Duration = .seconds(2), sourceLocation: SourceLocation = #_sourceLocation,
               _ condition: () -> Bool) async {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        if ContinuousClock.now >= deadline {
            Issue.record("Timed out waiting for condition", sourceLocation: sourceLocation)
            return
        }
        try? await Task.sleep(for: .milliseconds(5))
    }
}

/// Lets queued main-actor work and short sleeps run.
func settle(_ duration: Duration = .milliseconds(150)) async {
    try? await Task.sleep(for: duration)
}

@MainActor
@Suite("SearchModel")
struct SearchModelTests {
    let quiet = [show(1, "Quiet Hours")]

    @Test func startsIdle() {
        let model = SearchModel(directory: StubDirectory())
        #expect(model.state == .idle)
    }

    @Test func debounceSearchesOnlyTheLastTerm() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .milliseconds(80))
        model.query = "q"
        model.query = "qui"
        model.query = "quiet"
        #expect(directory.terms.isEmpty)
        await waitUntil { model.state == .results(quiet) }
        #expect(directory.terms == ["quiet"])
    }

    @Test func noSearchBeforeTheDebounceElapses() async {
        let directory = StubDirectory()
        let model = SearchModel(directory: directory, debounce: .seconds(10))
        model.query = "quiet"
        await settle()
        #expect(directory.terms.isEmpty)
        #expect(model.state == .idle)
    }

    @Test func trimsWhitespaceBeforeSearching() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "  quiet \n"
        await waitUntil { model.state == .results(quiet) }
        #expect(directory.terms == ["quiet"])
    }

    @Test func blankQueryGoesIdleWithoutSearching() async {
        let directory = StubDirectory()
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "   "
        await settle()
        #expect(model.state == .idle)
        #expect(directory.terms.isEmpty)
    }

    @Test func clearingTheQueryCancelsAPendingSearch() async {
        let directory = StubDirectory()
        let model = SearchModel(directory: directory, debounce: .milliseconds(50))
        model.query = "quiet"
        model.query = ""
        await settle()
        #expect(model.state == .idle)
        #expect(directory.terms.isEmpty)
    }

    @Test func showsLoadingWhileTheSearchIsInFlight() async {
        let directory = StubDirectory()
        directory.hold("quiet")
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { model.state == .loading }
        directory.release("quiet")
        await waitUntil { model.state == .results(quiet) }
    }

    @Test func noResultsShowsEmptyWithTheTypedTerm() async {
        let directory = StubDirectory()
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "Nothing "
        await waitUntil { model.state == .empty("Nothing") }
    }

    @Test func errorShowsAFriendlyMessage() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .failure(URLError(.notConnectedToInternet)))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { model.state == .failed("You’re offline. Check your connection and try again.") }
    }

    @Test func cancelledRequestErrorsAreIgnored() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .failure(URLError(.cancelled)))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { !directory.terms.isEmpty }
        await settle()
        #expect(model.state == .loading)
    }

    @Test func repeatQueryUsesTheCacheCaseInsensitively() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { model.state == .results(quiet) }
        model.query = ""
        model.query = "QUIET"
        // Cached answers are synchronous: no debounce, no loading state.
        #expect(model.state == .results(quiet))
        await settle()
        #expect(directory.terms == ["quiet"])
    }

    @Test func emptyResultsAreCachedToo() async {
        let directory = StubDirectory()
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "nothing"
        await waitUntil { model.state == .empty("nothing") }
        model.query = ""
        model.query = "Nothing"
        #expect(model.state == .empty("Nothing"))
        #expect(directory.terms == ["nothing"])
    }

    @Test func failuresAreNotCachedAndRetrySearchesAgain() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .failure(DirectoryError.rateLimited))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { model.state == .failed("Too many searches at once. Wait a moment, then try again.") }
        directory.answer("quiet", with: .success(quiet))
        model.retry()
        await waitUntil { model.state == .results(quiet) }
        #expect(directory.terms == ["quiet", "quiet"])
    }

    @Test func retrySkipsTheDebounce() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .seconds(10))
        model.query = "quiet"
        model.retry()
        await waitUntil { model.state == .results(quiet) }
        #expect(directory.terms == ["quiet"])
    }

    @Test func cancelBeforeTheDebounceStopsTheSearch() async {
        let directory = StubDirectory()
        let model = SearchModel(directory: directory, debounce: .milliseconds(50))
        model.query = "quiet"
        model.cancel()
        await settle()
        #expect(directory.terms.isEmpty)
        #expect(model.state == .idle)
    }

    @Test func cancelInFlightDropsTheLateAnswer() async {
        let directory = StubDirectory()
        directory.hold("quiet")
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { model.state == .loading }
        model.cancel()
        directory.release("quiet")
        await settle()
        #expect(model.state == .loading)
        // The dropped answer was not cached, so asking again searches again.
        model.retry()
        await waitUntil { model.state == .results(quiet) }
        #expect(directory.terms == ["quiet", "quiet"])
    }

    @Test func newerQueryWinsOverAnEarlierSlowOne() async {
        let directory = StubDirectory()
        let slow = [show(2, "Slow Rivers")]
        directory.hold("slow")
        directory.answer("slow", with: .success(slow))
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "slow"
        await waitUntil { directory.terms == ["slow"] }
        model.query = "quiet"
        await waitUntil { model.state == .results(quiet) }
        directory.release("slow")
        await settle()
        #expect(model.state == .results(quiet))
    }

    @Test func settingTheSameQueryDoesNotSearchAgain() async {
        let directory = StubDirectory()
        directory.answer("quiet", with: .success(quiet))
        let model = SearchModel(directory: directory, debounce: .zero)
        model.query = "quiet"
        await waitUntil { model.state == .results(quiet) }
        model.query = "quiet"
        await settle()
        #expect(directory.terms == ["quiet"])
    }
}

@Suite("SearchModel.message(for:)")
struct SearchMessageTests {
    static let offline = "You’re offline. Check your connection and try again."
    static let down = "The podcast directory isn’t responding right now."

    @Test("Error copy", arguments: [
        (URLError(.notConnectedToInternet) as Error, offline),
        (URLError(.networkConnectionLost), offline),
        (URLError(.dataNotAllowed), offline),
        (URLError(.timedOut), "The podcast directory took too long to answer."),
        (URLError(.badServerResponse), "Search didn’t work. Try again."),
        (DirectoryError.rateLimited, "Too many searches at once. Wait a moment, then try again."),
        (DirectoryError.http(status: 503), down),
        (DirectoryError.badResponse, down),
        (CocoaError(.fileReadUnknown), "Search didn’t work. Try again."),
    ])
    @MainActor func copy(error: Error, expected: String) {
        #expect(SearchModel.message(for: error) == expected)
    }
}
