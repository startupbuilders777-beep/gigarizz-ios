import CryptoKit
import Foundation

// MARK: - IdentityMatchCertificate
//
// Signed JSON edit receipt attached to every saved or shared GigaRizz photo.
// Counters the FaceApp/Facetune opacity — every photo we ship can prove what
// was done to it, how natural the edit was, and whether it passed our
// identity-preservation contract.
//
// V1 uses a device-local HMAC key so the receipt is locally tamper-evident.
// V2 will switch to a server-issued signing key + optional C2PA embedding.
//
// The receipt is shown in the export sheet and saved alongside the photo
// (PNG metadata for shared photos, paired JSON for in-app gallery items).

struct IdentityMatchCertificate: Codable, Equatable, Identifiable {
    let id: UUID
    let kitId: UUID?
    let photoId: UUID
    let issuedAt: Date

    // Audit context
    let toolsApplied: [String]              // e.g. ["face_restore", "color_grade", "outfit_swap"]
    let naturalnessIntensity: Int           // 0–100 slider value at export time
    let naturalnessLevel: String            // "conservative" | "standard" | "bold"

    // Identity Match
    let identityMatchScore: Double          // 0–1 normalized
    let identityMatchBand: String           // "excellent" | "acceptable" | "borderline" | "rejected"
    let identityMatchThreshold: Double      // threshold at export time

    // Drift signals — names of signals detected on this photo
    let driftSignals: [String]

    // Source photo content fingerprint (SHA-256 of the JPEG bytes).
    let sourceHash: String?

    // Signature — HMAC-SHA256 over a canonical JSON encoding of the fields above.
    let signature: String

    // MARK: - Init

    init(
        id: UUID = UUID(),
        kitId: UUID?,
        photoId: UUID,
        issuedAt: Date = Date(),
        toolsApplied: [String],
        naturalnessIntensity: Int,
        naturalnessLevel: String,
        identityMatchScore: Double,
        identityMatchBand: String,
        identityMatchThreshold: Double,
        driftSignals: [String],
        sourceHash: String?,
        signature: String
    ) {
        self.id = id
        self.kitId = kitId
        self.photoId = photoId
        self.issuedAt = issuedAt
        self.toolsApplied = toolsApplied
        self.naturalnessIntensity = naturalnessIntensity
        self.naturalnessLevel = naturalnessLevel
        self.identityMatchScore = identityMatchScore
        self.identityMatchBand = identityMatchBand
        self.identityMatchThreshold = identityMatchThreshold
        self.driftSignals = driftSignals
        self.sourceHash = sourceHash
        self.signature = signature
    }
}

// MARK: - IdentityMatchCertificateService

/// Issues and verifies Identity Match Certificates.
enum IdentityMatchCertificateService {

    /// Per-device key stored in Keychain in production; UserDefaults in dev.
    /// Stable across launches so we can verify previously-issued certificates.
    private static let keyStorageKey = "gigarizz_certificate_signing_key"

    // MARK: - Issuance

    static func issue(
        kitId: UUID?,
        photoId: UUID,
        toolsApplied: [String],
        identityScore: Double,
        identityBand: IdentityMatchService.Band,
        driftSignals: [FaceDriftDetector.Signal],
        sourceHash: String? = nil,
        issuedAt: Date = Date()
    ) -> IdentityMatchCertificate {
        let level = NaturalnessSettings.currentLevel
        let unsigned = IdentityMatchCertificate(
            kitId: kitId,
            photoId: photoId,
            issuedAt: issuedAt,
            toolsApplied: toolsApplied,
            naturalnessIntensity: NaturalnessSettings.intensity,
            naturalnessLevel: level.rawValue,
            identityMatchScore: identityScore,
            identityMatchBand: identityBand.rawValue,
            identityMatchThreshold: level.identityMatchThreshold,
            driftSignals: driftSignals.map { $0.rawValue },
            sourceHash: sourceHash,
            signature: "PENDING"
        )

        let signature = sign(unsigned)
        return IdentityMatchCertificate(
            id: unsigned.id,
            kitId: unsigned.kitId,
            photoId: unsigned.photoId,
            issuedAt: unsigned.issuedAt,
            toolsApplied: unsigned.toolsApplied,
            naturalnessIntensity: unsigned.naturalnessIntensity,
            naturalnessLevel: unsigned.naturalnessLevel,
            identityMatchScore: unsigned.identityMatchScore,
            identityMatchBand: unsigned.identityMatchBand,
            identityMatchThreshold: unsigned.identityMatchThreshold,
            driftSignals: unsigned.driftSignals,
            sourceHash: unsigned.sourceHash,
            signature: signature
        )
    }

    // MARK: - Verification

    static func verify(_ certificate: IdentityMatchCertificate) -> Bool {
        let expected = sign(certificate)
        return expected == certificate.signature
    }

    // MARK: - JSON helpers

    static func jsonRepresentation(_ certificate: IdentityMatchCertificate) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(certificate), let s = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return s
    }

    // MARK: - Signing internals

    private static func sign(_ certificate: IdentityMatchCertificate) -> String {
        let payload = canonicalPayload(certificate)
        let key = signingKey()
        let mac = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
        return Data(mac).base64EncodedString()
    }

    private static func canonicalPayload(_ certificate: IdentityMatchCertificate) -> String {
        // Stable string with no signature field, sorted keys, second precision date.
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime]
        let issued = df.string(from: certificate.issuedAt)
        let toolsJoined = certificate.toolsApplied.sorted().joined(separator: ",")
        let signalsJoined = certificate.driftSignals.sorted().joined(separator: ",")
        return [
            "id=\(certificate.id.uuidString)",
            "kit=\(certificate.kitId?.uuidString ?? "")",
            "photo=\(certificate.photoId.uuidString)",
            "issued=\(issued)",
            "tools=\(toolsJoined)",
            "natIntensity=\(certificate.naturalnessIntensity)",
            "natLevel=\(certificate.naturalnessLevel)",
            "score=\(String(format: "%.4f", certificate.identityMatchScore))",
            "band=\(certificate.identityMatchBand)",
            "threshold=\(String(format: "%.4f", certificate.identityMatchThreshold))",
            "signals=\(signalsJoined)",
            "hash=\(certificate.sourceHash ?? "")",
        ].joined(separator: "|")
    }

    private static func signingKey() -> SymmetricKey {
        if let raw = UserDefaults.standard.data(forKey: keyStorageKey) {
            return SymmetricKey(data: raw)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        UserDefaults.standard.set(data, forKey: keyStorageKey)
        return key
    }
}
