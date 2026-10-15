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

    func testMiniPlayerHidesWhenPausedAndReturnsOnPlay() {
        let app = launch()
        subscribeQuietHours(app)
        app.buttons["Fixture Episode 2"].tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(waitUntil(8) { playPause.label == "Pause" })
        app.buttons["closePlayer"].tap()

        let mini = app.buttons["miniPlayer"]
        let hide = app.buttons["hideMiniPlayer"]
        XCTAssertTrue(mini.waitForExistence(timeout: 5))
        XCTAssertFalse(hide.exists, "can't hide while playing")

        app.buttons["Pause"].firstMatch.tap()
        XCTAssertTrue(hide.waitForExistence(timeout: 3), "hide appears once paused")
        hide.tap()
        XCTAssertTrue(waitUntil(3) { !mini.exists }, "slid away")

        app.buttons["Fixture Episode 1"].tap()
        XCTAssertTrue(app.buttons["closePlayer"].waitForExistence(timeout: 8))
        app.buttons["closePlayer"].tap()
        XCTAssertTrue(mini.waitForExistence(timeout: 5), "back once something plays")
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
        for id in ["midnight", "mountain", "rainforest", "city"] {
            XCTAssertTrue(app.buttons["theme-\(id)"].exists, id)
        }
        beach.tap()
        XCTAssertTrue(waitUntil(3) { beach.isSelected })
        // Color Scapes sit below the Scenes; scroll the sheet to reach them.
        let ink = app.buttons["theme-ink"]
        for _ in 0..<3 where !ink.isHittable { app.swipeUp() }
        for id in ["paper", "ember", "ink"] {
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
