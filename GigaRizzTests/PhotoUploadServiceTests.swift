@testable import GigaRizz
import UIKit
import XCTest

/// Tests for PhotoUploadService's local concerns — resize ceiling, bytes prep.
/// The full network round-trip is tested at the backend layer; these tests
/// guarantee we never accidentally upload a 4K source image and get rate-limited
/// or burn through the user's cellular budget.
@MainActor
final class PhotoUploadServiceTests: XCTestCase {

    func testResize_keepsImageBelowLongestEdge() {
        let huge = Self.makeImage(size: CGSize(width: 3200, height: 2400))
        let resized = PhotoUploadService.shared.resize(huge, longestEdge: 1600)
        XCTAssertLessThanOrEqual(max(resized.size.width, resized.size.height), 1600)
    }

    func testResize_preservesAspectRatio() {
        let portrait = Self.makeImage(size: CGSize(width: 1500, height: 3000))
        let resized = PhotoUploadService.shared.resize(portrait, longestEdge: 1600)

        let originalRatio = 1500.0 / 3000.0
        let newRatio = resized.size.width / resized.size.height
        XCTAssertEqual(originalRatio, newRatio, accuracy: 0.01, "Aspect ratio drifted on resize")
    }

    func testResize_preservesSmallImagesUntouched() {
        // An image already under the ceiling should pass through with no scaling.
        let small = Self.makeImage(size: CGSize(width: 800, height: 600))
        let resized = PhotoUploadService.shared.resize(small, longestEdge: 1600)
        XCTAssertEqual(resized.size, small.size)
    }

    func testResize_scalesPortraitTallSide() {
        // Tall portraits should be capped on the height dimension.
        let portrait = Self.makeImage(size: CGSize(width: 1000, height: 4000))
        let resized = PhotoUploadService.shared.resize(portrait, longestEdge: 1600)
        XCTAssertEqual(resized.size.height, 1600, accuracy: 1)
        XCTAssertLessThan(resized.size.width, 1600)
    }

    // MARK: - Helpers

    private static func makeImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
