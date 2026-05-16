import SwiftUI
import UIKit

// MARK: - GlowUpStudioView
//
// The audit-driven photo improver. Single screen, single photo, named issues,
// one tap per fix. Built to beat Facetune's freeform tool palette and FaceApp's
// preset filters in our specific use case: "make this dating profile photo
// better while staying recognizably me."
//
// Pipeline:
//   1. Accept a UIImage (selected photo or generated output).
//   2. Run PhotoQualityAnalyzer to detect lighting / blur / framing issues.
//   3. Score identity match against the user's reference selfie (if available).
//   4. Render a triaged fix list — each fix routes to an existing surface
//      (FaceEnhancement, BackgroundReplacer, ColorGrade, generation re-roll).
//   5. Surface the Identity Match badge so the user trusts the result.
//
// Beats FaceApp/Facetune because:
//   - No freeform tool palette — only fixes that actually help this specific photo.
//   - Naturalness ceiling enforced (Conservative/Standard/Bold band, set in Settings).
//   - Identity Match score visible at the top — they hide drift; we show it.

struct GlowUpStudioView: View {
    let photo: UIImage
    let referenceSelfie: UIImage?

    @State private var detectedIssues: [PhotoQualityIssue] = []
    @State private var matchResult: IdentityMatchService.MatchResult?
    @State private var isAnalyzing = true
    @State private var routingTo: GlowUpRoute?
    @StateObject private var chain = GlowUpChainCoordinator()
    @StateObject private var vault = ReferenceSelfieVault.shared

    /// Reference selfie used for Identity Match scoring. Falls back to the
    /// vault when the caller doesn't pass one — Sprint 3 makes the studio
    /// stop pestering users to pick a reference if they've already set one.
    private var effectiveReference: UIImage? { referenceSelfie ?? vault.currentSelfie }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                hero
                identityBadge
                fixList
                naturalnessFooter
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Glow Up")
        .navigationBarTitleDisplayMode(.inline)
        .task { await analyze() }
        .sheet(item: $routingTo) { route in
            destination(for: route)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .overlay(alignment: .topTrailing) {
                    if let band = matchResult?.band {
                        identityChip(band: band)
                            .padding(DesignSystem.Spacing.small)
                    }
                }

            Text(heroSubtitle)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var heroSubtitle: String {
        if isAnalyzing { return "Analyzing photo…" }
        if detectedIssues.isEmpty {
            return "No issues detected. This photo is ready to upload."
        }
        return "We found \(detectedIssues.count) thing\(detectedIssues.count == 1 ? "" : "s") to fix."
    }

    // MARK: - Identity Match Badge

    @ViewBuilder
    private var identityBadge: some View {
        if let result = matchResult {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: result.band.iconName)
                    .foregroundStyle(badgeColor(for: result.band))
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.band.displayName)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Similarity \(Int(result.similarity * 100))% • Threshold \(Int(currentThreshold * 100))%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        } else if effectiveReference == nil {
            // Coach the user to upload a reference selfie so the badge can light up.
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("Add a reference selfie in Settings to unlock the Identity Match score.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    private func badgeColor(for band: IdentityMatchService.Band) -> Color {
        switch band {
        case .excellent: return DesignSystem.Colors.success
        case .acceptable: return DesignSystem.Colors.success
        case .borderline: return DesignSystem.Colors.warning
        case .rejected: return DesignSystem.Colors.error
        }
    }

    private func identityChip(band: IdentityMatchService.Band) -> some View {
        Label(band.shortLabel, systemImage: band.iconName)
            .font(DesignSystem.Typography.caption)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(badgeColor(for: band))
    }

    // MARK: - Fix list

    private var fixList: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            ForEach(recommendedFixes(), id: \.id) { fix in
                fixRow(fix)
            }
            if !detectedIssues.isEmpty {
                Button {
                    Task { await chain.run(sourceImage: photo, reference: effectiveReference) }
                } label: {
                    HStack {
                        if chain.isRunning {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "wand.and.sparkles")
                        }
                        Text(chain.isRunning ? "Running Glow Up…" : "Apply Glow Up Chain")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.flameOrange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }
                .disabled(chain.isRunning)
                .accessibilityLabel("Run the audit-driven Glow Up chain")
            }
            if !chain.stepResults.isEmpty {
                chainResultsPanel
            }
        }
    }

    @ViewBuilder
    private var chainResultsPanel: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Glow Up steps")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            ForEach(chain.stepResults) { step in
                HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                    Image(systemName: step.didRollback ? "arrow.uturn.backward" : "checkmark.circle.fill")
                        .foregroundStyle(step.didRollback ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.kind.displayName)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Identity \(Int(step.identityScore * 100))% (\(step.identityBand.rawValue))\(step.didRollback ? " — rolled back" : "")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            if let finalImage = chain.finalImage {
                Image(uiImage: finalImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private func fixRow(_ fix: GlowUpFix) -> some View {
        Button {
            routingTo = fix.route
        } label: {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                Image(systemName: fix.iconName)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .frame(width: 32, height: 32)
                    .background(DesignSystem.Colors.flameOrange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))

                VStack(alignment: .leading, spacing: 4) {
                    Text(fix.title)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(fix.explanation)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    // MARK: - Naturalness Footer

    private var naturalnessFooter: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(DesignSystem.Colors.success)
            Text("Naturalness: \(NaturalnessSettings.currentLevel.displayName)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text("Edit in Settings → Trust & Privacy")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
        }
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Logic

    private var currentThreshold: Double { NaturalnessSettings.currentLevel.identityMatchThreshold }

    private func recommendedFixes() -> [GlowUpFix] {
        if isAnalyzing { return [] }
        if detectedIssues.isEmpty {
            return [GlowUpFix(
                id: "polish",
                title: "Polish (optional)",
                explanation: "No issues found — try the Face Enhance Studio for subtle skin, eye, and teeth refinement.",
                iconName: "sparkles",
                route: .faceEnhance
            )]
        }

        return detectedIssues.map { issue in
            switch issue {
            case .tooDark:
                return GlowUpFix(
                    id: "lighting",
                    title: "Fix lighting",
                    explanation: "Photo reads too dark for Hinge/Tinder. Color Grade lifts shadows without crushing highlights.",
                    iconName: "sun.max.fill",
                    route: .colorGrade
                )
            case .poorLighting:
                return GlowUpFix(
                    id: "lighting",
                    title: "Even out lighting",
                    explanation: "Highlights are blown out — Color Grade re-balances exposure for a flattering tone.",
                    iconName: "circle.lefthalf.filled",
                    route: .colorGrade
                )
            case .blurry, .motionBlur:
                return GlowUpFix(
                    id: "sharpness",
                    title: "Restore sharpness",
                    explanation: "Photo is soft. Face Restore upscales the face with CodeFormer — anti-plastic, identity-preserving.",
                    iconName: "wand.and.rays",
                    route: .faceEnhance
                )
            case .faceTooSmall:
                return GlowUpFix(
                    id: "framing",
                    title: "Fix framing",
                    explanation: "Your face is too small in this frame. Crop tighter or regenerate this slot with a better composition.",
                    iconName: "crop.rotate",
                    route: .reroll
                )
            }
        }
    }

    private func analyze() async {
        isAnalyzing = true
        let issues = await PhotoQualityAnalyzer.analyze(image: photo)
        detectedIssues = issues

        if let reference = effectiveReference {
            do {
                matchResult = try await IdentityMatchService.match(candidate: photo, against: reference)
            } catch {
                matchResult = nil
            }
        }
        isAnalyzing = false
    }

    @ViewBuilder
    private func destination(for route: GlowUpRoute) -> some View {
        switch route {
        case .faceEnhance:
            FaceEnhancementView()
        case .colorGrade:
            // ColorGradeView routes its own internal state machine.
            EmptyDestinationView(title: "Color Grade", message: "Open the Color Grade tool from the Photos tab to apply lighting fixes.")
        case .background:
            EmptyDestinationView(title: "Background", message: "Open Background Replacer from the Photos tab.")
        case .reroll:
            EmptyDestinationView(title: "Re-roll", message: "Re-shoot this slot or generate a new candidate from the Upgrade tab.")
        }
    }
}

// MARK: - Local Types

private struct GlowUpFix {
    let id: String
    let title: String
    let explanation: String
    let iconName: String
    let route: GlowUpRoute
}

private enum GlowUpRoute: Identifiable {
    case faceEnhance
    case colorGrade
    case background
    case reroll

    var id: String {
        switch self {
        case .faceEnhance: return "faceEnhance"
        case .colorGrade: return "colorGrade"
        case .background: return "background"
        case .reroll: return "reroll"
        }
    }
}

private struct EmptyDestinationView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(title)
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
