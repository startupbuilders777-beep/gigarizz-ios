import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .generate
    @State private var tabBounce = false

    enum Tab: String, CaseIterable {
        case generate, profile, coach, matches
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GenerateView()
            }
            .tabItem { Label("Generate", systemImage: "wand.and.stars") }
            .tag(Tab.generate)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(Tab.profile)

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
        .onChange(of: selectedTab) { _, _ in
            DesignSystem.Haptics.light()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}
