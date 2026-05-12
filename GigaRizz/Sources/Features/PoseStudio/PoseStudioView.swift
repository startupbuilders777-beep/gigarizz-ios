import PhotosUI
import SwiftUI

/// Pose Studio — InstantID-backed "put me in this scene" generator.
///
/// Two flows:
///   1. Type a scene ("out of a helicopter holding a briefcase") → InstantID
///      renders you in that scene with locked identity.
///   2. Upload a reference photo → InstantID locks your face onto the pose
///      and composition of that reference. Closes the "make me look like
///      this exact photo" use case.
struct PoseStudioView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = PoseStudioViewModel()
    @State private var showPaywall = false

    /// Quick-start scenes — taps fill the prompt field. Each one is engineered
    /// to produce a strong dating-photo-worthy result via InstantID.
    private let quickPrompts: [(label: String, prompt: String)] = [
        ("Helicopter", "stepping out of a helicopter on a tarmac, holding a briefcase, sunset light, dramatic cinematic"),
        ("Yacht", "sitting on the deck of a luxury yacht at sunset, ocean horizon, candid casual smile"),
        ("Rooftop", "standing on a city rooftop bar at golden hour, skyline behind, smart casual outfit"),
        ("Mountain", "summit of a mountain at sunrise, hiking gear, victorious pose, dramatic landscape"),
        ("Coffee", "in a cozy specialty coffee shop, warm morning light, holding a latte, candid"),
        ("Concert", "front row at a concert, atmospheric stage lights, crowd blur, joyful expression")
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    header
                    facePhotoSection
                    promptSection
                    if !viewModel.promptText.isEmpty || viewModel.poseReferenceImage != nil { quickStartChips }
                    poseReferenceSection
                    if viewModel.facePhoto != nil && (!viewModel.promptText.isEmpty || viewModel.poseReferenceImage != nil) {
                        applyButton
                    }
                    if viewModel.isProcessing { processingOverlay }
                    if viewModel.resultImage != nil { resultSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Pose Studio")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.facePickerItem) {
            Task { await viewModel.loadFacePhoto() }
        }
        .onChange(of: viewModel.posePickerItem) {
            Task { await viewModel.loadPosePhoto() }
        }
        .alert("Couldn't generate", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var header: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "figure.wave")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Pose Studio")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Any pose, any scene. Your face locked. Powered by InstantID.")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    private var facePhotoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Your Face")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let image = viewModel.facePhoto {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    Button { viewModel.clearFace() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    .padding(DesignSystem.Spacing.small)
                }
            } else {
                PhotosPicker(selection: $viewModel.facePickerItem, matching: .images) {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("Upload a clear face photo")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Front-facing, well-lit, single person")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .strokeBorder(DesignSystem.Colors.flameOrange.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Describe the Scene")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            TextField(
                "out of a helicopter holding a briefcase…",
                text: $viewModel.promptText,
                axis: .vertical
            )
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .lineLimit(2...4)
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
            )
        }
    }

    private var quickStartChips: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Quick Start")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(quickPrompts, id: \.label) { entry in
                        Button {
                            viewModel.promptText = entry.prompt
                            DesignSystem.Haptics.light()
                        } label: {
                            Text(entry.label)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                                .padding(.horizontal, DesignSystem.Spacing.small)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.flameOrange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var poseReferenceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Pose Reference")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("Optional")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            if let image = viewModel.poseReferenceImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    Button { viewModel.clearPose() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    .padding(DesignSystem.Spacing.small)
                }
            } else {
                PhotosPicker(selection: $viewModel.posePickerItem, matching: .images) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 22))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Or copy a pose from a photo")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("We'll lock your face onto its composition")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var applyButton: some View {
        GRButton(title: "Generate", icon: "wand.and.stars", isLoading: viewModel.isProcessing) {
            if subscriptionManager.currentTier == .free {
                showPaywall = true
                DesignSystem.Haptics.warning()
            } else {
                Task { await viewModel.generate() }
                DesignSystem.Haptics.medium()
            }
        }
    }

    private var processingOverlay: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                ProgressView().tint(DesignSystem.Colors.flameOrange).scaleEffect(1.5)
                Text("Putting you in the scene…")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("InstantID is locking your identity")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                ProgressView(value: viewModel.progress).tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Result")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            if let result = viewModel.resultImage {
                Image(uiImage: result)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .cardShadow()

                HStack(spacing: DesignSystem.Spacing.small) {
                    GRButton(title: "Save", icon: "square.and.arrow.down") {
                        viewModel.saveResult()
                        DesignSystem.Haptics.success()
                    }
                    GRButton(title: "Try Another", icon: "arrow.counterclockwise", style: .secondary) {
                        viewModel.resultImage = nil
                        DesignSystem.Haptics.light()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class PoseStudioViewModel: ObservableObject {
    @Published var facePickerItem: PhotosPickerItem?
    @Published var posePickerItem: PhotosPickerItem?
    @Published var facePhoto: UIImage?
    @Published var poseReferenceImage: UIImage?
    @Published var promptText: String = ""
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var errorMessage: String?

    func loadFacePhoto() async {
        guard let item = facePickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            facePhoto = image
        }
    }

    func loadPosePhoto() async {
        guard let item = posePickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            poseReferenceImage = image
        }
    }

    func clearFace() {
        facePhoto = nil
        facePickerItem = nil
    }

    func clearPose() {
        poseReferenceImage = nil
        posePickerItem = nil
    }

    func generate() async {
        guard let face = facePhoto else { return }
        guard !promptText.isEmpty || poseReferenceImage != nil else { return }

        isProcessing = true
        progress = 0.05
        errorMessage = nil
        defer { isProcessing = false }

        switch ServiceMode.current {
        case .mock:
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 90_000_000)
                progress = Double(i) / 10.0
            }
            // Mock returns the face photo so the UI flow can be exercised offline.
            resultImage = face
        case .production:
            guard let faceURL = await PhotoUploadService.shared.tryUpload(face, purpose: "source") else {
                errorMessage = "Couldn't upload your face photo. Check your connection."
                return
            }
            progress = 0.15
            var poseURLString: String?
            if let pose = poseReferenceImage,
               let url = await PhotoUploadService.shared.tryUpload(pose, purpose: "source") {
                poseURLString = url.absoluteString
            }
            progress = 0.25

            // Default prompt when only a pose reference is given.
            let effectivePrompt = promptText.isEmpty
                ? "Photorealistic dating-profile portrait of a person, matching the pose and composition of the reference image"
                : "\(promptText). Photorealistic dating-profile quality, sharp focus, vertical 3:4."

            do {
                let job = try await GigaRizzAPIClient.shared.submitGeneration(
                    style: "custom",
                    prompt: effectivePrompt,
                    model: "instant_id",
                    sourceImageUrl: faceURL.absoluteString,
                    poseImageUrl: poseURLString
                )
                let jobId = job.jobId
                for _ in 0..<60 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: jobId)
                    progress = max(progress, max(status.progress, 0.3))
                    if status.status == "completed", let urlStr = status.resultUrls.first, let url = URL(string: urlStr) {
                        if let image = await Self.download(from: url) {
                            resultImage = image
                            progress = 1.0
                            DesignSystem.Haptics.success()
                            return
                        }
                    } else if status.status == "failed" {
                        errorMessage = status.error ?? "Generation failed"
                        return
                    }
                }
                errorMessage = "Generation timed out"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveResult() {
        guard let result = resultImage else { return }
        UIImageWriteToSavedPhotosAlbum(result, nil, nil, nil)
    }

    private static func download(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300 ~= http.statusCode) {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

#Preview {
    NavigationStack {
        PoseStudioView()
            .environmentObject(SubscriptionManager.shared)
    }
    .preferredColorScheme(.dark)
}
