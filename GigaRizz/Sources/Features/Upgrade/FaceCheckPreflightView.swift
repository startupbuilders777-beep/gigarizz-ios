import SwiftUI
import UIKit

// MARK: - FaceCheckPreflightView
//
// Hero feature of V3 Sprint 1. Predicts whether a generated or edited photo
// will pass Hinge Selfie Verification + Tinder Face Check before the user
// uploads it. Powered by IdentityMatchService (similarity score) and
// FaceDriftDetector (named drift signals).
//
// This is the feature FaceApp and Facetune cannot ship without cannibalizing
// their power-user behavior — their products incentivize the exact edits
// that fail verification.

struct FaceCheckPreflightView: View {
    let candidate: UIImage
    let reference: UIImage
    let onRegenerate: (() -> Void)?

    @State private var matchResult: IdentityMatchService.MatchResult?
    @State private var driftReport: FaceDriftDetector.Report = .empty
    @State private var isAnalyzing = true
    @State private var analysisError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                photoPanel
                verdictPanel
                signalsPanel
                actionsPanel
                disclaimerPanel
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Face Check Pre-Flight")
        .navigationBarTitleDisplayMode(.inline)
        .task { await analyze() }
    }

    // MARK: - Photos

    private var photoPanel: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                photoTile(image: reference, label: "Your reference")
                photoTile(image: candidate, label: "This photo")
            }
        }
    }

    private func photoTile(image: UIImage, label: String) -> some View {
        VStack(spacing: 6) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Verdict

    private var verdictPanel: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: verdictIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(verdictColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verdictHeadline)
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    if let result = matchResult {
                        Text("Identity similarity \(Int(result.similarity * 100))% • threshold \(Int(NaturalnessSettings.currentLevel.identityMatchThreshold * 100))%")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } else if isAnalyzing {
                        Text("Analyzing your face…")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } else if let analysisError {
                        Text(analysisError)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.warning)
                    }
                }
                Spacer()
            }

            Text(verdictExplanation)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(verdictColor.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).stroke(verdictColor.opacity(0.30), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var verdictHeadline: String {
        guard !isAnalyzing else { return "Checking…" }
        switch overallVerdict {
        case .pass: return "Predicted to pass"
        case .borderline: return "Borderline — may pass"
        case .fail: return "Predicted to fail"
        }
    }

    private var verdictExplanation: String {
        switch overallVerdict {
        case .pass:
            return "Your face still reads as you. Both Hinge Selfie Verification and Tinder Face Check should accept this photo."
        case .borderline:
            return "Some drift detected. The photo may pass verification, but a stricter app could reject it. Lower the naturalness intensity or apply fewer edits before uploading."
        case .fail:
            return "Significant drift from your reference selfie. Most dating apps will fail Face Check on this photo. Regenerate at a lower naturalness intensity or pick a different result."
        }
    }

    private var verdictIcon: String {
        switch overallVerdict {
        case .pass: return "checkmark.seal.fill"
        case .borderline: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.octagon.fill"
        }
    }

    private var verdictColor: Color {
        switch overallVerdict {
        case .pass: return DesignSystem.Colors.success
        case .borderline: return DesignSystem.Colors.warning
        case .fail: return DesignSystem.Colors.error
        }
    }

    private enum Verdict { case pass, borderline, fail }

    private var overallVerdict: Verdict {
        guard let result = matchResult else { return .borderline }
        if result.band == .rejected { return .fail }
        if result.band == .borderline { return .borderline }
        // Drift signals can downgrade a pass to borderline / fail.
        let critical: Set<FaceDriftDetector.Signal> = [.oversmoothing, .eyeWidening, .jawNarrowing]
        let criticalHits = driftReport.signals.filter { critical.contains($0) }
        if criticalHits.count >= 2 { return .fail }
        if !criticalHits.isEmpty { return .borderline }
        if !driftReport.signals.isEmpty { return .borderline }
        return .pass
    }

    // MARK: - Signals

    @ViewBuilder
    private var signalsPanel: some View {
        if !driftReport.signals.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Detected drift")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(driftReport.signals, id: \.id) { signal in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                        Image(systemName: signal.iconName)
                            .foregroundStyle(DesignSystem.Colors.warning)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(signal.displayName)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(signal.explanation)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionsPanel: some View {
        if let onRegenerate, overallVerdict != .pass {
            Button {
                onRegenerate()
            } label: {
                Label("Regenerate at lower intensity", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.flameOrange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            }
            .accessibilityHint("Regenerates the photo at a more conservative naturalness intensity")
        }
    }

    // MARK: - Disclaimer

    private var disclaimerPanel: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "info.circle")
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("Prediction only — final verification still depends on the dating app's own model. We tune our drift signals against public Face Check failure patterns.")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Logic

    private func analyze() async {
        isAnalyzing = true
        analysisError = nil
        async let match = runMatch()
        async let drift = runDrift()
        let (m, d) = await (match, drift)
        if let m {
            matchResult = m
        } else {
            analysisError = "Couldn't read a clear face from one of the photos."
        }
        driftReport = d
        isAnalyzing = false
    }

    private func runMatch() async -> IdentityMatchService.MatchResult? {
        do {
            return try await IdentityMatchService.match(candidate: candidate, against: reference)
        } catch {
            return nil
        }
    }

    private func runDrift() async -> FaceDriftDetector.Report {
        await FaceDriftDetector.detect(candidate: candidate, reference: reference)
    }
}
