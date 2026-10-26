import XCTest

/// First launch: the intro leads to the show picker, and picked shows land in the Library.
/// Also: + in search adds a show in one tap, and search remembers its last query.
@MainActor
final class FirstRunUITests: XCTestCase {
    func testIntroThenPickShows() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-firstRun", "-theme", "almanac"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Step 2 of 3"].waitForExistence(timeout: 5), "installing counts as step 1")
        app.buttons["onboardingNext"].tap()
        XCTAssertTrue(app.staticTexts["Select your 10 podcasts of interest"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["addPicked"].isEnabled, "nothing picked yet")
        let tile = app.buttons.matching(identifier: "pickShow").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()
        XCTAssertTrue(app.staticTexts["1 of 10 picked"].waitForExistence(timeout: 5))
        app.buttons["addPicked"].tap()

        XCTAssertTrue(waitUntil(5) { !app.staticTexts["Select your 10 podcasts of interest"].exists })
        XCTAssertTrue(app.buttons["New"].waitForExistence(timeout: 5), "Home opens with shows, so the page tabs show")
    }

    func testPlusAddsFromSearchAndQueryIsRemembered() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "almanac"]
        app.launch()

        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        let add = app.buttons["addShow"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        XCTAssertTrue(waitUntil(5) { !app.buttons["addShow"].exists }, "+ goes away once the show is in the Library")

        app.terminate()
        app.launchArguments = ["-uitest", "-theme", "almanac"]
        app.launch()
        let search = app.buttons["librarySearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        XCTAssertTrue(waitUntil(5) { app.textFields["searchField"].value as? String == "quiet" }, "search remembers the last query")
    }
}
