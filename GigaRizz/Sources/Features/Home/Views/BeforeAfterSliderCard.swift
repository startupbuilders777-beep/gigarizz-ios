import SwiftUI

// MARK: - Before/After Slider Card

/// Viral home screen hook: draggable before/after comparison card.
/// Shown prominently on HomeView for returning users with existing generations.
/// Auto-animates if no interaction for 3 seconds.
struct BeforeAfterSliderCard: View {
    let beforeImageName: String?
    let afterImageName: String?
    let styleName: String
    let onGenerateMore: () -> Void

    @State private var sliderPosition: CGFloat = 0.5
    @State private var isDragging = false
    @State private var autoAnimateTimer: Timer?
    @State private var isAnimating = false
    @State private var animationPhase: CGFloat = 0.0

    // Fallback images for demo (SF Symbols placeholders)
    private let demoBefore = "person.fill"
    private let demoAfter = "person.crop.circle.fill"

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Card
            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.deepNight)
                    .frame(height: 280)

                // Comparison view
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let dividerX = width * sliderPosition

                    ZStack {
                        // AFTER (right/after) — full image
                        Image(systemName: demoAfter)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: 280)
                            .clipped()
                            .overlay(
                                Text("AFTER")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(DesignSystem.Colors.flameOrange)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(8),
                                alignment: .topTrailing
                            )

                        // BEFORE (left/before) — clipped by slider
                        Image(systemName: demoBefore)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: dividerX, height: 280)
                            .clipped()
                            .overlay(
                                Text("BEFORE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(8),
                                alignment: .topLeading
                            )

                        // Slider divider line
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3)
                            .position(x: dividerX, y: 140)

                        // Drag handle
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .overlay(
                                Image(systemName: "arrow.left.and.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(DesignSystem.Colors.deepNight)
                            )
                            .position(x: dividerX, y: 140)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        cancelAutoAnimation()
                                        let newX = min(max(value.location.x, 0), width)
                                        sliderPosition = newX / width
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        startAutoAnimation()
                                    }
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            }

            // Style badge + CTA
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Glow-Up")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(styleName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }

                Spacer()

                Button {
                    DesignSystem.Haptics.medium()
                    onGenerateMore()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Generate More")
                            .font(DesignSystem.Typography.smallButton)
                    }
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.surface)
        )
        .onAppear {
            startAutoAnimation()
        }
        .onDisappear {
            cancelAutoAnimation()
        }
    }

    // MARK: - Auto Animation

    private func startAutoAnimation() {
        cancelAutoAnimation()
        // Delay 3 seconds before starting
        autoAnimateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            guard !isDragging else { return }
            performAutoSweep()
        }
    }

    private func cancelAutoAnimation() {
        autoAnimateTimer?.invalidate()
        autoAnimateTimer = nil
    }

    private func performAutoSweep() {
        guard !isDragging else { return }

        withAnimation(.easeInOut(duration: 2.0)) {
            sliderPosition = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
            guard !isDragging else { return }
            withAnimation(.easeInOut(duration: 2.0)) {
                sliderPosition = 0.05
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
                guard !isDragging else { return }
                performAutoSweep()
            }
        }
    }
}

// MARK: - Sample Transformation Card (for new users)

struct SampleTransformationCard: View {
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Sample before/after preview
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.deepNight)
                    .frame(height: 200)

                HStack(spacing: 0) {
                    // Before sample
                    VStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                        Text("BEFORE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.large)

                    // Arrow
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .padding(.horizontal, DesignSystem.Spacing.small)

                    // After sample
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("AFTER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.large)
                }
            }

            // CTA
            Button {
                DesignSystem.Haptics.medium()
                onGenerate()
            } label: {
                Text("See Your Glow-Up")
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.surface)
        )
    }
}

// MARK: - Preview

#Preview("Slider Card") {
    VStack {
        BeforeAfterSliderCard(
            beforeImageName: nil,
            afterImageName: nil,
            styleName: "Confident",
            onGenerateMore: {}
        )
        .padding()

        SampleTransformationCard(onGenerate: {})
            .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
