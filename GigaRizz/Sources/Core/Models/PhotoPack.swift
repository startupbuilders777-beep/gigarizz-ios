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

// MARK: - All Photo Packs

extension PhotoPack {
    /// The "Essential 6" - complete dating profile in one tap
    static let essential6 = PhotoPack(
        name: "The Essential 6",
        description: "Complete dating profile in one tap. The 6 photos every profile needs.",
        icon: "star.circle.fill",
        platform: .general,
        photoTypes: [
            PackPhotoType(
                name: "Hero Headshot",
                description: "Your primary photo - warm smile, direct eye contact",
                icon: "face.smiling.inverse",
                aiPrompt: "Professional dating profile headshot, warm genuine smile, direct eye contact, natural lighting, clean background, high quality portrait, shot on Canon R5 85mm f/1.4, attractive confident expression",
                importance: .critical
            ),
            PackPhotoType(
                name: "Full Body",
                description: "Head-to-toe shot showing your style",
                icon: "figure.stand",
                aiPrompt: "Full body portrait, stylish casual outfit, urban setting, confident relaxed stance, natural daylight, lifestyle photography, well-dressed attractive person",
                importance: .critical
            ),
            PackPhotoType(
                name: "Activity Shot",
                description: "Doing something you love - shows personality",
                icon: "figure.hiking",
                aiPrompt: "Candid activity photo, person enjoying a hobby outdoors, natural authentic expression, action or movement, golden hour lighting, lifestyle adventure photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Social Proof",
                description: "Looking social and fun in a group setting",
                icon: "person.3.fill",
                aiPrompt: "Social lifestyle photo, person at a gathering or event, warm smile, well-lit restaurant or bar, natural candid moment, social photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Candid Lifestyle",
                description: "Natural, unposed moment showing real you",
                icon: "camera.fill",
                aiPrompt: "Candid lifestyle portrait, person in a coffee shop or bookstore, natural unposed moment, warm ambient lighting, authentic relaxed vibe, lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Adventure/Travel",
                description: "Shows you live an exciting life",
                icon: "airplane",
                aiPrompt: "Adventure travel portrait, scenic exotic location, person looking confident and adventurous, golden hour sunset, wide angle landscape, professional travel photography",
                importance: .bonus
            ),
        ],
        gradient: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
        tier: .free,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Tinder-optimized pack
    static let tinderPack = PhotoPack(
        name: "Tinder Dominator",
        description: "Bold, attention-grabbing photos optimized for Tinder's algorithm.",
        icon: "flame.fill",
        platform: .tinder,
        photoTypes: [
            PackPhotoType(
                name: "Swipe-Right Headshot",
                description: "Bright, bold primary photo that stops the scroll",
                icon: "hand.tap.fill",
                aiPrompt: "High-impact dating headshot, bright vibrant colors, strong eye contact, 10/10 smile, perfect lighting, close crop, Tinder-optimized portrait, shot on iPhone 15 Pro",
                importance: .critical
            ),
            PackPhotoType(
                name: "Lifestyle Flex",
                description: "Full body showing off your best outfit and vibe",
                icon: "figure.stand",
                aiPrompt: "Stylish full body photo, trendy outfit, urban setting, cool confident stance, bright natural lighting, fashion-forward dating photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Fun Energy",
                description: "Action shot that shows you're fun to be around",
                icon: "party.popper.fill",
                aiPrompt: "Fun energetic lifestyle photo, laughing candid moment, bright colorful setting, social atmosphere, warm genuine expression, dynamic composition",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Mystery Shot",
                description: "Looking away or profile view - creates intrigue",
                icon: "eye.slash.fill",
                aiPrompt: "Artistic profile portrait, looking away into distance, moody atmospheric lighting, cinematic feel, mysterious attractive vibe, editorial photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Adventure",
                description: "Shows you're not boring - outdoor/travel shot",
                icon: "mountain.2.fill",
                aiPrompt: "Adventure outdoor portrait, hiking or beach or mountain, athletic casual wear, golden hour sunlight, scenic natural backdrop, adventurous spirit",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Night Out",
                description: "Well-dressed, social, night scene",
                icon: "moon.stars.fill",
                aiPrompt: "Night out portrait, upscale bar or restaurant, well-dressed smart casual, warm ambient lighting, confident relaxed pose, social nightlife photography",
                importance: .bonus
            ),
        ],
        gradient: [DesignSystem.Colors.tinder, .pink],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Hinge-optimized pack
    static let hingePack = PhotoPack(
        name: "Hinge Charmer",
        description: "Genuine, conversation-starting photos that match Hinge's authentic vibe.",
        icon: "heart.fill",
        platform: .hinge,
        photoTypes: [
            PackPhotoType(
                name: "Warm Welcome",
                description: "Approachable, warm primary photo",
                icon: "face.smiling.inverse",
                aiPrompt: "Warm approachable portrait, genuine smile, soft natural lighting, simple clean background, inviting expression, conversation-starting dating photo, authentic feel",
                importance: .critical
            ),
            PackPhotoType(
                name: "Passion Project",
                description: "Doing something you're passionate about",
                icon: "paintpalette.fill",
                aiPrompt: "Person engaged in a creative hobby, painting or cooking or playing music, focused passionate expression, natural setting, candid authentic moment, storytelling photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "With Friends",
                description: "Shows you're valued by others",
                icon: "person.2.fill",
                aiPrompt: "Social gathering photo, laughing with friends, genuine happy moment, warm restaurant or outdoor setting, natural candid, social proof dating photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Dressed Up",
                description: "Show you clean up nice",
                icon: "tshirt.fill",
                aiPrompt: "Well-dressed portrait, smart casual or semi-formal outfit, elegant setting, confident posture, clean sharp styling, attractive put-together look",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Outdoor Casual",
                description: "Relaxed outdoor shot in nature or city",
                icon: "leaf.fill",
                aiPrompt: "Casual outdoor portrait, park or garden or urban rooftop, relaxed natural pose, golden hour light, comfortable authentic vibe, lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Quirky/Fun",
                description: "Shows your personality and humor",
                icon: "theatermask.and.paintbrush.fill",
                aiPrompt: "Fun personality photo, playful expression, interesting unique setting, shows sense of humor, creative composition, memorable dating photo",
                importance: .bonus
            ),
        ],
        gradient: [DesignSystem.Colors.hinge, Color(hex: "8B7355")],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Bumble-optimized pack
    static let bumblePack = PhotoPack(
        name: "Bumble Standout",
        description: "Friendly, approachable photos that make women want to message first.",
        icon: "bolt.fill",
        platform: .bumble,
        photoTypes: [
            PackPhotoType(
                name: "Friendly Face",
                description: "Approachable, kind primary photo",
                icon: "face.smiling",
                aiPrompt: "Friendly approachable headshot, warm kind smile, bright natural lighting, soft background, trustworthy genuine expression, women-friendly dating photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Dog/Pet Lover",
                description: "With a pet - instant conversation starter",
                icon: "pawprint.fill",
                aiPrompt: "Person with a cute dog in a park, genuine happy smile, natural sunlight, warm heartfelt moment with pet, lifestyle photography, conversation-starting photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Cooking/Foodie",
                description: "In the kitchen or at a great restaurant",
                icon: "fork.knife",
                aiPrompt: "Person cooking in a modern kitchen or enjoying food at a nice restaurant, genuine smile, warm lighting, shows domestic skill and taste, lifestyle dating photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Active Lifestyle",
                description: "Hiking, biking, or sport - shows healthy living",
                icon: "figure.run",
                aiPrompt: "Active lifestyle portrait, hiking trail or cycling or yoga, athletic casual wear, natural outdoor setting, healthy energetic vibe, fitness lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Culture Shot",
                description: "Museum, concert, or bookstore - shows depth",
                icon: "books.vertical.fill",
                aiPrompt: "Cultural outing portrait, art museum or bookstore or concert, thoughtful engaged expression, interesting setting, shows intellectual depth, lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Laughing Candid",
                description: "Mid-laugh genuine joy moment",
                icon: "face.smiling.inverse",
                aiPrompt: "Genuine laughing candid portrait, mid-laugh natural joy, bright warm setting, authentic happy moment, not posed, natural photography captures real personality",
                importance: .bonus
            ),
        ],
        gradient: [DesignSystem.Colors.bumble, .orange],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

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
                aiPrompt: "Professional studio headshot, clean white or gray background, business attire, confident approachable expression, studio lighting, corporate photography, sharp focus 85mm portrait",
                importance: .critical
            ),
            PackPhotoType(
                name: "Business Casual",
                description: "Smart casual in a modern office setting",
                icon: "building.2.fill",
                aiPrompt: "Business casual portrait, modern office or co-working space, smart casual outfit, confident relaxed pose, natural window lighting, professional lifestyle photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Outdoor Professional",
                description: "Professional look in an urban outdoor setting",
                icon: "building.columns.fill",
                aiPrompt: "Outdoor professional portrait, urban architecture background, business casual attire, golden hour light, confident stance, editorial professional photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Creative Professional",
                description: "Shows your creative or innovative side",
                icon: "lightbulb.fill",
                aiPrompt: "Creative professional portrait, modern creative workspace, trendy smart casual, innovative vibe, warm natural lighting, startup culture photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Conference Ready",
                description: "Speaking or networking at an event",
                icon: "person.wave.2.fill",
                aiPrompt: "Professional event portrait, conference or networking setting, well-dressed leader vibe, ambient event lighting, confident engaging expression, corporate event photography",
                importance: .bonus
            ),
            PackPhotoType(
                name: "Executive Casual",
                description: "Relaxed but polished weekend executive look",
                icon: "sun.max.fill",
                aiPrompt: "Executive casual portrait, upscale cafe or lounge, relaxed polished look, casual luxury outfit, warm ambient lighting, premium lifestyle photography",
                importance: .bonus
            ),
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
                aiPrompt: "Beach portrait, tropical paradise setting, casual beach outfit, golden sunset light, ocean background, warm adventurous vibe, travel photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Mountain Summit",
                description: "Hiking or at a mountain viewpoint",
                icon: "mountain.2.fill",
                aiPrompt: "Mountain hiking portrait, summit or scenic viewpoint, athletic outdoor wear, dramatic mountain backdrop, golden hour light, adventure photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "City Explorer",
                description: "Exploring a famous city or landmark",
                icon: "building.2.fill",
                aiPrompt: "City exploration portrait, famous landmark or charming street, stylish casual outfit, golden hour, photogenic urban setting, travel lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Cafe Culture",
                description: "European cafe or exotic food market scene",
                icon: "cup.and.saucer.fill",
                aiPrompt: "European cafe portrait, charming outdoor cafe, espresso or wine, relaxed sophisticated traveler vibe, warm ambient lighting, lifestyle travel photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Sunset Silhouette",
                description: "Dramatic sunset or golden hour hero shot",
                icon: "sunset.fill",
                aiPrompt: "Dramatic sunset portrait, silhouette or golden glow, scenic overlook, adventurous spirit, cinematic wide composition, epic travel photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Local Experience",
                description: "Immersed in local culture",
                icon: "globe.americas.fill",
                aiPrompt: "Cultural immersion portrait, local market or temple or historic site, respectful engaged expression, vibrant colors, authentic travel experience photography",
                importance: .bonus
            ),
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
                aiPrompt: "Rooftop bar portrait, city skyline background, well-dressed smart casual, cocktail in hand, warm ambient lights, premium nightlife photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Fine Dining",
                description: "At an upscale restaurant",
                icon: "fork.knife",
                aiPrompt: "Fine dining portrait, upscale restaurant, well-dressed elegant, candelight warm glow, sophisticated atmosphere, premium lifestyle photography",
                importance: .critical
            ),
            PackPhotoType(
                name: "Cocktail Bar",
                description: "Stylish craft cocktail bar scene",
                icon: "wineglass.fill",
                aiPrompt: "Cocktail bar portrait, craft cocktail setting, moody ambient lighting, well-dressed stylish, relaxed confident pose, nightlife photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Live Music",
                description: "Concert or jazz club atmosphere",
                icon: "music.note",
                aiPrompt: "Live music venue portrait, concert or jazz club, dynamic lighting, stylish outfit, enjoying music vibes, entertainment nightlife photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "City Lights",
                description: "Walking through lit-up city streets at night",
                icon: "sparkles",
                aiPrompt: "Night city portrait, neon lights and city glow, walking urban streets, stylish evening outfit, cinematic moody atmosphere, night street photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "VIP Energy",
                description: "Exclusive club or lounge entrance",
                icon: "star.fill",
                aiPrompt: "VIP lounge portrait, exclusive upscale setting, designer outfit, confident commanding presence, dramatic lighting, luxury nightlife photography",
                importance: .bonus
            ),
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
                aiPrompt: "Gym portrait, modern gym setting, athletic wear, good physique showcase, gym mirror, confident pose, fitness photography, natural gym lighting",
                importance: .critical
            ),
            PackPhotoType(
                name: "Outdoor Run",
                description: "Running in a scenic location",
                icon: "figure.run",
                aiPrompt: "Running portrait, scenic trail or park, athletic wear, dynamic running pose, golden hour sunlight, fitness lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Yoga/Stretch",
                description: "Flexibility and mindfulness shot",
                icon: "figure.mind.and.body",
                aiPrompt: "Yoga portrait, beautiful outdoor or studio setting, athletic flexibility pose, calm focused expression, soft natural light, wellness photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Post-Workout Glow",
                description: "That healthy post-workout look",
                icon: "drop.fill",
                aiPrompt: "Post-workout portrait, healthy glow, athletic casual wear, drinking water or stretching, natural confident expression, healthy lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Hiking Summit",
                description: "Athletic outdoor achievement",
                icon: "mountain.2.fill",
                aiPrompt: "Hiking achievement portrait, mountain summit or scenic overlook, athletic wear, arms raised or triumphant pose, dramatic nature backdrop, adventure fitness photography",
                importance: .bonus
            ),
            PackPhotoType(
                name: "Sports Action",
                description: "Playing a sport - tennis, basketball, surfing",
                icon: "tennisball.fill",
                aiPrompt: "Sports action portrait, playing tennis or basketball or surfing, dynamic action pose, athletic skill display, natural outdoor lighting, sports photography",
                importance: .bonus
            ),
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
        fitnessPack,
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
