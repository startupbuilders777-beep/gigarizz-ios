import PhotosUI
import SwiftUI

// MARK: - Quick Upload Sheet

/// Single-screen, minimal-friction generation path for power users.
/// Flow: pick 1 photo → select style → tap Generate.
struct QuickUploadSheet: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = QuickUploadViewModel()
    @Environment(\.dismiss) private var dismiss

    // Show only free tier presets for quick selection
    private var quickPresets: [StylePreset] {
        StylePreset.allPresets.prefix(5).map { $0 }
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            if viewModel.isGenerating {
                generatingOverlay
            } else if viewModel.showResults {
                resultsView
            } else {
                mainContent
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
            Button("Retry") {
                Task {
                    await viewModel.generate(
                        userId: authManager.userId ?? "anonymous",
                        subscriptionManager: subscriptionManager
                    )
                }
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Header
            headerView

            // Photo picker zone
            photoPickerZone

            // Style carousel
            styleCarousel

            // Generate button
            generateButton

            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text("Quick Upload")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("One photo, one style, instant results")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
                DesignSystem.Haptics.light()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    // MARK: - Photo Picker Zone

    private var photoPickerZone: some View {
        Group {
            if let photo = viewModel.selectedPhoto {
                selectedPhotoView(photo)
            } else {
                emptyPhotoZone
            }
        }
    }

    private func selectedPhotoView(_ photo: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .strokeBorder(DesignSystem.Colors.flameOrange, lineWidth: 2)
                )
                .accessibilityLabel("Selected photo ready for generation")

            Button {
                viewModel.clearPhoto()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.6)))
            }
            .padding(DesignSystem.Spacing.small)
            .accessibilityLabel("Clear photo")
        }
    }

    private var emptyPhotoZone: some View {
        PhotosPicker(
            selection: $viewModel.photosPickerItem,
            matching: .images
        ) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)

                VStack(spacing: DesignSystem.Spacing.micro) {
                    Text("Select Photo")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Tap to pick your best selfie")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(
                        DesignSystem.Colors.flameOrange.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
            )
        }
    }

    // MARK: - Style Carousel

    private var styleCarousel: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Pick Style")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(quickPresets) { preset in
                        QuickStyleCard(
                            preset: preset,
                            isSelected: viewModel.selectedStyle?.id == preset.id,
                            onTap: {
                                withAnimation(DesignSystem.Animation.quickSpring) {
                                    viewModel.selectedStyle = preset
                                }
                                DesignSystem.Haptics.selection()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            GRButton(
                title: "Generate",
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

            if !viewModel.canGenerate {
                helpText
            }
        }
    }

    private var helpText: some View {
        Group {
            if viewModel.selectedPhoto == nil {
                Text("Select a photo to start")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            } else if viewModel.selectedStyle == nil {
                Text("Choose a style preset")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.surfaceSecondary, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: viewModel.generationProgress)
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignSystem.Animation.quickSpring, value: viewModel.generationProgress)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(viewModel.progressText)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Creating your dating photo...")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Button {
                viewModel.cancelGeneration()
                dismiss()
            } label: {
                Text("Cancel")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(Capsule())
            }
        }
        .padding(DesignSystem.Spacing.xxl)
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Success header
            VStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignSystem.Colors.success)

                Text("Photo Generated!")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            // Generated photo placeholder (mock AI doesn't return actual images)
            if viewModel.generatedPhotos.first != nil {
                generatedPhotoPlaceholder
            }

            // Share countdown or actions
            if viewModel.showSharePrompt {
                shareCountdownView
            } else {
                resultActions
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .onAppear {
            viewModel.startShareCountdown()
        }
    }

    private var generatedPhotoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)

            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "person.fill")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.5))

                Text("AI Generated Photo")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .cardShadow()
        .accessibilityLabel("AI generated dating photo")
    }

    private var shareCountdownView: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Sharing in \(viewModel.shareCountdown)s...")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.flameOrange)

            Button {
                viewModel.cancelShareCountdown()
            } label: {
                Text("Cancel")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    private var resultActions: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            GRButton(
                title: "Share",
                icon: "square.and.arrow.up",
                style: .primary
            ) {
                // Share placeholder - in production would share the actual generated image
                viewModel.cancelShareCountdown()
                DesignSystem.Haptics.success()
            }

            GRButton(
                title: "Generate Another",
                icon: "arrow.clockwise",
                style: .secondary
            ) {
                viewModel.reset()
            }

            GRButton(
                title: "Done",
                style: .outline
            ) {
                dismiss()
            }
        }
    }
}

// MARK: - Quick Style Card

/// Compact style preset card for quick selection carousel.
struct QuickStyleCard: View {
    let preset: StylePreset
    let isSelected: Bool
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
                        .frame(width: 60, height: 60)

                    Image(systemName: preset.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            isSelected ? DesignSystem.Colors.flameOrange : .clear,
                            lineWidth: 2
                        )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(DesignSystem.Animation.quickSpring, value: isSelected)

                Text(preset.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? DesignSystem.Colors.flameOrange
                            : DesignSystem.Colors.textSecondary
                    )
                    .lineLimit(1)
            }
        }
        .buttonStyle(HapticButtonStyle(hapticStyle: .light))
        .accessibilityLabel(preset.name)
        .accessibilityHint("Double tap to select \(preset.name) style")
    }
}

// MARK: - Preview

#Preview {
    QuickUploadSheet()
        .environmentObject(AuthManager.shared)
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}