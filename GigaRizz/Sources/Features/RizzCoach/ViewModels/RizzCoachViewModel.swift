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
        loadDemoData()
    }

    // MARK: - Data Loading

    func loadDemoData() {
        rizzScore = RizzScore.demo
        weeklyReport = WeeklyRizzReport.demo
        photoPerformances = PhotoPerformance.demoPerformances
        bioStrength = BioStrength.demo
        responseTimeStats = ResponseTimeStats.demo
        dailyTip = DailyTip.demo
        lastRefreshDate = Date()
    }

    func refreshAllData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            // In production: fetch from backend/local storage
            loadDemoData()
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
            // Aggregate from: photo scoring history, bio analysis, match activity
            rizzScore = RizzScore.demo
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
        } catch {}
        isLoading = false
    }
}
