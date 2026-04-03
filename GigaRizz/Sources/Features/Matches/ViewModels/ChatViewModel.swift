import Foundation
import SwiftUI

// MARK: - Chat View Model

@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var suggestions: [ChatSuggestion] = []
    @Published var inputText: String = ""
    @Published var isLoadingSuggestions: Bool = false
    @Published var showSuggestionBar: Bool = true
    @Published var dailySuggestionCount: Int = 0
    @Published var errorMessage: String?

    // MARK: - Constants

    let maxFreeSuggestionsPerDay: Int = 20

    // MARK: - Private Properties

    private let coachService = CoachService.shared
    private let match: Match
    private var lastSuggestionTime: Date?

    // MARK: - Computed Properties

    var hasUnreadMessages: Bool {
        messages.contains { !$0.isFromUser && !$0.isRead }
    }

    var lastMatchMessage: ChatMessage? {
        messages.last { !$0.isFromUser }
    }

    var canGenerateSuggestions: Bool {
        // TODO: Check subscription tier for unlimited
        dailySuggestionCount < maxFreeSuggestionsPerDay
    }

    // MARK: - Init

    init(match: Match, messages: [ChatMessage] = []) {
        self.match = match
        self.messages = messages.isEmpty ? ChatMessage.demoConversation : messages

        // Generate initial suggestions if there's an unread message
        if hasUnreadMessages {
            Task { await generateSuggestions() }
        }
    }

    // MARK: - Generate Suggestions

    func generateSuggestions() async {
        guard canGenerateSuggestions, let lastMessage = lastMatchMessage else { return }

        isLoadingSuggestions = true
        errorMessage = nil

        do {
            let generatedTexts = try await coachService.suggestReply(
                to: lastMessage.content,
                matchName: match.name
            )

            suggestions = generatedTexts.enumerated().map { index, text in
                let types: [SuggestionType] = [.continueTopic, .flirty, .changeSubject]
                return ChatSuggestion(text: text, type: types[safe: index] ?? .continueTopic)
            }

            dailySuggestionCount += 1
            lastSuggestionTime = Date()

            DesignSystem.Haptics.success()
        } catch {
            // Graceful degradation — show no suggestions rather than error
            suggestions = []
            errorMessage = nil
        }

        isLoadingSuggestions = false
    }

    // MARK: - Apply Suggestion

    func applySuggestion(_ suggestion: ChatSuggestion) {
        inputText = suggestion.text
        showSuggestionBar = false
        DesignSystem.Haptics.light()
    }

    // MARK: - Send Message

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = ChatMessage(content: inputText, isFromUser: true)
        messages.append(message)

        let sentText = inputText
        inputText = ""
        showSuggestionBar = true

        DesignSystem.Haptics.medium()

        // Regenerate suggestions after sending
        // (simulate match response after delay for demo)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await generateSuggestions()
        }
    }

    // MARK: - Mark as Read

    func markMessagesAsRead() {
        for index in messages.indices where !messages[index].isFromUser {
            messages[index].isRead = true
        }
    }

    // MARK: - Provide Feedback

    func provideFeedback(_ suggestion: ChatSuggestion, feedback: SuggestionFeedback) {
        if let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            suggestions[index].feedback = feedback
            DesignSystem.Haptics.light()
        }
    }

    // MARK: - Refresh Suggestions

    func refreshSuggestions() async {
        suggestions = []
        await generateSuggestions()
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
