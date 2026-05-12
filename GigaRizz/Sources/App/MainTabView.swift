import SwiftUI

// MARK: - Main Tab View
//
// Two tab structures, switched by the v2UpgradeFlow feature flag:
//   • V1 (default): Home / Generate / Coach / Matches
//   • V2 (Codex plan): Upgrade / Photos / Coach / Profile
//
// V2 hides V1 surfaces entirely so the user reads one funnel, not two.

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @ObservedObject var deepLinkManager = DeepLinkManager.shared
    @StateObject private var featureFlags = FeatureFlagManager.shared

    // Deep link sheet states
    @State private var showPaywallFromDeepLink = false
    @State private var paywallInitialTier: TierOption?
    @State private var paywallPromoCode: String?

    enum Tab: String, CaseIterable {
        case upgrade, photos, profile  // V2
        case home, generate, coach, matches  // V1
    }

    var body: some View {
        ZStack {
            if featureFlags.isEnabled(.v2UpgradeFlow) {
                v2TabView
            } else {
                v1TabView
            }

            DeepLinkRouterView(selectedTab: $selectedTab)

            VStack {
                DeepLinkToastView()
                Spacer()
            }
        }
        .onChange(of: deepLinkManager.destination) { _, destination in
            handleDeepLinkDestination(destination)
        }
        .sheet(isPresented: $showPaywallFromDeepLink) {
            PaywallView(initialTier: paywallInitialTier, promoCode: paywallPromoCode)
        }
        .onAppear {
            // Default selection per tab set.
            if featureFlags.isEnabled(.v2UpgradeFlow) {
                if ![Tab.upgrade, .photos, .coach, .profile].contains(selectedTab) {
                    selectedTab = .upgrade
                }
            } else {
                if ![Tab.home, .generate, .coach, .matches].contains(selectedTab) {
                    selectedTab = .home
                }
            }
            if deepLinkManager.hasPendingDeepLink {
                deepLinkManager.routeDeferredDeepLink()
            }
        }
    }

    // MARK: - V2 Tabs

    private var v2TabView: some View {
        TabView(selection: $selectedTab) {
            UpgradeFlowView()
                .tabItem { Label("Upgrade", systemImage: "wand.and.sparkles.inverse") }
                .tag(Tab.upgrade)

            PhotosTabView()
                .tabItem { Label("Photos", systemImage: "photo.on.rectangle.angled") }
                .tag(Tab.photos)

            NavigationStack {
                CoachView()
            }
            .tabItem { Label("Coach", systemImage: "brain.head.profile") }
            .tag(Tab.coach)

            SettingsView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(DesignSystem.Colors.flameOrange)
    }

    // MARK: - V1 Tabs (unchanged)

    private var v1TabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            NavigationStack {
                GenerateView()
            }
            .tabItem { Label("Generate", systemImage: "wand.and.stars") }
            .tag(Tab.generate)

            NavigationStack {
                CoachView()
            }
            .tabItem { Label("Coach", systemImage: "brain.head.profile") }
            .tag(Tab.coach)

            NavigationStack {
                MatchesView()
            }
            .tabItem { Label("Matches", systemImage: "heart.circle") }
            .tag(Tab.matches)
        }
        .tint(DesignSystem.Colors.flameOrange)
    }

    // MARK: - Deep Link Handling

    private func handleDeepLinkDestination(_ destination: DeepLinkDestination?) {
        guard let destination = destination else { return }
        if case .paywall(tier: let tier, promoCode: let promo) = destination {
            paywallInitialTier = tier ?? .plus
            paywallPromoCode = promo
            showPaywallFromDeepLink = true
            deepLinkManager.destination = nil
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
