import XCTest

/// exp_night_auto: a deliberate start between 22:00 and 04:59 turns Sleep on,
/// once per episode load. `-nightHour` fakes the local hour (Debug only).
@MainActor
final class NightAutoUITests: XCTestCase {
    private func startEpisode(flag: Bool, hour: Int) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "midnight", "-nightHour", String(hour)]
        if flag { app.launchArguments += ["-exp_night_auto", "YES"] }
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

    private func moonValue(_ app: XCUIApplication) -> String {
        app.buttons["moonKey"].value as? String ?? ""
    }

    func testLateStartTurnsSleepOn() {
        let app = startEpisode(flag: true, hour: 23)
        XCTAssertTrue(moonValue(app).hasPrefix("On. Fade begins in"), moonValue(app))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "night-auto-on"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testDaytimeStartLeavesSleepOff() {
        let app = startEpisode(flag: true, hour: 14)
        XCTAssertEqual(moonValue(app), "Off")
    }

    func testFlagOffLeavesSleepOff() {
        let app = startEpisode(flag: false, hour: 23)
        XCTAssertEqual(moonValue(app), "Off")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "night-auto-off"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testTurningSleepOffSticksOnResume() {
        let app = startEpisode(flag: true, hour: 23)
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
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" }, "playing again")
        sleep(1)
        XCTAssertEqual(moonValue(app), "Off", "resume does not re-arm Sleep")
    }
}
