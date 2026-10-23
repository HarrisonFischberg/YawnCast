import XCTest

/// The Moon key on the mini player.
@MainActor
final class MiniMoonUITests: XCTestCase {
    private func playFixtureAndCloseNowPlaying() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "ink"]
        app.launch()
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        XCTAssertTrue(app.buttons["subscribeKey"].waitForExistence(timeout: 5))
        app.buttons["Fixture Episode 3"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        playPause.tap()
        let close = app.buttons["closePlayer"]
        XCTAssertTrue(close.waitForExistence(timeout: 8))
        close.tap()
        XCTAssertTrue(app.buttons["miniPlayer"].waitForExistence(timeout: 5))
        return app
    }

    func testMiniMoonKeyTogglesSleep() {
        let app = playFixtureAndCloseNowPlaying()
        let key = app.buttons["miniMoonKey"]
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        XCTAssertEqual(key.label, "Sleep")
        XCTAssertEqual(key.value as? String, "Off")

        key.tap()
        XCTAssertTrue(waitUntil(3) { (key.value as? String) == "On" }, "tap turns Sleep on")
        XCTAssertTrue(key.isSelected)

        // Now Playing agrees.
        app.buttons["miniPlayer"].tap()
        let moon = app.buttons["moonKey"]
        XCTAssertTrue(moon.waitForExistence(timeout: 5))
        XCTAssertTrue((moon.value as? String ?? "").hasPrefix("On"), "\(String(describing: moon.value))")
        app.buttons["closePlayer"].tap()

        XCTAssertTrue(key.waitForExistence(timeout: 5))
        key.tap()
        XCTAssertTrue(waitUntil(3) { (key.value as? String) == "Off" }, "second tap turns Sleep off")
    }
}
