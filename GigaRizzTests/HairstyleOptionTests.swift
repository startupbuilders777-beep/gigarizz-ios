@testable import GigaRizz
import XCTest

/// Locks the HairstyleOption catalog. Hairstyle Picker is a marquee FaceApp parity feature;
/// dropping options here would silently ship a regressed UI to gold-tier users.
final class HairstyleOptionTests: XCTestCase {

    func testCatalog_hasMinimumViableSelection() {
        XCTAssertGreaterThanOrEqual(HairstyleOption.catalog.count, 6)
    }

    func testCatalog_idsAreUnique() {
        let ids = HairstyleOption.catalog.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate hairstyle id: \(ids)")
    }

    func testCatalog_eachHairPhraseInstructsIdentityPreservation() {
        for option in HairstyleOption.catalog {
            XCTAssertGreaterThanOrEqual(
                option.hairPhrase.count, 30,
                "\(option.name) hair phrase too short — model needs more detail"
            )
        }
    }

    func testCatalog_namesFitGridChips() {
        for option in HairstyleOption.catalog {
            XCTAssertLessThanOrEqual(option.name.count, 22)
        }
    }
}
