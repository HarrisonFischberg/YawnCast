import XCTest

/// Wake extend (exp_wake_extend): Play within 10 minutes of a Sleep fade-out turns Sleep back on.
/// `-fastSleep` makes a full fade take about 32 s of active playback.
@MainActor
final class WakeExtendUITests: XCTestCase {
    private func fadeOutThenPlay(flag: Bool) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-fastSleep", "-theme", "ember"]
        if flag { app.launchArguments += ["-exp_wake_extend", "YES"] }
        app.launch()
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        let episode = app.buttons["Fixture Episode 3"]
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        episode.tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" }, "playing")

        let moon = app.buttons["moonKey"]
        moon.tap()
        XCTAssertTrue(waitUntil(60) { playPause.label == "Play" }, "Sleep faded and paused")
        XCTAssertTrue(waitUntil(3) { (moon.value as? String) == "Off" }, "Sleep ended")

        playPause.tap()
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" }, "playing again")
        return app
    }

    /// Optional evidence capture: `TEST_RUNNER_SCREENSHOT_DIR=<dir> xcodebuild ... test`.
    private func saveShot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    func testPlayAfterFadeTurnsSleepBackOn() {
        let app = fadeOutThenPlay(flag: true)
        let moon = app.buttons["moonKey"]
        XCTAssertTrue(waitUntil(5) { (moon.value as? String ?? "").hasPrefix("On.") }, "Sleep back on, got \(moon.value as? String ?? "nil")")
        saveShot("wake-extend-on")
    }

    func testPlayAfterFadeLeavesSleepOffWithoutFlag() {
        let app = fadeOutThenPlay(flag: false)
        let moon = app.buttons["moonKey"]
        sleep(2)
        XCTAssertEqual(moon.value as? String, "Off")
        saveShot("wake-extend-off")
    }
}
