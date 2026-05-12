import PhotosUI
import SwiftUI

// MARK: - Outfit Option

struct OutfitOption: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let gradient: [Color]
    /// The wardrobe phrase appended to the Nano Banana 2 prompt. Designed to swap
    /// only the clothing while preserving identity, pose, lighting, and background.
    let wardrobePhrase: String
}

extension OutfitOption {
    static let catalog: [OutfitOption] = [
        OutfitOption(
            id: "cozy_sweater",
            name: "Cozy Sweater",
            icon: "tshirt.fill",
            gradient: [.brown, DesignSystem.Colors.goldAccent],
            wardrobePhrase: "soft cream-colored cable-knit sweater, autumn date-night look"
        ),
        OutfitOption(
            id: "tailored_suit",
            name: "Tailored Suit",
            icon: "person.crop.rectangle",
            gradient: [.gray, .blue],
            wardrobePhrase: "well-fitted charcoal tailored suit with crisp white shirt, no tie, sophisticated dating look"
        ),
        OutfitOption(
            id: "white_tee",
            name: "Crisp White Tee",
            icon: "tshirt",
            gradient: [.white, .gray],
            wardrobePhrase: "clean fitted white t-shirt with minimal styling, classic photogenic look"
        ),
        OutfitOption(
            id: "leather_jacket",
            name: "Leather Jacket",
            icon: "jacket",
            gradient: [.black, .red],
            wardrobePhrase: "fitted black leather biker jacket over a plain dark t-shirt, confident edge"
        ),
        OutfitOption(
            id: "hoodie_athleisure",
            name: "Athleisure",
            icon: "figure.run",
            gradient: [.green, .teal],
            wardrobePhrase: "premium grey athletic hoodie and joggers, fit-and-active dating-app look"
        ),
        OutfitOption(
            id: "linen_shirt",
            name: "Linen Beach",
            icon: "sun.max.fill",
            gradient: [.cyan, .yellow],
            wardrobePhrase: "open-collar linen shirt in warm cream, sun-kissed vacation vibe"
        )
    ]
}

// MARK: - View

struct AIOutfitChangerView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = AIOutfitChangerViewModel()
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    header
                    photoSection
                    if viewModel.selectedPhoto != nil { outfitGrid }
                    if viewModel.isProcessing { processingOverlay }
                    if viewModel.resultImage != nil { resultSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Outfit Studio")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
        .alert("Couldn't change outfit", isPresented: .init(
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
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Outfit Studio")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Swap your fit. Keep your face. Powered by Nano Banana 2.")
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
                        Text("Best results with a clear waist-up shot")
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

    private var outfitGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Pick an Outfit")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(OutfitOption.catalog) { outfit in
                    Button {
                        Task {
                            if subscriptionManager.currentTier == .free {
                                showPaywall = true
                                DesignSystem.Haptics.warning()
                                return
                            }
                            await viewModel.applyOutfit(outfit)
                        }
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(LinearGradient(colors: outfit.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 70)
                                Image(systemName: outfit.icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            Text(outfit.name)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(
                                    viewModel.appliedOutfitId == outfit.id
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
                Text("Swapping your outfit…")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Nano Banana 2 is preserving your face and pose")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                ProgressView(value: viewModel.progress).tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("New Outfit")
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
                        viewModel.appliedOutfitId = nil
                        DesignSystem.Haptics.light()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class AIOutfitChangerViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedPhoto: UIImage?
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var errorMessage: String?
    @Published var appliedOutfitId: String?

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
            resultImage = nil
            appliedOutfitId = nil
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        photosPickerItem = nil
        resultImage = nil
        appliedOutfitId = nil
        progress = 0
    }

    func applyOutfit(_ outfit: OutfitOption) async {
        guard let original = selectedPhoto else { return }
        isProcessing = true
        progress = 0.05
        errorMessage = nil
        appliedOutfitId = outfit.id

        defer { isProcessing = false }

        switch ServiceMode.current {
        case .mock:
            // Animate progress so the UI feels alive in dev builds.
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                progress = Double(i) / 10.0
            }
            resultImage = original
        case .production:
            // Upload + invoke Nano Banana 2 with an outfit-specific prompt.
            guard let sourceURL = await PhotoUploadService.shared.tryUpload(original, purpose: "source") else {
                errorMessage = "Couldn't upload your photo. Check your connection."
                return
            }
            progress = 0.25
            do {
                let prompt = "Same person, same face, same pose, same background. Change ONLY the clothing to: \(outfit.wardrobePhrase). Photorealistic dating-profile portrait."
                let job = try await GigaRizzAPIClient.shared.submitGeneration(
                    style: "outfit_swap",
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
                        errorMessage = status.error ?? "Outfit change failed"
                        return
                    }
                }
                errorMessage = "Outfit change timed out"
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
        AIOutfitChangerView()
            .environmentObject(SubscriptionManager.shared)
    }
    .preferredColorScheme(.dark)
}
