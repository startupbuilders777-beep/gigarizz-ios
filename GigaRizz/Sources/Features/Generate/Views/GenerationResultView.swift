import SwiftUI

// MARK: - Generation Result View

struct GenerationResultView: View {
    let generatedPhotos: [GeneratedPhoto]
    let style: String
    @State private var selectedIndex = 0
    @State private var showSaveConfirmation = false
    @State private var showFullScreenPreview = false
    @State private var previewStartingIndex = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.l) {
                    // MARK: - Header
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Your Photos Are Ready! 🔥")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("\(generatedPhotos.count) photos · \(style) style")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.m)

                    // MARK: - Photo Carousel
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(generatedPhotos.enumerated()), id: \.element.id) { index, photo in
                            generatedPhotoCard(photo: photo, index: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 420)

                    // MARK: - Photo Counter
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(0..<generatedPhotos.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    index == selectedIndex
                                        ? DesignSystem.Colors.flameOrange
                                        : DesignSystem.Colors.surfaceSecondary
                                )
                                .frame(width: 8, height: 8)
                                .animation(DesignSystem.Animation.quickSpring, value: selectedIndex)
                        }
                    }

                    Spacer()

                    // MARK: - Action Buttons
                    VStack(spacing: DesignSystem.Spacing.s) {
                        GRButton(
                            title: "Save All to Photos",
                            icon: "square.and.arrow.down"
                        ) {
                            saveAllPhotos()
                        }

                        HStack(spacing: DesignSystem.Spacing.s) {
                            GRButton(title: "Share", icon: "square.and.arrow.up", style: .outline) {
                                DesignSystem.Haptics.light()
                            }

                            GRButton(title: "Generate More", icon: "arrow.counterclockwise", style: .secondary) {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.bottom, DesignSystem.Spacing.l)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .overlay {
                if showSaveConfirmation {
                    saveConfirmationOverlay
                }
            }
            .fullScreenCover(isPresented: $showFullScreenPreview) {
                FullScreenPhotoPreviewView(
                    photos: generatedPhotos,
                    startingIndex: $previewStartingIndex,
                    onDismiss: { showFullScreenPreview = false }
                )
            }
        }
    }

    // MARK: - Photo Card

    private func generatedPhotoCard(photo: GeneratedPhoto, index: Int) -> some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: gradientForIndex(index),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Photo content
                VStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("AI Generated Photo")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("#\(index + 1)")
                        .font(DesignSystem.Typography.scoreLarge)
                        .foregroundStyle(.white)
                }

                // Tap to expand indicator
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(DesignSystem.Spacing.s)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(DesignSystem.Spacing.m)
                    }
                }
            }
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .padding(.horizontal, DesignSystem.Spacing.l)
            .cardShadow()
            .onTapGesture {
                DesignSystem.Haptics.light()
                previewStartingIndex = index
                showFullScreenPreview = true
            }
        }
    }

    private func gradientForIndex(_ index: Int) -> [Color] {
        let gradients: [[Color]] = [
            [DesignSystem.Colors.flameOrange, .orange],
            [.purple, .blue],
            [.teal, .cyan],
            [.pink, .red],
        ]
        return gradients[index % gradients.count]
    }

    // MARK: - Save All Photos

    private func saveAllPhotos() {
        showSaveConfirmation = true
        DesignSystem.Haptics.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveConfirmation = false
            }
        }
    }

    // MARK: - Save Confirmation

    private var saveConfirmationOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: DesignSystem.Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                    .font(.system(size: 20))

                Text("Photos saved to library!")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.m)
            .background(DesignSystem.Colors.surface)
            .clipShape(Capsule())
            .cardShadow()
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(DesignSystem.Animation.smoothSpring, value: showSaveConfirmation)
    }
}

#Preview {
    GenerationResultView(
        generatedPhotos: [
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Confident"),
        ],
        style: "Confident"
    )
    .preferredColorScheme(.dark)
}
