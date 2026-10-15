import XCTest

/// Sleep against the real AVPlayer, with `-fastSleep` timings so a full fade
/// fits in a test: fade after 4 s, 10 steps every 3 s, 1 s glides (total ≈ 32 s
/// of active playback). `debugGain` mirrors the live AVPlayer.volume.
@MainActor
final class SleepUITests: XCTestCase {
    private func startPlayback() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-fastSleep", "-theme", "ember"]
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

    private func gain(_ app: XCUIApplication) -> Double {
        Double(app.staticTexts["debugGain"].label) ?? -1
    }

    /// M4.2 + M4.5 + M4.10: full fade on the real player, then pause, gain restored, nothing else plays.
    func testFullFadeDrivesPlayerVolumeThenPauses() {
        let app = startPlayback()
        let moon = app.buttons["moonKey"]
        moon.tap()
        XCTAssertTrue((moon.value as? String ?? "").hasPrefix("On. Fade begins in"))
        XCTAssertEqual(gain(app), 1.0, accuracy: 0.001)

        var samples: [Double] = []
        let playPause = app.buttons["playPause"]
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline, playPause.label == "Pause" {
            samples.append(gain(app))
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        XCTAssertEqual(playPause.label, "Play", "Sleep paused playback")
        XCTAssertTrue(waitUntil(3) { (moon.value as? String) == "Off" }, "Sleep ended")
        XCTAssertEqual(gain(app), 1.0, accuracy: 0.001, "gain restored for next deliberate play")

        let fade = samples.filter { $0 >= 0 }
        XCTAssertFalse(fade.isEmpty)
        // Never increases while fading.
        for (a, b) in zip(fade, fade.dropFirst()) { XCTAssertLessThanOrEqual(b, a + 0.001, "gain rose: \(fade)") }
        // Each step level was observed.
        for level in [0.8, 0.6, 0.4, 0.2] {
            XCTAssertTrue(fade.contains { abs($0 - level) < 0.011 }, "missing step \(level) in \(fade)")
        }
        XCTAssertTrue(fade.contains { $0 < 0.2 }, "reached near zero before pause")
        print("GAIN-SAMPLES:", fade.map { String(format: "%.2f", $0) }.joined(separator: " "))
        let record = XCTAttachment(string: fade.map { String(format: "%.2f", $0) }.joined(separator: " "))
        record.name = "gain-samples"
        record.lifetime = .keepAlways
        add(record)

        // Still the same episode; nothing else started.
        sleep(3)
        XCTAssertEqual(playPause.label, "Play")
        XCTAssertTrue(app.staticTexts["Fixture Episode 3"].exists)
    }

    /// M4.4: cancel mid-fade restores baseline on the real player.
    func testCancelMidFadeRestoresVolume() {
        let app = startPlayback()
        let moon = app.buttons["moonKey"]
        moon.tap()
        XCTAssertTrue(waitUntil(20) { self.gain(app) <= 0.61 }, "fade reached 60%")
        moon.tap()
        XCTAssertEqual(moon.value as? String, "Off")
        XCTAssertTrue(waitUntil(3) { abs(self.gain(app) - 1.0) < 0.001 }, "restored to 1.0, got \(gain(app))")
        XCTAssertEqual(app.buttons["playPause"].label, "Pause", "cancel keeps playing")
    }

    /// M4.3: pausing freezes the countdown on the real player.
    func testPauseFreezesCountdown() {
        let app = startPlayback()
        let moon = app.buttons["moonKey"]
        let playPause = app.buttons["playPause"]
        moon.tap()
        playPause.tap()
        XCTAssertEqual(playPause.label, "Play")
        let frozen = moon.value as? String
        sleep(8) // longer than the 4 s fade delay
        XCTAssertEqual(moon.value as? String, frozen, "countdown frozen while paused")
        XCTAssertEqual(gain(app), 1.0, accuracy: 0.001)
        playPause.tap()
        XCTAssertTrue(waitUntil(15) { (moon.value as? String ?? "").contains("Fading") }, "countdown resumes after play")
    }
}
