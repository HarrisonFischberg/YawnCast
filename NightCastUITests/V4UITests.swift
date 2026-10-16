import XCTest

/// v0.4: hideable mini player, collapsible Sleep bubble, Library layouts and
/// reordering, Explore search/interests/categories.
@MainActor
final class V4UITests: XCTestCase {
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "ink"]
        app.launch()
        return app
    }

    private func subscribeQuietHours(_ app: XCUIApplication) {
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        XCTAssertTrue(app.buttons["subscribeKey"].waitForExistence(timeout: 5))
        app.buttons["subscribeKey"].tap()
    }

    private func backToHome(_ app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let close = app.buttons["closeSearch"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
    }

    func testMiniPlayerAlwaysStaysOnScreen() {
        let app = launch()
        subscribeQuietHours(app)
        app.buttons["Fixture Episode 2"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" })
        app.buttons["closePlayer"].tap()

        let mini = app.buttons["miniPlayer"]
        XCTAssertTrue(mini.waitForExistence(timeout: 5))
        app.buttons["Pause"].firstMatch.tap()
        XCTAssertFalse(app.buttons["hideMiniPlayer"].exists, "no hide control any more")
        XCTAssertTrue(mini.exists, "stays while paused")

        // Still there while typing in search.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("q")
        XCTAssertTrue(mini.exists, "stays while typing")
        XCTAssertFalse(app.buttons["miniPlayerPill"].exists)
    }

    func testSwipeDownClosesNowPlaying() {
        let app = launch()
        subscribeQuietHours(app)
        app.buttons["Fixture Episode 3"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        // Drag from the open middle of the screen (above the scrubber).
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.32))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 420)))
        XCTAssertTrue(waitUntil(4) { !app.buttons["closePlayer"].exists }, "swipe down closed Now Playing")
        XCTAssertTrue(app.buttons["miniPlayer"].waitForExistence(timeout: 3), "back to the mini player")
    }

    func testSleepBubbleCollapsesAndReopens() {
        let app = launch()
        subscribeQuietHours(app)
        app.buttons["Fixture Episode 3"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" })
        app.buttons["moonKey"].tap()

        let countdown = app.buttons["sleepCountdown"]
        let pill = app.buttons["sleepBubbleCollapsed"]
        XCTAssertTrue(countdown.waitForExistence(timeout: 3))
        XCTAssertTrue(waitUntil(9) { pill.exists && !countdown.exists }, "tucks away after a few quiet seconds")
        pill.tap()
        XCTAssertTrue(countdown.waitForExistence(timeout: 3), "tap the pill for the full ±5 controls")
        countdown.tap()
        XCTAssertTrue(waitUntil(3) { pill.exists }, "tap the countdown to tuck it away")
    }

    func testLibraryLayoutsAndReorder() {
        let app = launch()
        subscribeQuietHours(app)
        backToHome(app)

        // Subscribe a second show from Explore → Browse → Fiction.
        app.buttons["pageDot-Explore"].tap()
        let fiction = app.buttons["category-Fiction"]
        XCTAssertTrue(fiction.waitForExistence(timeout: 8))
        fiction.tap()
        let rivers = app.buttons["Slow Rivers, Fixture Studio"]
        XCTAssertTrue(rivers.waitForExistence(timeout: 8))
        rivers.tap()
        app.buttons["subscribeKey"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["pageDot-Library"].tap()

        let quiet = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(quiet.waitForExistence(timeout: 5))
        XCTAssertLessThan(quiet.frame.minY + quiet.frame.minX, rivers.frame.minY + rivers.frame.minX, "Quiet Hours first")

        // Press, hold and drag Slow Rivers onto Quiet Hours → it takes the first slot.
        rivers.press(forDuration: 0.8, thenDragTo: quiet)
        XCTAssertTrue(waitUntil(5) { rivers.frame.minX < quiet.frame.minX || rivers.frame.minY < quiet.frame.minY }, "drag reordered")

        // Layouts: header key cycles Large → Small → List; Settings picks directly.
        let layoutKey = app.buttons["layoutKey"]
        let large = rivers.frame.width
        layoutKey.tap()
        XCTAssertTrue(waitUntil(3) { rivers.frame.width < large }, "small cards")
        layoutKey.tap()
        XCTAssertTrue(waitUntil(3) { rivers.frame.width > large }, "list rows span the width")
        layoutKey.tap()
        XCTAssertTrue(waitUntil(3) { abs(rivers.frame.width - large) < 1 }, "one click cycles back to large")

        // Themes: Scenes and Color Scapes, one tap applies.
        app.buttons["themesKey"].tap()
        let beach = app.buttons["theme-beach"]
        XCTAssertTrue(beach.waitForExistence(timeout: 3))
        for id in ["midnight", "mountain", "rainforest", "ocean", "city"] {
            XCTAssertTrue(app.buttons["theme-\(id)"].exists, id)
        }
        beach.tap()
        XCTAssertTrue(waitUntil(3) { beach.isSelected })
        // Color Scapes sit below the Scenes; scroll the sheet to reach them.
        let redLight = app.buttons["theme-redlight"]
        for _ in 0..<4 where !redLight.isHittable { app.swipeUp() }
        for id in ["paper", "ember", "ink", "redlight"] {
            XCTAssertTrue(app.buttons["theme-\(id)"].waitForExistence(timeout: 3), id)
        }
    }

    func testExploreSearchInterestsAndCategories() {
        let app = launch()
        subscribeQuietHours(app)
        backToHome(app)
        app.buttons["pageDot-Explore"].tap()

        XCTAssertTrue(app.buttons["interest-Fiction"].waitForExistence(timeout: 8), "interest from the saved show's genre")
        app.buttons["category-Comedy"].tap()
        XCTAssertTrue(app.buttons["Loud Laughs, Fixture Studio"].waitForExistence(timeout: 8), "category page lists its shows")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["exploreSearch"].tap()
        XCTAssertTrue(app.textFields["searchField"].waitForExistence(timeout: 5), "search from Explore")
    }
}
