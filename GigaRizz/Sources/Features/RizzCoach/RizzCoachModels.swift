import Foundation

// MARK: - Rizz Score

/// Composite score (1-100) representing overall dating profile quality.
struct RizzScore: Codable, Equatable {
    let overallScore: Int
    let categories: [RizzScoreCategory]
    let lastUpdated: Date
    let previousScore: Int?
    let trend: ScoreTrend

    enum ScoreTrend: String, Codable {
        case improving = "Improving"
        case stable = "Stable"
        case declining = "Needs Attention"
    }

    init(
        overallScore: Int,
        categories: [RizzScoreCategory],
        lastUpdated: Date = Date(),
        previousScore: Int? = nil,
        trend: ScoreTrend = .stable
    ) {
        self.overallScore = min(100, max(1, overallScore))
        self.categories = categories
        self.lastUpdated = lastUpdated
        self.previousScore = previousScore
        self.trend = trend
    }

    /// Demo score for previews.
    static let demo = RizzScore(
        overallScore: 72,
        categories: [
            RizzScoreCategory(name: "Photos", score: 75, weight: 0.35, icon: "photo.fill"),
            RizzScoreCategory(name: "Bio", score: 68, weight: 0.25, icon: "text.quote"),
            RizzScoreCategory(name: "Activity", score: 82, weight: 0.20, icon: "chart.line.uptrend.xyaxis"),
            RizzScoreCategory(name: "Response Time", score: 60, weight: 0.15, icon: "clock.fill"),
            RizzScoreCategory(name: "Prompts", score: 70, weight: 0.10, icon: "text.badge.star")
        ],
        previousScore: 65,
        trend: .improving
    )
}

// MARK: - Rizz Score Category

/// Individual category contributing to the overall Rizz Score.
struct RizzScoreCategory: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let score: Int
    let weight: Double
    let icon: String
    var feedback: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        score: Int,
        weight: Double,
        icon: String,
        feedback: String? = nil
    ) {
        self.id = id
        self.name = name
        self.score = min(100, max(1, score))
        self.weight = weight
        self.icon = icon
        self.feedback = feedback
    }
}

// MARK: - Weekly Rizz Report

/// Weekly summary of profile improvements and insights.
struct WeeklyRizzReport: Identifiable, Codable {
    let id: String
    let weekStartDate: Date
    let weekEndDate: Date
    let scoreChange: Int
    let insights: [RizzInsight]
    let topActions: [RizzAction]
    let milestone: String?

    init(
        id: String = UUID().uuidString,
        weekStartDate: Date,
        weekEndDate: Date,
        scoreChange: Int,
        insights: [RizzInsight],
        topActions: [RizzAction],
        milestone: String? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.scoreChange = scoreChange
        self.insights = insights
        self.topActions = topActions
        self.milestone = milestone
    }

    /// Demo report for previews.
    static let demo = WeeklyRizzReport(
        weekStartDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
        weekEndDate: Date(),
        scoreChange: 7,
        insights: [
            RizzInsight(type: .photo, title: "New top photo detected", description: "Your golden hour shot is now your #1 performer"),
            RizzInsight(type: .bio, title: "Bio engagement up 23%", description: "Your updated bio is getting more profile views"),
            RizzInsight(type: .response, title: "Response time improved", description: "Down from 18h to 6h average — great progress!")
        ],
        topActions: [
            RizzAction(priority: 1, title: "Replace Photo #3", description: "It's your weakest performer. Try a full-body shot."),
            RizzAction(priority: 2, title: "Add a hobby photo", description: "Photos showing activities get 2x more matches."),
            RizzAction(priority: 3, title: "Respond within 2h today", description: "3 matches are waiting for your reply.")
        ],
        milestone: "Rizz Score crossed 70! You're now in the top 30%."
    )
}

// MARK: - Rizz Insight

/// Individual insight in a weekly report.
struct RizzInsight: Identifiable, Codable {
    let id: String
    let type: InsightType
    let title: String
    let description: String

    enum InsightType: String, Codable {
        case photo = "Photos"
        case bio = "Bio"
        case response = "Response"
        case activity = "Activity"
        case prompts = "Prompts"
    }

    init(
        id: String = UUID().uuidString,
        type: InsightType,
        title: String,
        description: String
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
    }
}

// MARK: - Rizz Action

/// Actionable improvement suggestion.
struct RizzAction: Identifiable, Codable {
    let id: String
    let priority: Int
    let title: String
    let description: String

    init(
        id: String = UUID().uuidString,
        priority: Int,
        title: String,
        description: String
    ) {
        self.id = id
        self.priority = priority
        self.title = title
        self.description = description
    }
}

// MARK: - Photo Performance

/// Performance metrics for a single photo.
struct PhotoPerformance: Identifiable, Codable {
    let id: String
    let photoId: String
    let rank: Int
    let swipeRate: Double
    let matchRate: Double
    let thumbnailURL: URL?
    let feedback: String

    init(
        id: String = UUID().uuidString,
        photoId: String,
        rank: Int,
        swipeRate: Double,
        matchRate: Double,
        thumbnailURL: URL? = nil,
        feedback: String
    ) {
        self.id = id
        self.photoId = photoId
        self.rank = rank
        self.swipeRate = swipeRate
        self.matchRate = matchRate
        self.thumbnailURL = thumbnailURL
        self.feedback = feedback
    }

    /// Demo performances for previews.
    static let demoPerformances: [PhotoPerformance] = [
        PhotoPerformance(photoId: "1", rank: 1, swipeRate: 0.82, matchRate: 0.24, feedback: "Your top performer! Great lighting and genuine smile."),
        PhotoPerformance(photoId: "2", rank: 2, swipeRate: 0.68, matchRate: 0.18, feedback: "Strong second photo. Consider more eye contact."),
        PhotoPerformance(photoId: "3", rank: 3, swipeRate: 0.45, matchRate: 0.08, feedback: "This photo underperforms. Replace with action shot."),
        PhotoPerformance(photoId: "4", rank: 4, swipeRate: 0.32, matchRate: 0.05, feedback: "Low engagement. Too dark and cluttered background.")
    ]
}

// MARK: - Bio Strength

/// Analysis of dating profile bio quality.
struct BioStrength: Codable {
    let overallScore: Int
    let voiceConsistency: Int
    let specificity: Int
    let hookQuality: Int
    let lengthScore: Int
    let suggestions: [String]

    init(
        overallScore: Int,
        voiceConsistency: Int,
        specificity: Int,
        hookQuality: Int,
        lengthScore: Int,
        suggestions: [String]
    ) {
        self.overallScore = min(100, max(1, overallScore))
        self.voiceConsistency = min(100, max(1, voiceConsistency))
        self.specificity = min(100, max(1, specificity))
        self.hookQuality = min(100, max(1, hookQuality))
        self.lengthScore = min(100, max(1, lengthScore))
        self.suggestions = suggestions
    }

    /// Demo bio strength for previews.
    static let demo = BioStrength(
        overallScore: 68,
        voiceConsistency: 75,
        specificity: 60,
        hookQuality: 70,
        lengthScore: 65,
        suggestions: [
            "Add a specific hobby or interest (e.g., 'weekend hiking' instead of 'outdoorsy')",
            "Include a conversation hook — a question or bold statement",
            "Your opening line is generic — try something memorable",
            "Consider mentioning what you're looking for more directly"
        ]
    )
}

// MARK: - Response Time Stats

/// Response time tracking and analysis.
struct ResponseTimeStats: Codable {
    let averageResponseHours: Double
    let fastestResponseHours: Double
    let slowestResponseHours: Double
    let streak: Int
    let nudgeMessage: String?
    let improvementTip: String

    init(
        averageResponseHours: Double,
        fastestResponseHours: Double,
        slowestResponseHours: Double,
        streak: Int,
        nudgeMessage: String? = nil,
        improvementTip: String
    ) {
        self.averageResponseHours = averageResponseHours
        self.fastestResponseHours = fastestResponseHours
        self.slowestResponseHours = slowestResponseHours
        self.streak = streak
        self.nudgeMessage = nudgeMessage
        self.improvementTip = improvementTip
    }

    /// Demo stats for previews.
    static let demo = ResponseTimeStats(
        averageResponseHours: 6.2,
        fastestResponseHours: 0.5,
        slowestResponseHours: 18.0,
        streak: 3,
        nudgeMessage: "3 matches are waiting! Respond now to keep your streak.",
        improvementTip: "Responding within 2 hours increases match retention by 40%."
    )
}

// MARK: - Daily Tip

/// Daily actionable dating tip.
struct DailyTip: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: TipCategory
    let actionTitle: String
    let createdAt: Date

    enum TipCategory: String, Codable {
        case photo = "Photos"
        case bio = "Bio"
        case conversation = "Conversation"
        case activity = "Activity"
        case timing = "Timing"
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: TipCategory,
        actionTitle: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.actionTitle = actionTitle
        self.createdAt = createdAt
    }

    /// Demo tip for previews.
    static let demo = DailyTip(
        title: "Golden Hour Magic",
        description: "Photos taken 1 hour before sunset get 2x more matches. Plan your next photo session for 6-7pm today.",
        category: .photo,
        actionTitle: "Schedule Photo Session"
    )
}
