import SwiftUI

// MARK: - Bio Writer View

struct BioWriterView: View {
    @StateObject private var viewModel = BioWriterViewModel()
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.l) {
                    headerSection
                    platformSelector
                    personalityInput
                    interestsInput
                    vibeSelector
                    generateBioButton

                    if viewModel.isGenerating {
                        generatingSection
                    }

                    if !viewModel.generatedBios.isEmpty {
                        generatedBiosSection
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("AI Bio Writer")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(subscriptionManager)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Bio Writer")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Platform-optimized bios that get conversations started")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.s)
    }

    // MARK: - Platform Selector

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("What app?")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.s) {
                ForEach(BioPlatform.allCases) { platform in
                    Button {
                        withAnimation(DesignSystem.Animation.quickSpring) {
                            viewModel.selectedPlatform = platform
                        }
                        DesignSystem.Haptics.light()
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: platform.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(
                                    viewModel.selectedPlatform == platform
                                    ? platform.color : DesignSystem.Colors.textSecondary
                                )
                                .frame(width: 50, height: 50)
                                .background(
                                    viewModel.selectedPlatform == platform
                                    ? platform.color.opacity(0.15) : DesignSystem.Colors.surface
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle().strokeBorder(
                                        viewModel.selectedPlatform == platform
                                        ? platform.color : .clear, lineWidth: 2
                                    )
                                )

                            Text(platform.rawValue)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(
                                    viewModel.selectedPlatform == platform
                                    ? platform.color : DesignSystem.Colors.textSecondary
                                )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Personality Input

    private var personalityInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Your personality")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.xs) {
                ForEach(PersonalityTrait.allCases) { trait in
                    traitChip(trait)
                }
            }
        }
    }

    private func traitChip(_ trait: PersonalityTrait) -> some View {
        let isSelected = viewModel.selectedTraits.contains(trait)
        return Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                if isSelected {
                    viewModel.selectedTraits.remove(trait)
                } else if viewModel.selectedTraits.count < 3 {
                    viewModel.selectedTraits.insert(trait)
                }
            }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: 4) {
                Text(trait.emoji)
                    .font(.system(size: 14))
                Text(trait.rawValue)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.s)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
            .clipShape(Capsule())
        }
    }

    // MARK: - Interests Input

    private var interestsInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Text("Your interests")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(viewModel.selectedInterests.count)/5")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.xs) {
                ForEach(InterestCategory.allCases) { interest in
                    interestChip(interest)
                }
            }
        }
    }

    private func interestChip(_ interest: InterestCategory) -> some View {
        let isSelected = viewModel.selectedInterests.contains(interest)
        return Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                if isSelected {
                    viewModel.selectedInterests.remove(interest)
                } else if viewModel.selectedInterests.count < 5 {
                    viewModel.selectedInterests.insert(interest)
                }
            }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: 6) {
                Text(interest.emoji)
                Text(interest.rawValue)
                    .font(DesignSystem.Typography.smallButton)
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
            .clipShape(Capsule())
        }
    }

    // MARK: - Vibe Selector

    private var vibeSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Bio vibe")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(BioVibe.allCases) { vibe in
                        Button {
                            withAnimation(DesignSystem.Animation.quickSpring) { viewModel.selectedVibe = vibe }
                            DesignSystem.Haptics.light()
                        } label: {
                            Text(vibe.rawValue)
                                .font(DesignSystem.Typography.smallButton)
                                .foregroundStyle(
                                    viewModel.selectedVibe == vibe ? .white : DesignSystem.Colors.textSecondary
                                )
                                .padding(.horizontal, DesignSystem.Spacing.s)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(
                                    viewModel.selectedVibe == vibe
                                    ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateBioButton: some View {
        GRButton(
            title: "Generate Bios",
            icon: "text.bubble.fill",
            isLoading: viewModel.isGenerating,
            isDisabled: !viewModel.canGenerate
        ) {
            Task { await viewModel.generateBios() }
        }
    }

    // MARK: - Generating

    private var generatingSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            ProgressView()
                .tint(DesignSystem.Colors.flameOrange)
            Text("Crafting your perfect bio...")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, DesignSystem.Spacing.l)
    }

    // MARK: - Generated Bios

    private var generatedBiosSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            HStack {
                Text("Your Bios")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Button {
                    Task { await viewModel.generateBios() }
                } label: {
                    Label("Regenerate", systemImage: "arrow.counterclockwise")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }

            ForEach(Array(viewModel.generatedBios.enumerated()), id: \.offset) { index, bio in
                bioCard(bio, index: index)
            }
        }
    }

    private func bioCard(_ bio: GeneratedBio, index: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Label(bio.style, systemImage: bio.icon)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Spacer()
                Text("\(bio.text.count) chars")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Text(bio.text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .textSelection(.enabled)

            HStack(spacing: DesignSystem.Spacing.s) {
                Button {
                    UIPasteboard.general.string = bio.text
                    DesignSystem.Haptics.success()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .padding(.horizontal, DesignSystem.Spacing.s)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.flameOrange.opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { star in
                        Image(systemName: star < bio.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }
}

#Preview {
    NavigationStack {
        BioWriterView()
    }
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}
