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

    func setPrompts(_ prompts: [PromptKitItem]) {
        guard var kit = current else { return }
        kit.prompts = prompts
        save(kit)
    }

    func setOpeners(_ openers: [String]) {
        guard var kit = current else { return }
        kit.openers = openers
        save(kit)
    }

    func seedStarterCopyIfNeeded(from audit: ProfileAuditResult) {
        guard var kit = current else { return }
        let platform = kit.targetPlatforms.first?.rawValue.lowercased() ?? "hinge"

        if kit.bio?.isEmpty ?? true {
            kit.bio = Self.starterBio(for: kit, audit: audit)
        }
        if kit.prompts.isEmpty {
            kit.prompts = Self.starterPrompts(platform: platform)
        }
        if kit.openers.isEmpty {
            kit.openers = Self.starterOpeners()
        }
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

    private static func starterBio(for kit: ProfileKit, audit: ProfileAuditResult) -> String {
        let platform = kit.targetPlatforms.first?.rawValue ?? "Hinge"
        if audit.overallScore >= 75 {
            return "Optimized for \(platform): clear photos, real-life energy, and enough personality to make starting the conversation easy."
        }
        return "Optimized for \(platform): a cleaner photo order, stronger first impression, and a profile that gives matches something easy to ask about."
    }

    private static func starterPrompts(platform: String) -> [PromptKitItem] {
        [
            PromptKitItem(
                platform: platform,
                label: "Together, we could",
                content: "Find the best spot in the city for dinner, then pretend we discovered it first."
            ),
            PromptKitItem(
                platform: platform,
                label: "My simple pleasures",
                content: "Good coffee, low-stakes walks, and plans that accidentally turn into a full day."
            ),
            PromptKitItem(
                platform: platform,
                label: "The way to win me over is",
                content: "Be curious, be kind, and have at least one hill you're willing to lightly defend."
            ),
        ]
    }

    private static func starterOpeners() -> [String] {
        [
            "Your profile has real main-character Sunday energy. What's the best part of your ideal weekend?",
            "You seem like you have good taste in plans. Coffee walk or dinner spot for a first date?",
            "I need the story behind one of these photos. Which one has the best backstory?",
        ]
    }
}
