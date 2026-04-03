import SwiftUI

@main
struct GigaRizzApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var postHogManager = PostHogManager()
    @StateObject private var onboardingStateManager = OnboardingStateManager.shared

    @State private var showResumePrompt = false
    @State private var showOnboarding = false
    @State private var showPhotoTutorialOnly = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingStateManager.hasCompletedOnboarding {
                    // Completed onboarding -> show main app
                    if authManager.isAuthenticated {
                        MainTabView()
                            .environmentObject(authManager)
                            .environmentObject(subscriptionManager)
                            .environmentObject(postHogManager)
                            .environmentObject(onboardingStateManager)
                    } else {
                        SignInView()
                            .environmentObject(authManager)
                            .environmentObject(subscriptionManager)
                    }
                } else {
                    // Not completed -> show onboarding or resume prompt
                    OnboardingView(
                        stateManager: onboardingStateManager,
                        hasCompletedOnboarding: $onboardingStateManager.hasCompletedOnboarding,
                        photoTutorialOnly: showPhotoTutorialOnly
                    )
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                authManager.startAuthStateListener()
                postHogManager.initPostHog()
                handleLaunchState()
            }
            // Resume prompt overlay
            .overlay {
                if showResumePrompt {
                    OnboardingResumePromptView(
                        stateManager: onboardingStateManager,
                        isPresented: $showResumePrompt,
                        onResume: {
                            onboardingStateManager.resumeFromLastStep()
                        },
                        onStartOver: {
                            onboardingStateManager.startFresh()
                        }
                    )
                }
            }
            // Handle changes to onboarding state
            .onChange(of: onboardingStateManager.showResumePrompt) { _, newValue in
                showResumePrompt = newValue
            }
        }
    }

    private func handleLaunchState() {
        let launchState = onboardingStateManager.determineLaunchState()

        switch launchState {
        case .completed:
            // User has completed onboarding -> proceed to auth/main
            showOnboarding = false
            showResumePrompt = false

        case .fresh:
            // Fresh user -> show full onboarding from step 0
            showOnboarding = true
            showResumePrompt = false
            PostHogManager.shared.track("onboarding_started", properties: ["type": "fresh"])

        case .partial(let lastStep):
            // Returning user with partial completion -> show resume prompt
            showResumePrompt = true
            PostHogManager.shared.track("onboarding_return_detected", properties: [
                "last_completed_step": lastStep
            ])
        }
    }
}