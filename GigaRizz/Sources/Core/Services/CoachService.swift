import Foundation

// MARK: - Coach Service

/// AI-powered dating coach service for bios, openers, and conversation tips.
/// Uses ServiceMode to switch between mock (local templates) and production (OpenAI via Cloud Functions).
@MainActor
final class CoachService: ObservableObject {
    // MARK: - Singleton

    static let shared = CoachService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Chat Message

    struct ChatMessage: Identifiable, Equatable {
        let id: String
        let role: Role
        let content: String
        let timestamp: Date

        enum Role: String {
            case user, assistant, system
        }

        init(
            id: String = UUID().uuidString,
            role: Role,
            content: String,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }
    }

    // MARK: - Bio Tone

    enum BioTone: String, CaseIterable, Identifiable {
        case witty = "Witty & Playful"
        case sincere = "Sincere & Genuine"
        case bold = "Bold & Confident"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .witty: return "face.smiling.inverse"
            case .sincere: return "heart.fill"
            case .bold: return "flame.fill"
            }
        }

        var description: String {
            switch self {
            case .witty: return "Humor-forward, clever wordplay"
            case .sincere: return "Heartfelt, authentic vibes"
            case .bold: return "Direct, high-energy, memorable"
            }
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Generate Bio

    func generateBio(
        interests: [String],
        tone: BioTone,
        platform: DatingPlatform
    ) async throws -> String {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch ServiceMode.current {
        case .production:
            // LAUNCH TODO: Call Firebase Cloud Function "generateBio"
            // POST /generateBio { interests, tone, platform }
            // Parse response JSON → String bio
            return try await generateMockBio(tone: tone)

        case .mock:
            return try await generateMockBio(tone: tone)
        }
    }

    private func generateMockBio(tone: BioTone) async throws -> String {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let bios: [BioTone: [String]] = [
            .witty: [
                "6'1\" but my personality is what really stands out at crowded bars. Dog dad. Will debate pizza toppings with dangerous passion. Looking for someone who laughs at their own jokes (because I will too).",
                "Pro at finding the best brunch spots within a 5-mile radius. My ideal Sunday: farmers market → cook together → lose at Scrabble. Fluent in sarcasm and movie quotes.",
                "If we match, I promise excellent playlist curation and slightly above-average cooking. Trade offer: I bring the adventure, you bring the snacks."
            ],
            .sincere: [
                "Looking for something real in a swipe-right world. I love exploring new neighborhoods, weekend hikes, and those deep late-night conversations. Looking for someone kind, curious, and down to build something great together.",
                "I believe in showing up fully — for the people I care about and the things I'm passionate about. Love traveling, live music, and learning to be a better cook. Here to find my person.",
                "Moved here recently and fell in love with the city. Now looking for someone to share the best parts with. I value honesty, laughter, and being able to sit in comfortable silence."
            ],
            .bold: [
                "I'm the one your friends will say \"he seems fun\" about. Entrepreneur by day, amateur chef by night. I don't waste time — if we vibe, let's grab drinks this week.",
                "Main character energy only. Building cool things, staying active, and always planning the next trip. Looking for someone who matches my energy and isn't afraid to make the first move.",
                "Life's too short for boring dates — I'm planning the best one you've had this year. Bring your A-game and an appetite. Let's see if we've got chemistry."
            ]
        ]

        let options = bios[tone] ?? bios[.witty] ?? []
        DesignSystem.Haptics.success()
        return options.randomElement() ?? "Your profile is looking great!"
    }

    // MARK: - Generate Opening Lines

    func generateOpeningLines(
        matchName: String,
        platform: DatingPlatform,
        context: String? = nil
    ) async throws -> [String] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch ServiceMode.current {
        case .production:
            // LAUNCH TODO: Call Firebase Cloud Function "generateOpeningLines"
            // POST /generateOpeningLines { matchName, platform, context }
            return try await generateMockOpeningLines(matchName: matchName, context: context)

        case .mock:
            return try await generateMockOpeningLines(matchName: matchName, context: context)
        }
    }

    private func generateMockOpeningLines(matchName: String, context: String?) async throws -> [String] {
        try await Task.sleep(nanoseconds: 1_200_000_000)

        let lines: [[String]] = [
            [
                "Hey \(matchName)! I noticed \(context ?? "your profile") — gotta say, you've got great taste. What's the best thing you've done this week?",
                "Okay \(matchName), I need you to settle a debate: pineapple on pizza — yay or nay? (Your answer determines everything 😄)",
                "I had a really good opening line prepared, \(matchName), but then I saw your profile and forgot it. So let's just skip to the good part — what's your go-to weekend plan?"
            ],
            [
                "\(matchName)! Your \(context ?? "vibe") caught my eye. Quick question: if you could teleport anywhere right now, where are we going?",
                "Alright \(matchName), I'm gonna be honest — I swiped right faster than I'd like to admit. So what's the one thing I should know about you?",
                "Hey \(matchName) 👋 I'm not great at small talk but excellent at planning fun dates. Want to skip straight to that part?"
            ]
        ]

        DesignSystem.Haptics.success()
        return lines.randomElement() ?? lines[0]
    }

    // MARK: - Hinge Prompts

    func generateHingePrompts() async throws -> [(prompt: String, answer: String)] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch ServiceMode.current {
        case .production:
            // LAUNCH TODO: Call Firebase Cloud Function "generateHingePrompts"
            return try await generateMockHingePrompts()

        case .mock:
            return try await generateMockHingePrompts()
        }
    }

    private func generateMockHingePrompts() async throws -> [(prompt: String, answer: String)] {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let prompts: [(String, String)] = [
            ("The way to win me over is", "Show up with curiosity and a willingness to try that weird restaurant I've been eyeing"),
            ("I'm looking for", "Someone who can match my energy at a concert AND my calm on a lazy Sunday morning"),
            ("A life goal of mine", "To visit every continent and have a local friend on each one to show me the hidden gems"),
            ("My most irrational fear", "That one day autocorrect will ruin the perfect text at the worst possible moment"),
            ("I bet you can't", "Name a better brunch spot than the one I found last weekend. Challenge accepted?"),
            ("Green flags I look for", "You send memes at appropriate times, tip well, and can laugh at yourself")
        ]

        DesignSystem.Haptics.success()
        return Array(prompts.shuffled().prefix(3))
    }

    // MARK: - Conversation Reply

    func suggestReply(
        to message: String,
        matchName: String,
        conversationContext: String? = nil
    ) async throws -> [String] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch ServiceMode.current {
        case .production:
            // LAUNCH TODO: Call Firebase Cloud Function "suggestReply"
            // POST /suggestReply { message, matchName, conversationContext }
            return try await generateMockReplies()

        case .mock:
            return try await generateMockReplies()
        }
    }

    private func generateMockReplies() async throws -> [String] {
        try await Task.sleep(nanoseconds: 800_000_000)

        let replies = [
            "That's awesome! I've actually been wanting to try that. When are you free this week?",
            "Haha no way 😂 okay you're already cooler than most people I've matched with. Tell me more!",
            "Love that energy. I feel like we'd get along really well — want to find out over coffee?"
        ]

        DesignSystem.Haptics.success()
        return replies
    }
}
