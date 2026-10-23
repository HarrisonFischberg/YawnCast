import XCTest

/// Opt-in: real iTunes search, real RSS, real audio stream. Not run by default.
/// TEST_RUNNER_YAWNCAST_LIVE=1 xcodebuild test -only-testing:YawnCastUITests/LiveNetworkUITests ...
@MainActor
final class LiveNetworkUITests: XCTestCase {
    func testRealSearchSubscribeAndStream() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["YAWNCAST_LIVE"] == "1", "Set TEST_RUNNER_YAWNCAST_LIVE=1 to run")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-liveTest", "-theme", "almanac"]
        app.launch()

        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("nothing much happens")

        let results = app.descendants(matching: .any)["searchResults"]
        XCTAssertTrue(results.waitForExistence(timeout: 15), "real search results")
        attach(app, "1-search-results")
        let first = results.buttons.firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()

        let subscribe = app.buttons["subscribeKey"]
        XCTAssertTrue(subscribe.waitForExistence(timeout: 10))
        subscribe.tap()
        XCTAssertEqual(subscribe.label, "Subscribed")

        // First episode row: buttons below the "Episodes" header.
        let episodesHeader = app.descendants(matching: .any)["episodesHeader"]
        XCTAssertTrue(episodesHeader.waitForExistence(timeout: 20), "real feed loaded")
        attach(app, "2-show-detail")
        let episode = app.buttons.matching(identifier: "episodeRow").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        episode.tap()

        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 10))
        playPause.tap()
        XCTAssertTrue(waitUntil(30) { playPause.label == "Pause" && (playPause.value as? String ?? "") != "Loading" }, "stream started")
        let scrubber = app.descendants(matching: .any)["scrubber"]
        let before = scrubber.value as? String ?? ""
        sleep(5)
        let after = scrubber.value as? String ?? ""
        XCTAssertNotEqual(before, after, "real stream position advances (\(before) → \(after))")
        attach(app, "3-now-playing-streaming")
        playPause.tap()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
