import Foundation

// MARK: - NaturalnessSettings
//
// Single-source-of-truth for the V2 trust contract. The "Better photos, not a
// fake person" position is what distances GigaRizz from FaceApp + Facetune +
// every photo generator that drifts identity.
//
// V3 promotes the binary toggle to an intensity scale so users can choose
// how aggressive the generator is allowed to be — while the default stays
// conservative. The lever maps to backend prompt weighting and to the
// IdentityMatchService threshold used to gate generated photos.
//
// Backed by UserDefaults so it's thread-safe to read from any actor.

enum NaturalnessSettings {

    // MARK: - Storage Keys

    static let userDefaultsKey = "gigarizz_keep_me_natural"            // legacy bool
    static let intensityKey = "gigarizz_naturalness_intensity"         // 0–100

    // MARK: - Levels

    /// Three named intensity bands. Each maps to a default integer value, a
    /// backend prompt wrapper strength, and an IdentityMatchService threshold.
    enum Level: String, CaseIterable, Identifiable {
        case conservative // strong identity lock, subtle edits only — DEFAULT
        case standard     // balanced lift, still passes FaceCheck
        case bold         // higher creative ceiling, drift detector still active

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .conservative: return "Conservative"
            case .standard: return "Standard"
            case .bold: return "Bold"
            }
        }

        var subtitle: String {
            switch self {
            case .conservative: return "Subtle edits. Maximum identity preservation. Recommended."
            case .standard: return "Balanced upgrade. Most users start here once trust is established."
            case .bold: return "Stronger styling. Drift detector still rejects unrecognizable photos."
            }
        }

        var intensityValue: Int {
            switch self {
            case .conservative: return 25
            case .standard: return 55
            case .bold: return 85
            }
        }

        /// Identity-match similarity threshold below which a generated photo is rejected.
        var identityMatchThreshold: Double {
            switch self {
            case .conservative: return 0.80
            case .standard: return 0.70
            case .bold: return 0.55
            }
        }
    }

    // MARK: - Legacy Bool (kept for back-compat with existing call sites)

    /// Returns true if the user wants identity-preserving generation.
    /// Conservative + Standard both report true; Bold reports false to signal
    /// the more aggressive ceiling to legacy code paths.
    static var keepMeNatural: Bool {
        currentLevel != .bold
    }

    /// Persist the binary toggle (kept for Settings legacy switch).
    static func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userDefaultsKey)
        // Bridge into intensity if the slider value isn't already set.
        if UserDefaults.standard.object(forKey: intensityKey) == nil {
            setIntensity(value ? Level.conservative.intensityValue : Level.bold.intensityValue)
        }
    }

    // MARK: - Intensity (V3)

    /// Current intensity 0–100. Persisted; defaults to Conservative.
    static var intensity: Int {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: intensityKey) == nil {
            return Level.conservative.intensityValue
        }
        return min(100, max(0, defaults.integer(forKey: intensityKey)))
    }

    static func setIntensity(_ value: Int) {
        let clamped = min(100, max(0, value))
        UserDefaults.standard.set(clamped, forKey: intensityKey)
        // Keep the legacy bool aligned so anything still reading it sees a
        // value that matches the slider position.
        let mappedLevel = currentLevel(forIntensity: clamped)
        UserDefaults.standard.set(mappedLevel != .bold, forKey: userDefaultsKey)
    }

    /// Named band derived from the current intensity.
    static var currentLevel: Level { currentLevel(forIntensity: intensity) }

    static func currentLevel(forIntensity value: Int) -> Level {
        switch value {
        case ...40: return .conservative
        case 41...70: return .standard
        default: return .bold
        }
    }
}
