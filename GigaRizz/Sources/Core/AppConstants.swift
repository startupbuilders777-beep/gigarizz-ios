import Foundation

/// Centralized app constants for URLs, service keys, and configuration.
enum AppConstants {

    // MARK: - Legal URLs

    // swiftlint:disable:next force_unwrapping
    static let termsURL = URL(string: "https://www.gigarizz.app/terms")!
    // swiftlint:disable:next force_unwrapping
    static let privacyURL = URL(string: "https://www.gigarizz.app/privacy")!
    static let supportEmail = "support@gigarizz.app"

    // MARK: - RevenueCat

    static let revenueCatAPIKey = bundleString("REVENUECAT_API_KEY")

    static var isRevenueCatConfigured: Bool {
        isUsableSecret(revenueCatAPIKey)
    }

    // MARK: - PostHog

    static let postHogAPIKey = bundleString("POSTHOG_API_KEY")
    static let postHogHost = "https://us.i.posthog.com"

    static var isPostHogConfigured: Bool {
        isUsableSecret(postHogAPIKey)
    }

    // MARK: - Backend API

    /// GigaRizz FastAPI backend URL.
    /// In development, points to local server. In production, update to your deployed URL.
    #if DEBUG
    static var backendBaseURL: String {
        if let argIndex = CommandLine.arguments.firstIndex(of: "-dev_backend_base_url"),
           CommandLine.arguments.indices.contains(argIndex + 1) {
            return CommandLine.arguments[argIndex + 1]
        }
        if let override = UserDefaults.standard.string(forKey: "dev_backend_base_url"),
           !override.isEmpty {
            return override
        }
        return "http://localhost:8000"
    }
    #else
    static let backendBaseURL = "https://api.gigarizz.app"
    #endif

    // MARK: - RevenueCat Entitlements

    static let entitlementGold = "gold"
    static let entitlementPlus = "plus"

    // MARK: - RevenueCat Offering IDs

    static let offeringDefault = "default"

    // MARK: - UserDefaults Keys

    static let dailyPhotosUsedKey = "daily_photos_used"
    static let dailyPhotosDateKey = "daily_photos_date"
    static let onboardingCompletedKey = "onboarding_has_completed"
    static let onboardingSeenKey = "onboarding_has_seen"

    // MARK: - Helpers

    private static func bundleString(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return ""
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isUsableSecret(_ value: String) -> Bool {
        !value.isEmpty
            && !value.contains("REPLACE")
            && !value.contains("$(")
    }
}
