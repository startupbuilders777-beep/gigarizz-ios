import PostHog
import SwiftUI

// MARK: - Before/After Share View

struct BeforeAfterShareView: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let styleName: String

    @State private var sliderPosition: CGFloat = 0.5
    @State private var isDragging = false
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignSystem.Colors.deepNight.ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.large) {
                headerBar
                comparisonCard
                shareButtons
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)

            if showCopied {
                copiedToast
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [image, shareCaption])
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Share Your Glow-Up")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Before/After Comparison

    private var comparisonCard: some View {
        VStack(spacing: 0) {
            // Image comparison
            GeometryReader { geometry in
                let width = geometry.size.width
                let dividerX = width * sliderPosition

                ZStack {
                    // After image (full)
                    Image(uiImage: afterImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: width * 1.25)
                        .clipped()

                    // Before image (clipped by slider)
                    Image(uiImage: beforeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: width * 1.25)
                        .clipped()
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle().frame(width: dividerX)
                                Spacer()
                            }
                        )

                    // Divider line
                    Rectangle()
                        .fill(.white)
                        .frame(width: 3)
                        .position(x: dividerX, y: geometry.size.height / 2)
                        .shadow(color: .black.opacity(0.5), radius: 4)

                    // Drag handle
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.deepNight)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6)
                        .position(x: dividerX, y: geometry.size.height / 2)
                        .scaleEffect(isDragging ? 1.15 : 1.0)

                    // Labels
                    VStack {
                        HStack {
                            Text("BEFORE")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(DesignSystem.Spacing.small)

                            Spacer()

                            Text("AFTER")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    DesignSystem.Colors.flameOrange.opacity(0.8)
                                )
                                .clipShape(Capsule())
                                .padding(DesignSystem.Spacing.small)
                        }
                        Spacer()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            withAnimation(DesignSystem.Animation.quickSpring) {
                                isDragging = true
                                sliderPosition = min(max(value.location.x / width, 0.05), 0.95)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(DesignSystem.Animation.quickSpring) {
                                isDragging = false
                            }
                        }
                )
            }
            .frame(height: UIScreen.main.bounds.width * 1.15)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignSystem.CornerRadius.card,
                    topTrailingRadius: DesignSystem.CornerRadius.card
                )
            )

            // Watermark footer
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Text("Made with GigaRizz")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("•")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(styleName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(DesignSystem.Colors.surface)
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: DesignSystem.CornerRadius.card,
                    bottomTrailingRadius: DesignSystem.CornerRadius.card
                )
            )
        }
    }

    // MARK: - Share Buttons

    private var shareButtons: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Primary share row
            HStack(spacing: DesignSystem.Spacing.small) {
                shareButton(
                    title: "Instagram",
                    icon: "camera.fill",
                    color: .purple
                ) { shareToInstagram() }

                shareButton(
                    title: "TikTok",
                    icon: "play.fill",
                    color: .pink
                ) { shareGeneric() }

                shareButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    color: DesignSystem.Colors.flameOrange
                ) { shareGeneric() }
            }

            // Save button
            Button {
                saveToPhotos()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save to Photos")
                }
                .font(DesignSystem.Typography.button)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            }
        }
    }

    private func shareButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func renderShareImage() -> UIImage {
        if let cached = renderedImage { return cached }

        let size = CGSize(width: 1080, height: 1620)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Background
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Before image (left half)
            let halfWidth = size.width / 2
            beforeImage.draw(in: CGRect(x: 0, y: 0, width: halfWidth, height: size.height - 80))

            // After image (right half)
            afterImage.draw(in: CGRect(x: halfWidth, y: 0, width: halfWidth, height: size.height - 80))

            // Divider
            let dividerRect = CGRect(x: halfWidth - 2, y: 0, width: 4, height: size.height - 80)
            UIColor.white.setFill()
            context.fill(dividerRect)

            // Labels
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            "BEFORE".draw(at: CGPoint(x: 24, y: 24), withAttributes: attrs)
            "AFTER".draw(at: CGPoint(x: halfWidth + 24, y: 24), withAttributes: attrs)

            // Watermark
            let watermarkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            "🔥 Made with GigaRizz".draw(
                at: CGPoint(x: 24, y: size.height - 64),
                withAttributes: watermarkAttrs
            )
        }

        renderedImage = image
        return image
    }

    private func shareGeneric() {
        renderedImage = renderShareImage()
        showShareSheet = true

        PostHogSDK.shared.capture("before_after_shared", properties: [
            "style": styleName,
            "method": "generic"
        ])
    }

    private func shareToInstagram() {
        // Instagram Stories sharing via URL scheme
        let image = renderShareImage()
        guard let imageData = image.pngData() else { return }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]
        UIPasteboard.general.setItems([pasteboardItems], options: [
            .expirationDate: Date().addingTimeInterval(300)
        ])

        if let url = URL(string: "instagram-stories://share") {
            UIApplication.shared.open(url)
        } else {
            // Fallback to generic share
            shareGeneric()
        }

        PostHogSDK.shared.capture("before_after_shared", properties: [
            "style": styleName,
            "method": "instagram"
        ])
    }

    private func saveToPhotos() {
        let image = renderShareImage()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        DesignSystem.Haptics.success()

        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopied = false }
        }

        PostHogSDK.shared.capture("before_after_saved", properties: ["style": styleName])
    }

    private var shareCaption: String {
        "My dating photo glow-up with GigaRizz 🔥\n\n#GigaRizz #DatingApp #GlowUp #AIPhotos"
    }

    // MARK: - Toast

    private var copiedToast: some View {
        VStack {
            Spacer()
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("Saved to Photos!")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - ShareSheet UIKit bridge (local)

private struct LocalShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
