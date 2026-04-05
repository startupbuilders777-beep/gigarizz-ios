import Foundation
import UIKit

// MARK: - Aspect Ratio

/// Supported output aspect ratios for dating platforms.
enum AspectRatio: String, Codable, CaseIterable, Identifiable {
    case square = "1:1"           // Tinder, Instagram
    case portrait = "4:5"         // Hinge portrait
    case bumble = "1:1.2"         // Bumble portrait

    var id: String { rawValue }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .square: return "Square (Tinder)"
        case .portrait: return "Portrait (Hinge)"
        case .bumble: return "Bumble"
        }
    }

    /// Crop rect for center-top crop from 1024x1024 source.
    var cropRect: CGRect {
        switch self {
        case .square:
            return CGRect(x: 0, y: 0, width: 1024, height: 1024)
        case .portrait:
            // 1024x1280 crop from center-top
            return CGRect(x: 0, y: 0, width: 1024, height: 1280)
        case .bumble:
            // 1024x1229 crop from center-top
            return CGRect(x: 0, y: 0, width: 1024, height: 1229)
        }
    }

    /// Destination size in pixels.
    var pixelSize: CGSize {
        switch self {
        case .square: return CGSize(width: 1024, height: 1024)
        case .portrait: return CGSize(width: 1024, height: 1280)
        case .bumble: return CGSize(width: 1024, height: 1229)
        }
    }
}

// MARK: - Generation Request

/// Encapsulates all parameters needed for AI photo generation.
struct GenerationRequest: Codable, Equatable {
    /// User's selected source photos (compressed JPEG data).
    let sourcePhotoData: [Data]

    /// Primary source photo used for face reference (img2img).
    let primaryPhotoData: Data

    /// Style preset applied to generation.
    let stylePreset: String

    /// Additional style parameters.
    let styleParameters: StyleParameters

    /// Output aspect ratios requested.
    let aspectRatios: [AspectRatio]

    /// Enhancement intensity 0.0–1.0.
    let enhancementIntensity: Double

    /// Number of photos to generate per aspect ratio.
    let photoCount: Int

    /// User ID for storage paths.
    let userId: String

    /// Unique request ID for deduplication.
    let requestId: String

    init(
        sourcePhotoData: [Data],
        primaryPhotoData: Data,
        stylePreset: String,
        styleParameters: StyleParameters = StyleParameters(),
        aspectRatios: [AspectRatio] = AspectRatio.allCases,
        enhancementIntensity: Double = 0.7,
        photoCount: Int = 4,
        userId: String
    ) {
        self.sourcePhotoData = sourcePhotoData
        self.primaryPhotoData = primaryPhotoData
        self.stylePreset = stylePreset
        self.styleParameters = styleParameters
        self.aspectRatios = aspectRatios
        self.enhancementIntensity = enhancementIntensity
        self.photoCount = photoCount
        self.userId = userId
        self.requestId = UUID().uuidString
    }
}

// MARK: - Style Parameters

/// Fine-grained parameters for style tuning.
struct StyleParameters: Codable, Equatable {
    /// Lighting mode: warm, natural, dramatic, soft.
    let lighting: String

    /// Background type: solid, bokeh, urban, nature, abstract.
    let background: String

    /// Face enhancement: subtle, moderate, strong.
    let faceEnhancement: String

    /// Color tone: vibrant, muted, warm, cool.
    let colorTone: String

    /// Whether to preserve original expression vs artistic interpretation.
    let preserveExpression: Bool

    init(
        lighting: String = "warm",
        background: String = "bokeh",
        faceEnhancement: String = "moderate",
        colorTone: String = "vibrant",
        preserveExpression: Bool = true
    ) {
        self.lighting = lighting
        self.background = background
        self.faceEnhancement = faceEnhancement
        self.colorTone = colorTone
        self.preserveExpression = preserveExpression
    }

    /// Build a StyleParameters from a StylePreset.
    static func from(preset: StylePreset) -> StyleParameters {
        switch preset.name.lowercased() {
        case "confident":
            return StyleParameters(
                lighting: "warm",
                background: "solid",
                faceEnhancement: "strong",
                colorTone: "vibrant",
                preserveExpression: true
            )
        case "adventurous":
            return StyleParameters(
                lighting: "natural",
                background: "nature",
                faceEnhancement: "moderate",
                colorTone: "vibrant",
                preserveExpression: true
            )
        case "casual chic":
            return StyleParameters(
                lighting: "soft",
                background: "urban",
                faceEnhancement: "subtle",
                colorTone: "warm",
                preserveExpression: true
            )
        case "golden hour":
            return StyleParameters(
                lighting: "warm",
                background: "bokeh",
                faceEnhancement: "moderate",
                colorTone: "warm",
                preserveExpression: false
            )
        case "urban moody":
            return StyleParameters(
                lighting: "dramatic",
                background: "urban",
                faceEnhancement: "moderate",
                colorTone: "cool",
                preserveExpression: false
            )
        case "sporty":
            return StyleParameters(
                lighting: "natural",
                background: "nature",
                faceEnhancement: "moderate",
                colorTone: "vibrant",
                preserveExpression: true
            )
        case "mysterious":
            return StyleParameters(
                lighting: "dramatic",
                background: "abstract",
                faceEnhancement: "subtle",
                colorTone: "cool",
                preserveExpression: false
            )
        case "professional":
            return StyleParameters(
                lighting: "soft",
                background: "solid",
                faceEnhancement: "strong",
                colorTone: "neutral",
                preserveExpression: true
            )
        case "travel adventure":
            return StyleParameters(
                lighting: "natural",
                background: "nature",
                faceEnhancement: "moderate",
                colorTone: "vibrant",
                preserveExpression: true
            )
        case "clean minimal":
            return StyleParameters(
                lighting: "soft",
                background: "solid",
                faceEnhancement: "strong",
                colorTone: "neutral",
                preserveExpression: true
            )
        default:
            return StyleParameters()
        }
    }
}

// MARK: - Upload Request

/// Request to upload source photos to cloud storage before generation.
struct UploadRequest {
    let photos: [Data]
    let userId: String
    let requestId: String

    init(photos: [Data], userId: String) {
        self.photos = photos
        self.userId = userId
        self.requestId = UUID().uuidString
    }
}

// MARK: - Replicate API Request

/// Direct request payload for Replicate API (img2img workflow).
struct ReplicateAPIRequest: Codable {
    let version: String
    let input: ReplicateInput

    struct ReplicateInput: Codable {
        let image: String           // Base64 or URL of source
        let prompt: String
        let strength: Double        // img2img strength (0.0-1.0)
        let seed: Int?
        let aspectRatio: String?    // "1:1", "4:5", "1:1.2"
        let quality: String         // "regular", "portrait", "hd"
        let numOutputs: Int
        let guidanceScale: Double
        let negativePrompt: String?
        let model: String           // ".dev周二", "schnell"
    }
}
