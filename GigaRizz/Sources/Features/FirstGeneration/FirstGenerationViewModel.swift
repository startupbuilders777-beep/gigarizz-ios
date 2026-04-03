import Foundation
import SwiftUI
import PhotosUI

// MARK: - Generation Flow Step

enum GenerationFlowStep: Int, CaseIterable {
    case upload = 0
    case style = 1
    case generating = 2
    case results = 3
}

// MARK: - First Generation View Model

@MainActor
final class FirstGenerationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentStep: GenerationFlowStep = .upload
    @Published var selectedPhotos: [SelectedPhotoItem] = []
    @Published var photosPickerItems: [PhotosPickerItem] = []
    @Published var selectedStyle: StylePreset?
    @Published var aiSuggestedStyle: StylePreset?
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var generatedPhotos: [GeneratedPhoto] = []
    @Published var showSaveConfirmation = false
    @Published var currentTipIndex = 0
    @Published var errorMessage: String?

    // MARK: - AppStorage

    @AppStorage("hasGeneratedPhotos") var hasGeneratedPhotos = false

    // MARK: - Constants

    let minimumPhotos = 3
    let maximumPhotos = 5

    // MARK: - Services

    private let aiService = AIGenerationService.shared
    private var tipTimer: Timer?

    // MARK: - Computed Properties

    var canProceedFromUpload: Bool {
        selectedPhotos.count >= minimumPhotos
    }

    var photoCountText: String {
        "\(selectedPhotos.count)/\(maximumPhotos) photos"
    }

    var photoCountIcon: String {
        if selectedPhotos.isEmpty { return "photo" }
        if selectedPhotos.count >= minimumPhotos { return "checkmark.circle.fill" }
        return "exclamationmark.circle"
    }

    var photoCountColor: Color {
        if selectedPhotos.isEmpty { return DesignSystem.Colors.textSecondary }
        if selectedPhotos.count >= minimumPhotos { return DesignSystem.Colors.success }
        return DesignSystem.Colors.warning
    }

    var availableStyles: [StylePreset] {
        StylePreset.allPresets.filter { $0.tier == .free }
    }

    var progressText: String {
        if generationProgress < 0.15 {
            return "Analyzing your photos..."
        } else if generationProgress < 0.3 {
            return "Building your style profile..."
        } else if generationProgress < 0.5 {
            return "Creating magic ✨"
        } else if generationProgress < 0.8 {
            return "Generating your photos..."
        } else {
            return "Final touches..."
        }
    }

    var timeRemainingText: String {
        let remaining = Int((1.0 - generationProgress) * 30)
        if remaining <= 0 { return "Done!" }
        return "About \(remaining) seconds remaining"
    }

    let generationTips: [String] = [
        "💡 Great photos get 3x more matches on Tinder",
        "💡 Natural lighting beats studio lights 2:1",
        "💡 Smiles increase approachability by 40%",
        "💡 Clear eyes = trustworthy impressions",
        "💡 Solid colors photograph better than patterns"
    ]

    // MARK: - Photo Loading

    func loadPhotos() async {
        var loaded: [SelectedPhotoItem] = []

        for item in photosPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(SelectedPhotoItem(image: image))
            }
        }

        // Keep existing + add new, up to max
        let newPhotos = loaded.filter { newItem in
            !selectedPhotos.contains(where: { $0.id == newItem.id })
        }
        selectedPhotos = Array((selectedPhotos + newPhotos).prefix(maximumPhotos))

        // Auto-analyze photos to suggest style
        if selectedPhotos.count >= minimumPhotos {
            await analyzeAndSuggestStyle()
        }
    }

    // MARK: - Style Analysis (AI Auto-Suggest)

    private func analyzeAndSuggestStyle() async {
        // Simulated AI analysis - in production would use Vision API
        // Analyze lighting, composition, setting from photos
        let suggestedStyle = analyzePhotosForStyle(selectedPhotos)
        aiSuggestedStyle = suggestedStyle
        selectedStyle = suggestedStyle

        PostHogManager.shared.track("first_generation_style_suggested", properties: [
            "style": suggestedStyle.name,
            "photo_count": selectedPhotos.count
        ])
    }

    private func analyzePhotosForStyle(_ photos: [SelectedPhotoItem]) -> StylePreset {
        // In production: use Vision framework to analyze:
        // - Indoor vs outdoor (sky detection, greenery)
        // - Lighting quality (brightness, contrast)
        // - Composition (face position, background)
        // For now: return Confident as safe default
        let freeStyles = StylePreset.allPresets.filter { $0.tier == .free }
        return freeStyles.first ?? StylePreset.allPresets.first!
    }

    // MARK: - Navigation

    func goBack() {
        switch currentStep {
        case .style:
            currentStep = .upload
        case .generating:
            cancelGeneration()
            currentStep = .style
        default:
            break
        }
    }

    func proceedToStyle() {
        guard canProceedFromUpload else { return }
        currentStep = .style

        // If no style suggested yet, suggest now
        if aiSuggestedStyle == nil && selectedPhotos.count >= minimumPhotos {
            Task {
                await analyzeAndSuggestStyle()
            }
        }
    }

    func proceedToGenerating() {
        guard selectedStyle != nil else { return }
        currentStep = .generating
        startTipRotation()
        Task {
            await generatePhotos()
        }
    }

    // MARK: - Generation

    private func generatePhotos() async {
        guard let style = selectedStyle else { return }

        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        do {
            let images = selectedPhotos.map(\.image)
            let userId = "first_gen_user"

            // Use AI service to generate
            let result = try await aiService.generatePhotos(
                sourceImages: images,
                style: style,
                userId: userId,
                count: 4
            )

            // Track progress
            for await progress in progressStream() {
                generationProgress = progress
            }

            generatedPhotos = result.photos
            currentStep = .results
            hasGeneratedPhotos = true  // Mark as completed for first-time users

            PostHogManager.shared.track("first_generation_completed", properties: [
                "style": style.name,
                "photo_count": result.photos.count,
                "processing_time": result.processingTime
            ])

            DesignSystem.Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            currentStep = .style
            DesignSystem.Haptics.error()
        }

        isGenerating = false
        stopTipRotation()
    }

    private func progressStream() -> AsyncStream<Double> {
        AsyncStream { continuation in
            Task {
                while aiService.isGenerating {
                    continuation.yield(aiService.generationProgress)
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                continuation.yield(1.0)
                continuation.finish()
            }
        }
    }

    func cancelGeneration() {
        aiService.cancelGeneration()
        isGenerating = false
        generationProgress = 0
        stopTipRotation()
    }

    // MARK: - Tip Rotation

    private func startTipRotation() {
        tipTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentTipIndex = (self.currentTipIndex + 1) % self.generationTips.count
                }
            }
        }
    }

    private func stopTipRotation() {
        tipTimer?.invalidate()
        tipTimer = nil
    }

    // MARK: - Photo Actions

    func removePhoto(_ photo: SelectedPhotoItem) {
        selectedPhotos.removeAll { $0.id == photo.id }
        if selectedPhotos.count < minimumPhotos {
            aiSuggestedStyle = nil
            selectedStyle = nil
        }
    }

    func toggleFavorite(_ photo: GeneratedPhoto) {
        if let index = generatedPhotos.firstIndex(where: { $0.id == photo.id }) {
            generatedPhotos[index].isFavorite.toggle()
        }
    }

    func saveAllPhotos() {
        // In production: save to photo library using PHPhotoLibrary
        // For now: simulate save
        showSaveConfirmation = true

        PostHogManager.shared.track("first_generation_photos_saved", properties: [
            "photo_count": generatedPhotos.count
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showSaveConfirmation = false
            }
        }
    }

    // MARK: - Share Actions

    func shareToInstagram() {
        // Instagram Stories sharing via URL scheme
        // In production: render composite image and share

        PostHogManager.shared.track("first_generation_shared", properties: [
            "method": "instagram"
        ])
    }

    func shareGeneric() {
        // Generic share sheet
        PostHogManager.shared.track("first_generation_shared", properties: [
            "method": "generic"
        ])
    }

    // MARK: - Reset

    func reset() {
        selectedPhotos = []
        photosPickerItems = []
        selectedStyle = nil
        aiSuggestedStyle = nil
        generatedPhotos = []
        generationProgress = 0
        currentStep = .upload
        errorMessage = nil
        showSaveConfirmation = false
    }
}

// MARK: - PhotosPickerItem Handling

extension FirstGenerationViewModel {
    func handlePhotosPickerChange() {
        Task {
            await loadPhotos()
        }
    }
}