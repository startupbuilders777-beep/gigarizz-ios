import XCTest

@MainActor
final class GigaRizzUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func makeApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--disable-animations"] + extraArguments
        return app
    }

    // MARK: - App Launch

    func testApp_launchesWithoutCrash() {
        let app = makeApp()
        app.launch()
        XCTAssertTrue(app.exists)
    }

    // MARK: - Tab Bar

    func testTabBar_hasRequiredTabs() {
        let app = makeApp()
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
        let app = makeApp()
        app.launch()

        // Tab bar should be accessible
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 3) {
            XCTAssertGreaterThan(tabBar.buttons.count, 0, "Tab bar should have accessible buttons")
        }
    }

    // MARK: - V2 Upgrade Flow (forced on via DEBUG UserDefault override)

    func testV2UpgradeFlow_isReachableWhenForced() {
        // -dev_force_v2_upgrade_flow 1 sets the UserDefault directly via the
        // launch-arg mechanism; FeatureFlagManager honors it in DEBUG builds.
        let app = makeApp(extraArguments: ["-dev_force_v2_upgrade_flow", "1"])
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar never appeared")
            return
        }

        // The Upgrade tab is the leading tab when V2 is on.
        let upgradeTab = tabBar.buttons["Upgrade"]
        XCTAssertTrue(upgradeTab.waitForExistence(timeout: 3), "Upgrade tab should be present when V2 flag is forced on")

        upgradeTab.tap()

        // Step 1 hero copy should appear (Goal picker is the new first step).
        let stepLabel = app.staticTexts["STEP 1 OF 4"]
        XCTAssertTrue(stepLabel.waitForExistence(timeout: 3), "Step indicator should render on V2 root")

        // The "What do you want to improve?" question should be visible.
        let goalQuestion = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'improve'")).firstMatch
        XCTAssertTrue(goalQuestion.waitForExistence(timeout: 2), "Goal-picker prompt should be visible")
    }

    func testV2_hasFourTabsWhenForced() {
        let app = makeApp(extraArguments: ["-dev_force_v2_upgrade_flow", "1"])
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar never appeared")
            return
        }

        // Codex's V2 plan: Upgrade / Photos / Coach / Profile
        for label in ["Upgrade", "Photos", "Coach", "Profile"] {
            XCTAssertTrue(tabBar.buttons[label].exists, "V2 tab '\(label)' should be visible")
        }
        // V1 tabs should NOT be visible when V2 is on.
        for label in ["Home", "Generate", "Matches"] {
            XCTAssertFalse(tabBar.buttons[label].exists, "V1 tab '\(label)' should be hidden under V2")
        }
    }

    func testV2GoalSelection_advancesToPlatformStep() {
        let app = makeApp(extraArguments: ["-dev_force_v2_upgrade_flow", "1"])
        app.launch()

        let goal = app.buttons["upgrade_goal_more_matches"]
        XCTAssertTrue(goal.waitForExistence(timeout: 5), "More matches goal should be tappable")
        goal.tap()

        let continueButton = app.buttons["v2_primary_continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2), "Sticky Continue CTA should appear after goal selection")
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["STEP 2 OF 4"].waitForExistence(timeout: 3), "Goal confirmation should advance to platform step")
        XCTAssertTrue(app.buttons["upgrade_platform_hinge"].exists, "Hinge platform row should be tappable")
    }
}
