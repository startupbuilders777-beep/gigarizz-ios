import SwiftUI

struct OnboardingView: View {
    @ObservedObject var stateManager: OnboardingStateManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var isPhotoTutorialOnly = false

    private var pages: [OnboardingPage] {
        if isPhotoTutorialOnly {
            // Photo tutorial only (from Settings)
            return [
                OnboardingPage(
                    icon: "camera.fill",
                    title: "Photo Tutorial",
                    subtitle: "Learn how to take dating-app-worthy selfies.\nGood source photos = better AI results.",
                    gradient: [.purple, .blue]
                )
            ]
        }
        return [
            OnboardingPage(
                icon: "flame.fill",
                title: "Welcome to GigaRizz",
                subtitle: "Your AI-powered dating photo upgrade.\nBetter photos = more matches.",
                gradient: [DesignSystem.Colors.flameOrange, .orange]
            ),
            OnboardingPage(
                icon: "camera.fill",
                title: "Upload Your Selfies",
                subtitle: "Pick 3-6 of your best selfies.\nWe'll use AI to create fire dating photos.",
                gradient: [.purple, .blue]
            ),
            OnboardingPage(
                icon: "wand.and.stars",
                title: "Choose Your Style",
                subtitle: "Confident, Adventurous, Golden Hour —\npick a look that's 100% you.",
                gradient: [.teal, .cyan]
            ),
            OnboardingPage(
                icon: "heart.circle.fill",
                title: "Get More Matches",
                subtitle: "AI coach helps with bios, openers,\nand conversation starters. Let's go!",
                gradient: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent]
            )
        ]
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (only on skippable pages)
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 && OnboardingStep.fromIndex(currentPage).canSkip && !isPhotoTutorialOnly {
                        Button {
                            skipToNextPage()
                        } label: {
                            Text("Skip")
                                .font(DesignSystem.Typography.smallButton)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .frame(height: 44)

                // TabView for pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        onboardingPageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smoothSpring, value: currentPage)

                // Page indicators
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage
                                ? DesignSystem.Colors.flameOrange
                                : DesignSystem.Colors.surfaceSecondary)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(DesignSystem.Animation.quickSpring, value: currentPage)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.large)

                // Primary button
                GRButton(
                    title: currentPage == pages.count - 1
                        ? (isPhotoTutorialOnly ? "Done" : "Get Started")
                        : "Continue",
                    icon: currentPage == pages.count - 1
                        ? (isPhotoTutorialOnly ? "checkmark" : "flame.fill")
                        : "arrow.right"
                ) {
                    handleContinue()
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .onAppear {
            setupInitialState()
        }
    }

    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: page.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .shadow(
                        color: page.gradient.first?.opacity(0.4) ?? .clear,
                        radius: 20,
                        y: 10
                    )

                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Text content
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text(page.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }

    private func setupInitialState() {
        if isPhotoTutorialOnly {
            currentPage = 0
        } else {
            // Resume from last completed step + 1
            let resumeStep = min(stateManager.lastCompletedStep + 1, pages.count - 1)
            currentPage = resumeStep
        }
    }

    private func handleContinue() {
        DesignSystem.Haptics.light()

        if currentPage < pages.count - 1 {
            // Mark current step as completed
            if !isPhotoTutorialOnly {
                stateManager.completeStep(OnboardingStep.fromIndex(currentPage))
            }
            withAnimation(DesignSystem.Animation.smoothSpring) {
                currentPage += 1
            }
        } else {
            // Final page - complete onboarding
            completeOnboarding()
        }
    }

    private func skipToNextPage() {
        DesignSystem.Haptics.light()

        // Track skip event
        PostHogManager.shared.track("onboarding_step_skipped", properties: [
            "step": OnboardingStep.fromIndex(currentPage).rawValue,
            "step_index": currentPage
        ])

        withAnimation(DesignSystem.Animation.smoothSpring) {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        if isPhotoTutorialOnly {
            // Photo tutorial only - mark as seen and return
            stateManager.hasSeenPhotoTutorial = true
            hasCompletedOnboarding = true // This will dismiss the view
            PostHogManager.shared.track("photo_tutorial_completed")
        } else {
            // Full onboarding completion
            stateManager.completeOnboarding()
            hasCompletedOnboarding = true
        }

        DesignSystem.Haptics.success()
    }

    // MARK: - Photo Tutorial Only Mode

    init(stateManager: OnboardingStateManager = .shared, hasCompletedOnboarding: Binding<Bool>, photoTutorialOnly: Bool = false) {
        self.stateManager = stateManager
        self._hasCompletedOnboarding = hasCompletedOnboarding
        self._isPhotoTutorialOnly = State(initialValue: photoTutorialOnly)
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}