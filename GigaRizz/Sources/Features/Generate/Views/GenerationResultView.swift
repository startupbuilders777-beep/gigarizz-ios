import SwiftUI

// MARK: - Generation Result View

struct GenerationResultView: View {
    let generatedPhotos: [GeneratedPhoto]
    let style: String
    @State private var selectedIndex = 0
    @State private var showSaveConfirmation = false
    @State private var showCelebration = true
    @State private var confettiVisible = false
    @State private var scoreAnimated = false
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private let mockScores: [Double] = [8.7, 9.2, 8.4, 9.5]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                if showCelebration {
                    celebrationView
                } else {
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .overlay {
                if showSaveConfirmation { saveConfirmationOverlay }
            }
        }
        .onAppear {
            DesignSystem.Haptics.success()
            withAnimation(DesignSystem.Animation.smoothSpring.delay(0.3)) {
                confettiVisible = true
            }
            // Auto-dismiss celebration after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(DesignSystem.Animation.smoothSpring) {
                    showCelebration = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(DesignSystem.Animation.smoothSpring) {
                        scoreAnimated = true
                    }
                }
            }
        }
    }

    // MARK: - Celebration View

    private var celebrationView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            ZStack {
                // Confetti particles
                if confettiVisible {
                    ForEach(0..<20, id: \.self) { i in
                        Circle()
                            .fill(confettiColor(i))
                            .frame(width: CGFloat.random(in: 6...12))
                            .offset(
                                x: CGFloat.random(in: -150...150),
                                y: confettiVisible ? CGFloat.random(in: -200...200) : 0
                            )
                            .opacity(confettiVisible ? 0 : 1)
                            .animation(
                                .easeOut(duration: Double.random(in: 1.5...2.5)).delay(Double.random(in: 0...0.5)),
                                value: confettiVisible
                            )
                    }
                }

                VStack(spacing: DesignSystem.Spacing.l) {
                    Text("\u{1F525}")
                        .font(.system(size: 80))
                        .scaleEffect(confettiVisible ? 1.2 : 0.5)
                        .animation(DesignSystem.Animation.cardSpring, value: confettiVisible)

                    Text("Photos Ready!")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .opacity(confettiVisible ? 1 : 0)

                    Text("\(generatedPhotos.count) \(style) photos generated")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .opacity(confettiVisible ? 1 : 0)
                }
            }

            Spacer()
        }
    }

    private func confettiColor(_ index: Int) -> Color {
        let colors: [Color] = [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent, .cyan, .pink, DesignSystem.Colors.success]
        return colors[index % colors.count]
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // Header with scoring
            headerWithScore

            // Photo Carousel
            TabView(selection: $selectedIndex) {
                ForEach(Array(generatedPhotos.enumerated()), id: \.element.id) { index, photo in
                    generatedPhotoCard(photo: photo, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 400)

            // Photo dots
            photoDots

            Spacer()

            // Action buttons
            actionButtons
        }
    }

    // MARK: - Header with Score

    private var headerWithScore: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text("Your Photos")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("\(generatedPhotos.count) photos \u{B7} \(style) style")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            // Rizz score for current photo
            VStack(spacing: 2) {
                Text(scoreAnimated ? String(format: "%.1f", currentScore) : "0.0")
                    .font(DesignSystem.Typography.scoreDisplay)
                    .foregroundStyle(scoreColor(currentScore))
                    .contentTransition(.numericText())
                Text("Rizz Score")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.top, DesignSystem.Spacing.m)
    }

    private var currentScore: Double {
        guard selectedIndex < mockScores.count else { return 8.5 }
        return mockScores[selectedIndex]
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 9.0 { return DesignSystem.Colors.success }
        if score >= 8.0 { return DesignSystem.Colors.flameOrange }
        return DesignSystem.Colors.warning
    }

    // MARK: - Photo Card

    private func generatedPhotoCard(photo: GeneratedPhoto, index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: gradientForIndex(index),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "person.fill")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.5))

                Text("AI Enhanced")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(.white.opacity(0.7))

                // Score badge
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                    Text(String(format: "%.1f", mockScores[index % mockScores.count]))
                        .font(DesignSystem.Typography.callout)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(Capsule().fill(.white.opacity(0.2)))
            }
        }
        .frame(height: 370)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .padding(.horizontal, DesignSystem.Spacing.l)
        .cardShadow()
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

    // MARK: - Photo Dots

    private var photoDots: some View {
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
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            // Primary: Save all
            GRButton(title: "Save All to Photos", icon: "square.and.arrow.down") {
                saveAllPhotos()
            }

            // Secondary row
            HStack(spacing: DesignSystem.Spacing.s) {
                GRButton(title: "Share", icon: "square.and.arrow.up", style: .outline) {
                    showShareSheet = true
                    DesignSystem.Haptics.light()
                }

                GRButton(title: "Generate More", icon: "arrow.counterclockwise", style: .secondary) {
                    dismiss()
                }
            }

            // Use as profile button
            Button {
                DesignSystem.Haptics.medium()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 14))
                    Text("Set as Dating Profile Photo")
                        .font(DesignSystem.Typography.smallButton)
                }
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.bottom, DesignSystem.Spacing.l)
    }

    // MARK: - Save

    private func saveAllPhotos() {
        showSaveConfirmation = true
        DesignSystem.Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaveConfirmation = false }
        }
    }

    private var saveConfirmationOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: DesignSystem.Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                    .font(.system(size: 20))
                Text("\(generatedPhotos.count) photos saved to library!")
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
            GeneratedPhoto(userId: "demo", style: "Confident")
        ],
        style: "Confident"
    )
    .preferredColorScheme(.dark)
}
