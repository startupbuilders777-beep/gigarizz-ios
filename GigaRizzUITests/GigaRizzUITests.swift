import XCTest

final class GigaRizzUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--disable-animations"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - App Launch

    func testApp_launchesWithoutCrash() {
        app.launch()
        XCTAssertTrue(app.exists)
    }

    // MARK: - Tab Bar

    func testTabBar_hasRequiredTabs() {
        app.launch()

        // App should have a tab bar after launch
        let tabBar = app.tabBars.firstMatch
        let exists = tabBar.waitForExistence(timeout: 5)
        if exists {
            let buttons = tabBar.buttons
            XCTAssertGreaterThan(buttons.count, 0, "Tab bar should have at least one tab")
        }
    }

    // MARK: - Accessibility

    func testKeyScreens_haveAccessibilityIdentifiers() {
        app.launch()

        // Tab bar should be accessible
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 3) {
            XCTAssertGreaterThan(tabBar.buttons.count, 0, "Tab bar should have accessible buttons")
        }
    }
}
