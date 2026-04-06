import Foundation

/// Server-driven feature flags manager.
/// Fetches flags from the GigaRizz backend and caches locally.
/// Usage: `FeatureFlagManager.shared.isEnabled(.photoRanking)`
@MainActor
final class FeatureFlagManager: ObservableObject {
    static let shared = FeatureFlagManager()

    // MARK: - Feature Keys

    enum Feature: String, CaseIterable {
        case generation = "enable_generation"
        case coach = "enable_coach"
        case faceSwap = "enable_face_swap"
        case backgroundReplacer = "enable_background_replacer"
        case expressionCoach = "enable_expression_coach"
        case photoRanking = "enable_photo_ranking"
        case colorGrade = "enable_color_grade"
        case poseLibrary = "enable_pose_library"
        case introOffer = "enable_intro_offer"
        case batchGeneration = "enable_batch_generation"
        case premiumModels = "enable_premium_models"
        case photorealisticModels = "enable_photorealistic_models"
        case artisticModels = "enable_artistic_models"
        case promoBanner = "show_promo_banner"
    }

    // MARK: - Published State

    @Published private(set) var flags: FeatureFlags = .defaults
    @Published private(set) var lastFetched: Date?

    // MARK: - Flag Model

    struct FeatureFlags: Codable, Equatable {
        var enableGeneration: Bool
        var enableCoach: Bool
        var enableFaceSwap: Bool
        var enableBackgroundReplacer: Bool
        var enableExpressionCoach: Bool
        var enablePhotoRanking: Bool
        var enableColorGrade: Bool
        var enablePoseLibrary: Bool
        var enableIntroOffer: Bool
        var enableBatchGeneration: Bool
        var enablePremiumModels: Bool
        var enablePhotorealisticModels: Bool
        var enableArtisticModels: Bool
        var maxFreeGenerations: Int
        var maxPlusGenerations: Int
        var maxGoldGenerations: Int
        var maxBatchModels: Int
        var showPromoBanner: Bool
        var minAppVersion: String

        enum CodingKeys: String, CodingKey {
            case enableGeneration = "enable_generation"
            case enableCoach = "enable_coach"
            case enableFaceSwap = "enable_face_swap"
            case enableBackgroundReplacer = "enable_background_replacer"
            case enableExpressionCoach = "enable_expression_coach"
            case enablePhotoRanking = "enable_photo_ranking"
            case enableColorGrade = "enable_color_grade"
            case enablePoseLibrary = "enable_pose_library"
            case enableIntroOffer = "enable_intro_offer"
            case enableBatchGeneration = "enable_batch_generation"
            case enablePremiumModels = "enable_premium_models"
            case enablePhotorealisticModels = "enable_photorealistic_models"
            case enableArtisticModels = "enable_artistic_models"
            case maxFreeGenerations = "max_free_generations"
            case maxPlusGenerations = "max_plus_generations"
            case maxGoldGenerations = "max_gold_generations"
            case maxBatchModels = "max_batch_models"
            case showPromoBanner = "show_promo_banner"
            case minAppVersion = "min_app_version"
        }

        static let defaults = FeatureFlags(
            enableGeneration: true,
            enableCoach: true,
            enableFaceSwap: false,
            enableBackgroundReplacer: true,
            enableExpressionCoach: true,
            enablePhotoRanking: true,
            enableColorGrade: true,
            enablePoseLibrary: true,
            enableIntroOffer: true,
            enableBatchGeneration: true,
            enablePremiumModels: true,
            enablePhotorealisticModels: true,
            enableArtisticModels: true,
            maxFreeGenerations: 3,
            maxPlusGenerations: 30,
            maxGoldGenerations: 999,
            maxBatchModels: 4,
            showPromoBanner: false,
            minAppVersion: "1.0.0"
        )
    }

    // MARK: - Cache Keys

    private let cacheKey = "gigarizz_feature_flags"
    private let cacheDateKey = "gigarizz_feature_flags_date"

    // MARK: - Init

    init() {
        // Load cached flags on init
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(FeatureFlags.self, from: data) {
            self.flags = cached
            self.lastFetched = UserDefaults.standard.object(forKey: cacheDateKey) as? Date
        }
    }

    // MARK: - Public API

    /// Check if a feature is enabled.
    func isEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .generation: return flags.enableGeneration
        case .coach: return flags.enableCoach
        case .faceSwap: return flags.enableFaceSwap
        case .backgroundReplacer: return flags.enableBackgroundReplacer
        case .expressionCoach: return flags.enableExpressionCoach
        case .photoRanking: return flags.enablePhotoRanking
        case .colorGrade: return flags.enableColorGrade
        case .poseLibrary: return flags.enablePoseLibrary
        case .introOffer: return flags.enableIntroOffer
        case .batchGeneration: return flags.enableBatchGeneration
        case .premiumModels: return flags.enablePremiumModels
        case .photorealisticModels: return flags.enablePhotorealisticModels
        case .artisticModels: return flags.enableArtisticModels
        case .promoBanner: return flags.showPromoBanner
        }
    }

    /// Max generations allowed for a given tier.
    func maxGenerations(tier: String) -> Int {
        switch tier {
        case "gold": return flags.maxGoldGenerations
        case "plus": return flags.maxPlusGenerations
        default: return flags.maxFreeGenerations
        }
    }

    /// Max models allowed in a batch generation.
    var maxBatchModels: Int { flags.maxBatchModels }

    /// Fetch latest flags from server. Falls back to cache on failure.
    func refresh() async {
        do {
            let newFlags = try await GigaRizzAPIClient.shared.fetchFeatureFlags()
            self.flags = newFlags
            self.lastFetched = Date()

            // Cache to disk
            if let data = try? JSONEncoder().encode(newFlags) {
                UserDefaults.standard.set(data, forKey: cacheKey)
                UserDefaults.standard.set(Date(), forKey: cacheDateKey)
            }
        } catch {
            // Keep cached flags — don't crash
            #if DEBUG
            print("[FeatureFlags] Refresh failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Auto-refresh if stale (older than 1 hour).
    func refreshIfNeeded() async {
        if let last = lastFetched, Date().timeIntervalSince(last) < 3600 {
            return  // Fresh enough
        }
        await refresh()
    }
}
