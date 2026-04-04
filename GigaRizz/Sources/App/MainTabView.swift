import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @ObservedObject var deepLinkManager = DeepLinkManager.shared
    
    // Deep link sheet states
    @State private var showPaywallFromDeepLink = false
    @State private var paywallInitialTier: TierOption?
    @State private var paywallPromoCode: String?

    enum Tab: String, CaseIterable {
        case home, generate, coach, matches
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home Dashboard - Primary navigation hub
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(Tab.home)

                // Generate - Photo generation flow
                NavigationStack {
                    GenerateView()
                }
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
                }
                .tag(Tab.generate)

                // Coach - AI dating advice
                NavigationStack {
                    CoachView()
                }
                .tabItem {
                    Label("Coach", systemImage: "brain.head.profile")
                }
                .tag(Tab.coach)

                // Matches - Match tracking
                NavigationStack {
                    MatchesView()
                }
                .tabItem {
                    Label("Matches", systemImage: "heart.circle")
                }
                .tag(Tab.matches)
            }
            .tint(DesignSystem.Colors.flameOrange)
            
            // Deep link router overlay (handles navigation routing)
            DeepLinkRouterView(selectedTab: $selectedTab)
            
            // Deep link error toast overlay
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
            // Check for deferred deep links
            if deepLinkManager.hasPendingDeepLink {
                deepLinkManager.routeDeferredDeepLink()
            }
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLinkDestination(_ destination: DeepLinkDestination?) {
        guard let destination = destination else { return }
        
        // Handle paywall deep links separately (modal presentation)
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
