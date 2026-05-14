@testable import GigaRizz
import XCTest

// MARK: - FeatureFlags Codable Tests

final class FeatureFlagsCodableTests: XCTestCase {

    // MARK: - JSON Encoding/Decoding

    func testDefaults_roundTrip() throws {
        let flags = FeatureFlagManager.FeatureFlags.defaults
        let data = try JSONEncoder().encode(flags)
        let decoded = try JSONDecoder().decode(FeatureFlagManager.FeatureFlags.self, from: data)
        XCTAssertEqual(flags, decoded)
    }

    func testDefaults_haveExpectedValues() {
        let flags = FeatureFlagManager.FeatureFlags.defaults
        XCTAssertTrue(flags.enableGeneration)
        XCTAssertTrue(flags.enableCoach)
        XCTAssertFalse(flags.enableFaceSwap)
        XCTAssertTrue(flags.enableBackgroundReplacer)
        XCTAssertTrue(flags.enableExpressionCoach)
        XCTAssertTrue(flags.enablePhotoRanking)
        XCTAssertTrue(flags.enableColorGrade)
        XCTAssertTrue(flags.enablePoseLibrary)
        XCTAssertTrue(flags.enableIntroOffer)
        XCTAssertEqual(flags.maxFreeGenerations, 3)
        XCTAssertEqual(flags.maxPlusGenerations, 30)
        XCTAssertEqual(flags.maxGoldGenerations, 999)
        XCTAssertFalse(flags.showPromoBanner)
        XCTAssertEqual(flags.minAppVersion, "1.0.0")
        XCTAssertTrue(flags.enableV2UpgradeFlow)
    }

    func testDecode_fromServerJSON() throws {
        let json = """
        {
            "enable_generation": false,
            "enable_coach": true,
            "enable_face_swap": true,
            "enable_background_replacer": false,
            "enable_expression_coach": true,
            "enable_photo_ranking": false,
            "enable_color_grade": true,
            "enable_pose_library": false,
            "enable_intro_offer": true,
            "enable_batch_generation": true,
            "enable_premium_models": true,
            "enable_photorealistic_models": true,
            "enable_artistic_models": true,
            "enable_face_enhance": true,
            "enable_outfit_studio": true,
            "enable_hairstyle": true,
            "enable_age_studio": true,
            "enable_pose_studio": true,
            "enable_hinge_overlay": true,
            "enable_nano_banana_2": true,
            "enable_gpt_image_2": true,
            "enable_instant_id": true,
            "paywall_mode": "hard",
            "soft_paywall_after_uses": 5,
            "onboarding_enabled": true,
            "onboarding_quiz_enabled": false,
            "onboarding_skip_enabled": true,
            "onboarding_max_steps": 30,
            "onboarding_show_social_proof": true,
            "onboarding_show_testimonials": true,
            "onboarding_show_video_demo": true,
            "enable_v2_upgrade_flow": true,
            "enable_audit_endpoint": true,
            "enable_screenshot_coach": true,
            "max_free_generations": 5,
            "max_plus_generations": 50,
            "max_gold_generations": 1000,
            "max_batch_models": 4,
            "show_promo_banner": true,
            "min_app_version": "2.0.0"
        }
        """.data(using: .utf8)!

        let flags = try JSONDecoder().decode(FeatureFlagManager.FeatureFlags.self, from: json)
        XCTAssertFalse(flags.enableGeneration)
        XCTAssertTrue(flags.enableCoach)
        XCTAssertTrue(flags.enableFaceSwap)
        XCTAssertFalse(flags.enableBackgroundReplacer)
        XCTAssertTrue(flags.enablePoseStudio)
        XCTAssertEqual(flags.paywallMode, "hard")
        XCTAssertEqual(flags.softPaywallAfterUses, 5)
        XCTAssertEqual(flags.onboardingMaxSteps, 30)
        XCTAssertFalse(flags.onboardingQuizEnabled)
        XCTAssertEqual(flags.maxFreeGenerations, 5)
        XCTAssertEqual(flags.maxPlusGenerations, 50)
        XCTAssertEqual(flags.maxGoldGenerations, 1000)
        XCTAssertEqual(flags.maxBatchModels, 4)
        XCTAssertTrue(flags.enableV2UpgradeFlow)
        XCTAssertTrue(flags.enableAuditEndpoint)
        XCTAssertTrue(flags.showPromoBanner)
        XCTAssertEqual(flags.minAppVersion, "2.0.0")
    }

    // MARK: - Feature Enum

    func testFeature_allCasesHaveRawValue() {
        for feature in FeatureFlagManager.Feature.allCases {
            XCTAssertFalse(feature.rawValue.isEmpty)
        }
    }

    func testFeature_caseCount() {
        // 14 core + 9 SOTA + 6 onboarding sub-flags + 2 V2 + 1 screenshotCoach = 32
        XCTAssertEqual(FeatureFlagManager.Feature.allCases.count, 32)
    }

    func testFeature_rawValuesAreSnakeCase() {
        for feature in FeatureFlagManager.Feature.allCases {
            XCTAssertTrue(feature.rawValue.contains("_"), "\(feature) raw value should use snake_case")
        }
    }

    // MARK: - isEnabled

    @MainActor
    func testIsEnabled_matchesDefaultFlags() {
        let manager = FeatureFlagManager()
        XCTAssertTrue(manager.isEnabled(.generation))
        XCTAssertTrue(manager.isEnabled(.coach))
        XCTAssertFalse(manager.isEnabled(.faceSwap))
        XCTAssertTrue(manager.isEnabled(.backgroundReplacer))
        XCTAssertTrue(manager.isEnabled(.expressionCoach))
        XCTAssertTrue(manager.isEnabled(.photoRanking))
        XCTAssertTrue(manager.isEnabled(.colorGrade))
        XCTAssertTrue(manager.isEnabled(.poseLibrary))
        XCTAssertTrue(manager.isEnabled(.introOffer))
        XCTAssertFalse(manager.isEnabled(.promoBanner))
        XCTAssertTrue(manager.isEnabled(.v2UpgradeFlow))
    }

    // MARK: - maxGenerations

    @MainActor
    func testMaxGenerations_tiers() {
        let manager = FeatureFlagManager()
        XCTAssertEqual(manager.maxGenerations(tier: "free"), 3)
        XCTAssertEqual(manager.maxGenerations(tier: "plus"), 30)
        XCTAssertEqual(manager.maxGenerations(tier: "gold"), 999)
    }

    @MainActor
    func testMaxGenerations_unknownTierReturnsFree() {
        let manager = FeatureFlagManager()
        XCTAssertEqual(manager.maxGenerations(tier: "unknown"), 3)
        XCTAssertEqual(manager.maxGenerations(tier: ""), 3)
    }
}
