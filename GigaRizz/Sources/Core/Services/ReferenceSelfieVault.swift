import Combine
import Foundation
import UIKit

// MARK: - ReferenceSelfieVault
//
// Local store for the user's baseline selfie. Stored in Application Support so
// it survives reinstalls done over an existing user account but is excluded
// from backups (URLResourceKey set on save).
//
// Why this exists: every Sprint 1+2 photo-aware surface (PhotoBriefStudio,
// FaceCheckPreflight, FaceRefineStudio, GlowUpStudio) needs a reference
// selfie to compute Identity Match. Without a vault, the user has to re-pick
// the same selfie every time. The vault is the back-end of "set my baseline
// once, every feature trusts it from there on."
//
// V1 scope: single reference selfie. V2 will support an album with auto-pick
// of best baseline (Reference Selfie Vault Sprint 4 stretch).

@MainActor
final class ReferenceSelfieVault: ObservableObject {
    static let shared = ReferenceSelfieVault()

    // MARK: - Published state

    @Published private(set) var currentSelfie: UIImage?
    @Published private(set) var lastUpdated: Date?

    // MARK: - Storage

    private let fileName = "reference_selfie.jpg"

    private var fileURL: URL? {
        guard let dir = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return dir.appendingPathComponent(fileName)
    }

    // MARK: - Init

    init() {
        loadFromDisk()
    }

    // MARK: - API

    /// Load the persisted selfie into memory. Cheap — runs on init.
    func loadFromDisk() {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        currentSelfie = image
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        lastUpdated = attrs?[.modificationDate] as? Date
    }

    /// Persist a new reference selfie. Replaces any existing one.
    func setSelfie(_ image: UIImage) {
        currentSelfie = image
        guard var url = fileURL,
              let data = image.jpegData(compressionQuality: 0.92) else { return }
        do {
            try data.write(to: url, options: .atomic)
            // Exclude from iCloud backups — selfie is regenerable from the
            // user's photo library if they ever lose it.
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
            lastUpdated = Date()
        } catch {
            // Non-fatal: in-memory state still updates so the session works.
        }
    }

    /// Forget the stored selfie.
    func clearSelfie() {
        currentSelfie = nil
        lastUpdated = nil
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// True if a selfie has been stored.
    var hasSelfie: Bool { currentSelfie != nil }
}
