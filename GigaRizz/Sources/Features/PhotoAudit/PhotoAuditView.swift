import PhotosUI
import SwiftUI

// MARK: - Photo Audit View

struct PhotoAuditView: View {
    @StateObject private var viewModel = PhotoAuditViewModel()
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            if viewModel.isAnalyzing {
                analyzingOverlay
            } else if let result = viewModel.auditResult {
                auditResultsView(result)
            } else {
                uploadPrompt
            }
        }
        .navigationTitle("Photo Audit")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadAndAnalyzePhoto() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(subscriptionManager)
        }
    }

    // MARK: - Upload Prompt

    private var uploadPrompt: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                Spacer().frame(height: DesignSystem.Spacing.xl)

                // Hero
                VStack(spacing: DesignSystem.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [DesignSystem.Colors.flameOrange.opacity(0.3), .clear],
                                    center: .center, startRadius: 30, endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("AI Photo Audit")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Upload a dating profile photo and get an\ninstant AI score with improvement tips")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // What we analyze
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("What We Analyze")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    auditCategoryPreview(icon: "sun.max.fill", name: "Lighting", desc: "Natural vs artificial, exposure, shadows")
                    auditCategoryPreview(icon: "rectangle.dashed", name: "Composition", desc: "Framing, rule of thirds, crop quality")
                    auditCategoryPreview(icon: "face.smiling", name: "Expression", desc: "Smile quality, eye contact, approachability")
                    auditCategoryPreview(icon: "photo.fill", name: "Background", desc: "Clutter, distractions, setting quality")
                    auditCategoryPreview(icon: "tshirt.fill", name: "Outfit", desc: "Style, fit, color coordination")
                    auditCategoryPreview(icon: "figure.stand", name: "Body Language", desc: "Posture, confidence signals, openness")
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                // Upload CTA
                PhotosPicker(
                    selection: $viewModel.photosPickerItem,
                    matching: .images
                ) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(DesignSystem.Typography.button)
                        Text("Upload Photo to Audit")
                            .font(DesignSystem.Typography.button)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(DesignSystem.Colors.flameOrange)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                Text("Free for all users - no account required")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer().frame(height: DesignSystem.Spacing.xxl)
            }
        }
    }

    private func auditCategoryPreview(icon: String, name: String, desc: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.flameOrange.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(desc)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    // MARK: - Analyzing Overlay

    private var analyzingOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Animated scanning effect
            ZStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                        .overlay(
                            scanLineOverlay
                        )
                }
            }

            VStack(spacing: DesignSystem.Spacing.small) {
                Text(viewModel.analysisStageText)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .animation(.easeInOut, value: viewModel.analysisStageText)

                ProgressView(value: viewModel.analysisProgress)
                    .tint(DesignSystem.Colors.flameOrange)
                    .scaleEffect(y: 2)
                    .padding(.horizontal, DesignSystem.Spacing.xl)

                Text("\(Int(viewModel.analysisProgress * 100))%")
                    .font(DesignSystem.Typography.scoreDisplay)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .contentTransition(.numericText())
            }

            Spacer()
        }
    }

    private var scanLineOverlay: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DesignSystem.Colors.flameOrange.opacity(0.4), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: 30)
                .offset(y: viewModel.analysisProgress * geo.size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    // MARK: - Audit Results

    private func auditResultsView(_ result: PhotoAuditResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Photo preview with score overlay
                photoWithScore(result)

                // Overall verdict
                verdictBanner(result)

                // Category breakdowns
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Detailed Analysis")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    ForEach(result.categories) { category in
                        categoryScoreRow(category)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                // Improvement tips
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("How to Improve")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    ForEach(Array(result.improvements.enumerated()), id: \.offset) { index, tip in
                        tipRow(number: index + 1, text: tip)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                // CTA: Generate better photos
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("Want photos that score 9+?")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    GRButton(title: "Generate AI Photos", icon: "wand.and.stars") {
                        DesignSystem.Haptics.medium()
                    }

                    GRButton(title: "Audit Another Photo", icon: "arrow.counterclockwise", style: .outline) {
                        viewModel.reset()
                        DesignSystem.Haptics.light()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
    }

    private func photoWithScore(_ result: PhotoAuditResult) -> some View {
        ZStack(alignment: .bottom) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            }

            // Score overlay
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overall Score")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(String(format: "%.1f", result.overallScore))
                        .font(DesignSystem.Typography.scoreLarge)
                        .foregroundStyle(.white)
                    Text("/10")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()

                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: result.overallScore / 10)
                        .stroke(scoreColor(result.overallScore), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text(scoreEmoji(result.overallScore))
                        .font(.system(size: 28))
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: DesignSystem.CornerRadius.card,
                    bottomTrailingRadius: DesignSystem.CornerRadius.card, topTrailingRadius: 0
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func verdictBanner(_ result: PhotoAuditResult) -> some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Text(scoreEmoji(result.overallScore))
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.verdict)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(result.verdictDetail)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func categoryScoreRow(_ category: AuditCategory) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .frame(width: 28, height: 28)
                    .background(DesignSystem.Colors.flameOrange.opacity(0.1))
                    .clipShape(Circle())

                Text(category.name)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: "%.1f", category.score))
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(scoreColor(category.score))
            }

            // Score bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor(category.score))
                        .frame(width: geo.size.width * category.score / 10, height: 8)
                }
            }
            .frame(height: 8)

            Text(category.feedback)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    private func tipRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
            Text("\(number)")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(DesignSystem.Colors.flameOrange)
                .clipShape(Circle())

            Text(text)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        if score >= 8 { return DesignSystem.Colors.success }
        if score >= 6 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    private func scoreEmoji(_ score: Double) -> String {
        if score >= 9 { return "🔥" }
        if score >= 8 { return "😍" }
        if score >= 7 { return "👍" }
        if score >= 5 { return "🤔" }
        return "😬"
    }
}

#Preview {
    NavigationStack {
        PhotoAuditView()
    }
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}
