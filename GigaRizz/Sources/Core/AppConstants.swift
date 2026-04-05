import Foundation

/// Centralized app constants — URLs, API keys, and configuration.
/// Replace placeholder keys before App Store submission.
enum AppConstants {

    // MARK: - Legal URLs

    // swiftlint:disable:next force_unwrapping
    static let termsURL = URL(string: "https://www.gigarizz.app/terms")!
    // swiftlint:disable:next force_unwrapping
    static let privacyURL = URL(string: "https://www.gigarizz.app/privacy")!
    static let supportEmail = "support@gigarizz.app"

    // MARK: - RevenueCat

    /// Replace with your real RevenueCat Apple API key from https://app.revenuecat.com
    static let revenueCatAPIKey = "appl_REPLACE_WITH_YOUR_REVENUECAT_KEY"

    // MARK: - PostHog

    /// Replace with your real PostHog project API key from https://us.posthog.com
    static let postHogAPIKey = "phc_REPLACE_WITH_YOUR_POSTHOG_KEY"
    static let postHogHost = "https://us.i.posthog.com"

    // MARK: - Backend API

    /// GigaRizz FastAPI backend URL.
    /// In development, points to local server. In production, update to your deployed URL.
    #if DEBUG
    static let backendBaseURL = "http://localhost:8000"
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
}
