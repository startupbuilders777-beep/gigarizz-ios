import PhotosUI
import SwiftUI
import UIKit

// MARK: - Drop Me In (V5 — user-supplied environment)
//
// "Replace yourself in an environment you choose." The Brief Studio puts the
// user in OUR 27 curated scenes; this puts them in ANY scene they hand us — a
// bar they like, a friend's travel photo, a place they wish they'd been.
// Unbounded environments vs a fixed preset library (beats ReGen too), with the
// same identity lock as everything else.
//
// Pipeline: selfie (identity) + scene photo (environment) → one generation that
// composites the locked subject into the scene, matching its light + angle.

struct SceneSwapView: View {
    @StateObject private var vault = ReferenceSelfieVault.shared

    @State private var selfiePickerItem: PhotosPickerItem?
    @State private var pickedSelfie: UIImage?
    @State private var scenePickerItem: PhotosPickerItem?
    @State private var sceneImage: UIImage?
    @State private var note: String = ""

    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var resultURLs: [String] = []
    @State private var savedConfirmation = false

    private var selfieImage: UIImage? { pickedSelfie ?? vault.currentSelfie }
    private var canRun: Bool { selfieImage != nil && sceneImage != nil && !isRunning }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                header
                photoPairSection
                noteSection
                if let errorMessage { errorBanner(errorMessage) }
                if !resultURLs.isEmpty { resultsSection }
                runButton.padding(.top, 4)
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.small)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Drop Me In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: selfiePickerItem) { _, item in load(item) { pickedSelfie = $0 } }
        .onChange(of: scenePickerItem) { _, item in load(item) { sceneImage = $0 } }
    }

    private func load(_ item: PhotosPickerItem?, into set: @escaping (UIImage) -> Void) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await MainActor.run { set(img) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        V2HeroCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "person.and.background.dotted")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                    Text("Put yourself anywhere")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                Text("Pick a photo of a place — any place — and we'll drop you into it, lit to match, still looking exactly like you.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    // MARK: - Photo pair

    private var photoPairSection: some View {
        HStack(spacing: 12) {
            photoSlot(
                title: "You",
                subtitle: selfieImage == nil ? "Your selfie" : "Ready",
                image: selfieImage,
                placeholderIcon: "person.crop.square",
                picker: $selfiePickerItem
            )
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            photoSlot(
                title: "The place",
                subtitle: sceneImage == nil ? "Any scene" : "Ready",
                image: sceneImage,
                placeholderIcon: "photo.on.rectangle.angled",
                picker: $scenePickerItem
            )
        }
    }

    private func photoSlot(
        title: String,
        subtitle: String,
        image: UIImage?,
        placeholderIcon: String,
        picker: Binding<PhotosPickerItem?>
    ) -> some View {
        PhotosPicker(selection: picker, matching: .images) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                    if let image {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: placeholderIcon)
                                .font(.system(size: 26))
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(image == nil ? DesignSystem.Colors.divider : DesignSystem.Colors.flameOrange.opacity(0.5), lineWidth: 1.5)
                )
                VStack(spacing: 1) {
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(image == nil ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.success)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            V2SectionHeader("Anything to add?", subtitle: "Optional — pose, outfit, where in the scene.")
            TextField("", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(14)
                .background(DesignSystem.Colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("e.g. standing by the window, navy jacket, looking off camera")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 18).padding(.top, 22)
                            .allowsHitTesting(false)
                    }
                }
        }
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

    // MARK: - Run

    private var runButton: some View {
        Button {
            DesignSystem.Haptics.medium()
            Task { await run() }
        } label: {
            HStack(spacing: 10) {
                if isRunning {
                    ProgressView().tint(.white)
                    Text("Dropping you in…")
                } else {
                    Image(systemName: "person.and.background.dotted")
                    Text("Drop Me In")
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

    private func run() async {
        guard let selfieImage, let sceneImage else { return }
        isRunning = true
        errorMessage = nil
        resultURLs = []
        savedConfirmation = false
        defer { isRunning = false }

        async let selfieUpload = PhotoUploadService.shared.tryUpload(selfieImage, purpose: "source")
        async let sceneUpload = PhotoUploadService.shared.tryUpload(sceneImage, purpose: "scene")
        let (selfieURL, sceneURL) = await (selfieUpload, sceneUpload)

        guard let selfieURL else {
            errorMessage = "Couldn't upload your selfie. Check your connection and try again."
            return
        }

        let extra = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = """
        Place the exact person from the first reference image into the environment \
        shown in the second image. Identical face, identity, and bone structure — do \
        not alter the face. Match the scene's lighting, color, perspective, and depth \
        so the person looks naturally photographed there. Photorealistic.\
        \(extra.isEmpty ? "" : " \(extra)")
        """

        let sources = [selfieURL.absoluteString] + (sceneURL.map { [$0.absoluteString] } ?? [])
        do {
            // The backend `style` must be a known scene key; the actual target
            // environment rides in the prompt + the uploaded scene image.
            let job = try await GigaRizzAPIClient.shared.submitGeneration(
                style: "scene_coffee_shop",
                prompt: prompt,
                model: AIModel.default.id,
                sourceImageUrl: selfieURL.absoluteString,
                sourceImageUrls: sources,
                poseImageUrl: sceneURL?.absoluteString
            )
            resultURLs = try await pollUntilComplete(jobId: job.jobId)
            if resultURLs.isEmpty {
                errorMessage = "Generation finished but returned no images. Try again."
            }
        } catch {
            errorMessage = "Couldn't finish: \(error.localizedDescription)"
        }
    }

    private func pollUntilComplete(jobId: String) async throws -> [String] {
        for _ in 0..<180 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: jobId)
            if status.status == "completed", !status.resultUrls.isEmpty { return status.resultUrls }
            if status.status == "failed" {
                throw NSError(domain: "SceneSwap", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: status.error ?? "Generation failed."])
            }
        }
        throw NSError(domain: "SceneSwap", code: -2,
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
