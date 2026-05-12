import Foundation

// MARK: - ProfileKit (V2)
//
// Hero artifact of the V2 flow: a complete dating profile the user can ship.
// Audit + chosen photo set + bio + prompts + openers + per-platform photo order.
//
// Persisted locally via ProfileKitStore. Server-side persistence will follow
// once the backend POST /api/v1/profile-kit endpoint lands.

enum PhotoArchetype: String, Codable, CaseIterable, Identifiable {
    case firstPhoto = "first_photo"
    case casualCandid = "casual_candid"
    case dressedUp = "dressed_up"
    case hobbyActivity = "hobby_activity"
    case travelLifestyle = "travel_lifestyle"
    case socialProof = "social_proof"
    case fullBody = "full_body"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstPhoto: return "First Photo"
        case .casualCandid: return "Casual Candid"
        case .dressedUp: return "Dressed Up"
        case .hobbyActivity: return "Hobby / Activity"
        case .travelLifestyle: return "Travel / Lifestyle"
        case .socialProof: return "Social Proof"
        case .fullBody: return "Full Body"
        }
    }

    var systemImage: String {
        switch self {
        case .firstPhoto: return "person.crop.circle.fill"
        case .casualCandid: return "camera.fill"
        case .dressedUp: return "person.crop.square.fill"
        case .hobbyActivity: return "figure.run"
        case .travelLifestyle: return "airplane"
        case .socialProof: return "person.3.fill"
        case .fullBody: return "figure.stand"
        }
    }

    var whyItMatters: String {
        switch self {
        case .firstPhoto: return "Your first photo decides 80% of swipes. It needs a clear face, sharp eyes, and a real smile."
        case .casualCandid: return "Hinge and Tinder both reward variety — a relaxed, in-the-moment shot proves you're not staged."
        case .dressedUp: return "One styled photo signals you can show up. Date-night, wedding, or formal looks work."
        case .hobbyActivity: return "Activity shots are conversation bait. Lets matches open with 'how long have you been climbing?' instead of 'hi'."
        case .travelLifestyle: return "Travel photos signal a life worth being part of — without bragging."
        case .socialProof: return "Friends in frame proves you have one. Never your first photo, and never the only one."
        case .fullBody: return "Mandatory on Hinge. People who skip it get filtered out by default."
        }
    }
}

struct PhotoCritique: Codable, Equatable, Identifiable {
    var id: String { "\(photoIndex)-\(photoUrl)" }

    let photoUrl: String
    let photoIndex: Int
    let clarity: Int
    let lighting: Int
    let expression: Int
    let crop: Int
    let authenticity: Int
    let platformFit: Int
    let overall: Int
    let archetype: PhotoArchetype?
    let issues: [String]
    let strengths: [String]

    enum CodingKeys: String, CodingKey {
        case photoUrl = "photo_url"
        case photoIndex = "photo_index"
        case clarity, lighting, expression, crop, authenticity, overall
        case platformFit = "platform_fit"
        case archetype, issues, strengths
    }
}

struct ProfileFix: Codable, Equatable, Identifiable {
    var id: String { title }

    let title: String
    let detail: String
    let targetArchetype: PhotoArchetype?
    let suggestedStyle: String?

    enum CodingKeys: String, CodingKey {
        case title, detail
        case targetArchetype = "target_archetype"
        case suggestedStyle = "suggested_style"
    }
}

struct ProfileAuditResult: Codable, Equatable {
    let overallScore: Int
    let summary: String
    let bestPhotoIndex: Int
    let weakestPhotoIndex: Int
    let missingArchetypes: [PhotoArchetype]
    let topFixes: [ProfileFix]
    let perPhoto: [PhotoCritique]
    let targetPlatforms: [String]   // lowercase wire format ("hinge", "tinder", ...)
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case summary
        case bestPhotoIndex = "best_photo_index"
        case weakestPhotoIndex = "weakest_photo_index"
        case missingArchetypes = "missing_archetypes"
        case topFixes = "top_fixes"
        case perPhoto = "per_photo"
        case targetPlatforms = "target_platforms"
        case createdAt = "created_at"
    }
}

// MARK: - ProfileKit

struct PromptKitItem: Codable, Equatable, Identifiable {
    var id: String { "\(platform)-\(label)" }
    let platform: String
    let label: String
    let content: String
}

// MARK: - UpgradeGoal
//
// Codex's V2 Step 0: "What do you want to improve?". Persisted on the kit
// so analytics can segment users and the diagnosis copy can lean into the
// stated goal.

enum UpgradeGoal: String, Codable, CaseIterable, Identifiable {
    case moreMatches = "more_matches"
    case betterFirstPhoto = "better_first_photo"
    case betterHinge = "better_hinge"
    case betterTinderBumble = "better_tinder_bumble"
    case betterOpeners = "better_openers"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .moreMatches: return "More matches"
        case .betterFirstPhoto: return "Better first photo"
        case .betterHinge: return "Better Hinge profile"
        case .betterTinderBumble: return "Better Tinder / Bumble photos"
        case .betterOpeners: return "Better openers & replies"
        }
    }

    var subtitle: String {
        switch self {
        case .moreMatches: return "Diagnose what's costing matches and fix it."
        case .betterFirstPhoto: return "Lock in a strong, swipeable lead photo."
        case .betterHinge: return "Round out 6 photos + write your prompts."
        case .betterTinderBumble: return "Score your set, swap weak photos, ship."
        case .betterOpeners: return "Drop in a chat or profile, get unique openers."
        }
    }

    var systemImage: String {
        switch self {
        case .moreMatches: return "flame.fill"
        case .betterFirstPhoto: return "person.crop.circle.fill.badge.checkmark"
        case .betterHinge: return "heart.text.square.fill"
        case .betterTinderBumble: return "rectangle.stack.fill"
        case .betterOpeners: return "bubble.left.and.text.bubble.right.fill"
        }
    }
}

struct ProfileKit: Codable, Equatable, Identifiable {
    let id: String
    var userId: String
    var primaryGoal: UpgradeGoal?
    var targetPlatforms: [DatingPlatform]
    var audit: ProfileAuditResult?
    var currentPhotoUrls: [String]
    var generatedPhotoUrls: [String]
    var bio: String?
    var prompts: [PromptKitItem]
    var openers: [String]
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case primaryGoal = "primary_goal"
        case targetPlatforms = "target_platforms"
        case audit
        case currentPhotoUrls = "current_photo_urls"
        case generatedPhotoUrls = "generated_photo_urls"
        case bio, prompts, openers
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func empty(userId: String) -> ProfileKit {
        let now = Date()
        return ProfileKit(
            id: UUID().uuidString,
            userId: userId,
            primaryGoal: nil,
            targetPlatforms: [],
            audit: nil,
            currentPhotoUrls: [],
            generatedPhotoUrls: [],
            bio: nil,
            prompts: [],
            openers: [],
            createdAt: now,
            updatedAt: now
        )
    }

    var hasAudit: Bool { audit != nil }

    var totalPhotos: Int { currentPhotoUrls.count + generatedPhotoUrls.count }
}
