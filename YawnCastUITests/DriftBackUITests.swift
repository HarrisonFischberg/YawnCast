import XCTest

/// Drift back: after Sleep fades the episode out and pauses it, Now
/// Playing offers one key back to where the fade began. Uses `-fastSleep` timings
/// (fade after 4 s, whole fade ≈ 32 s of active playback), like SleepUITests.
@MainActor
final class DriftBackUITests: XCTestCase {
    private func startPlayback(theme: String, extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-fastSleep", "-theme", theme] + extra
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
        return app
    }

    /// Turns Sleep on and waits for it to fade out and pause. Fails if the key shows early.
    private func sleepThroughFade(_ app: XCUIApplication) {
        let moon = app.buttons["moonKey"]
        let playPause = app.buttons["playPause"]
        let key = app.buttons["driftBackKey"]
        moon.tap()
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline, playPause.label == "Pause" {
            XCTAssertFalse(key.exists, "no key while Sleep is on")
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        XCTAssertEqual(playPause.label, "Play", "Sleep paused playback")
        XCTAssertTrue(waitUntil(3) { (moon.value as? String) == "Off" }, "Sleep ended")
    }

    private func screenshot(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        // Optional copy for the Evolve card: TEST_RUNNER_DRIFT_BACK_SHOTS=<dir> xcodebuild …
        if let dir = ProcessInfo.processInfo.environment["DRIFT_BACK_SHOTS"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    func testKeyJumpsBackToFadeStart() {
        let app = startPlayback(theme: "midnight")
        sleepThroughFade(app)
        let key = app.buttons["driftBackKey"]
        XCTAssertTrue(key.waitForExistence(timeout: 3), "key after fade-and-pause")
        XCTAssertGreaterThanOrEqual(key.frame.height, 44)
        let label = key.label
        XCTAssertTrue(label.hasPrefix("Back to ") && label.hasSuffix(", where the fade began"), label)
        let spoken = String(label.dropFirst("Back to ".count).dropLast(", where the fade began".count))
        let scrubber = app.otherElements["scrubber"].exists ? app.otherElements["scrubber"] : app.sliders["scrubber"]
        let before = scrubber.value as? String ?? ""
        XCTAssertFalse(before.hasPrefix(spoken + " of"), "already at the marker: \(before)")
        screenshot(app, "drift-back-on")

        key.tap()
        XCTAssertTrue(waitUntil(3) { (scrubber.value as? String ?? "").hasPrefix(spoken + " of") },
                      "elapsed moved to \(spoken), got \(scrubber.value as? String ?? "nil")")
        XCTAssertTrue(waitUntil(3) { !key.exists }, "key goes away after the jump")
        XCTAssertEqual(app.buttons["playPause"].label, "Play", "the jump does not start playback")
    }

    func testPaperAccessibilityText() {
        let app = startPlayback(theme: "paper",
                                extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        sleepThroughFade(app)
        let key = app.buttons["driftBackKey"]
        XCTAssertTrue(key.waitForExistence(timeout: 3))
        XCTAssertTrue(key.isHittable)
        screenshot(app, "drift-back-on-paper-ax")
    }
}
