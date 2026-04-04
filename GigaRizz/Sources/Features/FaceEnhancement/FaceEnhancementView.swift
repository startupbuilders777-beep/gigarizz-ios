import PhotosUI
import SwiftUI
import Vision

// MARK: - Enhancement Intensity

enum EnhancementIntensity: Int, CaseIterable {
    case minimal = 1
    case natural = 2
    case enhanced = 3
    case polished = 4
    case glamorous = 5

    var label: String {
        switch self {
        case .minimal: "Minimal"
        case .natural: "Natural"
        case .enhanced: "Enhanced"
        case .polished: "Polished"
        case .glamorous: "Glamorous"
        }
    }

    var description: String {
        switch self {
        case .minimal: "Almost invisible, just a touch"
        case .natural: "Like you slept great"
        case .enhanced: "Best version of you"
        case .polished: "Headshot-quality"
        case .glamorous: "Photo-ready perfection"
        }
    }

    /// Enhancement parameters for this intensity level
    var parameters: EnhancementParameters {
        switch self {
        case .minimal:
            EnhancementParameters(
                skinSmoothing: 0.03,
                teethWhitening: 0.02,
                eyeBrightness: 0.05,
                skinToneEvening: 0.03,
                shadowReduction: 0.05
            )
        case .natural:
            EnhancementParameters(
                skinSmoothing: 0.08,
                teethWhitening: 0.05,
                eyeBrightness: 0.10,
                skinToneEvening: 0.08,
                shadowReduction: 0.10
            )
        case .enhanced:
            EnhancementParameters(
                skinSmoothing: 0.12,
                teethWhitening: 0.08,
                eyeBrightness: 0.12,
                skinToneEvening: 0.12,
                shadowReduction: 0.15
            )
        case .polished:
            EnhancementParameters(
                skinSmoothing: 0.18,
                teethWhitening: 0.12,
                eyeBrightness: 0.15,
                skinToneEvening: 0.15,
                shadowReduction: 0.20
            )
        case .glamorous:
            EnhancementParameters(
                skinSmoothing: 0.25,
                teethWhitening: 0.18,
                eyeBrightness: 0.18,
                skinToneEvening: 0.20,
                shadowReduction: 0.25
            )
        }
    }
}

// MARK: - Enhancement Parameters

struct EnhancementParameters {
    let skinSmoothing: Double
    let teethWhitening: Double
    let eyeBrightness: Double
    let skinToneEvening: Double
    let shadowReduction: Double
}

// MARK: - Face Enhancement View

struct FaceEnhancementView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = FaceEnhancementViewModel()
    @State private var showPaywall = false
    @State private var sliderPosition: CGFloat = 0.5
    @State private var selectedIntensity: EnhancementIntensity = .natural

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    headerSection
                    photoSection

                    if viewModel.selectedPhoto != nil {
                        intensitySliderSection
                        beforeAfterSection
                        enhancementDetailsSection
                        applyButton
                    }

                    if viewModel.isProcessing {
                        processingOverlay
                    }

                    if viewModel.resultImage != nil {
                        resultSection
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Face Enhancement")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Natural AI Retouching")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Enhancement that looks like you, not a filter")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.m)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Your Photo")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let image = viewModel.selectedPhoto {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))

                    Button {
                        viewModel.clearPhoto()
                        DesignSystem.Haptics.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    .padding(DesignSystem.Spacing.s)
                }
            } else {
                PhotosPicker(
                    selection: $viewModel.photosPickerItem,
                    matching: .images
                ) {
                    VStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)

                        Text("Upload a Portrait")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Best results with a clear face photo")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
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

    // MARK: - Intensity Slider

    private var intensitySliderSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Enhancement Level")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            GRCard {
                VStack(spacing: DesignSystem.Spacing.m) {
                    // 5-position slider
                    HStack(spacing: 0) {
                        ForEach(EnhancementIntensity.allCases, id: \.rawValue) { intensity in
                            Button {
                                withAnimation(DesignSystem.Animation.quickSpring) {
                                    selectedIntensity = intensity
                                    viewModel.updateIntensity(intensity)
                                }
                                DesignSystem.Haptics.selection()
                            } label: {
                                VStack(spacing: DesignSystem.Spacing.xs) {
                                    Circle()
                                        .fill(selectedIntensity == intensity
                                            ? DesignSystem.Colors.flameOrange
                                            : DesignSystem.Colors.surfaceSecondary)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    selectedIntensity == intensity
                                                        ? DesignSystem.Colors.goldAccent
                                                        : DesignSystem.Colors.textSecondary.opacity(0.3),
                                                    lineWidth: 2
                                                )
                                        )

                                    Text(intensity.label)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(selectedIntensity == intensity
                                            ? DesignSystem.Colors.flameOrange
                                            : DesignSystem.Colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    // Slider track
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(DesignSystem.Colors.surfaceSecondary)
                                .frame(height: 4)

                            Capsule()
                                .fill(DesignSystem.Colors.flameOrange)
                                .frame(width: geometry.size.width * CGFloat(selectedIntensity.rawValue - 1) / 4, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, DesignSystem.Spacing.xs)

                    Text(selectedIntensity.description)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Before/After Comparison

    private var beforeAfterSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Before & After Preview")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            BeforeAfterSliderView(
                originalImage: viewModel.selectedPhoto ?? UIImage(),
                enhancedImage: viewModel.previewImage ?? viewModel.selectedPhoto ?? UIImage(),
                sliderPosition: $sliderPosition
            )
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Enhancement Details

    private var enhancementDetailsSection: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("What's Enhanced")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                VStack(spacing: DesignSystem.Spacing.s) {
                    enhancementRow(
                        icon: "circle.lefthalf.filled",
                        title: "Skin Smoothing",
                        value: selectedIntensity.parameters.skinSmoothing,
                        color: DesignSystem.Colors.flameOrange
                    )
                    enhancementRow(
                        icon: "sun.max.fill",
                        title: "Eye Brightness",
                        value: selectedIntensity.parameters.eyeBrightness,
                        color: DesignSystem.Colors.goldAccent
                    )
                    enhancementRow(
                        icon: "tooth.fill",
                        title: "Teeth Whitening",
                        value: selectedIntensity.parameters.teethWhitening,
                        color: .white
                    )
                    enhancementRow(
                        icon: "circle.circle",
                        title: "Skin Tone Evening",
                        value: selectedIntensity.parameters.skinToneEvening,
                        color: .brown
                    )
                    enhancementRow(
                        icon: "moonphase.first.quarter",
                        title: "Shadow Reduction",
                        value: selectedIntensity.parameters.shadowReduction,
                        color: DesignSystem.Colors.surfaceSecondary
                    )
                }
            }
        }
    }

    private func enhancementRow(icon: String, title: String, value: Double, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text("\(Int(value * 100))%")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .monospacedDigit()
        }
    }

    // MARK: - Apply Button

    private var applyButton: some View {
        GRButton(
            title: "Apply Enhancement",
            icon: "sparkles",
            isLoading: viewModel.isProcessing
        ) {
            if subscriptionManager.currentTier == .free && viewModel.enhancementsUsed >= 3 {
                showPaywall = true
                DesignSystem.Haptics.warning()
            } else {
                Task {
                    await viewModel.applyEnhancement()
                }
                DesignSystem.Haptics.medium()
            }
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                ProgressView()
                    .tint(DesignSystem.Colors.flameOrange)
                    .scaleEffect(1.5)

                Text("Enhancing your photo...")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Faces detected: \(viewModel.facesDetected)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                ProgressView(value: viewModel.progress)
                    .tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Text("Enhanced Photo")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let result = viewModel.resultImage {
                Image(uiImage: result)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .cardShadow()
            }

            HStack(spacing: DesignSystem.Spacing.s) {
                GRButton(title: "Save", icon: "square.and.arrow.down") {
                    viewModel.saveResult()
                    DesignSystem.Haptics.success()
                }

                GRButton(title: "Try Another", icon: "arrow.counterclockwise", style: .secondary) {
                    viewModel.clearResult()
                    DesignSystem.Haptics.light()
                }
            }
        }
    }
}

// MARK: - Before/After Slider View

struct BeforeAfterSliderView: View {
    let originalImage: UIImage
    let enhancedImage: UIImage
    @Binding var sliderPosition: CGFloat
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced image (background)
                Image(uiImage: enhancedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Original image (clipped by slider position)
                Image(uiImage: originalImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .mask(
                        Rectangle()
                            .frame(width: geometry.size.width * sliderPosition)
                    )

                // Slider divider
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)

                // Slider handle
                Circle()
                    .fill(.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = value.location.x / geometry.size.width
                                sliderPosition = max(0.05, min(0.95, newPosition))
                            }
                    )

                // Labels
                VStack {
                    HStack {
                        Text("Before")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.white)
                            .padding(DesignSystem.Spacing.xs)
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(DesignSystem.Spacing.s)

                        Spacer()

                        Text("After")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.white)
                            .padding(DesignSystem.Spacing.xs)
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(DesignSystem.Spacing.s)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Face Enhancement ViewModel

@MainActor
final class FaceEnhancementViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedPhoto: UIImage?
    @Published var previewImage: UIImage?
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var facesDetected = 0
    @Published var currentIntensity: EnhancementIntensity = .natural
    @Published var enhancementsUsed = 0

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
            previewImage = image
            await detectFaces(in: image)
            await generatePreview()
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        previewImage = nil
        photosPickerItem = nil
        resultImage = nil
        facesDetected = 0
        progress = 0
    }

    func clearResult() {
        resultImage = nil
        previewImage = selectedPhoto
        progress = 0
    }

    func updateIntensity(_ intensity: EnhancementIntensity) {
        currentIntensity = intensity
        Task { await generatePreview() }
    }

    private func detectFaces(in image: UIImage) async {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            facesDetected = request.results?.count ?? 0
        } catch {
            facesDetected = 0
        }
    }

    private func generatePreview() async {
        guard let original = selectedPhoto else { return }
        let params = currentIntensity.parameters

        // Apply subtle enhancements for preview
        previewImage = await applyEnhancements(to: original, parameters: params, isPreview: true)
    }

    func applyEnhancement() async {
        guard let original = selectedPhoto else { return }
        isProcessing = true
        progress = 0

        let params = currentIntensity.parameters

        // Simulate processing with progress updates
        for i in 0..<10 {
            try? await Task.sleep(nanoseconds: 150_000_000)
            progress = Double(i + 1) / 10.0
        }

        resultImage = await applyEnhancements(to: original, parameters: params, isPreview: false)
        isProcessing = false
        enhancementsUsed += 1
        DesignSystem.Haptics.success()
    }

    private func applyEnhancements(to image: UIImage, parameters: EnhancementParameters, isPreview: Bool) async -> UIImage {
        // In production, this would use CoreML models for:
        // - Skin smoothing (CIFilter gaussian blur on skin regions)
        // - Teeth whitening (color adjustment on detected teeth)
        // - Eye brightness (exposure adjustment on eye regions)
        // - Skin tone evening (color matching across face)
        // - Shadow reduction (shadow/highlight balance)

        // For now, apply subtle CoreImage filters that preserve authenticity
        guard let cgImage = image.cgImage else { return image }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()

        // Apply subtle enhancements
        var outputImage = ciImage

        // Slight skin smoothing using noise reduction
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(parameters.skinSmoothing * 0.5, forKey: "inputNoiseLevel")
            if let output = noiseFilter.outputImage {
                outputImage = output
            }
        }

        // Slight brightness boost for eye area simulation
        if let brightnessFilter = CIFilter(name: "CIExposureAdjust") {
            brightnessFilter.setValue(outputImage, forKey: kCIInputImageKey)
            brightnessFilter.setValue(parameters.eyeBrightness * 0.3, forKey: kCIInputEVKey)
            if let output = brightnessFilter.outputImage {
                outputImage = output
            }
        }

        // Slight contrast adjustment for definition
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.0 + parameters.shadowReduction * 0.2, forKey: kCIInputContrastKey)
            contrastFilter.setValue(parameters.skinToneEvening * 0.1, forKey: kCIInputBrightnessKey)
            if let output = contrastFilter.outputImage {
                outputImage = output
            }
        }

        // Warm color tone (simulates healthy skin)
        if let toneFilter = CIFilter(name: "CIColorMatrix") {
            let rVector = CIVector(x: 1.0 + parameters.teethWhitening * 0.05, y: 0, z: 0, w: 0)
            let gVector = CIVector(x: 0, y: 1.0, z: 0, w: 0)
            let bVector = CIVector(x: 0, y: 0, z: 1.0 - parameters.teethWhitening * 0.02, w: 0)
            let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            let biasVector = CIVector(x: parameters.skinToneEvening * 0.02, y: 0, z: 0, w: 0)

            toneFilter.setValue(outputImage, forKey: kCIInputImageKey)
            toneFilter.setValue(rVector, forKey: "inputRVector")
            toneFilter.setValue(gVector, forKey: "inputGVector")
            toneFilter.setValue(bVector, forKey: "inputBVector")
            toneFilter.setValue(aVector, forKey: "inputAVector")
            toneFilter.setValue(biasVector, forKey: "inputBiasVector")

            if let output = toneFilter.outputImage {
                outputImage = output
            }
        }

        if let finalImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: finalImage)
        }

        return image
    }

    func saveResult() {
        guard let result = resultImage else { return }
        UIImageWriteToSavedPhotosAlbum(result, nil, nil, nil)
    }
}

#Preview {
    NavigationStack {
        FaceEnhancementView()
    }
    .environmentObject(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}