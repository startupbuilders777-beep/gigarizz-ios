import Foundation
import SwiftUI

// MARK: - Style Preset

/// AI generation style presets for dating photos.
struct StylePreset: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let prompt: String
    let tier: SubscriptionTier
    let gradient: [Color]

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String,
        prompt: String,
        tier: SubscriptionTier = .free,
        gradient: [Color] = [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.prompt = prompt
        self.tier = tier
        self.gradient = gradient
    }

    var isLocked: Bool {
        tier != .free
    }

    // MARK: - All Presets

    static let allPresets: [StylePreset] = [
        // Free Tier
        StylePreset(
            name: "Confident",
            description: "Professional headshot with warm tones, clean background.",
            icon: "sparkles",
            prompt: "Professional dating profile headshot, warm lighting, clean background, confident expression, high quality portrait photography",
            tier: .free,
            gradient: [DesignSystem.Colors.flameOrange, .orange]
        ),
        StylePreset(
            name: "Adventurous",
            description: "Outdoor adventure vibe with natural lighting.",
            icon: "mountain.2.fill",
            prompt: "Outdoor adventure portrait, natural sunlight, scenic background, adventurous expression, travel photography style",
            tier: .free,
            gradient: [.green, .teal]
        ),
        StylePreset(
            name: "Casual Chic",
            description: "Laid-back style, coffee shop or urban setting.",
            icon: "cup.and.saucer.fill",
            prompt: "Casual lifestyle portrait, coffee shop setting, relaxed natural pose, warm ambient lighting, lifestyle photography",
            tier: .free,
            gradient: [.brown, DesignSystem.Colors.goldAccent]
        ),

        // Plus Tier
        StylePreset(
            name: "Golden Hour",
            description: "Warm sunset glow for that perfect golden hour look.",
            icon: "sun.max.fill",
            prompt: "Golden hour portrait, warm sunset lighting, soft bokeh background, romantic atmosphere, cinematic photography",
            tier: .plus,
            gradient: [.orange, .yellow]
        ),
        StylePreset(
            name: "Urban Moody",
            description: "City vibes with dramatic mood lighting.",
            icon: "building.2.fill",
            prompt: "Urban portrait, city background, moody neon lighting, dramatic shadows, street photography style",
            tier: .plus,
            gradient: [.purple, .blue]
        ),
        StylePreset(
            name: "Sporty",
            description: "Active lifestyle shot showing your athletic side.",
            icon: "figure.run",
            prompt: "Athletic lifestyle portrait, sporty casual outfit, action pose, natural daylight, fitness photography",
            tier: .plus,
            gradient: [.red, DesignSystem.Colors.flameOrange]
        ),
        StylePreset(
            name: "Mysterious",
            description: "Dark and intriguing with artistic flair.",
            icon: "moon.stars.fill",
            prompt: "Artistic portrait, dark moody aesthetic, dramatic lighting, mysterious expression, fine art photography",
            tier: .plus,
            gradient: [.indigo, .purple]
        ),
        StylePreset(
            name: "Professional",
            description: "Business casual — LinkedIn meets dating app.",
            icon: "briefcase.fill",
            prompt: "Business casual portrait, office or modern backdrop, professional but approachable, clean styling, corporate photography",
            tier: .plus,
            gradient: [.gray, .blue]
        ),

        // Gold Tier
        StylePreset(
            name: "Travel Adventure",
            description: "Exotic location with wanderlust vibes.",
            icon: "airplane",
            prompt: "Travel portrait, exotic location background, adventurous styling, cinematic wide angle, travel photography",
            tier: .gold,
            gradient: [.teal, .cyan]
        ),
        StylePreset(
            name: "Clean Minimal",
            description: "Studio-quality minimal portrait.",
            icon: "square.fill",
            prompt: "Studio portrait, clean white background, minimalist styling, sharp focus, professional studio photography",
            tier: .gold,
            gradient: [.white, .gray]
        ),

        // Hinge-mode prompt overlays — pair with the gpt_image_2 model for best
        // text rendering. These produce shareable Hinge-prompt-formatted shots.
        StylePreset(
            id: "hinge_prompt",
            name: "Hinge: Fall For You",
            description: "Portrait with 'I'll fall for you if...' overlay.",
            icon: "text.bubble.fill",
            prompt: "Editorial portrait of a person, warm cinematic lighting, soft bokeh background, with the Hinge-style prompt text 'I'll fall for you if...' rendered in clean white sans-serif overlay in the lower-left third, photorealistic, vertical 3:4",
            tier: .gold,
            gradient: [.pink, .orange]
        ),
        StylePreset(
            id: "hinge_caption",
            name: "Hinge: Sunday Vibe",
            description: "Magazine-style with 'My ideal Sunday' caption.",
            icon: "sun.haze.fill",
            prompt: "Magazine-style portrait of a person, golden hour, candid expression, with the caption 'My ideal Sunday in 3 emojis' rendered in elegant white serif centered below the subject, photorealistic, vertical 3:4",
            tier: .gold,
            gradient: [.yellow, .orange]
        ),
        StylePreset(
            id: "hinge_chemistry",
            name: "Hinge: Two Truths",
            description: "Modern minimal with 'Two truths and a lie' tag.",
            icon: "rectangle.and.text.magnifyingglass",
            prompt: "Confident portrait of a person, modern minimal setting, natural smile, with the prompt 'Two truths and a lie' rendered as a small white tag in the upper-right corner, photorealistic, vertical 3:4",
            tier: .gold,
            gradient: [.indigo, .blue]
        )
    ]

    /// Returns presets available for a given subscription tier.
    static func available(for tier: SubscriptionTier) -> [StylePreset] {
        allPresets.filter { preset in
            switch tier {
            case .gold: return true
            case .plus: return preset.tier != .gold
            case .free: return preset.tier == .free
            }
        }
    }
}
