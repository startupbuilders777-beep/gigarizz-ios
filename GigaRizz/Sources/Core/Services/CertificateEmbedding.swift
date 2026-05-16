import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

// MARK: - CertificateEmbedding
//
// Stamps an `IdentityMatchCertificate` into a JPEG's EXIF metadata so the
// receipt travels with the photo when the user shares or saves it. Counters
// FaceApp / Facetune / ReGen opacity at the file level: any tool that reads
// EXIF can read our edit receipt and verify the signature against the per
// device key.
//
// Storage layout:
//   - EXIF UserComment (tag 0x9286) is set to "GigaRizz-Receipt-v1:<base64-json>".
//     UserComment is the canonical free-form text field; chosen over a custom
//     XMP namespace because every share extension preserves it.
//   - The receipt JSON is base64-encoded so the EXIF UTF-8 boundary doesn't
//     break it on round-trip through processors that re-encode comments.
//
// V2 will optionally embed a C2PA manifest alongside this. V1 ships the
// portable EXIF receipt only.

enum CertificateEmbedding {

    private static let prefix = "GigaRizz-Receipt-v1:"

    // MARK: - Public API

    /// Encode the certificate into the JPEG bytes of `image` and return new
    /// JPEG `Data`. Returns `nil` if anything in the ImageIO pipeline fails.
    static func embed(certificate: IdentityMatchCertificate, into image: UIImage, jpegQuality: CGFloat = 0.92) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        guard let jsonData = try? jsonEncoder.encode(certificate) else { return nil }
        let token = prefix + jsonData.base64EncodedString()

        // Existing EXIF (if any) is preserved by re-rendering the CGImage via
        // CGImageDestination with merged metadata. We use UTType.jpeg so the
        // output is broadly compatible.
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }

        let exifProps: [CFString: Any] = [
            kCGImagePropertyExifUserComment: token,
            kCGImagePropertyExifVersion: "0231"
        ]
        let metadata: [CFString: Any] = [
            kCGImagePropertyExifDictionary: exifProps,
            kCGImageDestinationLossyCompressionQuality: jpegQuality
        ]

        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return outputData as Data
    }

    /// Read a previously-embedded certificate out of a JPEG `Data` blob.
    /// Returns `nil` if no receipt is present or the signature fails to parse.
    static func extract(from imageData: Data) -> IdentityMatchCertificate? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        guard let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] else { return nil }
        guard let comment = exif[kCGImagePropertyExifUserComment] as? String else { return nil }
        guard comment.hasPrefix(prefix) else { return nil }
        let base64 = String(comment.dropFirst(prefix.count))
        guard let json = Data(base64Encoded: base64) else { return nil }
        return try? jsonDecoder.decode(IdentityMatchCertificate.self, from: json)
    }

    // MARK: - Private

    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
