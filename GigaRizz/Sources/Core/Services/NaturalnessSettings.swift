import Foundation

// MARK: - NaturalnessSettings
//
// Single-source-of-truth for the V2 trust toggle. Defaults to ON because the
// "Better photos, not a fake person" position is the V2 differentiator —
// power users can flip off in Settings if they want a more aggressive look.
//
// Backed directly by UserDefaults so it's safe to read from any actor /
// off-main contexts (UserDefaults is thread-safe).

enum NaturalnessSettings {
    static let userDefaultsKey = "gigarizz_keep_me_natural"

    /// Returns true if the user has opted in to identity-preserving generation.
    /// First-launch default: on.
    static var keepMeNatural: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: userDefaultsKey) == nil {
            return true
        }
        return defaults.bool(forKey: userDefaultsKey)
    }

    static func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userDefaultsKey)
    }
}
