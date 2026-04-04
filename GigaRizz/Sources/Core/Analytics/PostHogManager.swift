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

    /// Called after PostHogSDK.shared.setup() is done in GigaRizzApp.init().
    /// This simply flips the gate so track calls start flowing.
    func markInitialized() {
        isInitialized = true
    }

    /// Legacy entry point — kept for call-site compatibility.
    func initPostHog() {
        markInitialized()
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

    // MARK: - Funnel Events

    func trackAppOpened() {
        track("app_opened")
    }

    func trackSignInCompleted(method: String) {
        track("sign_in_completed", properties: ["method": method])
    }

    func trackSignUpCompleted(method: String) {
        track("sign_up_completed", properties: ["method": method])
    }

    func trackGenerationStarted(style: String) {
        track("generation_started", properties: ["style": style])
    }

    func trackGenerationCompleted(style: String, photoCount: Int, processingTime: TimeInterval) {
        track("generation_completed", properties: [
            "style": style,
            "photo_count": photoCount,
            "processing_time_seconds": processingTime
        ])
    }

    func trackCoachBioGenerated(platform: String, tone: String) {
        track("coach_bio_generated", properties: ["platform": platform, "tone": tone])
    }

    func trackCoachOpenerGenerated(platform: String) {
        track("coach_opener_generated", properties: ["platform": platform])
    }

    func trackMatchAdded() {
        track("match_added")
    }

    func trackBackgroundReplaced(scene: String) {
        track("background_replaced", properties: ["scene": scene])
    }

    func trackGalleryOpened() {
        track("gallery_opened")
    }

    // MARK: - User Property Enrichment

    /// Call after auth or subscription changes to attach user properties to all future events.
    func enrichUserProperties(subscriptionTier: String, totalGenerations: Int, signUpDate: Date?) {
        guard isInitialized else { return }
        var props: [String: Any] = [
            "subscription_tier": subscriptionTier,
            "total_generations": totalGenerations
        ]
        if let date = signUpDate {
            props["sign_up_date"] = ISO8601DateFormatter().string(from: date)
        }
        PostHogSDK.shared.capture("$set", properties: ["$set": props])
    }

    // MARK: - Track Event

    func trackEvent(_ event: String, properties: [String: Any] = [:]) {
        track(event, properties: properties)
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
