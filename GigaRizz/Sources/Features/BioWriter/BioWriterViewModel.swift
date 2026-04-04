import PostHog
import SwiftUI

// MARK: - Supporting Types

enum BioPlatform: String, CaseIterable, Identifiable {
    case tinder = "Tinder"
    case hinge = "Hinge"
    case bumble = "Bumble"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tinder: return "flame.fill"
        case .hinge: return "heart.text.square.fill"
        case .bumble: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .tinder: return DesignSystem.Colors.tinder
        case .hinge: return DesignSystem.Colors.hinge
        case .bumble: return DesignSystem.Colors.bumble
        }
    }

    var maxChars: Int {
        switch self {
        case .tinder: return 500
        case .hinge: return 150
        case .bumble: return 300
        }
    }
}

enum PersonalityTrait: String, CaseIterable, Identifiable, Hashable {
    case witty = "Witty"
    case adventurous = "Adventurous"
    case nerdy = "Nerdy"
    case creative = "Creative"
    case ambitious = "Ambitious"
    case chill = "Chill"
    case romantic = "Romantic"
    case sporty = "Sporty"
    case foodie = "Foodie"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .witty: return "😏"
        case .adventurous: return "🏔"
        case .nerdy: return "🤓"
        case .creative: return "🎨"
        case .ambitious: return "🚀"
        case .chill: return "😌"
        case .romantic: return "💕"
        case .sporty: return "🏋️"
        case .foodie: return "🍕"
        }
    }
}

enum InterestCategory: String, CaseIterable, Identifiable, Hashable {
    case travel = "Travel"
    case music = "Music"
    case fitness = "Fitness"
    case cooking = "Cooking"
    case photography = "Photography"
    case gaming = "Gaming"
    case reading = "Reading"
    case hiking = "Hiking"
    case dogs = "Dogs"
    case coffee = "Coffee"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .travel: return "✈️"
        case .music: return "🎵"
        case .fitness: return "💪"
        case .cooking: return "👨‍🍳"
        case .photography: return "📸"
        case .gaming: return "🎮"
        case .reading: return "📚"
        case .hiking: return "🥾"
        case .dogs: return "🐕"
        case .coffee: return "☕️"
        }
    }
}

enum BioVibe: String, CaseIterable, Identifiable {
    case funny = "😂 Funny"
    case sincere = "💯 Sincere"
    case mysterious = "🌙 Mysterious"
    case bold = "🔥 Bold"
    case playful = "😜 Playful"

    var id: String { rawValue }
}

struct GeneratedBio: Identifiable {
    let id = UUID()
    let text: String
    let style: String
    let icon: String
    let rating: Int
}

// MARK: - ViewModel

@MainActor
final class BioWriterViewModel: ObservableObject {
    @Published var selectedPlatform: BioPlatform = .tinder
    @Published var selectedTraits: Set<PersonalityTrait> = []
    @Published var selectedInterests: Set<InterestCategory> = []
    @Published var selectedVibe: BioVibe = .funny
    @Published var isGenerating = false
    @Published var generatedBios: [GeneratedBio] = []

    var canGenerate: Bool {
        !selectedTraits.isEmpty && !selectedInterests.isEmpty && !isGenerating
    }

    func generateBios() async {
        isGenerating = true
        generatedBios = []

        // Simulate AI generation delay
        try? await Task.sleep(for: .seconds(Double.random(in: 1.8...3.0)))

        let bios = buildBios()
        generatedBios = bios
        isGenerating = false

        PostHogSDK.shared.capture("bio_generated", properties: [
            "platform": selectedPlatform.rawValue,
            "traits": selectedTraits.map(\.rawValue),
            "interests": selectedInterests.map(\.rawValue),
            "vibe": selectedVibe.rawValue,
            "bio_count": bios.count
        ])
    }

    // MARK: - Bio Generation Engine

    private func buildBios() -> [GeneratedBio] {
        let traits = Array(selectedTraits)
        let interests = Array(selectedInterests)
        guard let firstTrait = traits.first, let firstInterest = interests.first else { return [] }

        var bios: [GeneratedBio] = []

        // Bio 1: Hook Lead
        let hook = hookOpener(platform: selectedPlatform, vibe: selectedVibe, trait: firstTrait)
        let body1 = interestLine(interests: interests, vibe: selectedVibe)
        let cta1 = callToAction(platform: selectedPlatform, vibe: selectedVibe)
        bios.append(GeneratedBio(
            text: "\(hook)\n\(body1)\n\(cta1)",
            style: "Hook Lead",
            icon: "sparkles",
            rating: Int.random(in: 4...5)
        ))

        // Bio 2: List Style
        let listBio = listStyleBio(traits: traits, interests: interests, platform: selectedPlatform)
        bios.append(GeneratedBio(
            text: listBio,
            style: "Quick List",
            icon: "list.bullet",
            rating: Int.random(in: 3...5)
        ))

        // Bio 3: Story Opener
        let story = storyBio(traits: traits, interests: interests, vibe: selectedVibe, platform: selectedPlatform)
        bios.append(GeneratedBio(
            text: story,
            style: "Story Opener",
            icon: "book.fill",
            rating: Int.random(in: 4...5)
        ))

        // Bio 4: Bold & Direct (platform specific)
        if selectedPlatform == .tinder || selectedPlatform == .bumble {
            let bold = boldBio(traits: traits, interests: interests, vibe: selectedVibe)
            bios.append(GeneratedBio(
                text: bold,
                style: "Bold & Direct",
                icon: "bolt.fill",
                rating: Int.random(in: 3...5)
            ))
        }

        return bios
    }

    // MARK: - Template Builders

    private func hookOpener(platform: BioPlatform, vibe: BioVibe, trait: PersonalityTrait) -> String {
        switch (vibe, trait) {
        case (.funny, .witty):
            return "My therapist says I have a great personality. Figured I should put it to use."
        case (.funny, .foodie):
            return "Warning: I will judge your restaurant picks. Gently. With love."
        case (.funny, .adventurous):
            return "Looking for someone to be irresponsible with in beautiful places."
        case (.bold, _):
            return "Not here to waste time. Let's skip the small talk and get to the good stuff."
        case (.mysterious, _):
            return "I could tell you about myself, but where's the fun in that?"
        case (.playful, .sporty):
            return "Swipe right if you can keep up. Fair warning: I don't go easy."
        case (.sincere, .romantic):
            return "Genuinely looking for someone who makes ordinary moments feel special."
        case (.sincere, _):
            return "Here for something real. No games, just good conversation and better company."
        default:
            return "Plot twist: I'm actually this interesting in real life."
        }
    }

    private func interestLine(interests: [InterestCategory], vibe: BioVibe) -> String {
        let names = interests.prefix(3).map { "\($0.emoji) \($0.rawValue)" }
        switch vibe {
        case .funny:
            return "Currently into \(names.joined(separator: ", ")). Subject to change without notice."
        case .sincere:
            return "Happiest when I'm doing \(names.joined(separator: " or "))."
        case .bold:
            return "\(names.joined(separator: " • ")). Non-negotiable."
        case .playful:
            return "You'll find me \(names.joined(separator: "-ing or "))-ing most weekends."
        case .mysterious:
            return "\(names.joined(separator: ". ")). The rest you'll have to discover yourself."
        }
    }

    private func callToAction(platform: BioPlatform, vibe: BioVibe) -> String {
        switch (platform, vibe) {
        case (.tinder, .funny):
            return "Swipe right if you appreciate someone who can make you laugh at your own funeral."
        case (.tinder, .bold):
            return "If this doesn't make you swipe right, nothing will."
        case (.hinge, .sincere):
            return "Send me a like if you're ready for conversations that matter."
        case (.hinge, _):
            return "Let me buy you a coffee and prove the bio isn't fiction."
        case (.bumble, .playful):
            return "Your move 😏"
        case (.bumble, _):
            return "Say hi. I promise I reply faster than your last match."
        default:
            return "Let's see if the chemistry is real."
        }
    }

    private func listStyleBio(traits: [PersonalityTrait], interests: [InterestCategory], platform: BioPlatform) -> String {
        var lines: [String] = []
        let emojis = traits.prefix(2).map(\.emoji)
        lines.append("\(emojis.joined()) \(traits.prefix(2).map(\.rawValue).joined(separator: " + ")) energy")

        for interest in interests.prefix(3) {
            let bullet: String
            switch interest {
            case .travel: bullet = "Passport stamps > material things"
            case .music: bullet = "My Spotify Wrapped is a personality test"
            case .fitness: bullet = "Gym before 7am, tacos after midnight"
            case .cooking: bullet = "I'll cook, you pick the playlist"
            case .photography: bullet = "I'll take photos of you pretending not to pose"
            case .gaming: bullet = "Yes, gaming counts as a hobby"
            case .reading: bullet = "Currently reading 3 books (finishing 0)"
            case .hiking: bullet = "Sundays are for trail therapy"
            case .dogs: bullet = "My dog is the real catch here"
            case .coffee: bullet = "Fueled by oat milk lattes"
            }
            lines.append("• \(bullet)")
        }

        if platform == .tinder {
            lines.append("\nLooking for: someone who gets my humor")
        }
        return lines.joined(separator: "\n")
    }

    private func storyBio(traits: [PersonalityTrait], interests: [InterestCategory], vibe: BioVibe, platform: BioPlatform) -> String {
        let mainTrait = traits.first ?? .adventurous
        let mainInterest = interests.first ?? .travel

        let opener: String
        switch (mainTrait, mainInterest) {
        case (.adventurous, .travel):
            opener = "Last month I found myself lost in a market in Marrakech with nothing but broken French and good vibes."
        case (.foodie, .cooking):
            opener = "I once spent 3 hours making pasta from scratch. It was the best date with myself I've ever had."
        case (.nerdy, .gaming):
            opener = "My Steam library has 200 games and I've finished 4. But those 4? Masterpieces."
        case (.sporty, .fitness):
            opener = "5am alarm. Gym. Cold shower. Coffee. I promise I'm more fun than this sounds."
        case (.creative, .photography):
            opener = "I see the world in frames. Sometimes I even capture it before the moment passes."
        case (.witty, _):
            opener = "I once made a complete stranger laugh so hard they spilled their coffee. I consider this my greatest achievement."
        case (.chill, _):
            opener = "My ideal weekend: zero plans, good company, and wherever the day takes us."
        default:
            opener = "I'm the person your friends describe as 'you'll love them when you meet them.'"
        }

        let closer: String
        switch vibe {
        case .funny: closer = "Anyway, I'm great at first dates. Second dates are where the real chaos begins."
        case .sincere: closer = "Looking for someone to share the next chapter with."
        case .bold: closer = "Ready to make this interesting?"
        case .playful: closer = "Now your turn — what's your story?"
        case .mysterious: closer = "But you'll have to meet me to hear the rest."
        }

        return "\(opener)\n\n\(closer)"
    }

    private func boldBio(traits: [PersonalityTrait], interests: [InterestCategory], vibe: BioVibe) -> String {
        let trait = traits.first ?? .adventurous
        let interest = interests.first ?? .travel

        return """
        \(trait.emoji) \(trait.rawValue). \(interest.emoji) \(interest.rawValue). No apologies.

        I know what I want and I'm not afraid to go after it. If you're the kind of person who texts back in under 3 hours, we might just get along.

        Hot take: dating apps work when both people actually try. So let's try.
        """
    }
}
