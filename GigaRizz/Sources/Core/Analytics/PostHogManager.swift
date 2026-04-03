import Foundation
import PostHog

/// Centralized analytics manager using PostHog.
@MainActor
final class PostHogManager: ObservableObject {
    // MARK: - Singleton

    static let shared = PostHogManager()

    // MARK: - Properties

    private(set) var isInitialized = false

    // MARK: - Init

    init() {}

    // MARK: - PostHog Configuration

    func initPostHog() {
        // PostHog SDK will be initialized when Firebase config is available.
        // Placeholder: in production, use actual API key from Firebase config.
        isInitialized = true
    }

    // MARK: - Identify

    func identify(userId: String, properties: [String: Any] = [:]) {
        guard isInitialized else { return }
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    func reset() {
        PostHogSDK.shared.reset()
    }

    // MARK: - Screen Views

    func screenView(name: String, properties: [String: Any] = [:]) {
        guard isInitialized else { return }
        var props = properties
        props["screen_name"] = name
        PostHogSDK.shared.capture("screen_view", properties: props)
    }

    // MARK: - Photo Events

    func trackPhotoGenerated(style: String, tier: String, photoCount: Int) {
        track("photo_generated", properties: [
            "style": style,
            "tier": tier,
            "photo_count": photoCount
        ])
    }

    func trackPhotoDownloaded(style: String) {
        track("photo_downloaded", properties: [
            "style": style
        ])
    }

    // MARK: - Onboarding Events

    func trackOnboardingCompleted() {
        track("onboarding_completed")
    }

    // MARK: - Subscription Events

    func trackPaywallViewed(trigger: String, variant: String? = nil) {
        var properties: [String: Any] = ["trigger": trigger]
        if let variant = variant {
            properties["variant"] = variant
        }
        track("subscription_paywall_viewed", properties: properties)
    }

    func trackSubscriptionStarted(plan: String, amount: Double) {
        track("subscription_started", properties: [
            "plan": plan,
            "amount": amount,
            "currency": "USD",
            "payment_method": "apple_iap"
        ])
    }

    func trackSubscriptionCancelled(plan: String) {
        track("subscription_cancelled", properties: [
            "plan": plan
        ])
    }

    // MARK: - Referral Events

    func trackReferralCodeShared() {
        track("referral_code_shared")
    }

    // MARK: - Private

    func track(_ event: String, properties: [String: Any] = [:]) {
        guard isInitialized else { return }
        var allProperties = properties
        allProperties["timestamp"] = ISO8601DateFormatter().string(from: Date())
        allProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        PostHogSDK.shared.capture(event, properties: allProperties)
    }
}
