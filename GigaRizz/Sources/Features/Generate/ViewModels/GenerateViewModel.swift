import Foundation
import PhotosUI
import SwiftUI

// MARK: - Generate View Model

@MainActor
final class GenerateViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedPhotos: [SelectedPhotoItem] = []
    @Published var photosPickerItems: [PhotosPickerItem] = []
    @Published var selectedStyle: StylePreset?
    @Published var generatedPhotos: [GeneratedPhoto] = []
    @Published var isLoadingPhotos = false
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var showPaywall = false
    @Published var showResults = false
    @Published var errorMessage: String?

    // MARK: - Services

    private let aiService = AIGenerationService.shared
    private let storageManager = StorageManager.shared
    private let stylePresetManager = StylePresetManager.shared

    // MARK: - Constants

    let minimumPhotos = 3
    let maximumPhotos = 6

    // MARK: - Computed Properties

    var canGenerate: Bool {
        selectedPhotos.count >= minimumPhotos && selectedStyle != nil && !isGenerating
    }

    var photoCountText: String {
        "\(selectedPhotos.count)/\(maximumPhotos) photos"
    }

    var progressText: String {
        if generationProgress < 0.25 {
            return "Analyzing your photos..."
        } else if generationProgress < 0.5 {
            return "Building your look..."
        } else if generationProgress < 0.9 {
            return "Creating magic ✨"
        } else {
            return "Almost done!"
        }
    }

    // MARK: - Photo Loading

    func loadPhotos() async {
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

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
    }

    // MARK: - Remove Photo

    func removePhoto(_ photo: SelectedPhotoItem) {
        selectedPhotos.removeAll { $0.id == photo.id }
        DesignSystem.Haptics.light()
    }

    // MARK: - Generate

    func generate(userId: String, subscriptionManager: SubscriptionManager) async {
        guard canGenerate else { return }

        guard subscriptionManager.canGeneratePhoto else {
            showPaywall = true
            return
        }

        guard let style = selectedStyle else { return }

        isGenerating = true
        errorMessage = nil

        do {
            let images = selectedPhotos.map(\.image)

            let result = try await aiService.generatePhotos(
                sourceImages: images,
                style: style,
                userId: userId
            )

            // Track progress from service
            for await progress in progressStream() {
                generationProgress = progress
            }

            generatedPhotos = result.photos
            subscriptionManager.incrementPhotoUsage()
            
            // Record style preset usage for future recommendations
            stylePresetManager.recordUsage(style)
            
            showResults = true

            PostHogManager.shared.trackPhotoGenerated(
                style: style.name,
                tier: subscriptionManager.currentTier.rawValue,
                photoCount: result.photos.count
            )
        } catch {
            errorMessage = error.localizedDescription
            DesignSystem.Haptics.error()
        }

        isGenerating = false
    }

    // MARK: - Progress Stream (simplified)

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

    // MARK: - Cancel Generation

    func cancelGeneration() {
        aiService.cancelGeneration()
        isGenerating = false
        generationProgress = 0
        PostHogManager.shared.track("generation_cancelled")
    }

    // MARK: - Reset

    func reset() {
        selectedPhotos = []
        photosPickerItems = []
        selectedStyle = nil
        generatedPhotos = []
        generationProgress = 0
        showResults = false
        errorMessage = nil
    }
}
