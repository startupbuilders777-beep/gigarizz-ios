import Foundation
import SwiftUI

// MARK: - Photo Pack

/// A themed collection of AI generation styles optimized for specific dating platforms or scenarios.
struct PhotoPack: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let platform: DatingPlatform?
    let photoTypes: [PackPhotoType]
    let gradient: [Color]
    let tier: SubscriptionTier
    let estimatedTime: String
    let photoCount: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String,
        platform: DatingPlatform? = nil,
        photoTypes: [PackPhotoType],
        gradient: [Color],
        tier: SubscriptionTier = .free,
        estimatedTime: String = "~30s",
        photoCount: Int = 6
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.platform = platform
        self.photoTypes = photoTypes
        self.gradient = gradient
        self.tier = tier
        self.estimatedTime = estimatedTime
        self.photoCount = photoCount
    }

    var isLocked: Bool { tier != .free }
}

// MARK: - Pack Photo Type

/// Describes what kind of photo each slot in a pack should be.
struct PackPhotoType: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let aiPrompt: String
    let importance: PhotoImportance

    enum PhotoImportance: String {
        case critical = "Must Have"
        case recommended = "Recommended"
        case bonus = "Bonus"
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String,
        aiPrompt: String,
        importance: PhotoImportance = .recommended
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.aiPrompt = aiPrompt
        self.importance = importance
    }
}
