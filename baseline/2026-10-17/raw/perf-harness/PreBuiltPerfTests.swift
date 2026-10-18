import XCTest

final class PreBuiltPerfTests: XCTestCase {
    func testColdLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-resetStore", "-theme", "ink"]
        let opts = XCTMeasureOptions()
        opts.iterationCount = 5
        measure(metrics: [XCTApplicationLaunchMetric(), XCTMemoryMetric(application: app), XCTCPUMetric(application: app)], options: opts) {
            app.launch()
        }
    }
}
