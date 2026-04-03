import Foundation
import SwiftUI

// MARK: - User Photo

/// Represents a user-uploaded photo used for AI generation.
struct UserPhoto: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let originalURL: URL?
    let createdAt: Date
    var status: PhotoStatus

    enum PhotoStatus: String, Codable {
        case uploading
        case uploaded
        case processing
        case completed
        case failed
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        originalURL: URL? = nil,
        createdAt: Date = Date(),
        status: PhotoStatus = .uploading
    ) {
        self.id = id
        self.userId = userId
        self.originalURL = originalURL
        self.createdAt = createdAt
        self.status = status
    }
}

// MARK: - Generated Photo

/// Represents an AI-generated photo.
struct GeneratedPhoto: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let style: String
    let imageURL: URL?
    let thumbnailURL: URL?
    let createdAt: Date
    var isFavorite: Bool

    init(
        id: String = UUID().uuidString,
        userId: String,
        style: String,
        imageURL: URL? = nil,
        thumbnailURL: URL? = nil,
        createdAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.style = style
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
}

// MARK: - Photo Score

/// Score breakdown for a profile photo.
struct PhotoScore: Identifiable, Codable {
    let id: String
    let overallScore: Double
    let categories: [ScoreCategory]
    let suggestions: [String]

    struct ScoreCategory: Identifiable, Codable {
        let id: String
        let name: String
        let score: Double
        let feedback: String

        init(
            id: String = UUID().uuidString,
            name: String,
            score: Double,
            feedback: String
        ) {
            self.id = id
            self.name = name
            self.score = score
            self.feedback = feedback
        }
    }

    init(
        id: String = UUID().uuidString,
        overallScore: Double,
        categories: [ScoreCategory],
        suggestions: [String]
    ) {
        self.id = id
        self.overallScore = overallScore
        self.categories = categories
        self.suggestions = suggestions
    }

    /// Demo score for preview/testing.
    static let demo = PhotoScore(
        overallScore: 7.2,
        categories: [
            ScoreCategory(name: "Lighting", score: 8.0, feedback: "Great natural lighting, well-exposed."),
            ScoreCategory(name: "Composition", score: 7.0, feedback: "Good framing, could use rule of thirds more."),
            ScoreCategory(name: "Expression", score: 7.5, feedback: "Genuine smile — very approachable."),
            ScoreCategory(name: "Background", score: 6.5, feedback: "Background is a bit cluttered. Try a cleaner setting."),
            ScoreCategory(name: "Outfit", score: 7.0, feedback: "Solid color choice, fits well.")
        ],
        suggestions: [
            "Try a photo with better background separation",
            "Add a full-body shot showing your style",
            "Include an action shot doing a hobby you enjoy"
        ]
    )
}

// MARK: - Selected Photo Item

/// Wraps a UIImage selected from the photo picker with metadata.
struct SelectedPhotoItem: Identifiable, Equatable {
    let id: String
    let image: UIImage
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        image: UIImage,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.image = image
        self.createdAt = createdAt
    }

    static func == (lhs: SelectedPhotoItem, rhs: SelectedPhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}
