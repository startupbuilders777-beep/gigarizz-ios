import SwiftUI

// MARK: - First Generation Flow View

/// Guides users through their first photo generation experience.
struct FirstGenerationFlowView: View {
    @StateObject private var viewModel = FirstGenerationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header
                    headerSection

                    // Content based on step
                    switch viewModel.currentStep {
                    case .welcome:
                        welcomeStep
                    case .photoTips:
                        photoTipsStep
                    case .styleSelection:
                        styleSelectionStep
                    case .generating:
                        generatingStep
                    }

                    Spacer()

                    // Navigation buttons
                    navigationButtons
                }
                .padding(DesignSystem.Spacing.l)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            ForEach(FirstGenerationViewModel.Step.allCases, id: \.self) { step in
                Capsule()
                    .fill(
                        step.rawValue <= viewModel.currentStep.rawValue
                            ? DesignSystem.Colors.flameOrange
                            : DesignSystem.Colors.surfaceSecondary
                    )
                    .frame(width: 40, height: 4)
            }
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Let's Create Your First Photos")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("In just a few steps, you'll have stunning dating photos ready to use.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Photo Tips Step

    private var photoTipsStep: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Text("Photo Tips for Best Results")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.s) {
                tipRow(icon: "sun.max", title: "Good Lighting", description: "Natural light works best")
                tipRow(icon: "person.crop.square", title: "Face Visible", description: "Clear face shots with different angles")
                tipRow(icon: "camera", title: "No Filters", description: "Upload raw photos for best AI results")
                tipRow(icon: "rectangle.stack", title: "Multiple Options", description: "3-5 photos give more variety")
            }
        }
    }

    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(description)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Style Selection Step

    private var styleSelectionStep: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Text("Choose Your Style")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Pick a style that matches your personality")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.s) {
                    ForEach(StylePreset.allPresets) { preset in
                        StylePresetCard(
                            preset: preset,
                            isSelected: viewModel.selectedStyle?.id == preset.id,
                            isLocked: false,
                            onTap: {
                                withAnimation(DesignSystem.Animation.quickSpring) {
                                    viewModel.selectedStyle = preset
                                }
                                DesignSystem.Haptics.light()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Generating Step

    private var generatingStep: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ProgressView()
                .scaleEffect(2)
                .tint(DesignSystem.Colors.flameOrange)

            Text("Generating Your Photos...")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("This usually takes about 30 seconds")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            if viewModel.currentStep != .generating {
                GRButton(
                    title: viewModel.currentStep == .styleSelection ? "Start Generating" : "Continue",
                    icon: viewModel.currentStep == .styleSelection ? "wand.and.stars" : "arrow.right",
                    isDisabled: viewModel.currentStep == .styleSelection && viewModel.selectedStyle == nil
                ) {
                    withAnimation(DesignSystem.Animation.smoothSpring) {
                        viewModel.advanceStep()
                    }
                    DesignSystem.Haptics.medium()
                }

                if viewModel.currentStep != .welcome {
                    Button("Back") {
                        withAnimation(DesignSystem.Animation.smoothSpring) {
                            viewModel.goBack()
                        }
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    FirstGenerationFlowView()
        .preferredColorScheme(.dark)
}
