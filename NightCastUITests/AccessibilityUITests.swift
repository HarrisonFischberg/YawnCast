import XCTest

/// Accessibility checks that can run on the Simulator: Xcode's accessibility
/// audit on the main screens, spoken labels and values, and the layout at the
/// largest accessibility text size. Contrast is checked by `scripts/contrast.py`;
/// what still needs a real VoiceOver pass is listed in
/// `replica/design/accessibility-review-m2.md`.
@MainActor
final class AccessibilityUITests: XCTestCase {
    private func launch(extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "almanac"] + extra
        app.launch()
        return app
    }

    /// Search, open Quiet Hours and subscribe, so the home pages exist.
    private func subscribeToFixtureShow(_ app: XCUIApplication) {
        app.buttons["findPodcastKey"].tap()
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("quiet")
        let result = app.buttons["Quiet Hours, Fixture Studio"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        let subscribe = app.buttons["subscribeKey"]
        XCTAssertTrue(subscribe.waitForExistence(timeout: 5))
        subscribe.tap()
    }

    /// Show → Search → Home.
    private func backToHome(_ app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let close = app.buttons["closeSearch"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
    }

    private func openPlayer(_ app: XCUIApplication) -> XCUIElement {
        let episode = app.buttons["Fixture Episode 3"]
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        episode.tap()
        let playPause = app.buttons["playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8), "Now Playing opened")
        return playPause
    }

    /// Missing labels, wrong traits, and elements VoiceOver can't reach.
    /// Contrast is left to contrast.py (the audit can't see past animated scenes),
    /// and fixed-size glyphs are covered by the large-text test below.
    private func audit(_ app: XCUIApplication, _ screen: String) throws {
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .trait, .elementDetection]) { issue in
            XCTFail("\(screen): \(issue.compactDescription) — \(issue.element?.debugDescription ?? "no element")")
            return true
        }
    }

    func testAuditMainScreens() throws {
        let app = launch()
        try audit(app, "Empty Library")
        subscribeToFixtureShow(app)
        try audit(app, "Show")
        let playPause = openPlayer(app)
        try audit(app, "Now Playing")
        app.buttons["moonKey"].tap()
        XCTAssertTrue(app.buttons["sleepPlus5"].waitForExistence(timeout: 3))
        try audit(app, "Now Playing, Sleep on")
        app.buttons["moonKey"].tap()
        playPause.tap()
        app.buttons["closePlayer"].tap()
        backToHome(app)
        XCTAssertTrue(app.buttons["pageDot-Library"].waitForExistence(timeout: 5))
        try audit(app, "Library")
        app.buttons["themesKey"].tap()
        XCTAssertTrue(app.buttons["theme-almanac"].waitForExistence(timeout: 5))
        // At its 80% detent the sheet leaves Library's title and search field showing
        // above it, dimmed. VoiceOver correctly can't reach them behind the modal, but
        // the audit still sees that text and reports "Potentially inaccessible text" with
        // no element. Drag the grabber up to the large detent so only the sheet is audited.
        let title = app.staticTexts["Themes"]
        let grabber = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        grabber.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)))
        XCTAssertTrue(waitUntil(3) { title.frame.minY < app.frame.height * 0.2 }, "Themes sheet at large detent")
        try audit(app, "Themes")
    }

    func testEpisodeCountIsReadAsWords() {
        let app = launch()
        subscribeToFixtureShow(app)
        let header = app.descendants(matching: .any)["episodesHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.label, "3 episodes")
    }

    /// The mini player's moon glyph used to be the only sign that Sleep is on.
    func testMiniPlayerSaysWhenSleepIsOn() {
        let app = launch()
        subscribeToFixtureShow(app)
        _ = openPlayer(app)
        app.buttons["moonKey"].tap()
        app.buttons["closePlayer"].tap()
        let mini = app.buttons["miniPlayer"]
        XCTAssertTrue(mini.waitForExistence(timeout: 5))
        XCTAssertEqual(mini.label, "Now playing: Fixture Episode 3")
        XCTAssertEqual(mini.value as? String, "Quiet Hours, Sleep on")
        XCTAssertEqual(app.buttons["miniPlayPause"].label, "Pause")

        mini.tap()
        app.buttons["moonKey"].tap()
        app.buttons["closePlayer"].tap()
        XCTAssertTrue(waitUntil(3) { (mini.value as? String) == "Quiet Hours" }, "Sleep off: \(mini.value ?? "")")
    }

    /// At the largest accessibility size every Now Playing control stays on
    /// screen and tappable, and Themes drops to one column.
    func testLargestTextSizeKeepsControlsReachable() {
        let app = launch(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        subscribeToFixtureShow(app)
        _ = openPlayer(app)
        for id in ["closePlayer", "Back 15 seconds", "playPause", "Forward 15 seconds", "moonKey"] {
            let key = app.buttons[id]
            XCTAssertTrue(key.waitForExistence(timeout: 3), id)
            XCTAssertTrue(key.isHittable, "\(id) is off screen or covered")
        }
        XCTAssertTrue(app.descendants(matching: .any)["scrubber"].isHittable, "scrubber")
        app.buttons["closePlayer"].tap()
        backToHome(app)

        let themes = app.buttons["themesKey"]
        XCTAssertTrue(themes.waitForExistence(timeout: 5))
        themes.tap()
        let almanac = app.buttons["theme-almanac"]
        let boro = app.buttons["theme-boro"]
        XCTAssertTrue(almanac.waitForExistence(timeout: 5))
        XCTAssertTrue(boro.exists)
        XCTAssertEqual(almanac.frame.minX, boro.frame.minX, accuracy: 1, "one column")
        XCTAssertGreaterThan(boro.frame.minY, almanac.frame.maxY - 1, "stacked, not side by side")
    }
}
