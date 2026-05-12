import Foundation

// MARK: - ProfileKitStore
//
// Local persistence for the user's V2 ProfileKit. Stored in UserDefaults
// for now; once backend POST /api/v1/profile-kit lands, this becomes
// a write-through cache in front of that endpoint.

@MainActor
final class ProfileKitStore: ObservableObject {
    static let shared = ProfileKitStore()

    @Published private(set) var current: ProfileKit?

    private let storageKey = "gigarizz_profile_kit_v2"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.current = Self.loadFromDefaults(defaults: defaults, key: storageKey)
    }

    func startNewKit(userId: String) -> ProfileKit {
        let kit = ProfileKit.empty(userId: userId)
        save(kit)
        return kit
    }

    func save(_ kit: ProfileKit) {
        var updated = kit
        updated.updatedAt = Date()
        current = updated
        persist(updated)
    }

    func clear() {
        current = nil
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: - Convenience mutators

    func updateAudit(_ audit: ProfileAuditResult) {
        guard var kit = current else { return }
        kit.audit = audit
        save(kit)
    }

    func setTargetPlatforms(_ platforms: [DatingPlatform]) {
        guard var kit = current else { return }
        kit.targetPlatforms = platforms
        save(kit)
    }

    func setPrimaryGoal(_ goal: UpgradeGoal) {
        guard var kit = current else { return }
        kit.primaryGoal = goal
        save(kit)
    }

    func setCurrentPhotos(_ urls: [String]) {
        guard var kit = current else { return }
        kit.currentPhotoUrls = urls
        save(kit)
    }

    func appendGeneratedPhoto(_ url: String) {
        guard var kit = current else { return }
        kit.generatedPhotoUrls.append(url)
        save(kit)
    }

    func setBio(_ bio: String?) {
        guard var kit = current else { return }
        kit.bio = bio
        save(kit)
    }

    // MARK: - Persistence

    private func persist(_ kit: ProfileKit) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(kit) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func loadFromDefaults(defaults: UserDefaults, key: String) -> ProfileKit? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ProfileKit.self, from: data)
    }
}
