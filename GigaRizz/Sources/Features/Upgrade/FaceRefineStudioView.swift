import PhotosUI
import SwiftUI
import UIKit

// MARK: - FaceRefineStudioView
//
// The generative companion to FaceEnhancementView. Where FaceEnhancement does
// subtle local CIFilter work (skin smooth, teeth whiten, eye brighten), this
// surface drives the backend image-edit models (GPT Image 2, Nano Banana 2)
// for structural refinements: smile enhance, smile add, jaw refine, nose
// refine, lip enhance, eye color swap, AI portrait.
//
// Every result auto-runs:
//   1. IdentityMatchService — similarity vs the source photo.
//   2. FaceDriftDetector — drift signal list.
//   3. IdentityMatchCertificateService — signed JSON receipt.
//
// Facetune AI Studio + FaceApp transformations + GigaRizz's identity contract
// in one screen. Naturalness intensity from Settings gates the prompt
// wrapping on the backend; FaceCheck Pre-Flight gates the result.

struct FaceRefineStudioView: View {
    let sourceImage: UIImage
    let photoId: UUID

    @State private var refineOptions: [RefineOption] = RefineOption.all
    @State private var selected: RefineOption?
    @State private var resultImage: UIImage?
    @State private var matchResult: IdentityMatchService.MatchResult?
    @State private var driftReport: FaceDriftDetector.Report = .empty
    @State private var certificate: IdentityMatchCertificate?
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var showPreflight = false
    @State private var showReceipt = false
    @State private var eyeColor: EyeColor = .blue

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                photoPair
                naturalnessChip
                if let selected, selected.style == .eyeColorSwap {
                    eyeColorPicker
                }
                refineGrid
                actionsBar
                if let error = generationError {
                    errorBanner(error)
                }
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Face Refine")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPreflight) {
            if let resultImage {
                NavigationStack {
                    FaceCheckPreflightView(
                        candidate: resultImage,
                        reference: sourceImage,
                        onRegenerate: { regenerateAtLowerIntensity() }
                    )
                }
            }
        }
        .sheet(isPresented: $showReceipt) {
            if let certificate {
                IdentityMatchCertificateSheet(certificate: certificate)
            }
        }
    }

    // MARK: - Photo Pair

    private var photoPair: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            photoTile(image: sourceImage, label: "Original", badge: nil)
            photoTile(
                image: resultImage,
                label: resultImage == nil ? (isGenerating ? "Refining…" : "Tap a refinement") : "After",
                badge: matchResult?.band.shortLabel
            )
        }
    }

    private func photoTile(image: UIImage?, label: String, badge: String?) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            if isGenerating {
                                ProgressView().tint(DesignSystem.Colors.flameOrange)
                            } else {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                }
                if let badge {
                    Text(badge)
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(DesignSystem.Spacing.small)
                }
            }
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Naturalness chip

    private var naturalnessChip: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(DesignSystem.Colors.success)
            Text("Naturalness: \(NaturalnessSettings.currentLevel.displayName) (\(NaturalnessSettings.intensity)/100)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text("Edit in Settings")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
        }
        .padding(.horizontal, DesignSystem.Spacing.small)
    }

    // MARK: - Eye color picker

    private var eyeColorPicker: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Target eye color")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(EyeColor.allCases, id: \.self) { color in
                    Button {
                        eyeColor = color
                    } label: {
                        Text(color.displayName)
                            .font(DesignSystem.Typography.caption)
                            .padding(.horizontal, DesignSystem.Spacing.small)
                            .padding(.vertical, 6)
                            .background(eyeColor == color ? DesignSystem.Colors.flameOrange.opacity(0.30) : DesignSystem.Colors.surfaceSecondary)
                            .clipShape(Capsule())
                            .foregroundStyle(eyeColor == color ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Grid

    private var refineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.small) {
            ForEach(refineOptions) { option in
                Button {
                    selected = option
                    Task { await generate(option) }
                } label: {
                    refineCard(option, isActive: selected == option)
                }
                .disabled(isGenerating)
            }
        }
    }

    private func refineCard(_ option: RefineOption, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: option.iconName)
                    .foregroundStyle(isActive ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                Text(option.title)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            Text(option.subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(2)
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? DesignSystem.Colors.flameOrange.opacity(0.10) : DesignSystem.Colors.surfaceSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isActive ? DesignSystem.Colors.flameOrange : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionsBar: some View {
        if resultImage != nil {
            HStack(spacing: DesignSystem.Spacing.small) {
                Button { showPreflight = true } label: {
                    Label("Face Check", systemImage: "checkmark.shield.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.success)

                Button { showReceipt = true } label: {
                    Label("Receipt", systemImage: "doc.text.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.Colors.flameOrange)
                .disabled(certificate == nil)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.Colors.error)
            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.error.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Generation

    private func generate(_ option: RefineOption) async {
        isGenerating = true
        generationError = nil
        defer { isGenerating = false }

        do {
            // Upload source so identity-aware providers can use it.
            let sourceUrl = await PhotoUploadService.shared.tryUpload(sourceImage, purpose: "source")
            let job = try await GigaRizzAPIClient.shared.submitGeneration(
                style: option.style.rawValue,
                prompt: option.style == .eyeColorSwap ? eyeColorPromptOverride() : nil,
                sourceImageUrl: sourceUrl?.absoluteString,
                sourceImageUrls: sourceUrl.map { [$0.absoluteString] }
            )

            // Poll for completion (max 2 min, 1s interval).
            let result = try await pollUntilComplete(jobId: job.jobId)
            if let url = URL(string: result), let data = try? await URLSession.shared.data(from: url).0,
               let image = UIImage(data: data) {
                resultImage = image
                await postProcess(image, tools: [option.style.rawValue])
            } else {
                generationError = "Could not load the refined photo."
            }
        } catch {
            generationError = "Refine failed: \(error.localizedDescription)"
        }
    }

    private func pollUntilComplete(jobId: String) async throws -> String {
        for _ in 0..<120 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: jobId)
            if status.status == "completed", let first = status.resultUrls.first {
                return first
            }
            if status.status == "failed" {
                throw NSError(domain: "FaceRefine", code: -1, userInfo: [NSLocalizedDescriptionKey: status.error ?? "Generation failed."])
            }
        }
        throw NSError(domain: "FaceRefine", code: -2, userInfo: [NSLocalizedDescriptionKey: "Refine timed out."])
    }

    private func eyeColorPromptOverride() -> String {
        "Change ONLY the iris color to \(eyeColor.displayName). Keep eye shape, eyelashes, and natural reflections."
    }

    private func regenerateAtLowerIntensity() {
        // Drop one band down; if already conservative, stay there but re-roll.
        let current = NaturalnessSettings.intensity
        let lower = max(20, current - 25)
        NaturalnessSettings.setIntensity(lower)
        if let selected {
            Task { await generate(selected) }
        }
        showPreflight = false
    }

    private func postProcess(_ image: UIImage, tools: [String]) async {
        async let match = (try? await IdentityMatchService.match(candidate: image, against: sourceImage))
        async let drift = FaceDriftDetector.detect(candidate: image, reference: sourceImage)
        let (m, d) = await (match, drift)
        matchResult = m
        driftReport = d

        certificate = IdentityMatchCertificateService.issue(
            kitId: nil,
            photoId: photoId,
            toolsApplied: tools,
            identityScore: m?.similarity ?? 0,
            identityBand: m?.band ?? .borderline,
            driftSignals: d.signals
        )
    }
}

// MARK: - RefineOption

private struct RefineOption: Identifiable, Equatable {
    let id: String
    let style: BackendStyle
    let title: String
    let subtitle: String
    let iconName: String

    static let all: [RefineOption] = [
        .init(id: "smile_enhance", style: .smileEnhance, title: "Enhance smile", subtitle: "Subtle lift on the smile you already have", iconName: "face.smiling"),
        .init(id: "add_smile", style: .addSmile, title: "Add smile", subtitle: "Warm closed-lip smile + eye crinkle", iconName: "face.smiling.inverse"),
        .init(id: "jaw_refine", style: .jawRefine, title: "Refine jaw", subtitle: "Small natural definition lift", iconName: "person.crop.square"),
        .init(id: "nose_refine", style: .noseRefine, title: "Refine nose", subtitle: "Subtle straightening, keeps your profile", iconName: "nose"),
        .init(id: "lip_enhance", style: .lipEnhance, title: "Enhance lips", subtitle: "Fuller natural look, no over-plump", iconName: "mouth.fill"),
        .init(id: "eye_color_swap", style: .eyeColorSwap, title: "Change eye color", subtitle: "Pick target shade", iconName: "eye.fill"),
        .init(id: "ai_portrait", style: .aiPortrait, title: "Editorial portrait", subtitle: "Magazine-style cinematic AI", iconName: "camera.viewfinder")
    ]
}

private enum BackendStyle: String {
    case smileEnhance = "smile_enhance"
    case addSmile = "add_smile"
    case jawRefine = "jaw_refine"
    case noseRefine = "nose_refine"
    case lipEnhance = "lip_enhance"
    case eyeColorSwap = "eye_color_swap"
    case aiPortrait = "ai_portrait"
}

private enum EyeColor: String, CaseIterable {
    case blue, green, hazel, brown, gray

    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .hazel: return "Hazel"
        case .brown: return "Brown"
        case .gray: return "Gray"
        }
    }
}

// MARK: - Receipt Sheet

struct IdentityMatchCertificateSheet: View {
    let certificate: IdentityMatchCertificate

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    header
                    metricBlock
                    toolsBlock
                    driftBlock
                    signatureBlock
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Identity Match Certificate")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("Every edit GigaRizz makes is recorded. Verify what changed.")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var metricBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Identity Match", value: "\(Int(certificate.identityMatchScore * 100))% (\(certificate.identityMatchBand))")
            row("Naturalness", value: "\(certificate.naturalnessLevel.capitalized) — \(certificate.naturalnessIntensity)/100")
            row("Threshold", value: "\(Int(certificate.identityMatchThreshold * 100))%")
            row("Issued", value: certificate.issuedAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    @ViewBuilder
    private var toolsBlock: some View {
        if !certificate.toolsApplied.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tools applied")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(certificate.toolsApplied, id: \.self) { tool in
                    Label(tool.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    @ViewBuilder
    private var driftBlock: some View {
        if !certificate.driftSignals.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Drift signals")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(certificate.driftSignals, id: \.self) { signal in
                    Label(signal.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    private var signatureBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signature")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(certificate.signature)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .textSelection(.enabled)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}
