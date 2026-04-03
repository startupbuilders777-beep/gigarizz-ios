import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home, generate, profile, coach, matches
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(Tab.home)

            NavigationStack {
                GenerateView()
                    .environmentObject(AIGenerationService.shared)
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
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}