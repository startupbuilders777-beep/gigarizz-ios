import SwiftUI

// MARK: - Onboarding Resume Prompt View

/// Card shown to returning users who partially completed onboarding.
struct OnboardingResumePromptView: View {
    @ObservedObject var stateManager: OnboardingStateManager
    @Binding var isPresented: Bool
    let onResume: () -> Void
    let onStartOver: () -> Void

    var body: some View {
        ZStack {
            DesignSystem.Colors.overlay.ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.large) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.3), radius: 12, y: 6)

                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Title
                Text("Welcome Back!")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                // Subtitle with progress
                Text("You made it to step \(stateManager.lastCompletedStep + 1) of \(OnboardingStep.allCases.count).")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                // Progress bar
                HStack(spacing: DesignSystem.Spacing.micro) {
                    ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= stateManager.lastCompletedStep
                                ? DesignSystem.Colors.flameOrange
                                : DesignSystem.Colors.surfaceSecondary)
                            .frame(height: 6)
                    }
                }
                .frame(maxWidth: 200)

                Spacer().frame(height: DesignSystem.Spacing.medium)

                // Buttons
                VStack(spacing: DesignSystem.Spacing.small) {
                    // Continue button (primary)
                    GRButton(
                        title: "Continue Where You Left Off",
                        icon: "arrow.right"
                    ) {
                        DesignSystem.Haptics.medium()
                        isPresented = false
                        onResume()
                    }

                    // Start Over button (secondary)
                    Button {
                        DesignSystem.Haptics.light()
                        isPresented = false
                        onStartOver()
                    } label: {
                        Text("Start Over")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.small)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .fill(DesignSystem.Colors.surface)
                    .cardShadow()
            )
            .padding(DesignSystem.Spacing.xl)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(DesignSystem.Animation.smoothSpring, value: isPresented)
    }
}

#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        OnboardingResumePromptView(
            stateManager: OnboardingStateManager.shared,
            isPresented: .constant(true),
            onResume: {},
            onStartOver: {}
        )
    }
    .preferredColorScheme(.dark)
}