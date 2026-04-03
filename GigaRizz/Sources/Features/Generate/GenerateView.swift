import PhotosUI
import SwiftUI

// MARK: - Generate View

struct GenerateView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = GenerateViewModel()
    @AppStorage("hasGeneratedPhotos") private var hasGeneratedPhotos = false
    @State private var showFirstGenerationFlow = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            if viewModel.isGenerating {
                generatingOverlay
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        headerBanner
                        firstTimePrompt
                        photoPickerSection
                        stylePickerSection
                        generateButton
                        usageBanner
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Generate")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.photosPickerItems) {
            Task { await viewModel.loadPhotos() }
        }
        .sheet(isPresented: $viewModel.showResults) {
            GenerationResultView(
                generatedPhotos: viewModel.generatedPhotos,
                style: viewModel.selectedStyle?.name ?? "Custom",
                userId: authManager.userId ?? "anonymous"
            )
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showFirstGenerationFlow) {
            FirstGenerationFlowView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            // Show guided flow for first-time users
            if !hasGeneratedPhotos {
                showFirstGenerationFlow = true
            }
        }
    }

    // MARK: - First-Time User Prompt

    private var firstTimePrompt: some View {
        Group {
            if !hasGeneratedPhotos {
                Button {
                    showFirstGenerationFlow = true
                    DesignSystem.Haptics.light()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("New here?")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            Text("Try our guided photo wizard")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(DesignSystem.Colors.flameOrange.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Photo Generator")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Upload selfies → pick a style → get fire photos")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Photo Picker Section

    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Your Photos")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(viewModel.photoCountText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(
                        viewModel.selectedPhotos.count >= viewModel.minimumPhotos
                            ? DesignSystem.Colors.success
                            : DesignSystem.Colors.textSecondary
                    )
            }

            if viewModel.selectedPhotos.isEmpty {
                PhotosPicker(
                    selection: $viewModel.photosPickerItems,
                    maxSelectionCount: viewModel.maximumPhotos,
                    matching: .images
                ) {
                    emptyPhotoPickerContent
                }
            } else {
                photoGrid
            }

            if viewModel.selectedPhotos.count < viewModel.minimumPhotos && !viewModel.selectedPhotos.isEmpty {
                Label("Add at least \(viewModel.minimumPhotos - viewModel.selectedPhotos.count) more photo(s)", systemImage: "info.circle")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.warning)
            }
        }
    }

    private var emptyPhotoPickerContent: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(DesignSystem.Colors.flameOrange)

            VStack(spacing: DesignSystem.Spacing.micro) {
                Text("Upload 3-6 Selfies")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Clear face shots, different angles, good lighting")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Text("Select Photos")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .strokeBorder(DesignSystem.Colors.flameOrange.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
    }

    private var photoGrid: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.xs),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.xs),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.xs)
            ], spacing: DesignSystem.Spacing.xs) {
                ForEach(viewModel.selectedPhotos) { photo in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))

                        Button {
                            viewModel.removePhoto(photo)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                }

                if viewModel.selectedPhotos.count < viewModel.maximumPhotos {
                    PhotosPicker(
                        selection: $viewModel.photosPickerItems,
                        maxSelectionCount: viewModel.maximumPhotos,
                        matching: .images
                    ) {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)

                            Text("Add")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(DesignSystem.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Style Picker Section

    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Choose Style")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(StylePreset.allPresets) { preset in
                        StylePresetCard(
                            preset: preset,
                            isSelected: viewModel.selectedStyle?.id == preset.id,
                            isLocked: shouldLockPreset(preset),
                            onTap: {
                                if shouldLockPreset(preset) {
                                    viewModel.showPaywall = true
                                } else {
                                    withAnimation(DesignSystem.Animation.quickSpring) {
                                        viewModel.selectedStyle = preset
                                    }
                                    DesignSystem.Haptics.light()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func shouldLockPreset(_ preset: StylePreset) -> Bool {
        switch subscriptionManager.currentTier {
        case .gold: return false
        case .plus: return preset.tier == .gold
        case .free: return preset.tier != .free
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            GRButton(
                title: "Generate Photos",
                icon: "wand.and.stars",
                isLoading: viewModel.isGenerating,
                isDisabled: !viewModel.canGenerate
            ) {
                Task {
                    await viewModel.generate(
                        userId: authManager.userId ?? "anonymous",
                        subscriptionManager: subscriptionManager
                    )
                }
            }

            if !viewModel.canGenerate && !viewModel.isGenerating {
                Text(generateHelpText)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var generateHelpText: String {
        if viewModel.selectedPhotos.count < viewModel.minimumPhotos {
            return "Upload at least \(viewModel.minimumPhotos) photos to start"
        } else if viewModel.selectedStyle == nil {
            return "Select a style preset"
        }
        return ""
    }

    // MARK: - Usage Banner

    private var usageBanner: some View {
        GRCard {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("\(subscriptionManager.currentTier.displayName) Plan")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(subscriptionManager.photosRemainingToday) photos left today")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                if subscriptionManager.currentTier == .free {
                    Button {
                        viewModel.showPaywall = true
                    } label: {
                        Text("Upgrade")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.deepNight)
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            Image(systemName: "wand.and.stars")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, isActive: true)

            VStack(spacing: DesignSystem.Spacing.small) {
                Text(viewModel.progressText)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                ProgressView(value: viewModel.generationProgress)
                    .tint(DesignSystem.Colors.flameOrange)
                    .scaleEffect(y: 2)
                    .padding(.horizontal, DesignSystem.Spacing.xl)

                Text("\(Int(viewModel.generationProgress * 100))%")
                    .font(DesignSystem.Typography.scoreDisplay)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .contentTransition(.numericText())
            }

            Text("This takes about 30 seconds.\nDon't close the app!")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            GRButton(title: "Cancel", style: .outline) {
                viewModel.isGenerating = false
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Style Preset Card

struct StylePresetCard: View {
    let preset: StylePreset
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: preset.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: preset.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)

                    if isLocked {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(Circle().fill(.black.opacity(0.6)))
                            }
                            Spacer()
                        }
                        .padding(4)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            isSelected ? DesignSystem.Colors.flameOrange : .clear,
                            lineWidth: 2
                        )
                )

                Text(preset.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(
                        isSelected
                            ? DesignSystem.Colors.flameOrange
                            : DesignSystem.Colors.textSecondary
                    )
                    .lineLimit(1)
            }
            .frame(width: 90)
        }
    }
}

#Preview {
    NavigationStack {
        GenerateView()
    }
    .environmentObject(AuthManager())
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}
