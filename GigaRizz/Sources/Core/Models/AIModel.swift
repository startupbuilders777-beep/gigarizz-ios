import Foundation

// MARK: - AI Model

/// Available AI models for photo generation.
/// Synced with backend `AIModelChoice` enum.
struct AIModel: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let provider: String
    let speed: String
    let quality: String
    let tier: String

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
        default: return speed.capitalized
        }
    }

    var qualityLabel: String {
        switch quality {
        case "best": return "Best"
        case "high": return "High"
        case "good": return "Good"
        default: return quality.capitalized
        }
    }

    var isLocked: Bool {
        requiredTier != .free
    }

    // MARK: - Defaults (used when backend isn't reachable)

    static let defaultModels: [AIModel] = [
        AIModel(id: "flux_schnell", name: "Flux Schnell", provider: "replicate", speed: "fast", quality: "good", tier: "free"),
        AIModel(id: "flux_dev", name: "Flux Dev", provider: "replicate", speed: "medium", quality: "high", tier: "plus"),
        AIModel(id: "flux_1_1_pro", name: "Flux 1.1 Pro", provider: "replicate", speed: "medium", quality: "best", tier: "gold"),
        AIModel(id: "sdxl", name: "SDXL", provider: "replicate", speed: "medium", quality: "good", tier: "free"),
        AIModel(id: "fal_flux_schnell", name: "Flux Schnell (fal)", provider: "fal", speed: "fastest", quality: "good", tier: "free"),
        AIModel(id: "fal_flux_dev", name: "Flux Dev (fal)", provider: "fal", speed: "fast", quality: "high", tier: "plus"),
        AIModel(id: "fal_flux_pro", name: "Flux Pro (fal)", provider: "fal", speed: "fast", quality: "best", tier: "gold"),
        AIModel(id: "dall_e_3", name: "DALL-E 3", provider: "openai", speed: "medium", quality: "high", tier: "plus"),
        AIModel(id: "gpt_image_1", name: "GPT Image 1", provider: "openai", speed: "medium", quality: "best", tier: "gold"),
    ]

    static let `default` = defaultModels[0]
}
