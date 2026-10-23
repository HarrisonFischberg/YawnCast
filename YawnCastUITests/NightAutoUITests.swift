import XCTest

/// Night auto: a deliberate start between 22:00 and 04:59 turns Sleep on,
/// once per episode load. `-nightHour` fakes the local hour (Debug only).
@MainActor
final class NightAutoUITests: XCTestCase {
    private func startEpisode(hour: Int) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "midnight", "-nightHour", String(hour)]
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
        XCTAssertEqual(playPause.label, "Play", "a row tap opens Now Playing without playing")
        playPause.tap()
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" }, "playing")
        return app
    }

    private func moonValue(_ app: XCUIApplication) -> String {
        app.buttons["moonKey"].value as? String ?? ""
    }

    func testLateStartTurnsSleepOn() {
        let app = startEpisode(hour: 23)
        XCTAssertTrue(moonValue(app).hasPrefix("On. Fade begins in"), moonValue(app))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "night-auto-on"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testDaytimeStartLeavesSleepOff() {
        let app = startEpisode(hour: 14)
        XCTAssertEqual(moonValue(app), "Off")
    }

    func testTurningSleepOffSticksOnResume() {
        let app = startEpisode(hour: 23)
        let moon = app.buttons["moonKey"]
        XCTAssertTrue(moonValue(app).hasPrefix("On"), moonValue(app))
        moon.tap()
        XCTAssertTrue(waitUntil(3) { self.moonValue(app) == "Off" })
        let playPause = app.buttons["playPause"]
        playPause.tap()
        XCTAssertTrue(waitUntil(3) { playPause.label == "Play" })
        // Back to the show page and tap the same episode again (the deliberate resume path).
        app.buttons["closePlayer"].tap()
        let episode = app.buttons["Fixture Episode 3"]
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        episode.tap()
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        playPause.tap()
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" }, "playing again")
        sleep(1)
        XCTAssertEqual(moonValue(app), "Off", "resume does not re-arm Sleep")
    }
    /// Harold's case: paused, app closed, reopened late, played from the mini player.
    func testLatePlayFromMiniPlayerAfterRelaunchTurnsSleepOn() {
        var app = startEpisode(hour: 14)
        let playPause = app.buttons["playPause"]
        playPause.tap()
        XCTAssertTrue(waitUntil(3) { playPause.label == "Play" })
        app.terminate()

        app = XCUIApplication()
        app.launchArguments = ["-uitest", "-theme", "midnight", "-nightHour", "23"]
        app.launch()
        let miniPlay = app.buttons["miniPlayPause"]
        XCTAssertTrue(miniPlay.waitForExistence(timeout: 8), "mini player restored")
        XCTAssertEqual(miniPlay.label, "Play")
        miniPlay.tap()
        XCTAssertTrue(waitUntil(8) { miniPlay.label == "Pause" }, "playing")
        let moonKey = app.buttons["miniMoonKey"]
        XCTAssertTrue(waitUntil(3) { (moonKey.value as? String) == "On" }, "Sleep turned on from the mini player")
    }

    func testRowTapOpensPlayerWithoutPlayingOrSleep() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "midnight", "-nightHour", "23"]
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
        XCTAssertTrue(playPause.waitForExistence(timeout: 8), "Now Playing opened")
        sleep(1)
        XCTAssertEqual(playPause.label, "Play", "waits for Play")
        XCTAssertEqual(moonValue(app), "Off", "Sleep waits for Play too")
        playPause.tap()
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" })
        XCTAssertTrue(waitUntil(3) { self.moonValue(app).hasPrefix("On") }, moonValue(app))
    }
}
