import XCTest

/// Runs against fixture services (`-uitest`): no network, a bundled 90 s tone,
/// and a dedicated library file that `-resetStore` clears.
@MainActor
final class CoreFlowUITests: XCTestCase {
    private func launch(reset: Bool, extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-theme", "almanac"] + (reset ? ["-resetStore"] : []) + extra
        app.launch()
        return app
    }

    private func searchAndOpenShow(_ app: XCUIApplication) {
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        let result = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(result.waitForExistence(timeout: 5), "search result row")
        result.tap()
        XCTAssertTrue(app.buttons["subscribeKey"].waitForExistence(timeout: 5))
    }

    func testEmptyLibraryOffersOneAction() {
        let app = launch(reset: true)
        XCTAssertTrue(app.staticTexts["Nothing on the nightstand yet."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["findPodcastKey"].exists)
    }

    func testSearchEmptyAndErrorStatesWithRetry() {
        let app = launch(reset: true)
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("nothing")
        XCTAssertTrue(app.staticTexts["No shows found"].waitForExistence(timeout: 5))
        field.clearAndType("offline")
        XCTAssertTrue(app.staticTexts["Couldn’t search"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["retryKey"].exists)
        field.clearAndType("quiet")
        XCTAssertTrue(app.buttons["Quiet Hours, Fixture Studio"].waitForExistence(timeout: 5))
    }

    /// M3.4: subscription survives relaunch.
    func testSubscribePersistsAcrossRelaunch() {
        var app = launch(reset: true)
        searchAndOpenShow(app)
        let subscribe = app.buttons["subscribeKey"]
        XCTAssertEqual(subscribe.label, "Subscribe")
        subscribe.tap()
        XCTAssertEqual(subscribe.label, "Subscribed")
        app.terminate()

        app = launch(reset: false)
        XCTAssertTrue(app.buttons["Quiet Hours, Fixture Studio"].waitForExistence(timeout: 5), "show tile after relaunch")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        XCTAssertTrue(app.buttons["subscribeKey"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["subscribeKey"].label, "Subscribed")
    }

    /// Subscribe → play → Sleep on → Sleep off. Playback must advance; no other episode starts.
    func testSubscribePlayAndSleepFlow() {
        let app = launch(reset: true)
        searchAndOpenShow(app)
        app.buttons["subscribeKey"].tap()

        let episode = app.buttons["Fixture Episode 3"]
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        episode.tap()

        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8), "Now Playing opened")
        XCTAssertTrue(app.staticTexts["Fixture Episode 3"].exists)
        XCTAssertEqual(playPause.label, "Play", "a row tap opens Now Playing without playing")
        playPause.tap()
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" }, "playing")

        let scrubber = app.otherElements["scrubber"].exists ? app.otherElements["scrubber"] : app.descendants(matching: .any)["scrubber"]
        let before = scrubber.value as? String ?? ""
        sleep(3)
        let after = scrubber.value as? String ?? ""
        XCTAssertNotEqual(before, after, "position advances while playing")

        // Dragging the thumb seeks on release (the 90 s tone: 80% along is past a minute).
        scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.25))
            .press(forDuration: 0.2, thenDragTo: scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.25)))
        XCTAssertTrue(waitUntil(3) { (scrubber.value as? String ?? "").hasPrefix("1 minute") }, "drag seeks: \(scrubber.value ?? "")")

        let moon = app.buttons["moonKey"]
        XCTAssertEqual(moon.value as? String, "Off")
        moon.tap()
        XCTAssertTrue((moon.value as? String ?? "").hasPrefix("On. Fade begins in"), "Sleep on: \(moon.value ?? "")")
        moon.tap()
        XCTAssertEqual(moon.value as? String, "Off")

        playPause.tap()
        XCTAssertEqual(playPause.label, "Play")
        XCTAssertTrue(app.staticTexts["Fixture Episode 3"].exists, "same episode still loaded")
    }

    /// M3.5 (UI side): position is kept and shown after relaunch.
    func testPositionSurvivesRelaunch() {
        var app = launch(reset: true)
        searchAndOpenShow(app)
        app.buttons["Fixture Episode 2"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        playPause.tap()
        app.buttons["Forward 15 seconds"].tap()
        app.buttons["Forward 15 seconds"].tap()
        sleep(1)
        playPause.tap() // pause → saves position
        app.terminate()

        app = launch(reset: false)
        let mini = app.buttons["miniPlayer"]
        XCTAssertTrue(mini.waitForExistence(timeout: 5), "mini-player restored")
        mini.tap()
        let scrubber = app.descendants(matching: .any)["scrubber"]
        XCTAssertTrue(scrubber.waitForExistence(timeout: 5))
        let value = scrubber.value as? String ?? ""
        XCTAssertTrue(value.contains("30 seconds") || value.contains("31 seconds") || value.contains("32 seconds") || value.contains("33 seconds"), "restored position: \(value)")
        XCTAssertEqual(app.buttons["playPause"].label, "Play", "never autoplays on relaunch")
    }
}

@MainActor
func waitUntil(_ timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
    return condition()
}

@MainActor
extension XCUIElement {
    func clearAndType(_ text: String) {
        tap()
        if let current = value as? String, !current.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        typeText(text)
    }
}
