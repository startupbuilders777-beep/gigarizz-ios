import PhotosUI
import SwiftUI

// MARK: - Hairstyle Option

struct HairstyleOption: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let gradient: [Color]
    /// The hair description appended to the Nano Banana 2 prompt. Detailed enough
    /// that the model produces a recognizable hairstyle without altering identity.
    let hairPhrase: String
}

extension HairstyleOption {
    static let catalog: [HairstyleOption] = [
        HairstyleOption(
            id: "classic_short",
            name: "Classic Short",
            icon: "person.crop.circle",
            gradient: [.brown, .gray],
            hairPhrase: "neat short side-parted haircut, classic groomed dating-profile look, natural color"
        ),
        HairstyleOption(
            id: "long_waves",
            name: "Long Waves",
            icon: "wind",
            gradient: [DesignSystem.Colors.flameOrange, .yellow],
            hairPhrase: "long flowing wavy hair down to shoulders, soft natural waves, warm honey highlights"
        ),
        HairstyleOption(
            id: "bun_updo",
            name: "Polished Bun",
            icon: "circle.dashed",
            gradient: [.purple, .pink],
            hairPhrase: "elegant low bun updo, a few soft face-framing pieces, sophisticated dating look"
        ),
        HairstyleOption(
            id: "fade_modern",
            name: "Modern Fade",
            icon: "scissors",
            gradient: [.gray, .black],
            hairPhrase: "modern mid-fade haircut with textured top, sharp clean lines, well-groomed look"
        ),
        HairstyleOption(
            id: "shoulder_length",
            name: "Shoulder Length",
            icon: "wave.3.right",
            gradient: [.teal, .blue],
            hairPhrase: "shoulder-length hair with subtle layers, glossy finish, natural movement"
        ),
        HairstyleOption(
            id: "pixie_cut",
            name: "Pixie Cut",
            icon: "sparkles",
            gradient: [.pink, .red],
            hairPhrase: "chic pixie cut with textured top, soft bangs, modern photogenic crop"
        )
    ]
}

// MARK: - View

struct HairstylePickerView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = HairstylePickerViewModel()
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    header
                    photoSection
                    if viewModel.selectedPhoto != nil { hairstyleGrid }
                    if viewModel.isProcessing { processingOverlay }
                    if viewModel.resultImage != nil { resultSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Hairstyle Try-On")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
        .alert("Couldn't change hairstyle", isPresented: .init(
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
                Image(systemName: "scissors")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Hairstyle Try-On")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("See yourself with a new look. Identity locked, hair swapped.")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Your Photo")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let image = viewModel.selectedPhoto {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    Button { viewModel.clearPhoto() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    .padding(DesignSystem.Spacing.small)
                }
            } else {
                PhotosPicker(selection: $viewModel.photosPickerItem, matching: .images) {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("Upload a Portrait")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Best with a clear front-facing photo")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
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

    private var hairstyleGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Pick a Hairstyle")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(HairstyleOption.catalog) { hairstyle in
                    Button {
                        Task {
                            if subscriptionManager.currentTier == .free {
                                showPaywall = true
                                DesignSystem.Haptics.warning()
                                return
                            }
                            await viewModel.applyHairstyle(hairstyle)
                        }
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(LinearGradient(colors: hairstyle.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 70)
                                Image(systemName: hairstyle.icon)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            Text(hairstyle.name)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(
                                    viewModel.appliedHairstyleId == hairstyle.id
                                        ? DesignSystem.Colors.flameOrange
                                        : DesignSystem.Colors.textSecondary
                                )
                                .lineLimit(1)
                        }
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
        }
    }

    private var processingOverlay: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                ProgressView().tint(DesignSystem.Colors.flameOrange).scaleEffect(1.5)
                Text("Restyling your hair…")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Nano Banana 2 is locking your face")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                ProgressView(value: viewModel.progress).tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("New Hairstyle")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            if let result = viewModel.resultImage {
                Image(uiImage: result)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .cardShadow()

                HStack(spacing: DesignSystem.Spacing.small) {
                    GRButton(title: "Save", icon: "square.and.arrow.down") {
                        viewModel.saveResult()
                        DesignSystem.Haptics.success()
                    }
                    GRButton(title: "Try Another", icon: "arrow.counterclockwise", style: .secondary) {
                        viewModel.resultImage = nil
                        viewModel.appliedHairstyleId = nil
                        DesignSystem.Haptics.light()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class HairstylePickerViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedPhoto: UIImage?
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var errorMessage: String?
    @Published var appliedHairstyleId: String?

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
            resultImage = nil
            appliedHairstyleId = nil
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        photosPickerItem = nil
        resultImage = nil
        appliedHairstyleId = nil
        progress = 0
    }

    func applyHairstyle(_ hairstyle: HairstyleOption) async {
        guard let original = selectedPhoto else { return }
        isProcessing = true
        progress = 0.05
        errorMessage = nil
        appliedHairstyleId = hairstyle.id

        defer { isProcessing = false }

        switch ServiceMode.current {
        case .mock:
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                progress = Double(i) / 10.0
            }
            resultImage = original
        case .production:
            guard let sourceURL = await PhotoUploadService.shared.tryUpload(original, purpose: "source") else {
                errorMessage = "Couldn't upload your photo. Check your connection."
                return
            }
            progress = 0.25
            do {
                let prompt = "Same person, same face, same expression, same background. Change ONLY the hairstyle to: \(hairstyle.hairPhrase). Photorealistic dating-profile portrait."
                let job = try await GigaRizzAPIClient.shared.submitGeneration(
                    style: "hairstyle_swap",
                    prompt: prompt,
                    model: "nano_banana_2",
                    sourceImageUrl: sourceURL.absoluteString
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
                        errorMessage = status.error ?? "Hairstyle change failed"
                        return
                    }
                }
                errorMessage = "Hairstyle change timed out"
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
        HairstylePickerView()
            .environmentObject(SubscriptionManager.shared)
    }
    .preferredColorScheme(.dark)
}
