@testable import GigaRizz
import XCTest

/// Locks AIModel.defaultModels to the backend MODEL_CATALOG.
/// When a new model lands on the backend, this test forces us to mirror it on iOS
/// — without parity the iOS picker silently shows fewer options than the API supports.
final class AIModelParityTests: XCTestCase {

    func testDefaultModels_count_matchesBackend() {
        // Backend MODEL_CATALOG has 20 models as of iter 2 (10 Replicate + 6 fal + 3 OpenAI + face_restore on Replicate).
        // If you add or remove models on the backend, update this assertion AND backend test_list_models.
        XCTAssertEqual(AIModel.defaultModels.count, 20, "iOS catalog drifted from backend MODEL_CATALOG")
    }

    func testDefaultModels_firstIsFreeFluxSchnell() {
        let first = AIModel.defaultModels.first
        XCTAssertEqual(first?.id, "flux_schnell")
        XCTAssertEqual(first?.tier, "free")
    }

    func testDefaultModels_containsSOTAAdditions() {
        let ids = Set(AIModel.defaultModels.map(\.id))
        XCTAssertTrue(ids.contains("nano_banana_2"), "Nano Banana 2 missing from iOS catalog")
        XCTAssertTrue(ids.contains("gpt_image_2"), "GPT Image 2 missing from iOS catalog")
        XCTAssertTrue(ids.contains("instant_id"), "InstantID missing from iOS catalog")
        XCTAssertTrue(ids.contains("face_restore"), "CodeFormer face_restore missing from iOS catalog")
    }

    func testDefaultModels_allCategoriesAreKnown() {
        let validCategories: Set<String> = ["fast", "balanced", "classic", "artistic", "premium", "photorealistic"]
        for model in AIModel.defaultModels {
            XCTAssertTrue(
                validCategories.contains(model.category),
                "Unknown category '\(model.category)' on model \(model.id)"
            )
        }
    }

    func testDefaultModels_allTiersAreKnown() {
        let validTiers: Set<String> = ["free", "plus", "gold"]
        for model in AIModel.defaultModels {
            XCTAssertTrue(
                validTiers.contains(model.tier),
                "Unknown tier '\(model.tier)' on model \(model.id)"
            )
        }
    }

    func testDefaultModels_allProvidersAreKnown() {
        let validProviders: Set<String> = ["replicate", "fal", "openai"]
        for model in AIModel.defaultModels {
            XCTAssertTrue(
                validProviders.contains(model.provider),
                "Unknown provider '\(model.provider)' on model \(model.id)"
            )
        }
    }

    func testDefaultModels_groupingPreservesAllModels() {
        let grouped = AIModel.grouped(AIModel.defaultModels)
        let totalAfterGroup = grouped.reduce(0) { $0 + $1.models.count }
        XCTAssertEqual(totalAfterGroup, AIModel.defaultModels.count, "grouped() lost or duplicated models")
    }

    func testDefaultModels_idsAreUnique() {
        let ids = AIModel.defaultModels.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Duplicate model id in defaultModels: \(ids)")
    }
}

/// Style preset coverage — Hinge templates are gold-tier and have prompts that
/// reference the overlay text, so a typo'd prompt would silently degrade GPT Image 2 output.
final class StylePresetTests: XCTestCase {

    func testHingePresets_arePresent() {
        let ids = Set(StylePreset.allPresets.map(\.id))
        XCTAssertTrue(ids.contains("hinge_prompt"))
        XCTAssertTrue(ids.contains("hinge_caption"))
        XCTAssertTrue(ids.contains("hinge_chemistry"))
    }

    func testHingePresets_areGoldTier() {
        let hingePresets = StylePreset.allPresets.filter { $0.id.hasPrefix("hinge_") }
        XCTAssertFalse(hingePresets.isEmpty)
        for preset in hingePresets {
            XCTAssertEqual(preset.tier, .gold, "\(preset.name) should be gold-tier")
        }
    }

    func testHingePresets_promptsContainOverlayText() {
        guard let prompt = StylePreset.allPresets.first(where: { $0.id == "hinge_prompt" }) else {
            return XCTFail("hinge_prompt preset missing")
        }
        XCTAssertTrue(prompt.prompt.contains("I'll fall for you if"), "Overlay text dropped from prompt")
    }
}
