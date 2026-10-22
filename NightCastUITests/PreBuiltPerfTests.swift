import XCTest

/// Performance measurements for the pre-built speed work (F-007 and the F-001 to F-004
/// fixes). Meant to run against a Release build on the `NightCast-prebuilt` simulator
/// after `scripts/prebuilt/seed_library.py` has seeded a populated library; see
/// `scripts/prebuilt/measure.sh`. Release builds ignore launch arguments, so these tests
/// pass none and depend on the seeded data.
///
/// Primary delta metric: CPU Instructions Retired (relative standard deviation is
/// about 0.2 percent), with CPU time and wall-clock duration recorded beside it.
@MainActor
final class PreBuiltPerfTests: XCTestCase {
    private let options: XCTMeasureOptions = {
        let o = XCTMeasureOptions()
        o.iterationCount = 5
        return o
    }()

    private func cpu(_ app: XCUIApplication) -> [XCTMetric] {
        [XCTCPUMetric(application: app), XCTClockMetric()]
    }

    /// F-001: cold launch with the populated library.
    func testColdLaunchPopulated() {
        continueAfterFailure = false
        let app = XCUIApplication()
        measure(metrics: [XCTApplicationLaunchMetric(), XCTCPUMetric(application: app), XCTMemoryMetric(application: app)], options: options) {
            app.launch()
        }
    }

    /// F-003 (and F-004): open a show from the Library, start an episode, close the
    /// player, and go back to the Library. The app is launched once, outside the
    /// measured block, so launch cost is not part of this number.
    func testOpenShowPlayAndReturn() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let tile = app.buttons["Seed Show 01, Seed Studio 1"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        measure(metrics: cpu(app), options: options) {
            tile.tap()
            let episode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Episode 149'")).firstMatch
            XCTAssertTrue(episode.waitForExistence(timeout: 10))
            episode.tap()
            let close = app.buttons["closePlayer"]
            XCTAssertTrue(close.waitForExistence(timeout: 10))
            close.tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(tile.waitForExistence(timeout: 10))
        }
    }

    /// F-004: render the Library grid (new-episode markers) by scrolling it.
    func testLibraryScrollRender() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Seed Show 02, Seed Studio 2"].waitForExistence(timeout: 10))
        measure(metrics: cpu(app), options: options) {
            for _ in 0..<3 { app.swipeUp(velocity: .fast) }
            for _ in 0..<3 { app.swipeDown(velocity: .fast) }
        }
    }

    /// F-002: library saves. Each Mark as Played / Unplayed writes library.json.
    /// Six toggles per iteration, an even number, so the library ends where it began.
    func testLibrarySaves() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let tile = app.buttons["Seed Show 03, Seed Studio 3"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()
        let episode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Episode 147'")).firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        func toggle() {
            episode.press(forDuration: 1.0)
            let item = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mark as'")).firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 5))
            item.tap()
        }
        toggle(); toggle() // steady state before measuring
        measure(metrics: cpu(app), options: options) {
            for _ in 0..<6 { toggle() }
        }
    }

    // MARK: Profiling scenarios
    // Plain tests (no XCTest measuring) that scripts/prebuilt/profile.sh runs five times
    // under Time Profiler, to attribute main-thread milliseconds to the code in a finding.

    func testProfileSaves() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let tile = app.buttons["Seed Show 03, Seed Studio 3"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()
        let episode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Episode 147'")).firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        for _ in 0..<12 {
            episode.press(forDuration: 1.0)
            let item = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mark as'")).firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 5))
            item.tap()
        }
    }

    func testProfileOpenShow() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let tile = app.buttons["Seed Show 01, Seed Studio 1"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        for _ in 0..<8 {
            tile.tap()
            let episode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Episode 149'")).firstMatch
            XCTAssertTrue(episode.waitForExistence(timeout: 10))
            episode.tap()
            let close = app.buttons["closePlayer"]
            XCTAssertTrue(close.waitForExistence(timeout: 10))
            close.tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(tile.waitForExistence(timeout: 10))
        }
    }

    func testProfileScroll() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Seed Show 02, Seed Studio 2"].waitForExistence(timeout: 10))
        for _ in 0..<8 {
            for _ in 0..<3 { app.swipeUp(velocity: .fast) }
            for _ in 0..<3 { app.swipeDown(velocity: .fast) }
        }
    }
}
