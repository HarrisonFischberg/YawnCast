import XCTest

/// The three home pages (New · Library · Explore) and the always-present mini player.
@MainActor
final class HomePagesUITests: XCTestCase {
    private func launchAndSubscribe() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "almanac"]
        app.launch()
        XCTAssertFalse(app.buttons["pageDot-Library"].exists, "no pages before anything is subscribed")
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        let subscribe = app.buttons["subscribeKey"]
        XCTAssertTrue(subscribe.waitForExistence(timeout: 5))
        subscribe.tap()
        return app
    }

    private func backToHome(_ app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap() // Show → Search
        let close = app.buttons["closeSearch"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()                                           // Search → Home
    }

    func testPagesAppearAfterSubscribeAndSwipeBothWays() {
        let app = launchAndSubscribe()
        backToHome(app)

        let libraryDot = app.buttons["pageDot-Library"]
        XCTAssertTrue(libraryDot.waitForExistence(timeout: 5), "page dots appear once the Library has a show")
        XCTAssertTrue(libraryDot.isSelected, "Library is the middle, default page")
        let tile = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(tile.exists)

        // Swipe left → Explore: suggestions from the fixture Fiction chart, Library show excluded.
        tile.swipeLeft()
        XCTAssertTrue(waitUntil(5) { app.buttons["pageDot-Explore"].isSelected }, "swiped to Explore")
        XCTAssertTrue(app.staticTexts["Top picks for you"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Slow Rivers, Fixture Studio"].exists)
        XCTAssertTrue(app.buttons["Lantern Tales, Fixture Studio"].exists)
        XCTAssertFalse(app.buttons["Loud Laughs, Fixture Studio"].exists, "no shared genre → not suggested")
        XCTAssertTrue(app.buttons["Add Slow Rivers to Library"].exists, "Explore tiles have a quick-add +")

        // Swipe right twice → New: newest episodes, today first.
        app.swipeRight()
        XCTAssertTrue(waitUntil(5) { libraryDot.isSelected })
        app.swipeRight()
        XCTAssertTrue(waitUntil(5) { app.buttons["pageDot-New"].isSelected }, "swiped to New")
        let newest = app.buttons["Fixture Episode 3, Quiet Hours"]
        XCTAssertTrue(newest.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Today"].exists || app.staticTexts["TODAY"].exists)

        // Dots are tappable too.
        app.buttons["pageDot-Explore"].tap()
        XCTAssertTrue(waitUntil(5) { app.buttons["pageDot-Explore"].isSelected })
    }

    func testMiniPlayerStaysOnEveryScreenOncePlaying() {
        let app = launchAndSubscribe()
        let mini = app.buttons["miniPlayer"]
        XCTAssertFalse(mini.exists, "nothing playing yet")

        app.buttons["Fixture Episode 2"].tap()
        let close = app.buttons["closePlayer"]
        XCTAssertTrue(close.waitForExistence(timeout: 8))
        close.tap()

        XCTAssertTrue(mini.waitForExistence(timeout: 5), "on Show detail")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(mini.waitForExistence(timeout: 5), "on Search")
        app.buttons["closeSearch"].tap()
        XCTAssertTrue(mini.waitForExistence(timeout: 5), "on Library")
        app.buttons["pageDot-New"].tap()
        XCTAssertTrue(waitUntil(5) { mini.isHittable }, "on New")
        app.buttons["pageDot-Explore"].tap()
        XCTAssertTrue(waitUntil(5) { mini.isHittable }, "on Explore")

        // Still the episode we chose, and the mini player reopens the player.
        mini.tap()
        XCTAssertTrue(app.staticTexts["Fixture Episode 2"].waitForExistence(timeout: 5))
    }

    func testUnsubscribeFromLibraryContextMenu() {
        let app = launchAndSubscribe()
        backToHome(app)
        let tile = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.press(forDuration: 1.0)
        let unsubscribe = app.buttons["Unsubscribe"]
        XCTAssertTrue(unsubscribe.waitForExistence(timeout: 5))
        unsubscribe.tap()
        XCTAssertTrue(app.buttons["findPodcastKey"].waitForExistence(timeout: 5), "back to the empty Library")
        XCTAssertFalse(app.buttons["pageDot-Library"].exists, "pages hide when the Library is empty")

        // The toast offers a way back, and Undo restores the show and its pages.
        let undo = app.buttons["undoKey"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3), "Undo toast after unsubscribing")
        undo.tap()
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "show is back after Undo")
        XCTAssertTrue(app.buttons["pageDot-Library"].exists)
        XCTAssertTrue(waitUntil(3) { !undo.exists }, "toast leaves once used")
    }
}
