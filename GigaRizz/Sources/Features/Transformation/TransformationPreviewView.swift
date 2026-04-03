import PhotosUI
import SwiftUI

// MARK: - Transformation Preview View

/// Featured card on the home screen showing before/after comparison of user's most recent generation.
/// For new users, displays a sample transformation as social proof.
struct TransformationPreviewView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = TransformationPreviewViewModel()
    @AppStorage("hasGeneratedPhotos") private var hasGeneratedPhotos = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var showGenerateFlow = false
    @State private var showComparisonDetail = false
    @State private var isDismissed = false

    var body: some View {
        Group {
            if !isDismissed {
                if hasGeneratedPhotos && viewModel.hasRecentGeneration {
                    userTransformationCard
                } else {
                    sampleTransformationCard
                }
            }
        }
        .onAppear {
            viewModel.fetchRecentGeneration(userId: authManager.userId ?? "anonymous")
        }
        .fullScreenCover(isPresented: $showGenerateFlow) {
            FirstGenerationFlowView()
        }
        .sheet(isPresented: $showComparisonDetail) {
            if let before = viewModel.beforeImage, let after = viewModel.afterImage {
                TransformationComparisonSheet(
                    beforeImage: before,
                    afterImage: after,
                    styleName: viewModel.styleName
                )
            }
        }
    }

    // MARK: - User Transformation Card

    private var userTransformationCard: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Last Transformation")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(viewModel.timeAgoText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Dismiss button
                Button {
                    withAnimation(DesignSystem.Animation.quickSpring) {
                        isDismissed = true
                    }
                    DesignSystem.Haptics.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .accessibilityLabel("Dismiss card")
            }

            // Before/After Slider Card
            BeforeAfterSliderCard(
                beforeImage: viewModel.beforeImage ?? placeholderBefore,
                afterImage: viewModel.afterImage ?? placeholderAfter,
                autoAnimate: !reduceMotion,
                onTap: {
                    DesignSystem.Haptics.medium()
                    showComparisonDetail = true
                }
            )

            // Action row
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Share button
                ShareComparisonButton(
                    beforeImage: viewModel.beforeImage ?? placeholderBefore,
                    afterImage: viewModel.afterImage ?? placeholderAfter
                )

                Spacer()

                // Generate More button
                Button {
                    DesignSystem.Haptics.light()
                    showGenerateFlow = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14))
                        Text("Generate More")
                            .font(DesignSystem.Typography.smallButton)
                    }
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Generate more photos")
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge))
        .cardShadow()
    }

    // MARK: - Sample Transformation Card (New Users)

    private var sampleTransformationCard: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Header with gradient
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DesignSystem.Colors.flameOrange.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("See What GigaRizz Can Do")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Real transformations from our users")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }

            // Sample before/after
            BeforeAfterSliderCard(
                beforeImage: sampleBeforeImage,
                afterImage: sampleAfterImage,
                autoAnimate: !reduceMotion,
                showLabels: true,
                onTap: {
                    DesignSystem.Haptics.medium()
                    showComparisonDetail = true
                }
            )

            // CTA
            GRButton(
                title: "Create Your Photos",
                icon: "wand.and.stars"
            ) {
                DesignSystem.Haptics.medium()
                showGenerateFlow = true
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                .strokeBorder(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange.opacity(0.5), DesignSystem.Colors.goldAccent.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cardShadow()
    }

    // MARK: - Placeholder Images

    private var placeholderBefore: UIImage {
        // Create a placeholder with "Before" label
        renderPlaceholder(text: "BEFORE", color: UIColor.systemGray)
    }

    private var placeholderAfter: UIImage {
        // Create a placeholder with "After" label
        renderPlaceholder(text: "AFTER", color: UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0))
    }

    private func renderPlaceholder(text: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 300, height: 280)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(red: 0.1, green: 0.1, blue: 0.14, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]

            let attributedString = NSAttributedString(string: text, attributes: attrs)
            let textRect = attributedString.boundingRect(
                with: CGSize(width: size.width, height: size.height),
                options: .usesLineFragmentOrigin,
                context: nil
            )

            let drawPoint = CGPoint(
                x: (size.width - textRect.width) / 2,
                y: (size.height - textRect.height) / 2
            )
            attributedString.draw(at: drawPoint)
        }
    }

    // MARK: - Sample Images (Social Proof)

    private var sampleBeforeImage: UIImage {
        // Create a sample "before" image - selfie style placeholder
        let size = CGSize(width: 300, height: 280)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Gradient background simulating a selfie
            let colors = [UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0),
                         UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colors.map { $0.cgColor } as CFArray,
                                       locations: [0, 1])!

            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])

            // "BEFORE" label
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.systemGray
            ]

            let string = "BEFORE"
            NSAttributedString(string: string, attributes: attrs)
                .draw(at: CGPoint(x: 12, y: 12))

            // Center icon
            UIImage(systemName: "person.crop.circle")?
                .withTintColor(.systemGray, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: size.width/2 - 40, y: size.height/2 - 40, width: 80, height: 80))
        }
    }

    private var sampleAfterImage: UIImage {
        // Create a sample "after" image - polished result placeholder
        let size = CGSize(width: 300, height: 280)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Warm gradient background
            let colors = [UIColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0),
                         UIColor(red: 0.1, green: 0.1, blue: 0.14, alpha: 1.0)]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colors.map { $0.cgColor } as CFArray,
                                       locations: [0, 1])!

            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])

            // "AFTER" label with flame orange
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)
            ]

            NSAttributedString(string: "AFTER", attributes: attrs)
                .draw(at: CGPoint(x: size.width - 50, y: 12))

            // Sparkles icon
            UIImage(systemName: "sparkles")?
                .withTintColor(UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0), renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: size.width/2 - 40, y: size.height/2 - 40, width: 80, height: 80))
        }
    }
}

// MARK: - Before/After Slider Card

/// Draggable slider comparing before and after photos.
/// Auto-animates after 3 seconds of inactivity.
struct BeforeAfterSliderCard: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    var autoAnimate: Bool = true
    var showLabels: Bool = false
    let onTap: () -> Void

    @State private var sliderPosition: CGFloat = 0.5
    @State private var isDragging = false
    @State private var animationTimer: Timer?
    @State private var hasInteracted = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let animationDuration: TimeInterval = 2.0
    private let inactivityThreshold: TimeInterval = 3.0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // After image (full, clipped by slider)
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .accessibilityHidden(true)

                // Before image (clipped to show left portion)
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .mask(
                        Rectangle()
                            .frame(width: width * sliderPosition)
                    )
                    .accessibilityHidden(true)

                // Slider divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: height)
                    .position(x: width * sliderPosition, y: height / 2)

                // Drag handle
                sliderHandle(position: width * sliderPosition)

                // Labels (optional)
                if showLabels {
                    labelsOverlay(width: width, height: height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(value: value, width: width)
                    }
                    .onEnded { _ in
                        endDrag()
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        onTap()
                    }
            )
        }
        .frame(height: 280)
        .onAppear {
            if autoAnimate && !reduceMotion {
                startInactivityTimer()
            }
        }
        .onDisappear {
            stopAnimationTimer()
        }
        .onChange(of: reduceMotion) { _, newValue in
            if newValue {
                stopAnimationTimer()
            } else if autoAnimate {
                startInactivityTimer()
            }
        }
    }

    // MARK: - Slider Handle

    private func sliderHandle(position: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .position(x: position, y: 140)
        .accessibilityLabel("Drag to compare before and after")
        .accessibilityHint("Slide left or right to reveal more of the transformation")
    }

    // MARK: - Labels Overlay

    private func labelsOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // BEFORE label (left side)
            Text("BEFORE")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .position(x: 40, y: 20)

            // AFTER label (right side)
            Text("AFTER")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .position(x: width - 40, y: 20)
        }
    }

    // MARK: - Drag Handling

    private func handleDrag(value: DragGesture.Value, width: CGFloat) {
        isDragging = true
        hasInteracted = true
        stopAnimationTimer()

        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
            sliderPosition = max(0.05, min(0.95, value.location.x / width))
        }
    }

    private func endDrag() {
        isDragging = false
        DesignSystem.Haptics.light()

        if autoAnimate && !reduceMotion {
            startInactivityTimer()
        }
    }

    // MARK: - Auto-Animation

    private func startInactivityTimer() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: inactivityThreshold, repeats: false) { _ in
            Task { @MainActor in
                startSweepAnimation()
            }
        }
    }

    private func startSweepAnimation() {
        guard !isDragging && autoAnimate && !reduceMotion else { return }

        // Sweep from current position to opposite end, then back
        let targetPosition: CGFloat = sliderPosition < 0.5 ? 0.95 : 0.05

        withAnimation(.easeInOut(duration: animationDuration)) {
            sliderPosition = targetPosition
        }

        // After sweep completes, return to center and restart timer
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.5) {
            withAnimation(.easeInOut(duration: animationDuration / 2)) {
                sliderPosition = 0.5
            }

            if !hasInteracted {
                startInactivityTimer()
            }
        }
    }

    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Share Comparison Button

struct ShareComparisonButton: View {
    let beforeImage: UIImage
    let afterImage: UIImage

    @State private var showShareSheet = false

    var body: some View {
        Button {
            DesignSystem.Haptics.light()
            showShareSheet = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                Text("Share")
                    .font(DesignSystem.Typography.smallButton)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(Capsule())
        }
        .accessibilityLabel("Share transformation comparison")
        .sheet(isPresented: $showShareSheet) {
            if let comparisonImage = createComparisonImage() {
                ShareSheet(items: [comparisonImage])
            }
        }
    }

    private func createComparisonImage() -> UIImage? {
        let cardWidth: CGFloat = 600
        let cardHeight: CGFloat = 300
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cardWidth, height: cardHeight))

        return renderer.image { context in
            // Background
            UIColor(red: 0.1, green: 0.1, blue: 0.14, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: cardWidth, height: cardHeight)))

            // Before image (left half)
            let beforeRect = CGRect(x: 0, y: 0, width: cardWidth / 2, height: cardHeight)
            beforeImage.draw(in: beforeRect)

            // After image (right half)
            let afterRect = CGRect(x: cardWidth / 2, y: 0, width: cardWidth / 2, height: cardHeight)
            afterImage.draw(in: afterRect)

            // Divider line
            UIColor.white.setStroke()
            context.cgContext.setLineWidth(4)
            context.cgContext.move(to: CGPoint(x: cardWidth / 2, y: 0))
            context.cgContext.addLine(to: CGPoint(x: cardWidth / 2, y: cardHeight))
            context.cgContext.strokePath()

            // Labels
            let beforeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.systemGray
            ]
            NSAttributedString(string: "BEFORE", attributes: beforeAttrs)
                .draw(at: CGPoint(x: 12, y: 12))

            let afterAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)
            ]
            NSAttributedString(string: "AFTER", attributes: afterAttrs)
                .draw(at: CGPoint(x: cardWidth - 60, y: 12))
        }
    }
}

// MARK: - Transformation Comparison Sheet

struct TransformationComparisonSheet: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let styleName: String

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.large) {
                    // Style badge
                    HStack {
                        Spacer()
                        Text(styleName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(Capsule())
                        Spacer()
                    }

                    // Interactive comparison
                    BeforeAfterSliderCard(
                        beforeImage: beforeImage,
                        afterImage: afterImage,
                        autoAnimate: true,
                        showLabels: true,
                        onTap: {}
                    )

                    // Action buttons
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Button {
                            showShareSheet = true
                            DesignSystem.Haptics.light()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.medium)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(Capsule())
                        }

                        Button {
                            // Save to photo library
                            Task {
                                if let comparison = createComparisonForSaving() {
                                    try await saveToPhotoLibrary(comparison)
                                }
                            }
                            DesignSystem.Haptics.success()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "arrow.down.circle")
                                Text("Save")
                            }
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.medium)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let comparison = createComparisonForSaving() {
                    ShareSheet(items: [comparison])
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func createComparisonForSaving() -> UIImage? {
        let width: CGFloat = 600
        let height: CGFloat = 280
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        return renderer.image { context in
            UIColor(red: 0.1, green: 0.1, blue: 0.14, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))

            beforeImage.draw(in: CGRect(x: 0, y: 0, width: width / 2, height: height))
            afterImage.draw(in: CGRect(x: width / 2, y: 0, width: width / 2, height: height))

            UIColor.white.setStroke()
            context.cgContext.setLineWidth(4)
            context.cgContext.move(to: CGPoint(x: width / 2, y: 0))
            context.cgContext.addLine(to: CGPoint(x: width / 2, y: height))
            context.cgContext.strokePath()
        }
    }

    private func saveToPhotoLibrary(_ image: UIImage) async throws {
        let photoLibraryService = PhotoLibraryService()
        try await photoLibraryService.saveImage(image)
    }
}

// MARK: - Preview

#Preview("User Transformation") {
    TransformationPreviewView()
        .environmentObject(AuthManager())
        .padding()
        .background(DesignSystem.Colors.background)
        .preferredColorScheme(.dark)
}

#Preview("Before/After Slider") {
    BeforeAfterSliderCard(
        beforeImage: UIImage(systemName: "person")!
            .withTintColor(.systemGray, renderingMode: .alwaysOriginal),
        afterImage: UIImage(systemName: "sparkles")!
            .withTintColor(.systemOrange, renderingMode: .alwaysOriginal),
        autoAnimate: false,
        showLabels: true,
        onTap: {}
    )
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}