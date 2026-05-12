@testable import GigaRizz
import XCTest

final class ProfileKitOrdererTests: XCTestCase {

    // MARK: - slotCount + suggestedSlots

    func testSlotCount_perPlatform() {
        XCTAssertEqual(ProfileKitOrderer.slotCount(for: .hinge), 6)
        XCTAssertEqual(ProfileKitOrderer.slotCount(for: .tinder), 9)
        XCTAssertEqual(ProfileKitOrderer.slotCount(for: .bumble), 6)
        XCTAssertEqual(ProfileKitOrderer.slotCount(for: .raya), 5)
    }

    func testSuggestedSlots_alwaysStartWithFirstPhoto() {
        for platform in DatingPlatform.allCases {
            let slots = ProfileKitOrderer.suggestedSlots(for: platform)
            XCTAssertEqual(slots.first, .firstPhoto, "\(platform) suggested slots should lead with firstPhoto")
            XCTAssertGreaterThan(slots.count, 0)
        }
    }

    // MARK: - pickAndOrder

    func testPickAndOrder_promotesFirstPhotoArchetypeToTop() {
        let candidates = [
            OrderedPhoto(url: "u-candid-9",   archetype: .casualCandid, overallScore: 9),
            OrderedPhoto(url: "u-first-5",    archetype: .firstPhoto,   overallScore: 5),
            OrderedPhoto(url: "u-travel-7",   archetype: .travelLifestyle, overallScore: 7),
        ]
        let ordered = ProfileKitOrderer.pickAndOrder(candidates: candidates, limit: 6)
        XCTAssertEqual(ordered.first?.url, "u-first-5",
                       "A photo tagged firstPhoto must lead even if a higher-scoring photo exists")
    }

    func testPickAndOrder_neverPicksSocialProofAsFirst() {
        let candidates = [
            OrderedPhoto(url: "social",  archetype: .socialProof,  overallScore: 9),
            OrderedPhoto(url: "candid",  archetype: .casualCandid, overallScore: 7),
            OrderedPhoto(url: "dressed", archetype: .dressedUp,    overallScore: 6),
        ]
        let ordered = ProfileKitOrderer.pickAndOrder(candidates: candidates, limit: 6)
        XCTAssertNotEqual(ordered.first?.url, "social",
                          "Group / social_proof photos must never be the first photo")
    }

    func testPickAndOrder_prefersArchetypeVarietyAfterFirst() {
        let candidates = [
            OrderedPhoto(url: "first",     archetype: .firstPhoto,    overallScore: 9),
            OrderedPhoto(url: "candid-1",  archetype: .casualCandid,  overallScore: 8),
            OrderedPhoto(url: "candid-2",  archetype: .casualCandid,  overallScore: 7),
            OrderedPhoto(url: "travel",    archetype: .travelLifestyle, overallScore: 6),
        ]
        let ordered = ProfileKitOrderer.pickAndOrder(candidates: candidates, limit: 4)
        // Slot 1: first photo. Slot 2 should be highest unique archetype (candid-1).
        // Slot 3 should jump to a different archetype (travel) before adding the dup candid-2.
        XCTAssertEqual(ordered.map(\.url), ["first", "candid-1", "travel", "candid-2"])
    }

    func testPickAndOrder_respectsLimit() {
        let candidates = (0..<10).map {
            OrderedPhoto(url: "u-\($0)", archetype: nil, overallScore: 5)
        }
        let ordered = ProfileKitOrderer.pickAndOrder(candidates: candidates, limit: 6)
        XCTAssertEqual(ordered.count, 6)
    }

    // MARK: - order(for:audit:current:generated:)

    func testOrder_mergesCurrentAndGenerated() {
        let order = ProfileKitOrderer.order(
            for: .hinge,
            audit: nil,
            currentPhotoUrls: ["a", "b"],
            generatedPhotoUrls: ["c"]
        )
        XCTAssertEqual(order.platform, .hinge)
        XCTAssertEqual(order.photos.count, 3)
    }

    // MARK: - unfilledSlots

    func testUnfilledSlots_returnsOnlyMissingArchetypes() {
        let audit = ProfileAuditResult(
            overallScore: 70,
            summary: "",
            bestPhotoIndex: 0,
            weakestPhotoIndex: 0,
            missingArchetypes: [],
            topFixes: [],
            perPhoto: [
                PhotoCritique(
                    photoUrl: "p1", photoIndex: 0,
                    clarity: 8, lighting: 8, expression: 8, crop: 8, authenticity: 8, platformFit: 8, overall: 8,
                    archetype: .firstPhoto, issues: [], strengths: []
                )
            ],
            targetPlatforms: ["hinge"],
            createdAt: nil
        )
        let unfilled = ProfileKitOrderer.unfilledSlots(for: .hinge, audit: audit)
        XCTAssertFalse(unfilled.contains(.firstPhoto))
        XCTAssertTrue(unfilled.contains(.fullBody))
    }
}
