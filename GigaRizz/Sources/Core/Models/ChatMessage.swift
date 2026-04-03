import Foundation

// MARK: - Chat Message

/// Represents a single message in a conversation with a match.
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    var isRead: Bool

    init(
        id: String = UUID().uuidString,
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        isRead: Bool = true
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isRead = isRead
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Suggestion Type

/// Categories for reply suggestions.
enum SuggestionType: String, CaseIterable, Identifiable {
    case continueTopic = "Follow-up"
    case flirty = "Flirty"
    case changeSubject = "New Topic"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .continueTopic: return "arrow.clockwise"
        case .flirty: return "heart.fill"
        case .changeSubject: return "arrow.right"
        }
    }
}

// MARK: - Chat Suggestion

/// A contextual reply suggestion for the user.
struct ChatSuggestion: Identifiable, Equatable {
    let id: String
    let text: String
    let type: SuggestionType
    var feedback: SuggestionFeedback?

    init(
        id: String = UUID().uuidString,
        text: String,
        type: SuggestionType
    ) {
        self.id = id
        self.text = text
        self.type = type
    }
}

// MARK: - Suggestion Feedback

/// User feedback on a suggestion to improve future generations.
enum SuggestionFeedback: String, Codable {
    case positive = "liked"
    case negative = "disliked"
}

// MARK: - Demo Messages

extension ChatMessage {
    /// Demo conversation for previews and testing.
    static let demoConversation: [ChatMessage] = [
        ChatMessage(content: "Hey! I just got back from Japan, the food was incredible! 🍣", isFromUser: false, timestamp: Date().addingTimeInterval(-3600), isRead: true),
        ChatMessage(content: "That sounds amazing! Where did you go?", isFromUser: true, timestamp: Date().addingTimeInterval(-3500)),
        ChatMessage(content: "Tokyo and Osaka! The street food in Osaka was next level", isFromUser: false, timestamp: Date().addingTimeInterval(-3400), isRead: false)
    ]
}
