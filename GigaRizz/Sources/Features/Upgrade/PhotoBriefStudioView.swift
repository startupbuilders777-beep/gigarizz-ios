import PhotosUI
import SwiftUI
import UIKit

// MARK: - PhotoBriefStudioView (V3 Sprint 2 hero)
//
// Plain-English photo brief + curated scene catalog. The Sprint 2 counter to
// ReGen's preset library: ReGen ships pre-canned poses/environments only, with
// no narrative control. We ship 13 high-impact dating environments (helicopter,
// movie theatre, rooftop bar, Tokyo street, etc.) AND let the user write their
// own brief in plain English.
//
// Pipeline per generation:
//   1. User picks a reference selfie (or uses an already-set Identity Vault).
//   2. User picks a scene (optional) — pre-fills the brief.
//   3. User edits the brief (up to 250 chars).
//   4. Tap Generate → submitGeneration with style=scene_X + prompt=brief.
//      Backend's `_wrap_natural` adds identity-preservation language at the
//      user's chosen naturalness intensity.
//   5. Poll until completion. For each result image:
//      a. Run IdentityMatchService → similarity score + band.
//      b. Run FaceDriftDetector → 6 drift signals.
//      c. Issue IdentityMatchCertificate (HMAC-SHA256 signed receipt).
//   6. Render result grid with per-variant IdentityMatch chip.
//
// Beats ReGen because:
//   - Conversational brief (their hard-coded scene list can't compete).
//   - Identity Match score visible per generated photo (they show no signal).
//   - Edit Receipt per export (they ship none).

struct PhotoBriefStudioView: View {
    @State private var brief: String = ""
    @State private var selectedScene: PhotoScene?
    @State private var pickerItem: PhotosPickerItem?
    @State private var variantCount: Int = 4
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var results: [BriefResult] = []
    @State private var showScenePicker = false
    @State private var detailResult: BriefResult?

    @StateObject private var vault = ReferenceSelfieVault.shared
    @State private var qualityReport: ReferenceSelfieQuality.Report?
    @AppStorage("gigarizz_naturalness_intensity") private var naturalnessIntensity = NaturalnessSettings.Level.conservative.intensityValue

    private var referenceImage: UIImage? { vault.currentSelfie }

    private let kitId: UUID? = nil
    private let briefCharLimit = 250

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                header
                referenceSelfieCard
                qualityBanner
                sceneCard
                briefEditor
                variantPicker
                generateButton
                if let error = generationError {
                    errorBanner(error)
                }
                if !results.isEmpty {
                    resultsGrid
                }
                naturalnessFooter
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Photo Brief Studio")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScenePicker) {
            NavigationStack {
                ScenePickerSheet(selected: selectedScene) { scene in
                    selectedScene = scene
                    if brief.isEmpty || isJustSeed(brief) {
                        brief = scene.briefSeed
                    }
                    showScenePicker = false
                }
            }
        }
        .sheet(item: $detailResult) { result in
            BriefResultDetailSheet(result: result)
        }
        .onChange(of: pickerItem) { _, _ in
            Task { await loadReference() }
        }
        .onChange(of: vault.currentSelfie) { _, _ in
            Task { await refreshQuality() }
        }
        .task { await refreshQuality() }
    }

    @ViewBuilder
    private var qualityBanner: some View {
        if let report = qualityReport, report.verdict != .excellent {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack(spacing: 8) {
                    Image(systemName: report.verdict.iconName)
                        .foregroundStyle(report.verdict == .poor ? DesignSystem.Colors.error : DesignSystem.Colors.warning)
                    Text(report.verdict.displayName)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                ForEach(report.issues) { issue in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: issue.isCritical ? "xmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(issue.isCritical ? DesignSystem.Colors.error : DesignSystem.Colors.warning)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.title)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(issue.advice)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background((report.verdict == .poor ? DesignSystem.Colors.error : DesignSystem.Colors.warning).opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke((report.verdict == .poor ? DesignSystem.Colors.error : DesignSystem.Colors.warning).opacity(0.30), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    private func refreshQuality() async {
        guard let image = vault.currentSelfie else {
            qualityReport = nil
            return
        }
        qualityReport = await ReferenceSelfieQuality.evaluate(image: image)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tell us the photo you want")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("Plain English brief. We generate four drift-checked variants and certify each one looks like you.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var referenceSelfieCard: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                if let referenceImage {
                    Image(uiImage: referenceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "person.crop.square.badge.camera")
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(referenceImage == nil ? "Add a reference selfie" : "Reference selfie loaded")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(referenceImage == nil ? "Used to score Identity Match per variant." : "Tap to swap.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Image(systemName: referenceImage == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var sceneCard: some View {
        Button {
            showScenePicker = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.flameOrange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: selectedScene?.iconName ?? "rectangle.stack.fill")
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedScene?.displayName ?? "Pick a scene")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(selectedScene?.blurb ?? "Helicopter, movie theatre, rooftop, Tokyo street, and 9 more.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }

    private var briefEditor: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Brief")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(brief.count)/\(briefCharLimit)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(brief.count > briefCharLimit ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
            }
            ZStack(alignment: .topLeading) {
                if brief.isEmpty {
                    Text("e.g. Coffee shop, Brooklyn, golden hour, gray hoodie, looking off camera.")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.5))
                        .padding(DesignSystem.Spacing.small)
                }
                TextEditor(text: $brief)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .padding(.horizontal, 4)
                    .onChange(of: brief) { _, newValue in
                        if newValue.count > briefCharLimit {
                            brief = String(newValue.prefix(briefCharLimit))
                        }
                    }
            }
            .padding(DesignSystem.Spacing.small)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    private var variantPicker: some View {
        HStack {
            Text("Variants")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
            HStack(spacing: 6) {
                ForEach([2, 3, 4], id: \.self) { count in
                    Button {
                        variantCount = count
                    } label: {
                        Text("\(count)")
                            .font(DesignSystem.Typography.subheadline)
                            .frame(width: 36, height: 32)
                            .background(variantCount == count ? DesignSystem.Colors.flameOrange.opacity(0.30) : DesignSystem.Colors.surfaceSecondary)
                            .foregroundStyle(variantCount == count ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack {
                if isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(isGenerating ? "Generating…" : "Generate \(variantCount) variant\(variantCount == 1 ? "" : "s")")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.right")
                    .opacity(0.7)
            }
            .padding(DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(canGenerate ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceSecondary)
            .foregroundStyle(canGenerate ? .white : DesignSystem.Colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
        .disabled(!canGenerate || isGenerating)
    }

    private var canGenerate: Bool {
        !brief.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var resultsGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Variants")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(results) { result in
                    Button {
                        detailResult = result
                    } label: {
                        resultTile(result)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func resultTile(_ result: BriefResult) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: result.image)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            VStack(alignment: .leading, spacing: 4) {
                if let band = result.matchResult?.band {
                    Label(band.shortLabel, systemImage: band.iconName)
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(badgeColor(for: band))
                }
                if !result.driftSignals.isEmpty {
                    Label("\(result.driftSignals.count) drift", systemImage: "exclamationmark.triangle.fill")
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
            .padding(DesignSystem.Spacing.small)
        }
    }

    private var naturalnessFooter: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("Naturalness: \(NaturalnessSettings.currentLevel(forIntensity: naturalnessIntensity).displayName) (\(naturalnessIntensity)/100)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            Slider(value: Binding(
                get: { Double(naturalnessIntensity) },
                set: { naturalnessIntensity = Int($0) }
            ), in: 0...100, step: 5)
                .tint(DesignSystem.Colors.flameOrange)
                .accessibilityLabel("Naturalness intensity")
                .accessibilityValue("\(naturalnessIntensity) out of 100")
            Text(NaturalnessSettings.currentLevel(forIntensity: naturalnessIntensity).subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
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

    private func badgeColor(for band: IdentityMatchService.Band) -> Color {
        switch band {
        case .excellent, .acceptable: return DesignSystem.Colors.success
        case .borderline: return DesignSystem.Colors.warning
        case .rejected: return DesignSystem.Colors.error
        }
    }

    // MARK: - Logic

    /// True if the brief equals exactly one of the canned scene seeds — used to
    /// avoid clobbering the user's edits when they pick a different scene.
    private func isJustSeed(_ text: String) -> Bool {
        PhotoScene.catalog.contains { $0.briefSeed == text }
    }

    private func loadReference() async {
        guard let item = pickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            vault.setSelfie(image)
        }
    }

    private func generate() async {
        isGenerating = true
        generationError = nil
        results = []
        defer { isGenerating = false }

        // Upload reference selfie so identity-aware providers (Nano Banana 2,
        // GPT Image 2) can lock the face from it.
        var referenceUrl: URL?
        if let referenceImage {
            referenceUrl = await PhotoUploadService.shared.tryUpload(referenceImage, purpose: "source")
        }

        let style = selectedScene?.backendStyle ?? "scene_coffee_shop"
        let trimmedBrief = brief.trimmingCharacters(in: .whitespacesAndNewlines)
        // Push the user's plain English brief through `custom_prompt` so the
        // backend uses it verbatim — the naturalness wrapper still wraps it.
        let customPrompt = "Same person as the reference photo, same face, same identity. Photorealistic vertical 3:4 dating profile photo. Scene: \(trimmedBrief). Do not alter the face."

        do {
            let job = try await GigaRizzAPIClient.shared.submitGeneration(
                style: style,
                prompt: customPrompt,
                model: AIModel.default.id,
                sourceImageUrl: referenceUrl?.absoluteString,
                sourceImageUrls: referenceUrl.map { [$0.absoluteString] }
            )
            let urls = try await pollUntilComplete(jobId: job.jobId)
            // Limit results to requested variant count (provider may return fewer).
            let trimmedUrls = Array(urls.prefix(variantCount))
            try await loadAndScore(urls: trimmedUrls, tools: [style])
            if results.isEmpty {
                generationError = "Generation completed but returned no images. Try again."
            }
        } catch {
            generationError = "Generation failed: \(error.localizedDescription)"
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
                throw NSError(
                    domain: "PhotoBriefStudio",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: status.error ?? "Generation failed."]
                )
            }
        }
        throw NSError(
            domain: "PhotoBriefStudio",
            code: -2,
            userInfo: [NSLocalizedDescriptionKey: "Generation timed out."]
        )
    }

    private func loadAndScore(urls: [String], tools: [String]) async throws {
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { continue }

            var match: IdentityMatchService.MatchResult?
            var driftReport: FaceDriftDetector.Report = .empty
            if let referenceImage {
                match = try? await IdentityMatchService.match(candidate: image, against: referenceImage)
                driftReport = await FaceDriftDetector.detect(candidate: image, reference: referenceImage)
            }

            let photoId = UUID()
            let cert = IdentityMatchCertificateService.issue(
                kitId: kitId,
                photoId: photoId,
                toolsApplied: tools,
                identityScore: match?.similarity ?? 0,
                identityBand: match?.band ?? .borderline,
                driftSignals: driftReport.signals
            )

            results.append(BriefResult(
                id: photoId,
                image: image,
                matchResult: match,
                driftSignals: driftReport.signals,
                certificate: cert,
                sceneId: selectedScene?.id,
                brief: brief
            ))
        }
    }
}

// MARK: - BriefResult

struct BriefResult: Identifiable {
    let id: UUID
    let image: UIImage
    let matchResult: IdentityMatchService.MatchResult?
    let driftSignals: [FaceDriftDetector.Signal]
    let certificate: IdentityMatchCertificate
    let sceneId: String?
    let brief: String
}

// MARK: - BriefResultDetailSheet

struct BriefResultDetailSheet: View {
    let result: BriefResult

    @State private var showCertificate = false
    @State private var saveStatus: SaveStatus = .idle
    @StateObject private var vault = ReferenceSelfieVault.shared
    @StateObject private var photoLibrary = PhotoLibraryService()
    @Environment(\.dismiss) private var dismiss

    private enum SaveStatus: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    if let reference = vault.currentSelfie {
                        BeforeAfterCompare(
                            before: reference,
                            after: result.image
                        )
                        .frame(maxHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    } else {
                        Image(uiImage: result.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    }

                    metricBlock

                    if !result.driftSignals.isEmpty {
                        driftBlock
                    }

                    actions
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Variant Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCertificate) {
                IdentityMatchCertificateSheet(certificate: result.certificate)
            }
        }
    }

    private var metricBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Identity Match",
                value: result.matchResult.map { "\(Int($0.similarity * 100))% (\($0.band.rawValue))" } ?? "—")
            row("Naturalness",
                value: "\(result.certificate.naturalnessLevel.capitalized) — \(result.certificate.naturalnessIntensity)/100")
            row("Threshold",
                value: "\(Int(result.certificate.identityMatchThreshold * 100))%")
            if let scene = result.sceneId {
                row("Scene", value: scene)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var driftBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drift detected")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            ForEach(result.driftSignals, id: \.rawValue) { signal in
                Label(signal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(DesignSystem.Colors.warning)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var actions: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Button {
                    showCertificate = true
                } label: {
                    Label("Receipt", systemImage: "doc.text.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.Colors.flameOrange)

                ShareLink(item: shareItem, preview: SharePreview("GigaRizz photo", image: Image(uiImage: result.image))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.success)
            }

            Button {
                Task { await saveToPhotos() }
            } label: {
                HStack {
                    Image(systemName: saveButtonIcon)
                    Text(saveButtonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface)
                .foregroundStyle(saveButtonColor)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(saveButtonColor.opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            }
            .disabled(saveStatus == .saving || saveStatus == .saved)
            if case .failed(let message) = saveStatus {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.error)
            }
        }
    }

    private var saveButtonIcon: String {
        switch saveStatus {
        case .idle: return "square.and.arrow.down"
        case .saving: return "ellipsis.circle"
        case .saved: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var saveButtonTitle: String {
        switch saveStatus {
        case .idle: return "Save with receipt to Photos"
        case .saving: return "Saving…"
        case .saved: return "Saved with embedded receipt"
        case .failed: return "Couldn't save — tap to retry"
        }
    }

    private var saveButtonColor: Color {
        switch saveStatus {
        case .idle, .saving: return DesignSystem.Colors.flameOrange
        case .saved: return DesignSystem.Colors.success
        case .failed: return DesignSystem.Colors.error
        }
    }

    private func saveToPhotos() async {
        saveStatus = .saving
        let data = CertificateEmbedding.embed(certificate: result.certificate, into: result.image)
            ?? result.image.jpegData(compressionQuality: 0.92)
        guard let bytes = data else {
            saveStatus = .failed("Couldn't encode photo for export.")
            return
        }
        do {
            _ = try await photoLibrary.saveJPEGData(bytes)
            saveStatus = .saved
        } catch {
            saveStatus = .failed((error as? LocalizedError)?.errorDescription ?? "Save failed.")
        }
    }

    /// Materializes a temp JPEG with the certificate embedded in EXIF so the
    /// receipt travels with the shared photo. Falls back to the raw image when
    /// embedding fails — the share itself shouldn't break over a metadata
    /// error.
    private var shareItem: URL {
        let fallbackURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(result.id.uuidString).jpg")
        if let embedded = CertificateEmbedding.embed(certificate: result.certificate, into: result.image) {
            try? embedded.write(to: fallbackURL, options: .atomic)
        } else if let bare = result.image.jpegData(compressionQuality: 0.92) {
            try? bare.write(to: fallbackURL, options: .atomic)
        }
        return fallbackURL
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
