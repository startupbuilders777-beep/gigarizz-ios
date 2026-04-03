import PhotosUI
import SwiftUI

// MARK: - First Generation Flow View

/// Guided flow for first-time users to generate their AI dating photos.
/// 4 steps: Upload → Style → Wait → Share
struct FirstGenerationFlowView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = FirstGenerationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                switch viewModel.currentStep {
                case .upload:
                    uploadStep
                case .style:
                    styleStep
                case .generating:
                    generatingStep
                case .results:
                    resultsStep
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.currentStep != .results {
                        Button {
                            viewModel.goBack()
                            DesignSystem.Haptics.light()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.currentStep != .results {
                        Button {
                            dismiss()
                            DesignSystem.Haptics.light()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(DesignSystem.Colors.surface)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 1: Upload

    private var uploadStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header
                VStack(spacing: DesignSystem.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [DesignSystem.Colors.flameOrange.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Let's Create Your Photos")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Upload 3-5 selfies. AI will transform them into\nmagazine-quality dating photos in seconds.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, DesignSystem.Spacing.xl)

                // Photo requirements
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    requirementRow(icon: "checkmark.circle.fill", text: "Clear face visibility", isMet: true)
                    requirementRow(icon: "checkmark.circle.fill", text: "Different angles & poses", isMet: true)
                    requirementRow(icon: "checkmark.circle.fill", text: "Good lighting (no harsh shadows)", isMet: true)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                // Photo picker area
                if viewModel.selectedPhotos.isEmpty {
                    emptyPickerArea
                } else {
                    photoGrid
                }

                // Photo count indicator
                photoCountIndicator

                // Continue button
                GRButton(
                    title: "Continue",
                    icon: "arrow.right",
                    isDisabled: !viewModel.canProceedFromUpload
                ) {
                    viewModel.proceedToStyle()
                    DesignSystem.Haptics.medium()
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
    }

    private var emptyPickerArea: some View {
        PhotosPicker(
            selection: $viewModel.photosPickerItems,
            maxSelectionCount: viewModel.maximumPhotos,
            matching: .images
        ) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .strokeBorder(
                            DesignSystem.Colors.flameOrange.opacity(0.4),
                            style: StrokeStyle(lineWidth: 2, dash: [12, 6])
                        )
                        .frame(height: 200)

                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)

                        Text("Tap to Upload Photos")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("3-5 selfies required")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
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
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))

                        Button {
                            viewModel.removePhoto(photo)
                            DesignSystem.Haptics.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                }

                // Add more button
                if viewModel.selectedPhotos.count < viewModel.maximumPhotos {
                    PhotosPicker(
                        selection: $viewModel.photosPickerItems,
                        maxSelectionCount: viewModel.maximumPhotos - viewModel.selectedPhotos.count,
                        matching: .images
                    ) {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)

                            Text("Add")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
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
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private var photoCountIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: viewModel.photoCountIcon)
                .font(.system(size: 16))
                .foregroundStyle(viewModel.photoCountColor)

            Text(viewModel.photoCountText)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(viewModel.photoCountColor)

            Spacer()

            if viewModel.selectedPhotos.count < viewModel.minimumPhotos && !viewModel.selectedPhotos.isEmpty {
                Text("Need \(viewModel.minimumPhotos - viewModel.selectedPhotos.count) more")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.warning)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func requirementRow(icon: String, text: String, isMet: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isMet ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)

            Text(text)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
        .padding(DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    // MARK: - Step 2: Style Selection

    private var styleStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text("Choose Your Style")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("AI analyzed your photos and suggests: ")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary) +
                    Text(viewModel.aiSuggestedStyle?.name ?? "Confident")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                .padding(.top, DesignSystem.Spacing.xl)

                // AI suggestion card
                if let suggestedStyle = viewModel.aiSuggestedStyle {
                    GRCard {
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(
                                        LinearGradient(
                                            colors: suggestedStyle.gradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)

                                Image(systemName: suggestedStyle.icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DesignSystem.Colors.flameOrange)

                                    Text("AI Recommended")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                                }

                                Text(suggestedStyle.name)
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                Text(suggestedStyle.description)
                                    .font(DesignSystem.Typography.footnote)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button {
                                viewModel.selectedStyle = suggestedStyle
                                viewModel.proceedToGenerating()
                                DesignSystem.Haptics.medium()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(DesignSystem.Colors.success)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }

                // Style options
                Text("Or choose a different style:")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.medium)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(viewModel.availableStyles) { style in
                            styleCard(style)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }

                // Generate button
                GRButton(
                    title: "Generate My Photos",
                    icon: "wand.and.stars",
                    isDisabled: viewModel.selectedStyle == nil
                ) {
                    viewModel.proceedToGenerating()
                    DesignSystem.Haptics.medium()
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
    }

    private func styleCard(_ style: StylePreset) -> some View {
        Button {
            viewModel.selectedStyle = style
            DesignSystem.Haptics.light()
        } label: {
            VStack(spacing: DesignSystem.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: style.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: style.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)

                    if viewModel.selectedStyle?.id == style.id {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(DesignSystem.Colors.success))
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            viewModel.selectedStyle?.id == style.id
                                ? DesignSystem.Colors.flameOrange
                                : .clear,
                            lineWidth: 2
                        )
                )

                Text(style.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(
                        viewModel.selectedStyle?.id == style.id
                            ? DesignSystem.Colors.flameOrange
                            : DesignSystem.Colors.textSecondary
                    )
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Step 3: Generating

    private var generatingStep: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Animated flame effect
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignSystem.Colors.flameOrange.opacity(0.4),
                                DesignSystem.Colors.goldAccent.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
                    .scaleEffect(viewModel.generationProgress * 1.2 + 0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.generationProgress)

                // Icon
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, isActive: viewModel.isGenerating)
            }

            // Progress text
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text(viewModel.progressText)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                // Circular progress
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
                        .animation(.linear(duration: 0.3), value: viewModel.generationProgress)

                    Text("\(Int(viewModel.generationProgress * 100))%")
                        .font(DesignSystem.Typography.scoreDisplay)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .contentTransition(.numericText())
                }

                // Time estimate
                Text(viewModel.timeRemainingText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Tips carousel
            tipsCarousel

            Spacer()

            // Cancel button
            GRButton(title: "Cancel", style: .outline) {
                viewModel.cancelGeneration()
                viewModel.currentStep = .style
                DesignSystem.Haptics.light()
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    private var tipsCarousel: some View {
        TabView(selection: $viewModel.currentTipIndex) {
            ForEach(Array(viewModel.generationTips.enumerated()), id: \.offset) { index, tip in
                tipCard(tip)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 80)
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func tipCard(_ tip: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.goldAccent)

            Text(tip)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Step 4: Results

    private var resultsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Success header
                VStack(spacing: DesignSystem.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [DesignSystem.Colors.success.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(DesignSystem.Colors.success)
                    }

                    Text("Your Photos Are Ready! 🔥")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(viewModel.generatedPhotos.count) AI-generated photos")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.xl)

                // Photo masonry grid
                photoMasonryGrid

                // Share glow-up prompt
                shareGlowUpSection

                // Action buttons
                VStack(spacing: DesignSystem.Spacing.small) {
                    GRButton(
                        title: "Save All to Photos",
                        icon: "square.and.arrow.down"
                    ) {
                        viewModel.saveAllPhotos()
                        DesignSystem.Haptics.success()
                    }

                    GRButton(
                        title: "Generate More",
                        icon: "arrow.counterclockwise",
                        style: .secondary
                    ) {
                        viewModel.reset()
                        DesignSystem.Haptics.light()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .overlay {
            if viewModel.showSaveConfirmation {
                saveConfirmationToast
            }
        }
    }

    private var photoMasonryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
            GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
        ], spacing: DesignSystem.Spacing.small) {
            ForEach(Array(viewModel.generatedPhotos.enumerated()), id: \.element.id) { index, photo in
                generatedPhotoCard(photo: photo, index: index)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func generatedPhotoCard(photo: GeneratedPhoto, index: Int) -> some View {
        ZStack {
            // Placeholder gradient (in production, would show actual image)
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(
                    LinearGradient(
                        colors: gradientForIndex(index),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: index % 3 == 0 ? 220 : 180)

            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.5))

                Text("#\(index + 1)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Favorite button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        viewModel.toggleFavorite(photo)
                        DesignSystem.Haptics.light()
                    } label: {
                        Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(photo.isFavorite ? DesignSystem.Colors.flameOrange : .white.opacity(0.7))
                            .padding(8)
                            .background(Circle().fill(.black.opacity(0.4)))
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .cardShadow()
    }

    private func gradientForIndex(_ index: Int) -> [Color] {
        let gradients: [[Color]] = [
            [DesignSystem.Colors.flameOrange, .orange],
            [.purple, .blue],
            [.teal, .cyan],
            [.pink, .red],
            [DesignSystem.Colors.goldAccent, .yellow]
        ]
        return gradients[index % gradients.count]
    }

    private var shareGlowUpSection: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Share Your Glow-Up")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Show your friends how AI upgraded your photos!")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                HStack(spacing: DesignSystem.Spacing.medium) {
                    shareButton(title: "Instagram", icon: "camera.fill", color: .purple) {
                        viewModel.shareToInstagram()
                    }

                    shareButton(title: "TikTok", icon: "play.fill", color: .pink) {
                        viewModel.shareGeneric()
                    }

                    shareButton(title: "More", icon: "square.and.arrow.up", color: DesignSystem.Colors.flameOrange) {
                        viewModel.shareGeneric()
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func shareButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    private var saveConfirmationToast: some View {
        VStack {
            Spacer()

            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                    .font(.system(size: 20))

                Text("Saved to Photos!")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .cardShadow()
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(DesignSystem.Animation.smoothSpring, value: viewModel.showSaveConfirmation)
    }
}

// MARK: - Preview

#Preview {
    FirstGenerationFlowView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}