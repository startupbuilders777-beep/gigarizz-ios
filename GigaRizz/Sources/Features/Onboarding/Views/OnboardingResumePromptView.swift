import SwiftUI

// MARK: - Onboarding Resume Prompt View

/// Shown to returning users who started but didn't complete onboarding.
/// Offers option to resume from where they left off or restart.
struct OnboardingResumePromptView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onResume: () -> Void
    let onRestart: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // MARK: - Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.3), radius: 16, y: 8)
                    
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                
                // MARK: - Message
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text("Welcome Back!")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text("You started setting up GigaRizz but didn't finish. Would you like to continue where you left off?")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // MARK: - Progress Indicator
                progressIndicator
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // MARK: - Actions
                VStack(spacing: DesignSystem.Spacing.small) {
                    GRButton(
                        title: "Continue Setup",
                        icon: "arrow.right",
                        accessibilityHint: "Resumes onboarding from where you stopped"
                    ) {
                        viewModel.resumeOnboarding()
                        onResume()
                        DesignSystem.Haptics.medium()
                    }
                    
                    Button {
                        viewModel.restartOnboarding()
                        onRestart()
                        DesignSystem.Haptics.light()
                    } label: {
                        Text("Start Over")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                    
                    Button {
                        viewModel.skipOnboarding()
                        onSkip()
                        DesignSystem.Haptics.light()
                    } label: {
                        Text("Skip for now")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome Back. You started setting up GigaRizz but didn't finish.")
    }
    
    // MARK: - Progress Indicator
    
    @ViewBuilder
    private var progressIndicator: some View {
        GRCard(padding: DesignSystem.Spacing.medium) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Your Progress")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index < viewModel.currentPage ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceSecondary)
                            .frame(width: index < viewModel.currentPage ? 24 : 8, height: 8)
                    }
                }
                
                Text(pageLabel)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
        .accessibilityHidden(true)
    }
    
    private var pageLabel: String {
        let completed = viewModel.currentPage
        let total = viewModel.totalPages
        return "\(completed) of \(total) steps completed"
    }
}

// MARK: - Preview

#Preview {
    let vm = OnboardingViewModel()
    vm.currentPage = 1
    vm.hasSeenOnboarding = true
    vm.hasCompletedOnboarding = false
    
    return OnboardingResumePromptView(
        viewModel: vm,
        onResume: {},
        onRestart: {},
        onSkip: {}
    )
    .preferredColorScheme(.dark)
}