import XCTest

/// First launch: the stepped intro ends in Search, and the first saved show gets a success sheet.
@MainActor
final class FirstRunUITests: XCTestCase {
    func testIntroThenFirstShowSuccess() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-firstRun", "-theme", "almanac"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Step 2 of 3"].waitForExistence(timeout: 5), "installing counts as step 1")
        app.buttons["onboardingNext"].tap()
        XCTAssertTrue(app.staticTexts["Step 3 of 3"].waitForExistence(timeout: 5))
        app.buttons["onboardingNext"].tap()

        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "the intro ends in Search, not an empty screen")
        field.typeText("quiet")
        app.buttons["Quiet Hours, Fixture Studio"].tap()
        let subscribe = app.buttons["subscribeKey"]
        XCTAssertTrue(subscribe.waitForExistence(timeout: 5))
        subscribe.tap()

        XCTAssertTrue(app.staticTexts["On your nightstand"].waitForExistence(timeout: 5))
        app.buttons["successAction"].tap()
        XCTAssertTrue(waitUntil(5) { !app.staticTexts["On your nightstand"].exists })
    }
}
