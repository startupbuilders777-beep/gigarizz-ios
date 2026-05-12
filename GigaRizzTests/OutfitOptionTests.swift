@testable import GigaRizz
import XCTest

/// Locks the OutfitOption catalog so refactors can't silently drop wardrobe options.
final class OutfitOptionTests: XCTestCase {

    func testCatalog_hasMinimumViableSelection() {
        // Six is the floor below which the 3-column grid looks broken in the UI.
        XCTAssertGreaterThanOrEqual(OutfitOption.catalog.count, 6)
    }

    func testCatalog_idsAreUnique() {
        let ids = OutfitOption.catalog.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate outfit id in catalog: \(ids)")
    }

    func testCatalog_eachWardrobePhraseInstructsIdentityPreservation() {
        // Each wardrobe phrase must be specific (>= 30 chars) so Nano Banana 2 has
        // enough detail to render the outfit. Short phrases like "suit" produced
        // generic blurs in early prototypes.
        for outfit in OutfitOption.catalog {
            XCTAssertGreaterThanOrEqual(
                outfit.wardrobePhrase.count, 30,
                "\(outfit.name) wardrobe phrase too short — model needs more detail"
            )
        }
    }

    func testCatalog_namesAreShortEnoughForGridChips() {
        // 22 chars is roughly the 3-column grid label budget at default scale.
        for outfit in OutfitOption.catalog {
            XCTAssertLessThanOrEqual(outfit.name.count, 22, "\(outfit.name) too long for grid chip")
        }
    }
}
