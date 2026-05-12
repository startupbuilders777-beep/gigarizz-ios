import Foundation
import Photos
import UIKit

// MARK: - ProfileKitExporter
//
// Handles the three export actions a finished kit needs:
//   - copy bio / prompts to clipboard
//   - save photos to Photos
//   - share full kit via UIActivityViewController
//
// Exporting is the wedge. Without it the kit is just a gallery.

@MainActor
enum ProfileKitExporter {

    enum ExportError: LocalizedError {
        case photoLibraryDenied
        case photoDownloadFailed
        case noContent

        var errorDescription: String? {
            switch self {
            case .photoLibraryDenied:
                return "Photos access denied. Enable it in Settings → GigaRizz → Photos."
            case .photoDownloadFailed:
                return "Couldn't download one or more photos."
            case .noContent:
                return "Nothing to share yet — generate your kit first."
            }
        }
    }

    // MARK: - Clipboard

    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    /// Copy the full kit text payload (bio + prompts + openers) in one block.
    static func copyKitText(_ kit: ProfileKit) {
        UIPasteboard.general.string = kitTextBlock(kit)
    }

    /// Plain-text formatted kit, ready for pasting into Notes / Messages / etc.
    static func kitTextBlock(_ kit: ProfileKit) -> String {
        var out: [String] = []
        if let bio = kit.bio, !bio.isEmpty {
            out.append("BIO\n\(bio)")
        }
        if !kit.prompts.isEmpty {
            out.append("PROMPTS")
            for p in kit.prompts {
                out.append("• \(p.label)\n  \(p.content)")
            }
        }
        if !kit.openers.isEmpty {
            out.append("OPENERS")
            for o in kit.openers {
                out.append("• \(o)")
            }
        }
        return out.joined(separator: "\n\n")
    }

    // MARK: - Save photos

    /// Save a remote photo URL to the Photos library.
    static func savePhoto(remoteURL: URL) async throws {
        let status = await requestPhotoLibraryAuthorization()
        guard status == .authorized || status == .limited else {
            throw ExportError.photoLibraryDenied
        }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(from: remoteURL)
        } catch {
            throw ExportError.photoDownloadFailed
        }

        guard let image = UIImage(data: data) else {
            throw ExportError.photoDownloadFailed
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    /// Save many photos. Returns the count of successful saves.
    static func savePhotos(remoteURLs: [URL]) async -> Int {
        var saved = 0
        for url in remoteURLs {
            do {
                try await savePhoto(remoteURL: url)
                saved += 1
            } catch {
                continue
            }
        }
        return saved
    }

    // MARK: - Share sheet

    /// Build the activity item array for UIActivityViewController.
    /// Includes the kit text + any local image data the caller has already
    /// downloaded (URLs alone are passed through as-is).
    static func shareItems(_ kit: ProfileKit, includedImages: [UIImage] = []) -> [Any] {
        var items: [Any] = []
        let text = kitTextBlock(kit)
        if !text.isEmpty {
            items.append(text)
        }
        items.append(contentsOf: includedImages)
        return items
    }

    // MARK: - Auth helper

    private static func requestPhotoLibraryAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
