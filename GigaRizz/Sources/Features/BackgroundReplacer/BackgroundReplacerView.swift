import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import Vision

// MARK: - Background Scene

struct BackgroundScene: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let gradient: [Color]
    let description: String
    let prompt: String
}

// MARK: - Background Replacer View

struct BackgroundReplacerView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = BackgroundReplacerViewModel()
    @State private var showPaywall = false

    private let scenes: [BackgroundScene] = [
        BackgroundScene(name: "Beach Sunset", icon: "sun.horizon.fill", gradient: [.orange, .pink], description: "Golden hour on the beach", prompt: "beach sunset golden hour"),
        BackgroundScene(name: "City Rooftop", icon: "building.2.fill", gradient: [.purple, .blue], description: "Urban skyline at night", prompt: "city rooftop night skyline"),
        BackgroundScene(name: "Mountain Trail", icon: "mountain.2.fill", gradient: [.green, .teal], description: "Scenic mountain hike", prompt: "mountain trail scenic view"),
        BackgroundScene(name: "Coffee Shop", icon: "cup.and.saucer.fill", gradient: [.brown, DesignSystem.Colors.goldAccent], description: "Cozy cafe vibes", prompt: "cozy coffee shop interior"),
        BackgroundScene(name: "Art Gallery", icon: "photo.artframe", gradient: [.gray, .white], description: "Sophisticated art space", prompt: "modern art gallery white walls"),
        BackgroundScene(name: "Sports Car", icon: "car.fill", gradient: [.red, .orange], description: "Luxury car backdrop", prompt: "luxury sports car sunset"),
        BackgroundScene(name: "Travel Exotic", icon: "airplane", gradient: [.cyan, .blue], description: "Exotic destination vibes", prompt: "exotic travel destination tropical"),
        BackgroundScene(name: "Dog Park", icon: "dog.fill", gradient: [DesignSystem.Colors.goldAccent, .orange], description: "With a cute dog", prompt: "dog park sunny day golden retriever"),
        BackgroundScene(name: "Concert", icon: "music.note", gradient: [.pink, .purple], description: "VIP festival energy", prompt: "concert festival vip area lights")
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    headerSection
                    photoSection
                    if viewModel.selectedPhoto != nil { sceneGridSection }
                    if viewModel.isProcessing { processingOverlay }
                    if viewModel.resultImage != nil { resultSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Background Replacer")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Scene Selector")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Upload a photo, pick a scene, get magic")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Photo Section

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

                    Button {
                        viewModel.clearPhoto()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    .padding(DesignSystem.Spacing.small)
                }
            } else {
                PhotosPicker(
                    selection: $viewModel.photosPickerItem,
                    matching: .images
                ) {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)

                        Text("Upload a Photo")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Works best with a clear selfie or portrait")
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

    // MARK: - Scene Grid

    private var sceneGridSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Choose a Scene")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(scenes) { scene in
                    sceneCard(scene)
                }
            }
        }
    }

    private func sceneCard(_ scene: BackgroundScene) -> some View {
        let isSelected = viewModel.selectedScene?.id == scene.id
        return Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                viewModel.selectedScene = scene
            }
            DesignSystem.Haptics.light()
        } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: scene.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)

                    Image(systemName: scene.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(isSelected ? DesignSystem.Colors.flameOrange : .clear, lineWidth: 2)
                )

                Text(scene.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                ProgressView()
                    .tint(DesignSystem.Colors.flameOrange)
                    .scaleEffect(1.5)

                Text("Replacing background...")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                ProgressView(value: viewModel.progress)
                    .tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Result")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let resultImage = viewModel.resultImage {
                Image(uiImage: resultImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .cardShadow()
            }

            HStack(spacing: DesignSystem.Spacing.small) {
                GRButton(title: "Save", icon: "square.and.arrow.down") {
                    if let image = viewModel.resultImage {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                    DesignSystem.Haptics.success()
                }
                GRButton(title: "Try Another", icon: "arrow.counterclockwise", style: .secondary) {
                    viewModel.clearResult()
                }
            }
        }
    }
}

// MARK: - Background Replacer ViewModel

@MainActor
final class BackgroundReplacerViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedPhoto: UIImage?
    @Published var selectedScene: BackgroundScene? {
        didSet {
            if selectedScene != nil && selectedPhoto != nil {
                processImage()
            }
        }
    }
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0

    private let ciContext = CIContext()

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        photosPickerItem = nil
        selectedScene = nil
        resultImage = nil
    }

    func clearResult() {
        resultImage = nil
        selectedScene = nil
        progress = 0
    }

    // MARK: - Real Vision-Based Background Replacement

    private func processImage() {
        guard let photo = selectedPhoto, let scene = selectedScene else { return }
        isProcessing = true
        progress = 0

        Task {
            progress = 0.1

            switch ServiceMode.current {
            case .production, .mock:
                // Vision segmentation works on-device in both modes — no API needed
                if let result = await segmentAndComposite(photo: photo, scene: scene) {
                    resultImage = result
                    PostHogManager.shared.trackBackgroundReplaced(scene: scene.name)
                } else {
                    // Fallback: return original photo if segmentation fails
                    resultImage = photo
                }
            }

            isProcessing = false
            DesignSystem.Haptics.success()
        }
    }

    /// Uses Apple Vision VNGeneratePersonSegmentationRequest to isolate the person,
    /// then composites onto a gradient background matching the selected scene.
    private func segmentAndComposite(photo: UIImage, scene: BackgroundScene) async -> UIImage? {
        guard let cgImage = photo.cgImage else { return nil }

        progress = 0.2

        // 1. Create person segmentation request
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced // Good quality without being too slow
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        progress = 0.3

        // 2. Run Vision request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        progress = 0.5

        // 3. Extract the mask
        guard let observation = request.results?.first,
              let maskBuffer = observation.pixelBuffer as CVPixelBuffer? else {
            return nil
        }

        progress = 0.6

        // 4. Convert mask to CIImage
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)
        let originalCI = CIImage(cgImage: cgImage)

        // Scale mask to match original image size
        let scaleX = originalCI.extent.width / maskCI.extent.width
        let scaleY = originalCI.extent.height / maskCI.extent.height
        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        progress = 0.7

        // 5. Create gradient background matching the scene
        let backgroundCI = createGradientBackground(
            colors: scene.gradient,
            size: originalCI.extent.size
        )

        progress = 0.8

        // 6. Composite: person (from original) over gradient background using mask
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
        blendFilter.setValue(originalCI, forKey: kCIInputImageKey)
        blendFilter.setValue(backgroundCI, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)

        guard let outputCI = blendFilter.outputImage else { return nil }

        progress = 0.9

        // 7. Render final image
        guard let outputCG = ciContext.createCGImage(outputCI, from: originalCI.extent) else {
            return nil
        }

        progress = 1.0
        return UIImage(cgImage: outputCG)
    }

    /// Creates a CIImage gradient matching the scene's two colors.
    private func createGradientBackground(colors: [Color], size: CGSize) -> CIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let gradientImage = renderer.image { context in
            let cgContext = context.cgContext
            let resolvedColors = colors.map { UIColor($0).cgColor }
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: resolvedColors as CFArray,
                locations: [0.0, 1.0]
            ) else { return }
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }

        return CIImage(image: gradientImage) ?? CIImage()
    }
}

#Preview {
    NavigationStack {
        BackgroundReplacerView()
    }
    .environmentObject(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}
