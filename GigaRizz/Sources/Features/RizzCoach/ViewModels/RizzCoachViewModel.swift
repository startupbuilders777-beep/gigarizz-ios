import Foundation
import SwiftUI

// MARK: - Rizz Coach ViewModel

@MainActor
final class RizzCoachViewModel: ObservableObject {
    // MARK: - Published State

    @Published var rizzScore: RizzScore?
    @Published var weeklyReport: WeeklyRizzReport?
    @Published var photoPerformances: [PhotoPerformance] = []
    @Published var bioStrength: BioStrength?
    @Published var responseTimeStats: ResponseTimeStats?
    @Published var dailyTip: DailyTip?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var showScoreAnimation = false
    @Published var hasOptedInCloudSync = false

    // MARK: - Dependencies

    private let coachService = CoachService.shared
    private var lastRefreshDate: Date?

    // MARK: - Computed Properties

    var scoreChangeDisplay: String {
        guard let previous = rizzScore?.previousScore else { return "" }
        let change = rizzScore?.overallScore ?? 0 - previous
        if change > 0 { return "+\(change)" }
        if change < 0 { return "\(change)" }
        return "±0"
    }

    var needsRefresh: Bool {
        guard let lastRefresh = lastRefreshDate else { return true }
        return Date().timeIntervalSince(lastRefresh) > 3600 // 1 hour
    }

    // MARK: - Init

    init() {
        loadLocalData()
    }

    // MARK: - Data Loading

    /// Load from local gallery data to derive scores, or fall back to demo in DEBUG.
    private func loadLocalData() {
        // Derive photo count from real gallery data
        let photosKey = "gigarizz_generated_photos"
        var photoCount = 0
        var styleCount = 0
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
            photoCount = photos.count
            styleCount = Set(photos.map { $0.style }).count
        }

        if photoCount > 0 {
            // Build a real-ish score based on actual usage
            let photoScore = min(100, 50 + photoCount * 3)
            let bioScore = 65 // Will be updated when bio is analyzed by backend
            let activityScore = min(100, 40 + photoCount * 5)
            let overallScore = (photoScore * 35 + bioScore * 25 + activityScore * 20 + 60 * 15 + 70 * 10) / 100

            rizzScore = RizzScore(
                overallScore: overallScore,
                categories: [
                    RizzScoreCategory(name: "Photos", score: photoScore, weight: 0.35, icon: "photo.fill"),
                    RizzScoreCategory(name: "Bio", score: bioScore, weight: 0.25, icon: "text.quote"),
                    RizzScoreCategory(name: "Activity", score: activityScore, weight: 0.20, icon: "chart.line.uptrend.xyaxis"),
                    RizzScoreCategory(name: "Response Time", score: 60, weight: 0.15, icon: "clock.fill"),
                    RizzScoreCategory(name: "Prompts", score: 70, weight: 0.10, icon: "text.badge.star")
                ],
                previousScore: nil,
                trend: .stable
            )
            photoPerformances = []
            weeklyReport = nil
            bioStrength = nil
            responseTimeStats = nil
            dailyTip = DailyTip.demo // Tips are always useful
        } else {
            #if DEBUG
            // Demo data for previews/development only
            rizzScore = RizzScore.demo
            weeklyReport = WeeklyRizzReport.demo
            photoPerformances = PhotoPerformance.demoPerformances
            bioStrength = BioStrength.demo
            responseTimeStats = ResponseTimeStats.demo
            dailyTip = DailyTip.demo
            #else
            // Production: show empty state prompting user to generate photos
            rizzScore = nil
            weeklyReport = nil
            photoPerformances = []
            bioStrength = nil
            responseTimeStats = nil
            dailyTip = DailyTip.demo
            #endif
        }
        lastRefreshDate = Date()
    }

    func refreshAllData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            let previousScore = rizzScore?.overallScore
            loadLocalData()
            if let prev = previousScore {
                rizzScore = RizzScore(
                    overallScore: rizzScore?.overallScore ?? 0,
                    categories: rizzScore?.categories ?? [],
                    previousScore: prev,
                    trend: (rizzScore?.overallScore ?? 0) > prev ? .improving : .stable
                )
            }
            animateScoreIncrease()
            DesignSystem.Haptics.success()
        } catch {
            errorMessage = "Failed to refresh data. Please try again."
            DesignSystem.Haptics.error()
        }

        isRefreshing = false
        lastRefreshDate = Date()
    }

    func calculateRizzScore() async {
        isLoading = true

        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            let previousScore = rizzScore?.overallScore
            loadLocalData()
            if let prev = previousScore {
                rizzScore = RizzScore(
                    overallScore: rizzScore?.overallScore ?? 0,
                    categories: rizzScore?.categories ?? [],
                    previousScore: prev,
                    trend: (rizzScore?.overallScore ?? 0) > prev ? .improving : .stable
                )
            }
            animateScoreIncrease()
            DesignSystem.Haptics.medium()
        } catch {
            errorMessage = "Score calculation failed"
        }

        isLoading = false
    }

    // MARK: - Score Animation

    func animateScoreIncrease() {
        guard rizzScore?.previousScore != nil else { return }
        showScoreAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showScoreAnimation = false
        }
    }

    // MARK: - Actions

    func completeAction(_ action: RizzAction) {
        DesignSystem.Haptics.light()
        // In production: mark action as complete, recalculate score
    }

    func optInCloudSync() {
        hasOptedInCloudSync = true
        DesignSystem.Haptics.success()
        // In production: enable cloud sync via Firebase
    }

    func dismissTip() {
        dailyTip = nil
        DesignSystem.Haptics.light()
    }

    func getNewTip() async {
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            dailyTip = DailyTip(
                title: "Eye Contact Wins",
                description: "Photos with direct eye contact receive 35% more right swipes. Look at the camera lens, not the screen.",
                category: .photo,
                actionTitle: "Learn More"
            )
            DesignSystem.Haptics.light()
        } catch {
            // Tip loading is non-critical; silently fall back to current tip
        }
        isLoading = false
    }
}
