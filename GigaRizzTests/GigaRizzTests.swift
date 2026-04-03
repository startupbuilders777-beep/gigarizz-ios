@testable import GigaRizz
import XCTest

// MARK: - DesignSystem Tests

final class DesignSystemTests: XCTestCase {

    // MARK: - Colors

    func testColors_areValidHex() {
        // Verify all colors can be resolved (not nil)
        XCTAssertNotNil(DesignSystem.Colors.flameOrange)
        XCTAssertNotNil(DesignSystem.Colors.deepNight)
        XCTAssertNotNil(DesignSystem.Colors.background)
        XCTAssertNotNil(DesignSystem.Colors.goldAccent)
        XCTAssertNotNil(DesignSystem.Colors.surface)
        XCTAssertNotNil(DesignSystem.Colors.surfaceSecondary)
        XCTAssertNotNil(DesignSystem.Colors.textPrimary)
        XCTAssertNotNil(DesignSystem.Colors.textSecondary)
        XCTAssertNotNil(DesignSystem.Colors.success)
        XCTAssertNotNil(DesignSystem.Colors.warning)
        XCTAssertNotNil(DesignSystem.Colors.error)
    }

    func testPlatformColors_matchExpectedBrand() {
        XCTAssertNotNil(DesignSystem.Colors.tinder)
        XCTAssertNotNil(DesignSystem.Colors.hinge)
        XCTAssertNotNil(DesignSystem.Colors.bumble)
    }

    // MARK: - Typography

    func testTypography_allSizesReturnNonNilFont() {
        let fonts = [
            DesignSystem.Typography.largeTitle,
            DesignSystem.Typography.headline,
            DesignSystem.Typography.title,
            DesignSystem.Typography.body,
            DesignSystem.Typography.callout,
            DesignSystem.Typography.subheadline,
            DesignSystem.Typography.footnote,
            DesignSystem.Typography.caption,
            DesignSystem.Typography.button,
            DesignSystem.Typography.smallButton,
            DesignSystem.Typography.scoreDisplay,
            DesignSystem.Typography.scoreLarge
        ]
        fonts.forEach { XCTAssertNotNil($0) }
    }

    // MARK: - Spacing

    func testSpacing_valuesArePositive() {
        XCTAssertGreaterThan(DesignSystem.Spacing.micro, 0)
        XCTAssertGreaterThan(DesignSystem.Spacing.xs, 0)
        XCTAssertGreaterThan(DesignSystem.Spacing.s, 0)
        XCTAssertGreaterThan(DesignSystem.Spacing.m, 0)
        XCTAssertGreaterThan(DesignSystem.Spacing.l, 0)
        XCTAssertGreaterThan(DesignSystem.Spacing.xl, 0)
        XCTAssertGreaterThan(DesignSystem.Spacing.xxl, 0)
    }

    func testSpacing_hierarchy() {
        XCTAssertLessThan(DesignSystem.Spacing.micro, DesignSystem.Spacing.xs)
        XCTAssertLessThan(DesignSystem.Spacing.xs, DesignSystem.Spacing.s)
        XCTAssertLessThan(DesignSystem.Spacing.s, DesignSystem.Spacing.m)
        XCTAssertLessThan(DesignSystem.Spacing.m, DesignSystem.Spacing.l)
        XCTAssertLessThan(DesignSystem.Spacing.l, DesignSystem.Spacing.xl)
        XCTAssertLessThan(DesignSystem.Spacing.xl, DesignSystem.Spacing.xxl)
    }

    // MARK: - Corner Radius

    func testCornerRadius_valuesArePositive() {
        XCTAssertGreaterThan(DesignSystem.CornerRadius.small, 0)
        XCTAssertGreaterThan(DesignSystem.CornerRadius.medium, 0)
        XCTAssertGreaterThan(DesignSystem.CornerRadius.large, 0)
        XCTAssertGreaterThan(DesignSystem.CornerRadius.xlarge, 0)
    }

    func testCornerRadius_xlargeIsMaximum() {
        XCTAssertGreaterThan(
            DesignSystem.CornerRadius.xlarge,
            DesignSystem.CornerRadius.large
        )
        XCTAssertGreaterThan(
            DesignSystem.CornerRadius.large,
            DesignSystem.CornerRadius.medium
        )
    }
}

// MARK: - DatingPlatform Tests

final class DatingPlatformTests: XCTestCase {

    func testAllCases_haveValidRawValues() {
        for platform in DatingPlatform.allCases {
            XCTAssertFalse(platform.rawValue.isEmpty)
        }
    }

    func testAllCases_haveUniqueRawValues() {
        let rawValues = DatingPlatform.allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count)
    }

    func testAllCases_haveValidId() {
        for platform in DatingPlatform.allCases {
            XCTAssertEqual(platform.id, platform.rawValue)
        }
    }

    func testAllCases_haveIcon() {
        for platform in DatingPlatform.allCases {
            XCTAssertFalse(platform.icon.isEmpty)
        }
    }

    func testAllCases_haveColor() {
        for platform in DatingPlatform.allCases {
            XCTAssertNotNil(platform.color)
        }
    }

    func testAllCases_count() {
        XCTAssertEqual(DatingPlatform.allCases.count, 6)
    }
}

// MARK: - Match Tests

final class MatchTests: XCTestCase {

    func testMatch_initWithDefaults() {
        let match = Match(name: "Alice")
        XCTAssertEqual(match.name, "Alice")
        XCTAssertEqual(match.platform, .tinder)
        XCTAssertEqual(match.status, .new)
        XCTAssertEqual(match.notes, "")
        XCTAssertNil(match.lastMessageDate)
        XCTAssertNotNil(match.id)
    }

    func testMatch_initWithAllParams() {
        let date = Date()
        let match = Match(
            id: "test-id",
            name: "Bob",
            platform: .hinge,
            status: .active,
            notes: "Great conversation",
            lastMessageDate: date,
            matchedDate: date
        )
        XCTAssertEqual(match.id, "test-id")
        XCTAssertEqual(match.name, "Bob")
        XCTAssertEqual(match.platform, .hinge)
        XCTAssertEqual(match.status, .active)
        XCTAssertEqual(match.notes, "Great conversation")
        XCTAssertEqual(match.lastMessageDate, date)
    }

    func testDaysSinceLastMessage_returnsCorrectDays() {
        let calendar = Calendar.current
        let today = Date()
        guard let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) else {
            XCTFail("Failed to compute date"); return
        }

        let match = Match(name: "Test", lastMessageDate: threeDaysAgo)
        XCTAssertEqual(match.daysSinceLastMessage, 3)
    }

    func testIsStale_trueWhenMoreThan3Days() {
        let calendar = Calendar.current
        guard let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: Date()) else {
            XCTFail("Failed to compute date"); return
        }
        let match = Match(name: "Test", lastMessageDate: fourDaysAgo)
        XCTAssertTrue(match.isStale)
    }

    func testIsStale_falseWhenRecent() {
        let match = Match(name: "Test", lastMessageDate: Date())
        XCTAssertFalse(match.isStale)
    }

    func testIsStale_falseWhenNoMessage() {
        let match = Match(name: "Test", lastMessageDate: nil)
        XCTAssertFalse(match.isStale)
    }
}

// MARK: - RizzScore Tests

final class RizzScoreTests: XCTestCase {

    func testRizzScore_clampsToValidRange() {
        let score = RizzScore(
            overallScore: 150,
            categories: [],
            trend: .stable
        )
        XCTAssertEqual(score.overallScore, 100)
    }

    func testRizzScore_clampsNegativeToMinimum() {
        let score = RizzScore(
            overallScore: -10,
            categories: [],
            trend: .stable
        )
        XCTAssertEqual(score.overallScore, 1)
    }

    func testRizzScore_storesPreviousScore() {
        let score = RizzScore(
            overallScore: 75,
            categories: [],
            previousScore: 65,
            trend: .improving
        )
        XCTAssertEqual(score.previousScore, 65)
        XCTAssertEqual(score.trend, .improving)
    }

    func testRizzScore_demoIsValid() {
        let demo = RizzScore.demo
        XCTAssertGreaterThan(demo.overallScore, 0)
        XCTAssertLessThanOrEqual(demo.overallScore, 100)
        XCTAssertFalse(demo.categories.isEmpty)
    }

    func testRizzScoreCategory_clampScore() {
        let category = RizzScoreCategory(
            name: "Test",
            score: 200,
            weight: 0.5,
            icon: "star.fill"
        )
        XCTAssertEqual(category.score, 100)
    }

    func testRizzScoreCategory_negativeClamped() {
        let category = RizzScoreCategory(
            name: "Test",
            score: -50,
            weight: 0.5,
            icon: "star.fill"
        )
        XCTAssertEqual(category.score, 1)
    }
}
