import Foundation

// MARK: - PhotoScene
//
// Curated catalog of dating-attractive environments. Each entry maps a UI
// option to a backend GenerationStyle (scene_*) plus a brief seed the user
// can extend in plain English from PhotoBriefStudioView.
//
// Built to outclass ReGen's preset library: more interesting environments
// (helicopter, movie theatre, Tokyo street), every scene preserves identity
// via the `Same person...` lock in the backend prompt template, and every
// result auto-runs IdentityMatchService + drift detection + certificate.

struct PhotoScene: Identifiable, Hashable {
    let id: String
    let backendStyle: String         // matches backend GenerationStyle (scene_*)
    let category: Category
    let displayName: String
    let blurb: String                // one-line dating angle
    let briefSeed: String            // editable starting brief shown in the studio
    let iconName: String

    enum Category: String, CaseIterable, Identifiable {
        case adventure
        case cinematic
        case lifestyle
        case travel
        case professional
        case active

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .adventure: return "Adventure"
            case .cinematic: return "Cinematic"
            case .lifestyle: return "Lifestyle"
            case .travel: return "Travel"
            case .professional: return "Professional"
            case .active: return "Active"
            }
        }

        var subtitle: String {
            switch self {
            case .adventure: return "Movement + altitude. Scroll-stopping."
            case .cinematic: return "Story-rich indoor scenes that read interesting."
            case .lifestyle: return "How you actually live, made cinematic."
            case .travel: return "Implies depth without leaving home."
            case .professional: return "Status without LinkedIn vibes."
            case .active: return "Sport + craft. Implied competence."
            }
        }

        var iconName: String {
            switch self {
            case .adventure: return "mountain.2.fill"
            case .cinematic: return "film.fill"
            case .lifestyle: return "cup.and.saucer.fill"
            case .travel: return "airplane"
            case .professional: return "briefcase.fill"
            case .active: return "figure.run"
            }
        }
    }
}

// MARK: - Catalog

extension PhotoScene {

    /// The scenes Sprint 2 ships. Order matches what we want surfaced in the
    /// picker first — high-impact environments lead each category.
    static let catalog: [PhotoScene] = [
        // — Adventure —
        PhotoScene(
            id: "helicopter",
            backendStyle: "scene_helicopter",
            category: .adventure,
            displayName: "Helicopter",
            blurb: "Door-open helicopter shot over mountains or coast.",
            briefSeed: "In the open door of a helicopter mid-flight over a coastal landscape, aviator headset around the neck, soft late-afternoon light, confident half-smile.",
            iconName: "airplane.departure"
        ),
        PhotoScene(
            id: "ski_lift",
            backendStyle: "scene_ski_lift",
            category: .adventure,
            displayName: "Ski lift",
            blurb: "Chairlift with snowy alpine peaks behind.",
            briefSeed: "Riding a ski chairlift with snowy mountain peaks behind, soft alpine light, modern ski jacket zipped, warm cold-weather smile.",
            iconName: "snowflake"
        ),
        PhotoScene(
            id: "motorcycle",
            backendStyle: "scene_motorcycle",
            category: .adventure,
            displayName: "Motorcycle",
            blurb: "Sport bike on a scenic coastal road, helmet down.",
            briefSeed: "Standing next to a modern sport motorcycle on a scenic coastal road at golden hour, helmet held in hand at the side, riding jacket open, confident grounded posture.",
            iconName: "bolt.car.fill"
        ),
        PhotoScene(
            id: "yacht_deck",
            backendStyle: "scene_yacht_deck",
            category: .adventure,
            displayName: "Yacht deck",
            blurb: "Open deck of a sailing yacht, sea horizon behind.",
            briefSeed: "On the open deck of a modern sailing yacht at sea, midday sun, linen shirt, sunglasses pushed up, confident relaxed posture.",
            iconName: "ferry.fill"
        ),

        // — Cinematic —
        PhotoScene(
            id: "movie_theatre",
            backendStyle: "scene_movie_theatre",
            category: .cinematic,
            displayName: "Movie theatre",
            blurb: "Plush red seats, screen glow on one side of the face.",
            briefSeed: "Seated alone in a plush modern movie theatre, screen glow softly lighting one side of the face, deep red velvet seats around, smart-casual outfit, quiet confident expression.",
            iconName: "film.fill"
        ),
        PhotoScene(
            id: "concert",
            backendStyle: "scene_concert",
            category: .cinematic,
            displayName: "Concert crowd",
            blurb: "Magenta and blue stage lights, blurred crowd behind.",
            briefSeed: "In the crowd at a live concert venue, deep blue and magenta stage lights, soft motion behind, blurred crowd faces, in-the-moment expression.",
            iconName: "music.note.list"
        ),
        PhotoScene(
            id: "recording_studio",
            backendStyle: "scene_recording_studio",
            category: .cinematic,
            displayName: "Recording studio",
            blurb: "Mixing console glow, headphones around the neck.",
            briefSeed: "In a professional music recording studio, mixing console glowing in soft warm light, headphones around the neck, creative casual outfit, focused half-smile.",
            iconName: "headphones"
        ),
        PhotoScene(
            id: "art_gallery",
            backendStyle: "scene_art_gallery",
            category: .cinematic,
            displayName: "Art gallery",
            blurb: "Modern gallery, large abstract canvases, warm spots.",
            briefSeed: "In a contemporary art gallery, large abstract canvases on white walls, warm spot lighting, considered smart-casual outfit, gentle interested expression.",
            iconName: "paintpalette.fill"
        ),

        // — Lifestyle —
        PhotoScene(
            id: "rooftop_bar",
            backendStyle: "scene_rooftop_bar",
            category: .lifestyle,
            displayName: "Rooftop bar",
            blurb: "Skyline behind at golden hour, drink in hand.",
            briefSeed: "Standing at a rooftop bar at golden hour with warm city skyline behind, tailored smart-casual outfit, drink in hand, leaning posture, soft bokeh string lights.",
            iconName: "wineglass.fill"
        ),
        PhotoScene(
            id: "coffee_shop",
            backendStyle: "scene_coffee_shop",
            category: .lifestyle,
            displayName: "Coffee shop",
            blurb: "Brooklyn-style window seat, golden hour, latte.",
            briefSeed: "Seated at the window of a Brooklyn-style coffee shop, golden-hour light spilling in, latte in hand, soft natural smile, knit sweater.",
            iconName: "cup.and.saucer.fill"
        ),

        // — Travel —
        PhotoScene(
            id: "tokyo_street",
            backendStyle: "scene_tokyo_street",
            category: .travel,
            displayName: "Tokyo street",
            blurb: "Shibuya neon, light rain, modern layered outfit.",
            briefSeed: "Walking a Shibuya-style Tokyo street at night, neon signage in soft bokeh behind, light rain on pavement, modern smart-casual layered outfit, looking just past camera.",
            iconName: "moon.stars.fill"
        ),
        PhotoScene(
            id: "italian_cafe",
            backendStyle: "scene_italian_cafe",
            category: .travel,
            displayName: "Italian café",
            blurb: "Amalfi-coast café, espresso, lemon trees behind.",
            briefSeed: "Seated outside a small Amalfi-coast Italian café, espresso on the table, soft Mediterranean light, lemon trees in the background, linen outfit, warm relaxed smile.",
            iconName: "leaf.fill"
        ),

        // — Professional —
        PhotoScene(
            id: "private_jet",
            backendStyle: "scene_private_jet",
            category: .professional,
            displayName: "Private jet",
            blurb: "Cabin window with sky behind, tailored outfit.",
            briefSeed: "Seated in the cabin of a modern private jet, soft warm cabin lighting, oval window with sky behind, smart tailored outfit, relaxed unposed expression.",
            iconName: "airplane.circle.fill"
        ),
        PhotoScene(
            id: "observation_deck",
            backendStyle: "scene_observation_deck",
            category: .professional,
            displayName: "Observation deck",
            blurb: "NYC / Chicago skyline behind at blue hour.",
            briefSeed: "Standing at the open-air observation deck of a high-rise (NYC / Chicago skyline behind), late blue hour, city lights starting to glow, smart-casual outfit, hands in pockets.",
            iconName: "building.2.fill"
        ),

        // — Active —
        PhotoScene(
            id: "gym",
            backendStyle: "scene_gym",
            category: .active,
            displayName: "Boutique gym",
            blurb: "Mid-rep posture in a modern boutique gym.",
            briefSeed: "In a modern boutique gym, soft warm overhead light, fitted athletic outfit, mid-rep posture (no strain face), confident grounded expression.",
            iconName: "dumbbell.fill"
        ),
        PhotoScene(
            id: "sailing_race",
            backendStyle: "scene_sailing_race",
            category: .active,
            displayName: "Sailing race",
            blurb: "Hand on a winch, sail behind, salt spray.",
            briefSeed: "On the deck of a racing sailboat at sea, sail visible behind, salt spray, technical sailing jacket, hand on a winch, focused expression.",
            iconName: "sailboat.fill"
        ),
        PhotoScene(
            id: "golf_course",
            backendStyle: "scene_golf_course",
            category: .active,
            displayName: "Golf course",
            blurb: "Manicured tee box at sunrise, modern polo.",
            briefSeed: "On a manicured golf course tee box at sunrise, rolling fairway behind, modern golf polo, club resting at the side, relaxed grounded posture.",
            iconName: "figure.golf"
        ),
        PhotoScene(
            id: "dance_studio",
            backendStyle: "scene_dance_studio",
            category: .active,
            displayName: "Dance studio",
            blurb: "Mirror wall, ballet barre, mid-movement.",
            briefSeed: "In a sunlit dance studio with mirror wall and ballet barre, soft natural light, casual fitted athleisure, mid-movement relaxed pose, confident half-smile.",
            iconName: "figure.dance"
        ),

        // — Lifestyle (additions) —
        PhotoScene(
            id: "sushi_bar",
            backendStyle: "scene_sushi_bar",
            category: .lifestyle,
            displayName: "Sushi bar",
            blurb: "Counter at an upscale modern sushi bar.",
            briefSeed: "Seated at the counter of an upscale modern sushi bar, warm wood tones, chef faintly visible behind, smart-casual outfit, small confident smile.",
            iconName: "fork.knife"
        ),
        PhotoScene(
            id: "vineyard",
            backendStyle: "scene_vineyard",
            category: .lifestyle,
            displayName: "Vineyard walk",
            blurb: "Sunlit Tuscan vineyard at golden hour.",
            briefSeed: "Walking through a sunlit Tuscan-style vineyard, rows of vines softly out of focus behind, linen shirt, glass of red wine in hand, late golden hour, relaxed warm expression.",
            iconName: "leaf.arrow.triangle.circlepath"
        ),
        PhotoScene(
            id: "dog_park",
            backendStyle: "scene_dog_park",
            category: .lifestyle,
            displayName: "Dog park",
            blurb: "Kneeling next to a friendly dog at golden hour.",
            briefSeed: "In a sunlit park kneeling next to a friendly medium-sized dog, soft golden hour, casual cozy outfit, genuine warm smile, eye contact with camera.",
            iconName: "pawprint.fill"
        )
    ]

    static func grouped() -> [(Category, [PhotoScene])] {
        Category.allCases.map { category in
            (category, catalog.filter { $0.category == category })
        }
    }

    static func find(id: String) -> PhotoScene? {
        catalog.first { $0.id == id }
    }
}
