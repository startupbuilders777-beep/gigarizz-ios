import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .generate
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    enum Tab: String, CaseIterable {
        case generate, profile, coach, matches
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    GenerateView()
                }
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
                }
                .tag(Tab.generate)

                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)

                NavigationStack {
                    CoachView()
                }
                .tabItem {
                    Label("Coach", systemImage: "brain.head.profile")
                }
                .tag(Tab.coach)

                NavigationStack {
                    MatchesView()
                }
                .tabItem {
                    Label("Matches", systemImage: "heart.circle")
                }
                .tag(Tab.matches)
            }
            .tint(DesignSystem.Colors.flameOrange)
            .sheet(isPresented: $subscriptionManager.showPaywall) {
                PaywallView()
            }

            // Persistent subscription banner at top of screen
            SubscriptionStatusBanner()
                .environmentObject(subscriptionManager)
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}
