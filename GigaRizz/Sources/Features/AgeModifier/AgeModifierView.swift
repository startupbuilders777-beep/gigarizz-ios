import PhotosUI
import SwiftUI

// MARK: - Age Option

struct AgeOption: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let gradient: [Color]
    /// The age phrase appended to the Nano Banana 2 prompt. Detailed enough so
    /// the model understands the relative direction without altering identity.
    let agePhrase: String
}

extension AgeOption {
    static let catalog: [AgeOption] = [
        AgeOption(
            id: "younger_10",
            name: "−10 Years",
            icon: "arrow.down.circle.fill",
            gradient: [.green, .teal],
            agePhrase: "make the person look approximately 10 years younger, smoother skin, slightly fuller hair, retain identity"
        ),
        AgeOption(
            id: "younger_5",
            name: "−5 Years",
            icon: "minus.circle.fill",
            gradient: [.cyan, .blue],
            agePhrase: "make the person look approximately 5 years younger, refined skin, retain identity and bone structure"
        ),
        AgeOption(
            id: "current_polish",
            name: "Polished Now",
            icon: "sparkle",
            gradient: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
            agePhrase: "keep the same age but apply subtle dating-photo polish, well-rested look, healthy skin texture, retain identity"
        ),
        AgeOption(
            id: "older_5",
            name: "+5 Years",
            icon: "plus.circle.fill",
            gradient: [.orange, .red],
            agePhrase: "make the person look approximately 5 years older, more mature features, retain identity and warmth"
        ),
        AgeOption(
            id: "older_10",
            name: "+10 Years",
            icon: "arrow.up.circle.fill",
            gradient: [.purple, .indigo],
            agePhrase: "make the person look approximately 10 years older, mature distinguished look, retain identity and bone structure"
        ),
        AgeOption(
            id: "older_20",
            name: "+20 Years",
            icon: "arrow.up.right.circle.fill",
            gradient: [.gray, .black],
            agePhrase: "make the person look approximately 20 years older, distinguished mature look with grey hairs, retain identity"
        )
    ]
}

// MARK: - View

struct AgeModifierView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = AgeModifierViewModel()
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    header
                    photoSection
                    if viewModel.selectedPhoto != nil { ageGrid }
                    if viewModel.isProcessing { processingOverlay }
                    if viewModel.resultImage != nil { resultSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Age Studio")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
        .alert("Couldn't change age", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "hourglass")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Age Studio")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("See yourself across the years. Identity locked.")
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

    private var ageGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Pick an Age")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(AgeOption.catalog) { option in
                    Button {
                        Task {
                            if subscriptionManager.currentTier == .free {
                                showPaywall = true
                                DesignSystem.Haptics.warning()
                                return
                            }
                            await viewModel.applyAge(option)
                        }
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(LinearGradient(colors: option.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 70)
                                Image(systemName: option.icon)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            Text(option.name)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(
                                    viewModel.appliedAgeId == option.id
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
                Text("Time-traveling…")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Nano Banana 2 is preserving your identity")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                ProgressView(value: viewModel.progress).tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("New Age")
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
                        viewModel.appliedAgeId = nil
                        DesignSystem.Haptics.light()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class AgeModifierViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedPhoto: UIImage?
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var errorMessage: String?
    @Published var appliedAgeId: String?

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
            resultImage = nil
            appliedAgeId = nil
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        photosPickerItem = nil
        resultImage = nil
        appliedAgeId = nil
        progress = 0
    }

    func applyAge(_ option: AgeOption) async {
        guard let original = selectedPhoto else { return }
        isProcessing = true
        progress = 0.05
        errorMessage = nil
        appliedAgeId = option.id

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
                let prompt = "Same person, same identity, same bone structure, same eye color. \(option.agePhrase). Photorealistic dating-profile portrait, no over-smoothing."
                let job = try await GigaRizzAPIClient.shared.submitGeneration(
                    style: "age_modify",
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
                        errorMessage = status.error ?? "Age change failed"
                        return
                    }
                }
                errorMessage = "Age change timed out"
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
        AgeModifierView()
            .environmentObject(SubscriptionManager.shared)
    }
    .preferredColorScheme(.dark)
}
