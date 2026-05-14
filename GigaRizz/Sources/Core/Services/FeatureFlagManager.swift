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
        // SOTA features (iter 1-9)
        case faceEnhance = "enable_face_enhance"
        case outfitStudio = "enable_outfit_studio"
        case hairstyle = "enable_hairstyle"
        case ageStudio = "enable_age_studio"
        case poseStudio = "enable_pose_studio"
        case hingeOverlay = "enable_hinge_overlay"
        case nanoBanana2 = "enable_nano_banana_2"
        case gptImage2 = "enable_gpt_image_2"
        case instantID = "enable_instant_id"
        // Onboarding sub-flags
        case onboardingEnabled = "onboarding_enabled"
        case onboardingQuiz = "onboarding_quiz_enabled"
        case onboardingSkip = "onboarding_skip_enabled"
        case onboardingSocialProof = "onboarding_show_social_proof"
        case onboardingTestimonials = "onboarding_show_testimonials"
        case onboardingVideoDemo = "onboarding_show_video_demo"
        // V2 — Profile Upgrade flow (Codex V2 plan)
        case v2UpgradeFlow = "enable_v2_upgrade_flow"
        case auditEndpoint = "enable_audit_endpoint"
        case screenshotCoach = "enable_screenshot_coach"
    }

    /// Paywall presentation strategy — server-driven so we can A/B test.
    enum PaywallMode: String {
        case none, soft, hard
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
        // SOTA features
        var enableFaceEnhance: Bool
        var enableOutfitStudio: Bool
        var enableHairstyle: Bool
        var enableAgeStudio: Bool
        var enablePoseStudio: Bool
        var enableHingeOverlay: Bool
        var enableNanoBanana2: Bool
        var enableGptImage2: Bool
        var enableInstantID: Bool
        // Paywall + onboarding strategy
        var paywallMode: String
        var softPaywallAfterUses: Int
        var onboardingEnabled: Bool
        var onboardingQuizEnabled: Bool
        var onboardingSkipEnabled: Bool
        var onboardingMaxSteps: Int
        var onboardingShowSocialProof: Bool
        var onboardingShowTestimonials: Bool
        var onboardingShowVideoDemo: Bool
        // V2 — Profile Upgrade flow
        var enableV2UpgradeFlow: Bool
        var enableAuditEndpoint: Bool
        var enableScreenshotCoach: Bool
        // Quotas + misc
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
            case enableFaceEnhance = "enable_face_enhance"
            case enableOutfitStudio = "enable_outfit_studio"
            case enableHairstyle = "enable_hairstyle"
            case enableAgeStudio = "enable_age_studio"
            case enablePoseStudio = "enable_pose_studio"
            case enableHingeOverlay = "enable_hinge_overlay"
            case enableNanoBanana2 = "enable_nano_banana_2"
            case enableGptImage2 = "enable_gpt_image_2"
            case enableInstantID = "enable_instant_id"
            case paywallMode = "paywall_mode"
            case softPaywallAfterUses = "soft_paywall_after_uses"
            case onboardingEnabled = "onboarding_enabled"
            case onboardingQuizEnabled = "onboarding_quiz_enabled"
            case onboardingSkipEnabled = "onboarding_skip_enabled"
            case onboardingMaxSteps = "onboarding_max_steps"
            case onboardingShowSocialProof = "onboarding_show_social_proof"
            case onboardingShowTestimonials = "onboarding_show_testimonials"
            case onboardingShowVideoDemo = "onboarding_show_video_demo"
            case enableV2UpgradeFlow = "enable_v2_upgrade_flow"
            case enableAuditEndpoint = "enable_audit_endpoint"
            case enableScreenshotCoach = "enable_screenshot_coach"
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
            enableFaceEnhance: true,
            enableOutfitStudio: true,
            enableHairstyle: true,
            enableAgeStudio: true,
            enablePoseStudio: true,
            enableHingeOverlay: true,
            enableNanoBanana2: true,
            enableGptImage2: true,
            enableInstantID: true,
            paywallMode: "soft",
            softPaywallAfterUses: 3,
            onboardingEnabled: true,
            onboardingQuizEnabled: true,
            onboardingSkipEnabled: true,
            onboardingMaxSteps: 30,
            onboardingShowSocialProof: true,
            onboardingShowTestimonials: true,
            onboardingShowVideoDemo: true,
            enableV2UpgradeFlow: true,
            enableAuditEndpoint: true,
            enableScreenshotCoach: true,
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

    /// DEBUG-only override key for the V2 Upgrade flow. Lets internal builds
    /// preview the V2 experience without requiring the backend flag flip.
    /// In Release builds this key is never read.
    private static let v2PreviewOverrideKey = "dev_force_v2_upgrade_flow"

    /// Check if a feature is enabled.
    func isEnabled(_ feature: Feature) -> Bool {
        #if DEBUG
        if feature == .v2UpgradeFlow,
           UserDefaults.standard.bool(forKey: Self.v2PreviewOverrideKey) {
            return true
        }
        #endif
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
        case .faceEnhance: return flags.enableFaceEnhance
        case .outfitStudio: return flags.enableOutfitStudio
        case .hairstyle: return flags.enableHairstyle
        case .ageStudio: return flags.enableAgeStudio
        case .poseStudio: return flags.enablePoseStudio
        case .hingeOverlay: return flags.enableHingeOverlay
        case .nanoBanana2: return flags.enableNanoBanana2
        case .gptImage2: return flags.enableGptImage2
        case .instantID: return flags.enableInstantID
        case .onboardingEnabled: return flags.onboardingEnabled
        case .onboardingQuiz: return flags.onboardingQuizEnabled
        case .onboardingSkip: return flags.onboardingSkipEnabled
        case .onboardingSocialProof: return flags.onboardingShowSocialProof
        case .onboardingTestimonials: return flags.onboardingShowTestimonials
        case .onboardingVideoDemo: return flags.onboardingShowVideoDemo
        case .v2UpgradeFlow: return flags.enableV2UpgradeFlow
        case .auditEndpoint: return flags.enableAuditEndpoint
        case .screenshotCoach: return flags.enableScreenshotCoach
        }
    }

    /// Server-driven paywall mode.
    var paywallMode: PaywallMode {
        PaywallMode(rawValue: flags.paywallMode) ?? .soft
    }

    /// Soft paywall trigger count (Nth use that pops the dismissible paywall).
    var softPaywallAfterUses: Int { flags.softPaywallAfterUses }

    /// Onboarding step ceiling.
    var onboardingMaxSteps: Int { flags.onboardingMaxSteps }

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
