import FirebaseCore
import PostHog
import RevenueCat
import SwiftUI

@main
struct GigaRizzApp: App {
    // Use singletons so every view shares the same instance
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var postHogManager = PostHogManager.shared
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @StateObject private var replyReminderService = ReplyReminderService.shared

    // Onboarding state from UserDefaults
    @AppStorage("onboarding_has_completed") private var hasCompletedOnboarding = false
    @AppStorage("onboarding_has_seen") private var hasSeenOnboarding = false

    // In-memory state for resume prompt
    @State private var showResumePrompt = false
    @State private var onboardingViewModel: OnboardingViewModel?

    // MARK: - SDK Initialization

    init() {
        // Skip all SDK init when running as a test host
        guard !Self.isRunningTests else { return }

        // 1. Firebase — only configure when GoogleService-Info.plist is bundled.
        //    Skipping this guard caused the app to hard-crash on launch in dev
        //    builds without Firebase set up. Auth flows fall back to the dev
        //    user when Firebase isn't available.
        if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
        } else {
            #if DEBUG
            print("[GigaRizz] GoogleService-Info.plist not found — skipping Firebase configure (dev mode)")
            #endif
        }

        // 2. RevenueCat
        if AppConstants.isRevenueCatConfigured {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: AppConstants.revenueCatAPIKey)
        }

        // 3. PostHog
        if AppConstants.isPostHogConfigured {
            let phConfig = PostHogConfig(apiKey: AppConstants.postHogAPIKey, host: AppConstants.postHogHost)
            phConfig.captureApplicationLifecycleEvents = true
            phConfig.captureScreenViews = true
            PostHogSDK.shared.setup(phConfig)
            PostHogManager.shared.markInitialized()
        }
    }

    /// Detect if the process is being launched as a test host.
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    /// If Firebase is not bundled, do not trap users behind a dead login wall.
    /// App Review also expects core functionality to be usable when account
    /// features are not essential to the first-run experience.
    private var localAuthBypass: Bool {
        FirebaseApp.app() == nil
    }

    /// When V2 is on, skip the V1 30-step onboarding entirely. The Upgrade tab
    /// IS the audit-first onboarding, so running both back-to-back violates
    /// Codex's ≤2-minute-to-diagnosis North Star. Auto-marks the V1 flag so
    /// the user never sees the 30-step flow on this device again.
    @MainActor
    private var shouldSkipV1Onboarding: Bool {
        guard FeatureFlagManager.shared.isEnabled(.v2UpgradeFlow) else { return false }
        if !hasCompletedOnboarding {
            // Mark V1 onboarding as completed so the gate flips next time too.
            DispatchQueue.main.async { hasCompletedOnboarding = true }
        }
        return true
    }

    var body: some Scene {
        WindowGroup {
            Group {
                // MARK: - Launch Flow Logic
                // 1. Fresh user → OnboardingView
                // 2. Mid-onboarding returner → ResumePrompt then Onboarding
                // 3. Completed onboarding, no auth → SignInView
                // 4. Authenticated → MainTabView
                
                if !hasCompletedOnboarding && !shouldSkipV1Onboarding {
                    if hasSeenOnboarding && !hasCompletedOnboarding && !showResumePrompt {
                        // Returning user who didn't complete onboarding
                        OnboardingResumePromptView(
                            viewModel: onboardingViewModel ?? OnboardingViewModel(),
                            onResume: { startOnboardingResumeFlow() },
                            onRestart: { startOnboardingFresh() },
                            onSkip: { skipOnboardingAndSignIn() }
                        )
                        .onAppear {
                            if onboardingViewModel == nil {
                                onboardingViewModel = OnboardingViewModel()
                            }
                        }
                    } else {
                        // Fresh user or resuming onboarding
                        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                            .environmentObject(authManager)
                            .environmentObject(subscriptionManager)
                            .environmentObject(postHogManager)
                            .onAppear {
                                // Mark as seen when onboarding starts
                                if !hasSeenOnboarding {
                                    hasSeenOnboarding = true
                                    UserDefaults.standard.set(true, forKey: "onboarding_has_seen")
                                }
                            }
                            .onChange(of: hasCompletedOnboarding) { _, completed in
                                if completed {
                                    // Transition to sign in after onboarding completion
                                    UserDefaults.standard.set(true, forKey: "onboarding_has_completed")
                                }
                            }
                    }
                } else if authManager.isAuthenticated || localAuthBypass {
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                        .environmentObject(postHogManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                        .environmentObject(postHogManager)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                authManager.startAuthStateListener()
                AppRatingManager.shared.trackAppLaunch()
                
                // Check if we should show resume prompt
                checkResumePromptState()
                
                // Setup notification delegate
                setupNotificationDelegate()
            }
            .task {
                await FeatureFlagManager.shared.refreshIfNeeded()
            }
            .onOpenURL { url in
                // Handle deep links (custom scheme gigarizz:// and universal links https://gigarizz.app)
                _ = deepLinkManager.handleURL(url)
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuth in
                // Route deferred deep link after authentication
                if isAuth && deepLinkManager.hasPendingDeepLink {
                    deepLinkManager.routeDeferredDeepLink()
                }
            }
        }
    }
    
    // MARK: - Resume Flow Helpers
    
    private func checkResumePromptState() {
        // Show resume prompt if user started but didn't complete
        let hasSeen = UserDefaults.standard.bool(forKey: "onboarding_has_seen")
        let hasCompleted = UserDefaults.standard.bool(forKey: "onboarding_has_completed")
        
        if hasSeen && !hasCompleted {
            showResumePrompt = true
        }
    }
    
    private func startOnboardingResumeFlow() {
        showResumePrompt = false
        // OnboardingView will resume from saved page state
    }
    
    private func startOnboardingFresh() {
        // Reset state for fresh start
        UserDefaults.standard.set(false, forKey: "onboarding_has_seen")
        UserDefaults.standard.set(0, forKey: "onboarding_last_page")
        hasSeenOnboarding = false
        showResumePrompt = false
        
        // Create fresh ViewModel
        onboardingViewModel = OnboardingViewModel()
    }
    
    private func skipOnboardingAndSignIn() {
        hasCompletedOnboarding = true
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboarding_has_completed")
        UserDefaults.standard.set(true, forKey: "onboarding_has_seen")
        showResumePrompt = false
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationDelegate() {
        // Register for notification response handling
        UNUserNotificationCenter.current().delegate = NotificationDelegateHandler.shared
        
        // Schedule initial reply reminder background check
        Task {
            await replyReminderService.scheduleNextBackgroundCheck()
        }
    }
}
