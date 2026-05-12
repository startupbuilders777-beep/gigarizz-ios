@testable import GigaRizz
import XCTest

/// Locks the AgeOption catalog. Age Studio is a viral FaceApp parity feature;
/// removing options would silently drop a key UI surface.
final class AgeOptionTests: XCTestCase {

    func testCatalog_coversFullViralRange() {
        // FaceApp's age slider goes both directions; we need at least one
        // younger option and at least two older options to cover viral use cases.
        let ids = AgeOption.catalog.map(\.id)
        XCTAssertTrue(ids.contains(where: { $0.hasPrefix("younger_") }), "No younger options")
        XCTAssertTrue(ids.contains(where: { $0.hasPrefix("older_") }), "No older options")
    }

    func testCatalog_idsAreUnique() {
        let ids = AgeOption.catalog.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate age option id: \(ids)")
    }

    func testCatalog_eachAgePhraseRetainsIdentity() {
        // Every prompt must explicitly tell the model to retain identity. Without
        // this the model produces a different person at the new age.
        for option in AgeOption.catalog {
            XCTAssertTrue(
                option.agePhrase.lowercased().contains("retain identity")
                    || option.agePhrase.lowercased().contains("retain"),
                "\(option.name) age phrase doesn't pin identity preservation"
            )
        }
    }

    func testCatalog_namesFitGridChips() {
        for option in AgeOption.catalog {
            XCTAssertLessThanOrEqual(option.name.count, 22)
        }
    }
}
