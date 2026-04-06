import Foundation

// MARK: - AI Model

/// Available AI models for photo generation.
/// Synced with backend `AIModelChoice` enum — 16 models across 3 providers.
struct AIModel: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let provider: String
    let speed: String
    let quality: String
    let tier: String
    let category: String

    init(id: String, name: String, provider: String, speed: String, quality: String, tier: String, category: String = "classic") {
        self.id = id
        self.name = name
        self.provider = provider
        self.speed = speed
        self.quality = quality
        self.tier = tier
        self.category = category
    }

    var requiredTier: SubscriptionTier {
        switch tier {
        case "gold": return .gold
        case "plus": return .plus
        default: return .free
        }
    }

    var providerIcon: String {
        switch provider {
        case "fal": return "bolt.fill"
        case "openai": return "brain.fill"
        case "replicate": return "cpu.fill"
        default: return "sparkles"
        }
    }

    var providerLabel: String {
        switch provider {
        case "fal": return "fal.ai"
        case "openai": return "OpenAI"
        case "replicate": return "Replicate"
        default: return provider.capitalized
        }
    }

    var speedLabel: String {
        switch speed {
        case "fastest": return "Fastest"
        case "fast": return "Fast"
        case "medium": return "Medium"
        case "slow": return "Slow"
        default: return speed.capitalized
        }
    }

    var qualityLabel: String {
        switch quality {
        case "ultra": return "Ultra"
        case "best": return "Best"
        case "high": return "High"
        case "good": return "Good"
        default: return quality.capitalized
        }
    }

    var categoryLabel: String {
        switch category {
        case "fast": return "Fast"
        case "balanced": return "Balanced"
        case "classic": return "Classic"
        case "artistic": return "Artistic"
        case "premium": return "Premium"
        case "photorealistic": return "Photorealistic"
        default: return category.capitalized
        }
    }

    var categoryIcon: String {
        switch category {
        case "fast": return "hare.fill"
        case "balanced": return "scale.3d"
        case "classic": return "paintbrush.fill"
        case "artistic": return "paintpalette.fill"
        case "premium": return "crown.fill"
        case "photorealistic": return "camera.fill"
        default: return "sparkles"
        }
    }

    var isLocked: Bool {
        requiredTier != .free
    }

    /// Badge text shown on model card.
    var badge: String? {
        switch category {
        case "photorealistic": return "PHOTOREALISTIC"
        case "premium": return "PREMIUM"
        case "artistic": return "ARTISTIC"
        case "fast": return "FAST"
        default: return nil
        }
    }

    // MARK: - Defaults (used when backend isn't reachable)

    static let defaultModels: [AIModel] = [
        // Free tier
        AIModel(id: "flux_schnell", name: "Flux Schnell", provider: "replicate", speed: "fast", quality: "good", tier: "free", category: "fast"),
        AIModel(id: "sdxl", name: "SDXL", provider: "replicate", speed: "medium", quality: "good", tier: "free", category: "classic"),
        AIModel(id: "fal_flux_schnell", name: "Flux Schnell (fal)", provider: "fal", speed: "fastest", quality: "good", tier: "free", category: "fast"),
        AIModel(id: "fal_sdxl_lightning", name: "SDXL Lightning", provider: "fal", speed: "fastest", quality: "good", tier: "free", category: "fast"),
        // Plus tier
        AIModel(id: "flux_dev", name: "Flux Dev", provider: "replicate", speed: "medium", quality: "high", tier: "plus", category: "balanced"),
        AIModel(id: "sd3_medium", name: "SD3 Medium", provider: "replicate", speed: "medium", quality: "high", tier: "plus", category: "classic"),
        AIModel(id: "fal_flux_dev", name: "Flux Dev (fal)", provider: "fal", speed: "fast", quality: "high", tier: "plus", category: "balanced"),
        AIModel(id: "fal_recraft_v3", name: "Recraft V3", provider: "fal", speed: "fast", quality: "high", tier: "plus", category: "artistic"),
        AIModel(id: "dall_e_3", name: "DALL-E 3", provider: "openai", speed: "medium", quality: "high", tier: "plus", category: "classic"),
        AIModel(id: "playground_v3", name: "Playground v3", provider: "replicate", speed: "medium", quality: "high", tier: "plus", category: "artistic"),
        // Gold tier
        AIModel(id: "flux_1_1_pro", name: "Flux 1.1 Pro", provider: "replicate", speed: "medium", quality: "best", tier: "gold", category: "premium"),
        AIModel(id: "flux_1_1_pro_ultra", name: "Flux Pro Ultra", provider: "replicate", speed: "slow", quality: "ultra", tier: "gold", category: "premium"),
        AIModel(id: "fal_flux_pro", name: "Flux Pro (fal)", provider: "fal", speed: "fast", quality: "best", tier: "gold", category: "premium"),
        AIModel(id: "realvis_xl", name: "RealVisXL", provider: "replicate", speed: "medium", quality: "best", tier: "gold", category: "photorealistic"),
        AIModel(id: "ideogram_3", name: "Ideogram 3", provider: "replicate", speed: "medium", quality: "best", tier: "gold", category: "photorealistic"),
        AIModel(id: "gpt_image_1", name: "GPT Image 1", provider: "openai", speed: "medium", quality: "best", tier: "gold", category: "premium"),
    ]

    static let `default` = defaultModels[0]

    /// Group models by category for display.
    static func grouped(_ models: [AIModel]) -> [(category: String, models: [AIModel])] {
        let order = ["fast", "balanced", "classic", "artistic", "photorealistic", "premium"]
        var groups: [String: [AIModel]] = [:]
        for m in models {
            groups[m.category, default: []].append(m)
        }
        return order.compactMap { cat in
            guard let models = groups[cat], !models.isEmpty else { return nil }
            return (category: cat, models: models)
        }
    }
}
