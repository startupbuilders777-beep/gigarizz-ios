import Foundation

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

    init(
        id: String = UUID().uuidString,
        name: String,
        platform: DatingPlatform = .tinder,
        status: MatchStatus = .new,
        notes: String = "",
        lastMessageDate: Date? = nil,
        matchedDate: Date = Date(),
        photoName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.status = status
        self.notes = notes
        self.lastMessageDate = lastMessageDate
        self.matchedDate = matchedDate
        self.photoName = photoName
    }

    var daysSinceLastMessage: Int? {
        guard let last = lastMessageDate else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }

    var isStale: Bool {
        guard let days = daysSinceLastMessage else { return false }
        return days >= 3
    }
}

// MARK: - Dating Platform

enum DatingPlatform: String, Codable, CaseIterable, Identifiable {
    case tinder = "Tinder"
    case hinge = "Hinge"
    case bumble = "Bumble"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tinder: return "flame.fill"
        case .hinge: return "heart.text.square.fill"
        case .bumble: return "bolt.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .tinder: return DesignSystem.Colors.tinder
        case .hinge: return DesignSystem.Colors.hinge
        case .bumble: return DesignSystem.Colors.bumble
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

    var color: SwiftUI.Color {
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
        Match(name: "Sarah", platform: .tinder, status: .active, notes: "Loves hiking", lastMessageDate: Date().addingTimeInterval(-3600), matchedDate: Date().addingTimeInterval(-86400)),
        Match(name: "Emma", platform: .hinge, status: .new, matchedDate: Date()),
        Match(name: "Jessica", platform: .bumble, status: .stale, lastMessageDate: Date().addingTimeInterval(-259200), matchedDate: Date().addingTimeInterval(-432000)),
        Match(name: "Olivia", platform: .tinder, status: .dateScheduled, notes: "Coffee at Blue Bottle on Saturday", lastMessageDate: Date().addingTimeInterval(-7200), matchedDate: Date().addingTimeInterval(-172800)),
        Match(name: "Ava", platform: .hinge, status: .ghosted, lastMessageDate: Date().addingTimeInterval(-604800), matchedDate: Date().addingTimeInterval(-864000)),
    ]
}

import SwiftUI
