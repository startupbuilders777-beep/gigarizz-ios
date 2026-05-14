@testable import GigaRizz
import XCTest

// MARK: - ProfileKit + ProfileAuditResult Tests

final class ProfileKitTests: XCTestCase {

    // MARK: - PhotoArchetype

    func testPhotoArchetype_allCasesHaveDisplayName() {
        for archetype in PhotoArchetype.allCases {
            XCTAssertFalse(archetype.displayName.isEmpty)
            XCTAssertFalse(archetype.systemImage.isEmpty)
            XCTAssertGreaterThanOrEqual(archetype.whyItMatters.count, 30,
                "\(archetype) should have a substantive 'why it matters' explanation")
        }
    }

    func testPhotoArchetype_rawValuesAreSnakeCase() {
        XCTAssertEqual(PhotoArchetype.firstPhoto.rawValue, "first_photo")
        XCTAssertEqual(PhotoArchetype.casualCandid.rawValue, "casual_candid")
        XCTAssertEqual(PhotoArchetype.travelLifestyle.rawValue, "travel_lifestyle")
    }

    // MARK: - Upgrade goals

    func testUpgradeGoal_flowCasesStayFocusedOnProfileUpgrade() {
        XCTAssertFalse(UpgradeGoal.upgradeFlowCases.contains(.betterOpeners),
                       "Coach-only goals should live in the Coach tab, not the photo audit funnel")
        XCTAssertTrue(UpgradeGoal.upgradeFlowCases.contains(.moreMatches))
        XCTAssertTrue(UpgradeGoal.upgradeFlowCases.contains(.betterFirstPhoto))
    }

    // MARK: - ProfileAuditResult round-trip

    func testProfileAuditResult_decodesFromBackendJSON() throws {
        let json = """
        {
          "overall_score": 68,
          "summary": "Solid base.",
          "best_photo_index": 0,
          "weakest_photo_index": 2,
          "missing_archetypes": ["travel_lifestyle", "hobby_activity"],
          "top_fixes": [
            {"title": "Add a hobby photo",
             "detail": "No activity shot — generate one in your sport.",
             "target_archetype": "hobby_activity",
             "suggested_style": "adventure"}
          ],
          "per_photo": [
            {"photo_url": "https://x/p1.jpg", "photo_index": 0,
             "clarity": 8, "lighting": 7, "expression": 9,
             "crop": 8, "authenticity": 9, "platform_fit": 8, "overall": 8,
             "archetype": "first_photo",
             "issues": [], "strengths": ["clear face"]}
          ],
          "target_platforms": ["hinge", "tinder"],
          "created_at": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let audit = try decoder.decode(ProfileAuditResult.self, from: json)

        XCTAssertEqual(audit.overallScore, 68)
        XCTAssertEqual(audit.bestPhotoIndex, 0)
        XCTAssertEqual(audit.weakestPhotoIndex, 2)
        XCTAssertEqual(audit.missingArchetypes, [.travelLifestyle, .hobbyActivity])
        XCTAssertEqual(audit.topFixes.first?.title, "Add a hobby photo")
        XCTAssertEqual(audit.topFixes.first?.targetArchetype, .hobbyActivity)
        XCTAssertEqual(audit.perPhoto.first?.archetype, .firstPhoto)
        XCTAssertEqual(audit.perPhoto.first?.platformFit, 8)
        XCTAssertEqual(audit.targetPlatforms, ["hinge", "tinder"])
    }

    func testProfileAuditResult_mockProvidesCompleteDiagnosisShape() {
        let audit = ProfileAuditResult.mock(
            photoUrls: ["file:///one.jpg", "file:///two.jpg", "file:///three.jpg"],
            targetPlatforms: [.hinge, .tinder]
        )

        XCTAssertEqual(audit.perPhoto.count, 3)
        XCTAssertEqual(audit.targetPlatforms, ["hinge", "tinder"])
        XCTAssertFalse(audit.summary.isEmpty)
        XCTAssertEqual(audit.topFixes.count, 3)
        XCTAssertFalse(audit.missingArchetypes.isEmpty)
    }

    @MainActor
    func testUpgradeFlow_requiresThreePhotosForAudit() {
        let viewModel = UpgradeFlowViewModel()
        XCTAssertEqual(viewModel.minimumAuditPhotos, 3)
        XCTAssertFalse(viewModel.canStartAudit)
    }

    // MARK: - ProfileKit defaults

    func testProfileKit_emptyHasUUIDAndTimestamps() {
        let kit = ProfileKit.empty(userId: "u1")
        XCTAssertEqual(kit.userId, "u1")
        XCTAssertFalse(kit.id.isEmpty)
        XCTAssertNil(kit.audit)
        XCTAssertEqual(kit.totalPhotos, 0)
        XCTAssertFalse(kit.hasAudit)
    }

    @MainActor
    func testProfileKitStore_persistsAndRestores() throws {
        let suiteName = "com.gigarizz.profilekit.test"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ProfileKitStore(defaults: defaults)
        let kit = store.startNewKit(userId: "u-123")
        XCTAssertNotNil(store.current)
        XCTAssertEqual(store.current?.userId, "u-123")

        store.setTargetPlatforms([.hinge, .tinder])
        XCTAssertEqual(store.current?.targetPlatforms, [.hinge, .tinder])

        // Re-instantiate to confirm persistence survived
        let store2 = ProfileKitStore(defaults: defaults)
        XCTAssertEqual(store2.current?.id, kit.id)
        XCTAssertEqual(store2.current?.targetPlatforms, [.hinge, .tinder])
    }

    @MainActor
    func testProfileKitStore_seedStarterCopyFillsEmptyKit() {
        let suiteName = "com.gigarizz.profilekit.seed.test"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ProfileKitStore(defaults: defaults)
        _ = store.startNewKit(userId: "u-123")
        store.setTargetPlatforms([.hinge])
        let audit = ProfileAuditResult.mock(photoUrls: ["file:///one.jpg", "file:///two.jpg", "file:///three.jpg"], targetPlatforms: [.hinge])

        store.seedStarterCopyIfNeeded(from: audit)

        XCTAssertFalse(store.current?.bio?.isEmpty ?? true)
        XCTAssertEqual(store.current?.prompts.count, 3)
        XCTAssertEqual(store.current?.openers.count, 3)
    }
}
