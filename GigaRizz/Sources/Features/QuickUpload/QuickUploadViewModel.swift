import Foundation
import PhotosUI
import SwiftUI

// MARK: - Quick Upload ViewModel

/// Simplified view model for power user single-photo express generation.
@MainActor
final class QuickUploadViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedPhoto: UIImage?
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedStyle: StylePreset?
    @Published var generatedPhotos: [GeneratedPhoto] = []
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var showPaywall = false
    @Published var showResults = false
    @Published var showSharePrompt = false
    @Published var shareCountdown: Int = 3
    @Published var errorMessage: String?

    // MARK: - Services

    private let aiService = AIGenerationService.shared
    private let storageManager = StorageManager.shared
    private var shareTimer: Timer?

    // MARK: - Computed Properties

    var canGenerate: Bool {
        selectedPhoto != nil && selectedStyle != nil && !isGenerating
    }

    var progressText: String {
        if generationProgress < 0.3 {
            return "Uploading..."
        } else if generationProgress < 0.6 {
            return "AI thinking..."
        } else if generationProgress < 0.9 {
            return "Creating magic ✨"
        } else {
            return "Almost done!"
        }
    }

    // MARK: - Photo Loading

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
            DesignSystem.Haptics.light()
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        photosPickerItem = nil
        DesignSystem.Haptics.light()
    }

    // MARK: - Generate

    func generate(userId: String, subscriptionManager: SubscriptionManager) async {
        guard canGenerate, let photo = selectedPhoto, let style = selectedStyle else { return }

        guard subscriptionManager.canGeneratePhoto else {
            showPaywall = true
            return
        }

        isGenerating = true
        errorMessage = nil
        generationProgress = 0

        do {
            // Quick upload uses single photo mode
            let result = try await aiService.generatePhotos(
                sourceImages: [photo],
                style: style,
                userId: userId,
                count: 1,
                allowSinglePhoto: true // Quick Upload allows single photo
            )

            // Track progress
            for await progress in progressStream() {
                generationProgress = progress
            }

            generatedPhotos = result.photos
            subscriptionManager.incrementPhotoUsage()
            showResults = true

            DesignSystem.Haptics.success()

            PostHogManager.shared.track("quick_upload_generated", properties: [
                "style": style.name,
                "tier": subscriptionManager.currentTier.rawValue
            ])
        } catch {
            errorMessage = error.localizedDescription
            DesignSystem.Haptics.error()
        }

        isGenerating = false
    }

    // MARK: - Progress Stream

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

    // MARK: - Share Countdown

    func startShareCountdown() {
        shareCountdown = 3
        showSharePrompt = true

        shareTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.shareCountdown -= 1
                if self.shareCountdown <= 0 {
                    self.cancelShareCountdown()
                }
            }
        }
    }

    func cancelShareCountdown() {
        shareTimer?.invalidate()
        shareTimer = nil
        showSharePrompt = false
    }

    // MARK: - Cancel Generation

    func cancelGeneration() {
        aiService.cancelGeneration()
        isGenerating = false
        generationProgress = 0
    }

    // MARK: - Reset

    func reset() {
        selectedPhoto = nil
        photosPickerItem = nil
        selectedStyle = nil
        generatedPhotos = []
        generationProgress = 0
        showResults = false
        showSharePrompt = false
        errorMessage = nil
        cancelShareCountdown()
    }
}