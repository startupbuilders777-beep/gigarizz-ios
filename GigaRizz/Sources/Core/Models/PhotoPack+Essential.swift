import Foundation
import SwiftUI

// MARK: - Essential Photo Pack

extension PhotoPack {
    /// The "Essential 6" - complete dating profile in one tap
    static let essential6 = PhotoPack(
        name: "The Essential 6",
        description: "Complete dating profile in one tap. The 6 photos every profile need.",
        icon: "star.circle.fill",
        platform: .general,
        photoTypes: [
            PackPhotoType(
                name: "Hero Headshot",
                description: "Your primary photo - warm smile, direct eye contact",
                icon: "face.smiling.inverse",
                aiPrompt: "Professional dating profile headshot, warm genuine smile, direct eye " +
                    "contact, natural lighting, clean background, high quality portrait, " +
                    "shot on Canon R5 85mm f/1.4, attractive confident expression",
                importance: .critical
            ),
            PackPhotoType(
                name: "Full Body",
                description: "Head-to-toe shot showing your style",
                icon: "figure.stand",
                aiPrompt: "Full body portrait, stylish casual outfit, urban setting, confident " +
                    "relaxed stance, natural daylight, lifestyle photography, well-dressed person",
                importance: .critical
            ),
            PackPhotoType(
                name: "Activity Shot",
                description: "Doing something you love - shows personality",
                icon: "figure.hiking",
                aiPrompt: "Candid activity photo, person enjoying a hobby outdoors, natural " +
                    "authentic expression, action or movement, golden hour lighting, lifestyle",
                importance: .critical
            ),
            PackPhotoType(
                name: "Social Proof",
                description: "Looking social and fun in a group setting",
                icon: "person.3.fill",
                aiPrompt: "Social lifestyle photo, person at a gathering or event, warm smile, " +
                    "well-lit restaurant or bar, natural candid moment, social photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Candid Lifestyle",
                description: "Natural, unposed moment showing real you",
                icon: "camera.fill",
                aiPrompt: "Candid lifestyle portrait, person in a coffee shop or bookstore, " +
                    "natural unposed moment, warm ambient lighting, authentic relaxed vibe",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Adventure/Travel",
                description: "Shows you live an exciting life",
                icon: "airplane",
                aiPrompt: "Adventure travel portrait, scenic exotic location, person looking " +
                    "confident and adventurous, golden hour sunset, wide angle landscape",
                importance: .bonus
            )
        ],
        gradient: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
        tier: .free,
        estimatedTime: "~45s",
        photoCount: 6
    )
}
