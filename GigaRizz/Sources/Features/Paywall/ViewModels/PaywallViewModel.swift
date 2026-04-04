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

    /// Current RevenueCat offerings fetched on appear
    @Published var currentOffering: Offering?

    /// Introductory offer prices keyed by tier (e.g. "plus" → "$2.49/mo")
    @Published var introPrices: [String: String] = [:]

    /// Whether any tier has an active introductory offer
    var hasIntroOffer: Bool { !introPrices.isEmpty }

    // MARK: - Init

    init(
        initialTier: TierOption = .plus,
        subscriptionManager: SubscriptionManager = .shared,
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

        // Fetch RC offerings
        Task { await fetchOfferings() }

        // Start staggered card animations
        animateCardsIn()
    }

    /// Fetch RevenueCat offerings so we can map tier → Package.
    /// Also detects introductory offers (free trials, discounted first period).
    private func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current

            // Detect introductory offers per package
            if let offering = offerings.current {
                var intros: [String: String] = [:]
                for package in offering.availablePackages {
                    if let intro = package.storeProduct.introductoryDiscount {
                        let priceStr = intro.price == 0
                            ? "Free"
                            : intro.localizedPriceString
                        let periodStr: String
                        switch intro.subscriptionPeriod.unit {
                        case .day:   periodStr = intro.subscriptionPeriod.value == 7 ? "week" : "\(intro.subscriptionPeriod.value) day(s)"
                        case .week:  periodStr = "week"
                        case .month: periodStr = "mo"
                        case .year:  periodStr = "yr"
                        @unknown default: periodStr = ""
                        }
                        intros[package.identifier.lowercased()] = "\(priceStr)/\(periodStr)"
                    }
                }
                introPrices = intros
            }
        } catch {
            errorMessage = "Could not load prices. Check your connection."
        }
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

        // Map TierOption → RevenueCat Package
        guard let offering = currentOffering else {
            errorMessage = "Offerings not loaded yet. Please try again."
            isLoading = false
            return
        }

        // Lookup by package identifier matching tier name (e.g. "plus", "gold")
        let packageId = selectedTier.rawValue  // "plus" or "gold"
        guard let package = offering.availablePackages.first(where: { $0.identifier == packageId })
                ?? offering.availablePackages.first(where: { $0.identifier.lowercased().contains(packageId) })
        else {
            errorMessage = "Package \"\(packageId)\" not found. Check RevenueCat dashboard."
            isLoading = false
            return
        }

        do {
            try await subscriptionManager.purchase(package: package)
        } catch {
            errorMessage = error.localizedDescription
            DesignSystem.Haptics.error()
        }

        isLoading = false

        // Track subscription started event
        if subscriptionManager.currentTier != .free {
            postHogManager.trackSubscriptionStarted(
                plan: selectedTier.displayName,
                amount: selectedTier == .plus ? 4.99 : 14.99
            )
            DesignSystem.Haptics.success()
        }
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