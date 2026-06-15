import PhotosUI
import SwiftUI
import UIKit

// MARK: - Magic Studio (V5 flagship)
//
// One natural-language request → a transparent, identity-locked plan of complex
// operations → one generation. The FaceApp/Facetune killer: those apps make you
// do every edit by hand, one tool at a time, with no identity guardrail. Here
// you describe what you want — scene, outfit, lighting, cleanup, retouch — and
// see exactly what the AI will do before it touches your face.
//
// Pipeline:
//   1. Source = Reference Vault selfie (or pick a photo).
//   2. User types a compound request. MagicEditPlanner parses it live into an
//      ordered, labeled step plan shown as a timeline (the transparency beat).
//   3. Run → upload source → submitGeneration(style, composedPrompt, source)
//      through the same identity-preserving backend (`_wrap_natural` gates the
//      result at the user's naturalness intensity).
//   4. Render results; save with one tap.

struct MagicStudioView: View {
    @StateObject private var vault = ReferenceSelfieVault.shared

    @State private var request: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var resultURLs: [String] = []
    @State private var savedConfirmation = false

    private let examples = [
        "Put me on a rooftop bar at golden hour, change my hoodie to a white linen shirt, and fix the harsh lighting",
        "Coffee shop background, soft natural light, clean up my skin a little, confident soft smile",
        "Remove the person behind me, warm cinematic color grade, navy blazer"
    ]

    private var sourceImage: UIImage? { pickedImage ?? vault.currentSelfie }
    private var plan: MagicEditPlan { MagicEditPlanner.plan(from: request) }
    private var canRun: Bool { sourceImage != nil && !plan.isEmpty && !isRunning }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                header
                sourceSection
                requestSection
                if !plan.isEmpty { planSection }
                if let errorMessage { errorBanner(errorMessage) }
                if !resultURLs.isEmpty { resultsSection }
                runButton
                    .padding(.top, 4)
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.small)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Magic Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run { pickedImage = img }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        V2HeroCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                    Text("Describe it. We do the rest.")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                Text("Ask for everything at once — scene, outfit, lighting, cleanup. Every step stays locked to your real face.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    // MARK: - Source

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader("Your photo", subtitle: "Uses your reference selfie, or pick another.")
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                    if let sourceImage {
                        Image(uiImage: sourceImage)
                            .resizable().scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Image(systemName: "person.crop.square.badge.camera")
                            .font(.system(size: 26))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
                .frame(width: 84, height: 104)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(sourceImage == nil ? "No photo selected" : "Ready")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                            Text(sourceImage == nil ? "Choose photo" : "Change photo")
                        }
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Request

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader("What do you want?", subtitle: "One sentence. Combine as many edits as you like.")
            TextField("", text: $request, axis: .vertical)
                .lineLimit(3...6)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(14)
                .background(DesignSystem.Colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if request.isEmpty {
                        Text("e.g. Put me on a beach at sunset, white linen shirt, fix the lighting…")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 18)
                            .padding(.top, 22)
                            .allowsHitTesting(false)
                    }
                }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(examples, id: \.self) { ex in
                        Button {
                            DesignSystem.Haptics.light()
                            request = ex
                        } label: {
                            Text(exampleChipLabel(ex))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(DesignSystem.Colors.surfaceTertiary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func exampleChipLabel(_ s: String) -> String {
        let first = s.split(separator: ",").first.map(String.init) ?? s
        return "✨ " + first.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Plan timeline

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "The plan",
                subtitle: "\(plan.steps.count) operation\(plan.steps.count == 1 ? "" : "s") · runs in order"
            )
            V2Card {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
                        planRow(step, isLast: index == plan.steps.count - 1)
                    }
                }
            }
        }
    }

    private func planRow(_ step: MagicEditStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(DesignSystem.Colors.flameOrange.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: step.kind.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                if !isLast {
                    Rectangle()
                        .fill(DesignSystem.Colors.divider)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(step.title)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    lockBadge(step.kind.identityImpact)
                }
                Text(step.phrase)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 16)
            Spacer()
        }
    }

    @ViewBuilder
    private func lockBadge(_ impact: MagicEditStep.IdentityImpact) -> some View {
        switch impact {
        case .none:
            label("Face untouched", color: DesignSystem.Colors.success, icon: "lock.fill")
        case .low:
            label("Identity locked", color: DesignSystem.Colors.success, icon: "lock.fill")
        case .medium:
            label("Naturalness gated", color: DesignSystem.Colors.warning, icon: "shield.lefthalf.filled")
        }
    }

    private func label(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(text).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader("Results", subtitle: savedConfirmation ? "Saved to Photos ✓" : "Tap a photo to save it.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(resultURLs, id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            ZStack {
                                Rectangle().fill(DesignSystem.Colors.surfaceSecondary)
                                ProgressView().tint(DesignSystem.Colors.flameOrange)
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(DesignSystem.Colors.success.opacity(0.9))
                                .clipShape(Capsule())
                                .padding(8)
                        }
                        .onTapGesture { saveImage(from: url) }
                    }
                }
            }
            AIDisclosureBadge()
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.Colors.error)
            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Run button

    private var runButton: some View {
        Button {
            DesignSystem.Haptics.medium()
            Task { await run() }
        } label: {
            HStack(spacing: 10) {
                if isRunning {
                    ProgressView().tint(.white)
                    Text("Working your magic…")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Run Magic Edit")
                }
            }
            .font(DesignSystem.Typography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(DesignSystem.Gradients.flameCTA)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.45), radius: 16, x: 0, y: 8)
        }
        .disabled(!canRun)
        .opacity(canRun ? 1 : 0.5)
    }

    // MARK: - Execution

    private func run() async {
        guard let sourceImage else { return }
        isRunning = true
        errorMessage = nil
        resultURLs = []
        savedConfirmation = false
        defer { isRunning = false }

        let currentPlan = plan
        let sourceURL = await PhotoUploadService.shared.tryUpload(sourceImage, purpose: "source")

        do {
            let job = try await GigaRizzAPIClient.shared.submitGeneration(
                style: currentPlan.sceneStyle,
                prompt: currentPlan.composedPrompt,
                model: AIModel.default.id,
                sourceImageUrl: sourceURL?.absoluteString,
                sourceImageUrls: sourceURL.map { [$0.absoluteString] }
            )
            resultURLs = try await pollUntilComplete(jobId: job.jobId)
            if resultURLs.isEmpty {
                errorMessage = "Generation finished but returned no images. Try again."
            }
        } catch {
            errorMessage = "Couldn't finish the edit: \(error.localizedDescription)"
        }
    }

    private func pollUntilComplete(jobId: String) async throws -> [String] {
        for _ in 0..<180 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: jobId)
            if status.status == "completed", !status.resultUrls.isEmpty {
                return status.resultUrls
            }
            if status.status == "failed" {
                throw NSError(domain: "MagicStudio", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: status.error ?? "Generation failed."])
            }
        }
        throw NSError(domain: "MagicStudio", code: -2,
                      userInfo: [NSLocalizedDescriptionKey: "Generation timed out."])
    }

    private func saveImage(from url: URL) {
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            await MainActor.run {
                DesignSystem.Haptics.success()
                savedConfirmation = true
            }
        }
    }
}
