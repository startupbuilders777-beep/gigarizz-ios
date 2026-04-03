import Foundation
import SwiftUI

// MARK: - Lifestyle Photo Packs

extension PhotoPack {
    /// Professional headshot pack
    static let professionalPack = PhotoPack(
        name: "Professional Edge",
        description: "LinkedIn meets dating app. Business casual headshots that work everywhere.",
        icon: "briefcase.fill",
        platform: .general,
        photoTypes: [
            PackPhotoType(
                name: "Studio Headshot",
                description: "Clean, professional studio-quality headshot",
                icon: "camera.aperture",
                aiPrompt: "Professional studio headshot, clean white or gray background, business " +
                    "attire, confident approachable expression, studio lighting, corporate photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Business Casual",
                description: "Smart casual in a modern office setting",
                icon: "building.2.fill",
                aiPrompt: "Business casual portrait, modern office or co-working space, smart casual " +
                    "outfit, confident relaxed pose, natural window lighting, professional lifestyle",
                importance: .critical
            ),
            PackPhotoType(
                name: "Outdoor Professional",
                description: "Professional look in an urban outdoor setting",
                icon: "building.columns.fill",
                aiPrompt: "Outdoor professional portrait, urban architecture background, business " +
                    "casual attire, golden hour light, confident stance, editorial professional photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Creative Professional",
                description: "Shows your creative or innovative side",
                icon: "lightbulb.fill",
                aiPrompt: "Creative professional portrait, modern creative workspace, trendy smart " +
                    "casual, innovative vibe, warm natural lighting, startup culture photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Conference Ready",
                description: "Speaking or networking at an event",
                icon: "person.wave.2.fill",
                aiPrompt: "Professional event portrait, conference or networking setting, well-dressed " +
                    "leader vibe, ambient event lighting, confident engaging expression, corporate",
                importance: .bonus
            ),
            PackPhotoType(
                name: "Executive Casual",
                description: "Relaxed but polished weekend executive look",
                icon: "sun.max.fill",
                aiPrompt: "Executive casual portrait, upscale cafe or lounge, relaxed polished look, " +
                    "casual luxury outfit, warm ambient lighting, premium lifestyle photography",
                importance: .bonus
            )
        ],
        gradient: [.gray, .blue],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Adventure & Travel pack
    static let adventurePack = PhotoPack(
        name: "Adventure Seeker",
        description: "Exotic locations and outdoor adventures. Show you're not boring.",
        icon: "airplane",
        platform: .general,
        photoTypes: [
            PackPhotoType(
                name: "Beach Paradise",
                description: "Tropical beach or coastal setting",
                icon: "beach.umbrella.fill",
                aiPrompt: "Beach portrait, tropical paradise setting, casual beach outfit, golden " +
                    "sunset light, ocean background, warm adventurous vibe, travel photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Mountain Summit",
                description: "Hiking or at a mountain viewpoint",
                icon: "mountain.2.fill",
                aiPrompt: "Mountain hiking portrait, summit or scenic viewpoint, athletic outdoor wear, " +
                    "dramatic mountain backdrop, golden hour light, adventure photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "City Explorer",
                description: "Exploring a famous city or landmark",
                icon: "building.2.fill",
                aiPrompt: "City exploration portrait, famous landmark or charming street, stylish " +
                    "casual outfit, golden hour, photogenic urban setting, travel lifestyle",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Cafe Culture",
                description: "European cafe or exotic food market scene",
                icon: "cup.and.saucer.fill",
                aiPrompt: "European cafe portrait, charming outdoor cafe, espresso or wine, relaxed " +
                    "sophisticated traveler vibe, warm ambient lighting, lifestyle travel photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Sunset Silhouette",
                description: "Dramatic sunset or golden hour hero shot",
                icon: "sunset.fill",
                aiPrompt: "Dramatic sunset portrait, silhouette or golden glow, scenic overlook, " +
                    "adventurous spirit, cinematic wide composition, epic travel photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Local Experience",
                description: "Immersed in local culture",
                icon: "globe.americas.fill",
                aiPrompt: "Cultural immersion portrait, local market or temple or historic site, " +
                    "respectful engaged expression, vibrant colors, authentic travel experience",
                importance: .bonus
            )
        ],
        gradient: [.teal, .cyan],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Night Out pack
    static let nightOutPack = PhotoPack(
        name: "Night Out King",
        description: "Upscale nightlife, rooftop bars, and restaurant scenes.",
        icon: "moon.stars.fill",
        platform: .general,
        photoTypes: [
            PackPhotoType(
                name: "Rooftop Vibes",
                description: "City skyline rooftop bar or lounge",
                icon: "building.2.fill",
                aiPrompt: "Rooftop bar portrait, city skyline background, well-dressed smart casual, " +
                    "cocktail in hand, warm ambient lights, premium nightlife photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Fine Dining",
                description: "At an upscale restaurant",
                icon: "fork.knife",
                aiPrompt: "Fine dining portrait, upscale restaurant, well-dressed elegant, candelight " +
                    "warm glow, sophisticated atmosphere, premium lifestyle photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Cocktail Bar",
                description: "Stylish craft cocktail bar scene",
                icon: "wineglass.fill",
                aiPrompt: "Cocktail bar portrait, craft cocktail setting, moody ambient lighting, " +
                    "well-dressed stylish, relaxed confident pose, nightlife photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Live Music",
                description: "Concert or jazz club atmosphere",
                icon: "music.note",
                aiPrompt: "Live music venue portrait, concert or jazz club, dynamic lighting, " +
                    "stylish outfit, enjoying music vibes, entertainment nightlife photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "City Lights",
                description: "Walking through lit-up city streets at night",
                icon: "sparkles",
                aiPrompt: "Night city portrait, neon lights and city glow, walking urban streets, " +
                    "stylish evening outfit, cinematic moody atmosphere, night street photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "VIP Energy",
                description: "Exclusive club or lounge entrance",
                icon: "star.fill",
                aiPrompt: "VIP lounge portrait, exclusive upscale setting, designer outfit, " +
                    "confident commanding presence, dramatic lighting, luxury nightlife photography",
                importance: .bonus
            )
        ],
        gradient: [.purple, .indigo],
        tier: .gold,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Fitness pack
    static let fitnessPack = PhotoPack(
        name: "Fitness Pro",
        description: "Athletic lifestyle shots that show you take care of yourself.",
        icon: "figure.run",
        platform: .general,
        photoTypes: [
            PackPhotoType(
                name: "Gym Mirror",
                description: "Classic gym selfie with good form",
                icon: "dumbbell.fill",
                aiPrompt: "Gym portrait, modern gym setting, athletic wear, good physique showcase, " +
                    "gym mirror, confident pose, fitness photography, natural gym lighting",
                importance: .critical
            ),
            PackPhotoType(
                name: "Outdoor Run",
                description: "Running in a scenic location",
                icon: "figure.run",
                aiPrompt: "Running portrait, scenic trail or park, athletic wear, dynamic running " +
                    "pose, golden hour sunlight, fitness lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Yoga/Stretch",
                description: "Flexibility and mindfulness shot",
                icon: "figure.mind.and.body",
                aiPrompt: "Yoga portrait, beautiful outdoor or studio setting, athletic flexibility " +
                    "pose, calm focused expression, soft natural light, wellness photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Post-Workout Glow",
                description: "That healthy post-workout look",
                icon: "drop.fill",
                aiPrompt: "Post-workout portrait, healthy glow, athletic casual wear, drinking water " +
                    "or stretching, natural confident expression, healthy lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Hiking Summit",
                description: "Athletic outdoor achievement",
                icon: "mountain.2.fill",
                aiPrompt: "Hiking achievement portrait, mountain summit or scenic overlook, athletic " +
                    "wear, arms raised or triumphant pose, dramatic nature backdrop, adventure fitness",
                importance: .bonus
            ),
            PackPhotoType(
                name: "Sports Action",
                description: "Playing a sport - tennis, basketball, surfing",
                icon: "tennisball.fill",
                aiPrompt: "Sports action portrait, playing tennis or basketball or surfing, dynamic " +
                    "action pose, athletic skill display, natural outdoor lighting, sports photo",
                importance: .bonus
            )
        ],
        gradient: [.red, DesignSystem.Colors.flameOrange],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    // MARK: - All Packs

    static let allPacks: [PhotoPack] = [
        essential6,
        tinderPack,
        hingePack,
        bumblePack,
        professionalPack,
        adventurePack,
        nightOutPack,
        fitnessPack
    ]

    /// Packs available for a given tier
    static func available(for tier: SubscriptionTier) -> [PhotoPack] {
        allPacks.filter { pack in
            switch tier {
            case .gold: return true
            case .plus: return pack.tier != .gold
            case .free: return pack.tier == .free
            }
        }
    }
}
