import Foundation
import StoreKit
import SwiftUI

// MARK: - App Rating Manager

@MainActor
final class AppRatingManager: ObservableObject {
    static let shared = AppRatingManager()

    @AppStorage("totalPhotosGenerated") private var totalPhotosGenerated = 0
    @AppStorage("totalSessionCount") private var totalSessionCount = 0
    @AppStorage("hasRatedApp") private var hasRatedApp = false
    @AppStorage("lastRatingPromptDate") private var lastRatingPromptDateInterval: Double = 0
    @AppStorage("ratingPromptsShown") private var ratingPromptsShown = 0

    private let maxPromptsPerYear = 3

    private init() {}

    // MARK: - Tracking

    func trackAppLaunch() {
        totalSessionCount += 1
        checkAndPrompt()
    }

    func trackPhotoGenerated() {
        totalPhotosGenerated += 1
        // Prompt after first successful generation
        if totalPhotosGenerated == 1 {
            promptForReviewAfterDelay(seconds: 2)
        }
    }

    // MARK: - Prompting Logic

    func checkAndPrompt() {
        guard !hasRatedApp else { return }
        guard ratingPromptsShown < maxPromptsPerYear else { return }
        guard daysSinceLastPrompt > 30 else { return }

        let shouldPrompt = totalSessionCount >= 5 && totalPhotosGenerated >= 2
        if shouldPrompt {
            promptForReviewAfterDelay(seconds: 3)
        }
    }

    func promptForReviewAfterDelay(seconds: Double) {
        guard !hasRatedApp else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.requestReview()
        }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        ratingPromptsShown += 1
        lastRatingPromptDateInterval = Date().timeIntervalSince1970
        AppStore.requestReview(in: scene)
    }

    func markAsRated() {
        hasRatedApp = true
    }

    // MARK: - Helpers

    private var daysSinceLastPrompt: Int {
        guard lastRatingPromptDateInterval > 0 else { return 999 }
        let last = Date(timeIntervalSince1970: lastRatingPromptDateInterval)
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 999
    }

    var stats: (sessions: Int, photos: Int, rated: Bool) {
        (totalSessionCount, totalPhotosGenerated, hasRatedApp)
    }
}
