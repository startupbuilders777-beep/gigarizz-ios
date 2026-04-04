import Foundation
import SwiftUI

// MARK: - Match Inbox ViewModel

@MainActor
final class MatchInboxViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var matches: [Match] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Message Cache

    private var messagesCache: [String: [ConversationMessage]] = [:]

    // MARK: - Computed

    var activeCount: Int { matches.filter { $0.status == .active && !$0.hasUnread }.count }
    var unreadCount: Int { matches.filter { $0.hasUnread }.count }
    var newMatchCount: Int { matches.filter { $0.status == .new && !$0.hasUnread && $0.lastMessage == nil }.count }

    // MARK: - Init

    init() {
        loadMatches()
    }

    // MARK: - Data Loading

    func loadMatches() {
        isLoading = true
        // Load from local cache first
        matches = Match.demoMatches.sorted { lhs, rhs in
            if lhs.inboxSortPriority != rhs.inboxSortPriority {
                return lhs.inboxSortPriority < rhs.inboxSortPriority
            }
            let lhsDate = lhs.lastMessageDate ?? lhs.matchedDate
            let rhsDate = rhs.lastMessageDate ?? rhs.matchedDate
            return lhsDate > rhsDate
        }

        // Seed demo messages for each match
        for match in matches {
            if messagesCache[match.id] == nil {
                messagesCache[match.id] = generateDemoMessages(for: match)
            }
        }

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isLoading = false
        }
    }

    func refresh() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadMatches()
        DesignSystem.Haptics.success()
    }

    // MARK: - Filtering

    func filteredMatches(searchText: String) -> [Match] {
        guard !searchText.isEmpty else {
            return sortedMatches(matches)
        }
        return sortedMatches(matches.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        })
    }

    private func sortedMatches(_ matches: [Match]) -> [Match] {
        matches.sorted { lhs, rhs in
            if lhs.inboxSortPriority != rhs.inboxSortPriority {
                return lhs.inboxSortPriority < rhs.inboxSortPriority
            }
            let lhsDate = lhs.lastMessageDate ?? lhs.matchedDate
            let rhsDate = rhs.lastMessageDate ?? rhs.matchedDate
            return lhsDate > rhsDate
        }
    }

    // MARK: - Actions

    func archiveMatch(_ match: Match) {
        guard let index = matches.firstIndex(where: { $0.id == match.id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            matches[index].status = .archived
            matches[index].hasUnread = false
        }
        DesignSystem.Haptics.medium()
    }

    func unmatch(_ match: Match) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            matches.removeAll { $0.id == match.id }
        }
        messagesCache.removeValue(forKey: match.id)
        DesignSystem.Haptics.heavy()
    }

    func markAsRead(_ match: Match) {
        guard let index = matches.firstIndex(where: { $0.id == match.id }) else { return }
        if matches[index].hasUnread {
            matches[index].hasUnread = false
            DesignSystem.Haptics.light()
        }
    }

    func sendMessage(_ text: String, to match: Match) {
        let message = ConversationMessage(
            id: UUID().uuidString,
            text: text,
            isFromMe: true,
            timestamp: Date()
        )

        if messagesCache[match.id] == nil {
            messagesCache[match.id] = []
        }
        messagesCache[match.id]?.append(message)

        // Update match's last message
        if let index = matches.firstIndex(where: { $0.id == match.id }) {
            matches[index].lastMessage = text
            matches[index].lastMessageDate = Date()
        }

        // Simulate reply after delay
        simulateReply(to: match)
    }

    func messages(for matchId: String) -> [ConversationMessage] {
        return messagesCache[matchId] ?? []
    }

    // MARK: - Demo Reply Simulation

    private func simulateReply(to match: Match) {
        let replies = [
            "That's so interesting! Tell me more 😊",
            "Haha I love that!",
            "Would love to hear more about that",
            "That sounds amazing!",
            "Can't wait to meet you! 💕"
        ]

        let delaySeconds = Double.random(in: 1.5...3.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
            guard let self else { return }

            let reply = ConversationMessage(
                id: UUID().uuidString,
                text: replies.randomElement() ?? "Hey! \u{1F60A}",
                isFromMe: false,
                timestamp: Date()
            )

            self.messagesCache[match.id]?.append(reply)

            if let index = self.matches.firstIndex(where: { $0.id == match.id }) {
                self.matches[index].lastMessage = reply.text
                self.matches[index].lastMessageDate = Date()
                self.matches[index].hasUnread = true
            }

            DesignSystem.Haptics.success()
        }
    }

    // MARK: - Demo Messages

    private func generateDemoMessages(for match: Match) -> [ConversationMessage] {
        var messages: [ConversationMessage] = []

        if let lastMsg = match.lastMessage {
            // Add the last message
            messages.append(ConversationMessage(
                id: UUID().uuidString,
                text: lastMsg,
                isFromMe: false,
                timestamp: match.lastMessageDate ?? Date()
            ))
        }

        if match.status == .active || match.hasUnread {
            messages.append(ConversationMessage(
                id: UUID().uuidString,
                text: "Hey! I saw your photos, they're really great 👋",
                isFromMe: false,
                timestamp: (match.lastMessageDate ?? Date()).addingTimeInterval(-86400)
            ))
        }

        return messages
    }
}
