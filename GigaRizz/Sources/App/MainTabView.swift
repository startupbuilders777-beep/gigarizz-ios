import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { GenerateView().environmentObject(AIGenerationService.shared) }
                .tabItem { Label("Generate", systemImage: "wand.and.stars") }.tag(0)
            NavigationStack { ToolsHubView() }
                .tabItem { Label("Tools", systemImage: "sparkles.rectangle.stack") }.tag(1)
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }.tag(2)
            NavigationStack { AnalyticsDashboardView() }
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }.tag(3)
            NavigationStack { MatchesView() }
                .tabItem { Label("Matches", systemImage: "heart.text.square.fill") }.tag(4)
        }
        .tint(DesignSystem.Colors.flameOrange)
        .onAppear { configureTabBarAppearance() }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DesignSystem.Colors.surface)
        let normalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(DesignSystem.Colors.textSecondary)]
        let selectedAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(DesignSystem.Colors.flameOrange)]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DesignSystem.Colors.textSecondary)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DesignSystem.Colors.flameOrange)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview { MainTabView().environmentObject(AuthManager.shared).environmentObject(SubscriptionManager.shared).preferredColorScheme(.dark) }
