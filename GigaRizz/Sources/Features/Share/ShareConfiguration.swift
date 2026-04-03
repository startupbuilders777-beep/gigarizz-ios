import Foundation
import SwiftUI

// MARK: - Share Configuration

/// Configuration for sharing photos with optional watermark and caption.
struct ShareConfiguration {
    let includeWatermark: Bool
    let watermarkText: String
    let caption: String?
    let deepLinkId: String?
    let aspectRatio: ShareAspectRatio

    init(
        includeWatermark: Bool = true,
        watermarkText: String = "Made with GigaRizz",
        caption: String? = nil,
        deepLinkId: String? = nil,
        aspectRatio: ShareAspectRatio = .square
    ) {
        self.includeWatermark = includeWatermark
        self.watermarkText = watermarkText
        self.caption = caption
        self.deepLinkId = deepLinkId
        self.aspectRatio = aspectRatio
    }

    /// Default configuration for free tier (watermark on)
    static let freeDefault = ShareConfiguration(
        includeWatermark: true,
        caption: nil
    )

    /// Default configuration for Gold tier (watermark optional)
    static let goldDefault = ShareConfiguration(
        includeWatermark: false,
        caption: nil
    )

    /// Deep link URL for re-importing shared photos
    var deepLinkURL: URL? {
        guard let id = deepLinkId else { return nil }
        return URL(string: "gigarizz://photo/\(id)")
    }
}

// MARK: - Share Aspect Ratio

enum ShareAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"      // Tinder
    case portrait = "4:5"    // Hinge
    case stories = "9:16"    // Instagram Stories

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var datingPlatform: String {
        switch self {
        case .square: return "Tinder"
        case .portrait: return "Hinge"
        case .stories: return "Stories"
        }
    }

    var cropSize: CGSize {
        switch self {
        case .square: return CGSize(width: 1080, height: 1080)
        case .portrait: return CGSize(width: 1080, height: 1350)
        case .stories: return CGSize(width: 1080, height: 1920)
        }
    }
}

// MARK: - Share Caption Suggestion

/// Pre-filled caption suggestions for dating app contexts.
struct ShareCaptionSuggestion: Identifiable {
    let id: String
    let text: String
    let category: CaptionCategory
    let emoji: String

    init(
        id: String = UUID().uuidString,
        text: String,
        category: CaptionCategory,
        emoji: String = ""
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.emoji = emoji
    }

    /// Trending caption suggestions
    static let suggestions: [ShareCaptionSuggestion] = [
        ShareCaptionSuggestion(
            text: "New profile pic, who dis?",
            category: .flirty,
            emoji: "😏"
        ),
        ShareCaptionSuggestion(
            text: "Glow up in progress",
            category: .confident,
            emoji: "🔥"
        ),
        ShareCaptionSuggestion(
            text: "When the lighting hits just right",
            category: .casual,
            emoji: "✨"
        ),
        ShareCaptionSuggestion(
            text: "AI did the heavy lifting",
            category: .funny,
            emoji: "🤖"
        ),
        ShareCaptionSuggestion(
            text: "Ready for the matches",
            category: .confident,
            emoji: "💕"
        ),
        ShareCaptionSuggestion(
            text: "No photographer needed",
            category: .funny,
            emoji: "📸"
        ),
        ShareCaptionSuggestion(
            text: "This app changed my dating life",
            category: .authentic,
            emoji: "💯"
        ),
        ShareCaptionSuggestion(
            text: "The secret to better matches",
            category: .confident,
            emoji: "🤫"
        )
    ]
}

// MARK: - Caption Category

enum CaptionCategory: String, CaseIterable {
    case flirty
    case confident
    case casual
    case funny
    case authentic

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .flirty: return DesignSystem.Colors.flameOrange
        case .confident: return DesignSystem.Colors.goldAccent
        case .casual: return DesignSystem.Colors.textSecondary
        case .funny: return DesignSystem.Colors.bumble
        case .authentic: return DesignSystem.Colors.success
        }
    }
}