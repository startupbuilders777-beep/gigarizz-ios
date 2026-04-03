import SwiftUI

@main
struct GigaRizzApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var postHogManager = PostHogManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                        .environmentObject(postHogManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                authManager.startAuthStateListener()
                postHogManager.initPostHog()
            }
        }
    }
}
