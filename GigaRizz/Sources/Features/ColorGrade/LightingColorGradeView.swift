import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI

// MARK: - Lighting Preset

/// Pre-built color grading presets optimized for dating profile photos.
enum LightingPreset: String, CaseIterable, Identifiable {
    case original
    case goldenHour
    case softPortrait
    case cinematic
    case warmGlow
    case coolEdge
    case moody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Original"
        case .goldenHour: return "Golden Hour"
        case .softPortrait: return "Soft Portrait"
        case .cinematic: return "Cinematic"
        case .warmGlow: return "Warm Glow"
        case .coolEdge: return "Cool Edge"
        case .moody: return "Moody"
        }
    }

    var icon: String {
        switch self {
        case .original: return "photo"
        case .goldenHour: return "sun.max.fill"
        case .softPortrait: return "person.fill"
        case .cinematic: return "film"
        case .warmGlow: return "flame.fill"
        case .coolEdge: return "snowflake"
        case .moody: return "moon.fill"
        }
    }

    var description: String {
        switch self {
        case .original: return "No adjustments"
        case .goldenHour: return "Warm sunset tones, +40% more right-swipes"
        case .softPortrait: return "Soft flattering light for face shots"
        case .cinematic: return "Film-like contrast with rich shadows"
        case .warmGlow: return "Cozy warm tones, great for indoor photos"
        case .coolEdge: return "Clean modern look with cool undertones"
        case .moody: return "Dramatic low-key look for evening photos"
        }
    }

    /// CoreImage filter parameters for this preset
    var adjustments: ColorAdjustments {
        switch self {
        case .original:
            return ColorAdjustments()
        case .goldenHour:
            return ColorAdjustments(
                exposure: 0.15,
                warmth: 0.4,
                saturation: 1.15,
                contrast: 1.05,
                highlights: -0.1,
                shadows: 0.15,
                vibrance: 0.2
            )
        case .softPortrait:
            return ColorAdjustments(
                exposure: 0.1,
                warmth: 0.15,
                saturation: 0.95,
                contrast: 0.92,
                highlights: -0.15,
                shadows: 0.2,
                vibrance: 0.1
            )
        case .cinematic:
            return ColorAdjustments(
                exposure: -0.05,
                warmth: 0.1,
                saturation: 1.1,
                contrast: 1.2,
                highlights: -0.2,
                shadows: -0.1,
                vibrance: 0.15
            )
        case .warmGlow:
            return ColorAdjustments(
                exposure: 0.1,
                warmth: 0.35,
                saturation: 1.08,
                contrast: 1.0,
                highlights: 0.0,
                shadows: 0.1,
                vibrance: 0.25
            )
        case .coolEdge:
            return ColorAdjustments(
                exposure: 0.05,
                warmth: -0.25,
                saturation: 0.9,
                contrast: 1.1,
                highlights: -0.1,
                shadows: 0.05,
                vibrance: 0.1
            )
        case .moody:
            return ColorAdjustments(
                exposure: -0.15,
                warmth: 0.05,
                saturation: 0.85,
                contrast: 1.25,
                highlights: -0.3,
                shadows: -0.2,
                vibrance: 0.05
            )
        }
    }
}

// MARK: - Color Adjustments

struct ColorAdjustments {
    var exposure: Double = 0
    var warmth: Double = 0        // -1.0 (cool) to 1.0 (warm)
    var saturation: Double = 1.0  // 0.0 to 2.0, 1.0 = normal
    var contrast: Double = 1.0    // 0.5 to 2.0, 1.0 = normal
    var highlights: Double = 0    // -1.0 to 1.0
    var shadows: Double = 0       // -1.0 to 1.0
    var vibrance: Double = 0      // -1.0 to 1.0
}

// MARK: - Lighting & Color Grade View

struct LightingColorGradeView: View {
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var selectedPreset: LightingPreset = .original
    @State private var showBeforeAfter = false
    @State private var isProcessing = false
    @State private var manualAdjustments = ColorAdjustments()
    @State private var showManualControls = false

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    headerSection
                    photoSection
                    if originalImage != nil {
                        presetScrollSection
                        if showManualControls { manualControlsSection }
                        actionButtons
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Color Grade")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "camera.filters")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Lighting & Color Grade")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Professional color grading for dating photos")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Photo

    private var photoSection: some View {
        Group {
            if let displayImage = showBeforeAfter ? originalImage : (processedImage ?? originalImage) {
                ZStack {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))

                    // Before/After toggle
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showBeforeAfter.toggle()
                                DesignSystem.Haptics.light()
                            } label: {
                                Text(showBeforeAfter ? "Before" : "After")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(DesignSystem.Spacing.small)
                        }
                    }

                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                }
                .frame(maxHeight: 400)
            } else {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("Select a Photo")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Choose your best dating photo to enhance")
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
                .onChange(of: photosPickerItem) {
                    Task { await loadPhoto() }
                }
            }
        }
    }

    // MARK: - Preset Scroll

    private var presetScrollSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Presets")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Button {
                    withAnimation { showManualControls.toggle() }
                    DesignSystem.Haptics.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text(showManualControls ? "Hide" : "Manual")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(LightingPreset.allCases) { preset in
                        presetButton(preset)
                    }
                }
            }
        }
    }

    private func presetButton(_ preset: LightingPreset) -> some View {
        Button {
            selectedPreset = preset
            showManualControls = false
            DesignSystem.Haptics.light()
            Task { await applyPreset(preset) }
        } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
                // Thumbnail preview with filter
                if let originalImage, let thumb = applyFilterSync(to: originalImage, adjustments: preset.adjustments) {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                } else {
                    Image(systemName: preset.icon)
                        .font(.system(size: 24))
                        .frame(width: 64, height: 80)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Text(preset.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selectedPreset == preset ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(DesignSystem.Spacing.xs)
            .background(
                selectedPreset == preset
                    ? DesignSystem.Colors.flameOrange.opacity(0.15)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(
                        selectedPreset == preset ? DesignSystem.Colors.flameOrange : .clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manual Controls

    private var manualControlsSection: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Manual Adjustments")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                sliderRow(title: "Exposure", value: $manualAdjustments.exposure, range: -1...1, icon: "sun.max")
                sliderRow(title: "Warmth", value: $manualAdjustments.warmth, range: -1...1, icon: "thermometer")
                sliderRow(title: "Saturation", value: $manualAdjustments.saturation, range: 0...2, icon: "drop.fill")
                sliderRow(title: "Contrast", value: $manualAdjustments.contrast, range: 0.5...2, icon: "circle.lefthalf.filled")
                sliderRow(title: "Highlights", value: $manualAdjustments.highlights, range: -1...1, icon: "sun.haze")
                sliderRow(title: "Shadows", value: $manualAdjustments.shadows, range: -1...1, icon: "shadow")
                sliderRow(title: "Vibrance", value: $manualAdjustments.vibrance, range: -1...1, icon: "paintpalette")

                GRButton(title: "Apply Manual Grade", icon: "checkmark.circle") {
                    Task { await applyManualAdjustments() }
                }
            }
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .frame(width: 16)
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Slider(value: value, in: range)
                .tint(DesignSystem.Colors.flameOrange)
        }
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            if processedImage != nil {
                GRButton(title: "Save", icon: "square.and.arrow.down") {
                    saveToPhotos()
                }
            }
            GRButton(title: "New Photo", icon: "arrow.counterclockwise", style: .secondary) {
                originalImage = nil
                processedImage = nil
                photosPickerItem = nil
                selectedPreset = .original
                manualAdjustments = ColorAdjustments()
            }
        }
    }

    // MARK: - Image Processing

    private func loadPhoto() async {
        guard let item = photosPickerItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        originalImage = image
        processedImage = nil
        selectedPreset = .original
    }

    private func applyPreset(_ preset: LightingPreset) async {
        guard let originalImage else { return }
        isProcessing = true
        let adjustments = preset.adjustments
        let result = await Task.detached(priority: .userInitiated) { [context] in
            ColorGradeEngine.applyFilter(to: originalImage, adjustments: adjustments, context: context)
        }.value
        processedImage = result
        isProcessing = false
        DesignSystem.Haptics.medium()
        PostHogManager.shared.trackEvent("color_grade_applied", properties: [
            "preset": preset.rawValue
        ])
    }

    private func applyManualAdjustments() async {
        guard let originalImage else { return }
        isProcessing = true
        let adjustments = manualAdjustments
        let result = await Task.detached(priority: .userInitiated) { [context] in
            ColorGradeEngine.applyFilter(to: originalImage, adjustments: adjustments, context: context)
        }.value
        processedImage = result
        isProcessing = false
        DesignSystem.Haptics.medium()
        PostHogManager.shared.trackEvent("color_grade_manual")
    }

    /// Synchronous filter for thumbnails (used in preset scroll)
    private func applyFilterSync(to image: UIImage, adjustments: ColorAdjustments) -> UIImage? {
        ColorGradeEngine.applyFilter(to: image, adjustments: adjustments, context: context)
    }

    // MARK: - Save

    private func saveToPhotos() {
        guard let processedImage else { return }
        UIImageWriteToSavedPhotosAlbum(processedImage, nil, nil, nil)
        DesignSystem.Haptics.success()
        PostHogManager.shared.trackEvent("color_grade_saved")
    }
}

// MARK: - Color Grade Engine (nonisolated for background processing)

/// Nonisolated CoreImage processing engine so it can run off the main actor.
enum ColorGradeEngine: Sendable {
    /// Apply CoreImage filters with the given adjustments
    nonisolated static func applyFilter(to image: UIImage, adjustments: ColorAdjustments, context: CIContext) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        var output = ciImage

        if adjustments.exposure != 0 {
            let exposureFilter = CIFilter.exposureAdjust()
            exposureFilter.inputImage = output
            exposureFilter.ev = Float(adjustments.exposure * 2.0)
            if let result = exposureFilter.outputImage { output = result }
        }

        if adjustments.warmth != 0 {
            let tempFilter = CIFilter.temperatureAndTint()
            tempFilter.inputImage = output
            let targetTemp = 6500 + Float(adjustments.warmth * 2000)
            tempFilter.neutral = CIVector(x: CGFloat(targetTemp), y: 0)
            if let result = tempFilter.outputImage { output = result }
        }

        if adjustments.saturation != 1.0 || adjustments.contrast != 1.0 {
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = output
            colorFilter.saturation = Float(adjustments.saturation)
            colorFilter.contrast = Float(adjustments.contrast)
            if let result = colorFilter.outputImage { output = result }
        }

        if adjustments.highlights != 0 || adjustments.shadows != 0 {
            let highlightFilter = CIFilter.highlightShadowAdjust()
            highlightFilter.inputImage = output
            highlightFilter.highlightAmount = Float(1.0 + adjustments.highlights)
            highlightFilter.shadowAmount = Float(adjustments.shadows * 2.0)
            if let result = highlightFilter.outputImage { output = result }
        }

        if adjustments.vibrance != 0 {
            let vibranceFilter = CIFilter.vibrance()
            vibranceFilter.inputImage = output
            vibranceFilter.amount = Float(adjustments.vibrance)
            if let result = vibranceFilter.outputImage { output = result }
        }

        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LightingColorGradeView()
    }
    .preferredColorScheme(.dark)
}
