import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home, generate, coach, matches
    }

    var body: some View {
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
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
