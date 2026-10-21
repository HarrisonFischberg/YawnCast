import XCTest

/// The ±5 minute chip above the Moon key, and the show page's year sections.
@MainActor
final class SleepBubbleUITests: XCTestCase {
    private func openFixtureShow() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "almanac"]
        app.launch()
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        XCTAssertTrue(app.buttons["subscribeKey"].waitForExistence(timeout: 5))
        return app
    }

    func testBubbleAddsAndRemovesFiveMinutes() {
        let app = openFixtureShow()
        app.buttons["Fixture Episode 3"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" })

        let countdown = app.descendants(matching: .any)["sleepCountdown"]
        XCTAssertFalse(countdown.exists, "no chip before Sleep")
        app.buttons["moonKey"].tap()
        XCTAssertTrue(countdown.waitForExistence(timeout: 3), "chip appears with Sleep")
        // 90 s fixture episode → fade after about 45 s.
        XCTAssertTrue(countdown.label.hasPrefix("Fades in") && countdown.label.hasSuffix("sec"), countdown.label)

        app.buttons["sleepPlus5"].tap()
        XCTAssertTrue(waitUntil(3) { countdown.label.hasSuffix("min") }, "plus five: \(countdown.label)")
        app.buttons["sleepMinus5"].tap()
        XCTAssertTrue(waitUntil(3) { countdown.label.hasSuffix("sec") }, "minus five: \(countdown.label)")
        app.buttons["sleepMinus5"].tap()
        XCTAssertTrue(waitUntil(5) { countdown.label.hasPrefix("Fading") }, "fade starts now: \(countdown.label)")
        XCTAssertFalse(app.buttons["sleepMinus5"].isEnabled, "minus is off while fading")

        app.buttons["moonKey"].tap()
        XCTAssertTrue(waitUntil(3) { !countdown.exists }, "chip goes away with Sleep off")
    }

    func testEpisodesGroupedByYearWithOrderToggle() {
        let app = openFixtureShow()
        let year = Calendar.current.component(.year, from: Date())
        let header = app.descendants(matching: .any)["yearHeader"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertTrue(header.label.hasPrefix(String(year)), header.label)

        let order = app.buttons["episodeOrder"]
        XCTAssertTrue(order.label.contains("Newest first"))
        let rows = app.buttons.matching(identifier: "episodeRow")
        XCTAssertEqual(rows.element(boundBy: 0).label, "Fixture Episode 3")
        order.tap()
        XCTAssertTrue(waitUntil(3) { order.label.contains("Oldest first") })
        XCTAssertTrue(waitUntil(3) { rows.element(boundBy: 0).label == "Fixture Episode 1" }, "start to finish")
    }
}
