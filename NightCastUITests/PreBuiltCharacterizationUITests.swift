import XCTest

/// Characterization tests (pre-built, 2026-10-17). They assert what the app does
/// today for the flows the speed work touches (F-001, F-003, F-004, F-002), so a
/// later change that alters them is visible. They wait for content (up to 8 s)
/// instead of asserting it is on the very first frame.
@MainActor
final class PreBuiltCharacterizationUITests: XCTestCase {
    private func launch(reset: Bool) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-theme", "ink"] + (reset ? ["-resetStore"] : [])
        app.launch()
        return app
    }

    private func subscribeToQuietHours(_ app: XCUIApplication) {
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        let subscribe = app.buttons["subscribeKey"]
        XCTAssertTrue(subscribe.waitForExistence(timeout: 5))
        subscribe.tap()
        XCTAssertTrue(waitUntil(5) { subscribe.label == "Subscribed" })
        // Let the show page finish its feed load so the feed is cached to disk.
        XCTAssertTrue(app.buttons["Fixture Episode 3"].waitForExistence(timeout: 8))
    }

    /// F-001 / F-004: after a relaunch the New page lists the cached episodes, and
    /// the Library tile carries the "New episode" marker.
    func testRelaunchShowsCachedNewEpisodesAndNewMarker() {
        var app = launch(reset: true)
        subscribeToQuietHours(app)
        app.terminate()

        app = launch(reset: false)
        let tile = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(tile.waitForExistence(timeout: 8), "Library tile after relaunch")
        XCTAssertTrue(waitUntil(8) { (tile.value as? String) == "New episode" }, "tile marked as having a new episode: \(String(describing: tile.value))")

        app.buttons["pageDot-New"].tap()
        XCTAssertTrue(waitUntil(5) { app.buttons["pageDot-New"].isSelected })
        XCTAssertTrue(app.buttons["Fixture Episode 3, Quiet Hours"].waitForExistence(timeout: 8), "newest episode listed on New")
        XCTAssertTrue(app.buttons["Fixture Episode 2, Quiet Hours"].exists)
    }

    /// F-003: opening a show from the Library and tapping an episode starts it and
    /// opens the player with that episode, and the show page is intact on return.
    func testOpenShowFromLibraryAndPlayEpisode() {
        var app = launch(reset: true)
        subscribeToQuietHours(app)
        app.terminate()

        app = launch(reset: false)
        let tile = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(tile.waitForExistence(timeout: 8))
        tile.tap()
        let episode = app.buttons["Fixture Episode 2"]
        XCTAssertTrue(episode.waitForExistence(timeout: 8), "show page lists cached episodes")
        XCTAssertTrue(app.buttons["Fixture Episode 1"].exists)
        episode.tap()
        XCTAssertTrue(app.buttons["playPause"].waitForExistence(timeout: 8), "player opens")
        XCTAssertTrue(app.staticTexts["Fixture Episode 2"].exists)
        let close = app.buttons["closePlayer"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(app.buttons["Fixture Episode 3"].waitForExistence(timeout: 5), "show page intact after the player closes")
    }

    /// F-002: a saved position and subscription survive the app being sent to the
    /// background and then killed, with the library file written after pausing.
    func testPositionAndSubscriptionSurviveBackgroundThenKill() {
        var app = launch(reset: true)
        subscribeToQuietHours(app)
        app.buttons["Fixture Episode 2"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        app.buttons["Forward 15 seconds"].tap()
        app.buttons["Forward 15 seconds"].tap()
        sleep(1)
        playPause.tap() // pause saves the position
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.terminate()

        app = launch(reset: false)
        XCTAssertTrue(app.buttons["Quiet Hours, Fixture Studio"].waitForExistence(timeout: 8), "subscription kept")
        let mini = app.buttons["miniPlayer"]
        XCTAssertTrue(mini.waitForExistence(timeout: 5), "mini-player restored")
        mini.tap()
        let scrubber = app.descendants(matching: .any)["scrubber"]
        XCTAssertTrue(scrubber.waitForExistence(timeout: 5))
        let value = scrubber.value as? String ?? ""
        XCTAssertTrue(value.contains("30 seconds") || value.contains("31 seconds") || value.contains("32 seconds") || value.contains("33 seconds"), "restored position: \(value)")
    }
}
