import Foundation
import UIKit

/// Uploads UIImage bytes to the GigaRizz backend's presigned-upload endpoint.
///
/// Flow:
///   1. POST /api/v1/uploads/presign   → { upload_url, public_url, key }
///   2. PUT  upload_url with JPEG bytes (Content-Type: image/jpeg)
///   3. Return public_url so callers can pass it to /api/v1/generate
///
/// The `public_url` is what AI providers (Replicate, fal.ai, OpenAI) fetch as the
/// source image, unlocking identity-preserving generation across InstantID,
/// Nano Banana 2, GPT Image 2, etc.
@MainActor
final class PhotoUploadService {
    static let shared = PhotoUploadService()

    /// Default JPEG quality for source uploads — 0.85 keeps file size <2MB while
    /// preserving enough detail for face-aware models.
    private let jpegQuality: CGFloat = 0.85

    /// Largest dimension we'll send. Most providers cap at 2048px and compress anyway,
    /// so a 1600px long edge is a healthy ceiling that keeps uploads fast on cellular.
    private let maxDimension: CGFloat = 1600

    enum UploadError: LocalizedError {
        case encodingFailed
        case uploadFailed(underlying: Error)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Couldn't prepare your photo for upload."
            case .uploadFailed(let error):
                return "Upload failed: \(error.localizedDescription)"
            case .invalidResponse:
                return "Server returned an invalid upload response."
            }
        }
    }

    /// Uploads `image` and returns the public URL to pass to the backend.
    /// `purpose` is one of "source" | "result" | "avatar".
    func upload(_ image: UIImage, purpose: String = "source") async throws -> URL {
        let resized = resize(image, longestEdge: maxDimension)
        guard let data = resized.jpegData(compressionQuality: jpegQuality) else {
            throw UploadError.encodingFailed
        }

        let presign: GigaRizzAPIClient.UploadPresignResponse
        do {
            presign = try await GigaRizzAPIClient.shared.requestPresignedUpload(
                contentType: "image/jpeg",
                purpose: purpose
            )
        } catch {
            throw UploadError.uploadFailed(underlying: error)
        }

        do {
            try await GigaRizzAPIClient.shared.putToPresignedURL(
                presign.uploadUrl,
                data: data,
                contentType: "image/jpeg"
            )
        } catch {
            throw UploadError.uploadFailed(underlying: error)
        }

        guard let publicURL = URL(string: presign.publicUrl) else {
            throw UploadError.invalidResponse
        }
        return publicURL
    }

    /// Best-effort upload that returns nil instead of throwing — useful when the
    /// caller wants to gracefully fall back to local-only generation paths.
    func tryUpload(_ image: UIImage, purpose: String = "source") async -> URL? {
        do { return try await upload(image, purpose: purpose) } catch { return nil }
    }

    // MARK: - Resize

    /// Internal so unit tests can verify the long-edge ceiling without bringing
    /// the whole upload round-trip into scope.
    internal func resize(_ image: UIImage, longestEdge: CGFloat) -> UIImage {
        let size = image.size
        let largest = max(size.width, size.height)
        guard largest > longestEdge else { return image }

        let scale = longestEdge / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
