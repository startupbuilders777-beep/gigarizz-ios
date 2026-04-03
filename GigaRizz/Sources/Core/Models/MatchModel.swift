import Foundation
import SwiftUI

// MARK: - Match

/// Represents a dating match tracked by the user.
struct Match: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var platform: DatingPlatform
    var status: MatchStatus
    var notes: String
    var lastMessageDate: Date?
    let matchedDate: Date
    var photoName: String? // SF Symbol or initial
    var hasUnread: Bool
    var lastMessage: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        platform: DatingPlatform = .tinder,
        status: MatchStatus = .new,
        notes: String = "",
        lastMessageDate: Date? = nil,
        matchedDate: Date = Date(),
        photoName: String? = nil,
        hasUnread: Bool = false,
        lastMessage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.status = status
        self.notes = notes
        self.lastMessageDate = lastMessageDate
        self.matchedDate = matchedDate
        self.photoName = photoName
        self.hasUnread = hasUnread
        self.lastMessage = lastMessage
    }

    var daysSinceLastMessage: Int? {
        guard let last = lastMessageDate else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }

    var isStale: Bool {
        guard let days = daysSinceLastMessage else { return false }
        return days >= 3
    }

    /// Priority for inbox sorting: 0 = unread, 1 = new match, 2 = active, 3 = stale/ghosted, 4 = archived
    var inboxSortPriority: Int {
        if hasUnread { return 0 }
        if status == .new && lastMessage == nil { return 1 }
        if status == .active || status == .dateScheduled { return 2 }
        if status == .stale || status == .ghosted { return 3 }
        if status == .archived { return 4 }
        return 2
    }
}

// MARK: - Inbox Badge

enum InboxBadge: Equatable {
    case unread
    case newMatch
    case active
    case stale
    case ghosted
    case dateScheduled
    case archived

    static func from(match: Match) -> InboxBadge {
        if match.hasUnread { return .unread }
        if match.status == .new && match.lastMessage == nil { return .newMatch }
        switch match.status {
        case .new, .active: return .active
        case .stale: return .stale
        case .ghosted: return .ghosted
        case .dateScheduled: return .dateScheduled
        case .archived: return .archived
        }
    }

    var icon: String {
        switch self {
        case .unread: return "circle.fill"
        case .newMatch: return "sparkles"
        case .active: return "message.fill"
        case .stale: return "clock.fill"
        case .ghosted: return "eye.slash.fill"
        case .dateScheduled: return "calendar.badge.checkmark"
        case .archived: return "archivebox.fill"
        }
    }

    var label: String {
        switch self {
        case .unread: return "Unread"
        case .newMatch: return "New"
        case .active: return "Active"
        case .stale: return "Stale"
        case .ghosted: return "Ghosted"
        case .dateScheduled: return "Date"
        case .archived: return "Archived"
        }
    }

    var color: Color {
        switch self {
        case .unread: return Color(red: 1.0, green: 0.42, blue: 0.21) // Flame Orange
        case .newMatch: return Color(red: 0.0, green: 0.78, blue: 0.33) // Success Green
        case .active: return Color(red: 1.0, green: 0.42, blue: 0.21) // Flame Orange
        case .stale: return Color(red: 1.0, green: 0.7, blue: 0.0) // Warning Gold
        case .ghosted: return Color(red: 1.0, green: 0.24, blue: 0.44) // Error Red
        case .dateScheduled: return .cyan
        case .archived: return Color(red: 0.63, green: 0.63, blue: 0.69) // Text Secondary
        }
    }
}

// MARK: - Dating Platform

enum DatingPlatform: String, Codable, CaseIterable, Identifiable {
    case tinder = "Tinder"
    case hinge = "Hinge"
    case bumble = "Bumble"
    case raya = "Raya"
    case general = "General"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tinder: return "flame.fill"
        case .hinge: return "heart.text.square.fill"
        case .bumble: return "bolt.fill"
        case .raya: return "star.circle.fill"
        case .general: return "app.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .tinder: return DesignSystem.Colors.tinder
        case .hinge: return DesignSystem.Colors.hinge
        case .bumble: return DesignSystem.Colors.bumble
        case .raya: return .purple
        case .general: return DesignSystem.Colors.flameOrange
        case .other: return DesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - Match Status

enum MatchStatus: String, Codable, CaseIterable, Identifiable {
    case new = "New"
    case active = "Active"
    case stale = "Stale"
    case ghosted = "Ghosted"
    case dateScheduled = "Date Scheduled"
    case archived = "Archived"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .new: return "sparkles"
        case .active: return "message.fill"
        case .stale: return "clock.fill"
        case .ghosted: return "eye.slash.fill"
        case .dateScheduled: return "calendar.badge.checkmark"
        case .archived: return "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .new: return DesignSystem.Colors.success
        case .active: return DesignSystem.Colors.flameOrange
        case .stale: return DesignSystem.Colors.warning
        case .ghosted: return DesignSystem.Colors.error
        case .dateScheduled: return .cyan
        case .archived: return DesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - Demo Data

extension Match {
    static let demoMatches: [Match] = [
        Match(
            name: "Sarah",
            platform: .tinder,
            status: .active,
            notes: "Loves hiking",
            lastMessageDate: Date().addingTimeInterval(-3600),
            matchedDate: Date().addingTimeInterval(-86400),
            hasUnread: true,
            lastMessage: "That sounds amazing! 🥾"
        ),
        Match(
            name: "Emma",
            platform: .hinge,
            status: .new,
            matchedDate: Date(),
            hasUnread: false,
            lastMessage: nil
        ),
        Match(
            name: "Jessica",
            platform: .bumble,
            status: .stale,
            lastMessageDate: Date().addingTimeInterval(-259200),
            matchedDate: Date().addingTimeInterval(-432000),
            hasUnread: false,
            lastMessage: "Hey! How's your week going?"
        ),
        Match(
            name: "Olivia",
            platform: .tinder,
            status: .dateScheduled,
            notes: "Coffee at Blue Bottle on Saturday",
            lastMessageDate: Date().addingTimeInterval(-7200),
            matchedDate: Date().addingTimeInterval(-172800),
            hasUnread: false,
            lastMessage: "Can't wait for Saturday! ☕"
        ),
        Match(
            name: "Ava",
            platform: .hinge,
            status: .ghosted,
            lastMessageDate: Date().addingTimeInterval(-604800),
            matchedDate: Date().addingTimeInterval(-864000),
            hasUnread: false,
            lastMessage: "So what are you up to this weekend?"
        ),
        Match(
            name: "Mia",
            platform: .tinder,
            status: .active,
            lastMessageDate: Date().addingTimeInterval(-1800),
            matchedDate: Date().addingTimeInterval(-43200),
            hasUnread: true,
            lastMessage: "Your photos are so cool! Where was that taken?"
        )
    ]
}