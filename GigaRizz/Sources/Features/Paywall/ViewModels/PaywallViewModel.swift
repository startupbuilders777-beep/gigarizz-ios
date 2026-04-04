import Combine
import RevenueCat
import SwiftUI

// MARK: - Subscription Tier Option

/// Tier options for the paywall with pricing and features.
enum TierOption: String, CaseIterable, Identifiable {
    case free
    case plus
    case gold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .gold: return "Gold"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .plus: return "$4.99"
        case .gold: return "$14.99"
        }
    }

    var period: String {
        switch self {
        case .free: return ""
        case .plus: return "/month"
        case .gold: return "/month"
        }
    }

    var badgeText: String? {
        switch self {
        case .free: return nil
        case .plus: return "MOST POPULAR"
        case .gold: return "BEST VALUE"
        }
    }

    var badgeStyle: PremiumBadge.BadgeStyle? {
        switch self {
        case .free: return nil
        case .plus: return .popular
        case .gold: return .bestValue
        }
    }

    var dailyPhotoLimit: Int {
        switch self {
        case .free: return 3
        case .plus: return 30
        case .gold: return Int.max
        }
    }

    var features: [TierFeature] {
        switch self {
        case .free:
            return [
                TierFeature(icon: "camera.fill", text: "3 photos/day", included: true),
                TierFeature(icon: "wand.and.stars", text: "1 style preset", included: true),
                TierFeature(icon: "arrow.down.circle", text: "HD downloads", included: false),
                TierFeature(icon: "brain.head.profile", text: "Rizz Coach", included: false),
                TierFeature(icon: "bolt.fill", text: "Priority queue", included: false)
            ]
        case .plus:
            return [
                TierFeature(icon: "camera.fill", text: "30 photos/day", included: true),
                TierFeature(icon: "wand.and.stars", text: "10 style presets", included: true),
                TierFeature(icon: "arrow.down.circle", text: "HD downloads", included: true),
                TierFeature(icon: "brain.head.profile", text: "Rizz Coach", included: true),
                TierFeature(icon: "bolt.fill", text: "Priority queue", included: false)
            ]
        case .gold:
            return [
                TierFeature(icon: "infinity", text: "Unlimited photos", included: true),
                TierFeature(icon: "wand.and.stars", text: "All style presets", included: true),
                TierFeature(icon: "arrow.down.circle", text: "HD downloads", included: true),
                TierFeature(icon: "brain.head.profile", text: "Rizz Coach", included: true),
                TierFeature(icon: "bolt.fill", text: "Priority queue", included: true)
            ]
        }
    }
}

// MARK: - Tier Feature

struct TierFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let included: Bool
}

// MARK: - Paywall ViewModel

@MainActor
final class PaywallViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTier: TierOption
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRestoring = false
    @Published var hasFreePhotosRemaining = true
    @Published var cardAnimationIndex: Int = -1

    // MARK: - Dependencies

    private let subscriptionManager: SubscriptionManager
    private let postHogManager: PostHogManager

    // MARK: - Init

    init(
        initialTier: TierOption = .plus,
        subscriptionManager: SubscriptionManager = .init(),
        postHogManager: PostHogManager = .shared
    ) {
        self.selectedTier = initialTier
        self.subscriptionManager = subscriptionManager
        self.postHogManager = postHogManager
        self.hasFreePhotosRemaining = subscriptionManager.canGeneratePhoto
    }

    // MARK: - Actions

    func onAppear() {
        // Track paywall viewed event
        postHogManager.trackPaywallViewed(trigger: "paywall_modal", variant: "tier_cards")

        // Start staggered card animations
        animateCardsIn()
    }

    func selectTier(_ tier: TierOption) {
        guard tier != .free else { return }
        DesignSystem.Haptics.light()
        selectedTier = tier
    }

    func purchaseSelectedTier() async {
        guard selectedTier != .free else { return }

        isLoading = true
        errorMessage = nil
        DesignSystem.Haptics.medium()

        // In production, this would call RevenueCat purchase
        // For now, simulate the purchase flow
        try? await Task.sleep(for: .seconds(1))

        isLoading = false

        // Track subscription started event
        postHogManager.trackSubscriptionStarted(
            plan: selectedTier.displayName,
            amount: selectedTier == .plus ? 4.99 : 14.99
        )

        DesignSystem.Haptics.success()
    }

    func restorePurchases() async {
        isRestoring = true
        errorMessage = nil

        await subscriptionManager.restorePurchases()

        isRestoring = false
    }

    // MARK: - Animation

    private func animateCardsIn() {
        // Staggered animation: cards animate in with 80ms delay
        for index in 0..<TierOption.allCases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) { [weak self] in
                guard let self = self else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    self.cardAnimationIndex = index
                }
            }
        }
    }

    // MARK: - Computed

    var canDismiss: Bool {
        hasFreePhotosRemaining
    }
}