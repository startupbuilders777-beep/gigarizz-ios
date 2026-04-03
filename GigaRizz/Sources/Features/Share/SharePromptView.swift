import SwiftUI
import PhotosUI

// MARK: - Share Prompt View

/// Full-screen share prompt modal shown after photo generation.
struct SharePromptView: View {
    let photos: [GeneratedPhoto]
    let style: String
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var shareService = ShareService()
    @State private var selectedPhotoIndex = 0
    @State private var selectedCaption: String?
    @State private var includeWatermark = true
    @State private var selectedAspectRatio: ShareAspectRatio = .square
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.large) {
                headerSection
                photoPreviewSection
                captionSection
                aspectRatioSection
                watermarkSection
                Spacer()
                actionButtons
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.large)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                items: shareItems,
                completion: { activityType, completed, _, _ in
                    shareService.handleShareCompletion(
                        activityType: activityType,
                        completed: completed,
                        photoId: photos[selectedPhotoIndex].id,
                        style: style
                    )
                    if completed {
                        dismiss()
                    }
                }
            )
        }
        .onAppear {
            // Free tier: watermark on by default
            includeWatermark = subscriptionManager.currentTier == .free
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Share Your Glow-Up")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("One tap to Instagram, Messages, or anywhere")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Photo Preview

    private var photoPreviewSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Select Photo")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Photo carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        photoThumbnail(index: index, photo: photo)
                    }
                }
                .padding(.horizontal, 2)
            }

            // Main preview
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: gradientForIndex(selectedPhotoIndex),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: DesignSystem.Spacing.medium) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("AI Generated Photo #\(selectedPhotoIndex + 1)")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(.white.opacity(0.7))

                    Text(style)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .cardShadow()
        }
    }

    private func photoThumbnail(index: Int, photo: GeneratedPhoto) -> some View {
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                selectedPhotoIndex = index
            }
            DesignSystem.Haptics.light()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(
                        LinearGradient(
                            colors: gradientForIndex(index),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .strokeBorder(
                        selectedPhotoIndex == index
                            ? DesignSystem.Colors.flameOrange
                            : .clear,
                        lineWidth: 2
                    )
            )
        }
    }

    private func gradientForIndex(_ index: Int) -> [Color] {
        let gradients: [[Color]] = [
            [DesignSystem.Colors.flameOrange, .orange],
            [.purple, .blue],
            [.teal, .cyan],
            [.pink, .red]
        ]
        return gradients[index % gradients.count]
    }

    // MARK: - Caption Section

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Label("Caption Suggestion", systemImage: "text.quote")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(ShareCaptionSuggestion.suggestions) { suggestion in
                        captionChip(suggestion)
                    }
                }
            }

            if let caption = selectedCaption {
                HStack {
                    Text(caption)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Button {
                        selectedCaption = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            }
        }
    }

    private func captionChip(_ suggestion: ShareCaptionSuggestion) -> some View {
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                selectedCaption = suggestion.emoji + " " + suggestion.text
            }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: 4) {
                Text(suggestion.emoji)
                Text(suggestion.text)
                    .font(DesignSystem.Typography.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                selectedCaption?.contains(suggestion.text) == true
                    ? DesignSystem.Colors.flameOrange.opacity(0.2)
                    : DesignSystem.Colors.surfaceSecondary
            )
            .foregroundStyle(
                selectedCaption?.contains(suggestion.text) == true
                    ? DesignSystem.Colors.flameOrange
                    : DesignSystem.Colors.textSecondary
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        selectedCaption?.contains(suggestion.text) == true
                            ? DesignSystem.Colors.flameOrange
                            : .clear,
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Aspect Ratio Section

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Label("Format", systemImage: "rectangle.crop")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(ShareAspectRatio.allCases) { ratio in
                    aspectRatioButton(ratio)
                }
            }
        }
    }

    private func aspectRatioButton(_ ratio: ShareAspectRatio) -> some View {
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                selectedAspectRatio = ratio
            }
            DesignSystem.Haptics.light()
        } label: {
            VStack(spacing: DesignSystem.Spacing.micro) {
                Image(systemName: ratio.icon)
                    .font(.system(size: 16))

                Text(ratio.displayName)
                    .font(DesignSystem.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(
                selectedAspectRatio == ratio
                    ? DesignSystem.Colors.flameOrange.opacity(0.15)
                    : DesignSystem.Colors.surface
            )
            .foregroundStyle(
                selectedAspectRatio == ratio
                    ? DesignSystem.Colors.flameOrange
                    : DesignSystem.Colors.textSecondary
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .strokeBorder(
                        selectedAspectRatio == ratio
                            ? DesignSystem.Colors.flameOrange
                            : .clear,
                        lineWidth: 1.5
                    )
            )
        }
    }

    // MARK: - Watermark Section

    private var watermarkSection: some View {
        GRCard {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("\"Made with GigaRizz\" watermark")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Friends see where you got your glow-up")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                if subscriptionManager.currentTier == .gold {
                    Toggle("", isOn: $includeWatermark)
                        .labelsHidden()
                        .tint(DesignSystem.Colors.flameOrange)
                } else {
                    Text("Free")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, DesignSystem.Spacing.micro)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            GRButton(
                title: "Share Now",
                icon: "square.and.arrow.up",
                isLoading: shareService.isProcessing
            ) {
                Task {
                    await sharePhoto()
                }
            }

            HStack(spacing: DesignSystem.Spacing.small) {
                GRButton(
                    title: "Save to Photos",
                    icon: "square.and.arrow.down",
                    style: .secondary
                ) {
                    saveToLibrary()
                }

                GRButton(
                    title: "Later",
                    style: .outline
                ) {
                    dismiss()
                }
            }
        }
        .padding(.bottom, DesignSystem.Spacing.large)
    }

    // MARK: - Actions

    private func sharePhoto() async {
        // Create placeholder image for demo
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let placeholderImage = renderer.image { context in
            let gradient = gradientForIndex(selectedPhotoIndex)
            UIColor(gradient[0]).setFill()
            UIRectFill(CGRect(origin: .zero, size: renderer.format.bounds.size))
        }

        let configuration = ShareConfiguration(
            includeWatermark: includeWatermark,
            caption: selectedCaption,
            deepLinkId: photos[selectedPhotoIndex].id,
            aspectRatio: selectedAspectRatio
        )

        shareItems = await shareService.prepareShareItems(
            image: placeholderImage,
            configuration: configuration
        )

        showShareSheet = true
        DesignSystem.Haptics.light()
    }

    private func saveToLibrary() {
        DesignSystem.Haptics.success()
        // PhotoLibraryService handles saving
        dismiss()
    }
}

// MARK: - Share Aspect Ratio Icon Extension

extension ShareAspectRatio {
    var icon: String {
        switch self {
        case .square: return "square"
        case .portrait: return "rectangle.portrait"
        case .stories: return "rectangle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    SharePromptView(
        photos: [
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Confident")
        ],
        style: "Confident"
    )
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}