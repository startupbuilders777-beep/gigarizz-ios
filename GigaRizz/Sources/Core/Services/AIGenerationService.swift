import Foundation
import UIKit

// MARK: - AI Generation Service

/// Service for generating AI-enhanced dating photos.
/// Currently uses mock generation — swap in real API (Stability AI, DALL-E, Replicate) when ready.
@MainActor
final class AIGenerationService: ObservableObject {
    // MARK: - Singleton

    static let shared = AIGenerationService()

    // MARK: - Published Properties

    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var errorMessage: String?

    // MARK: - Generation Result

    struct GenerationResult {
        let photos: [GeneratedPhoto]
        let style: String
        let processingTime: TimeInterval
    }

    // MARK: - Init

    init() {}

    // MARK: - Generate Photos

    /// Generate AI photos from source images using a style preset.
    /// - Parameters:
    ///   - sourceImages: 3-6 user photos
    ///   - style: The style preset to apply
    ///   - userId: Current user ID
    ///   - count: Number of photos to generate (default 4)
    /// - Returns: Array of generated photos
    func generatePhotos(
        sourceImages: [UIImage],
        style: StylePreset,
        userId: String,
        count: Int = 4
    ) async throws -> GenerationResult {
        guard !sourceImages.isEmpty else {
            throw GenerationError.noSourceImages
        }

        guard sourceImages.count >= 3 else {
            throw GenerationError.insufficientPhotos(minimum: 3, provided: sourceImages.count)
        }

        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        let startTime = Date()

        do {
            // Simulate AI processing stages
            // Stage 1: Analyzing source photos (0-25%)
            for step in 1...5 {
                try await Task.sleep(nanoseconds: 300_000_000)
                generationProgress = Double(step) * 0.05
            }

            // Stage 2: Building face model (25-50%)
            for step in 1...5 {
                try await Task.sleep(nanoseconds: 400_000_000)
                generationProgress = 0.25 + Double(step) * 0.05
            }

            // Stage 3: Generating styled photos (50-90%)
            var generatedPhotos: [GeneratedPhoto] = []
            for i in 0..<count {
                try await Task.sleep(nanoseconds: 500_000_000)
                generationProgress = 0.5 + (Double(i + 1) / Double(count)) * 0.4

                let photo = GeneratedPhoto(
                    userId: userId,
                    style: style.name,
                    createdAt: Date()
                )
                generatedPhotos.append(photo)
            }

            // Stage 4: Post-processing (90-100%)
            try await Task.sleep(nanoseconds: 300_000_000)
            generationProgress = 1.0

            let processingTime = Date().timeIntervalSince(startTime)

            isGenerating = false
            DesignSystem.Haptics.success()

            return GenerationResult(
                photos: generatedPhotos,
                style: style.name,
                processingTime: processingTime
            )
        } catch is CancellationError {
            isGenerating = false
            throw GenerationError.cancelled
        } catch {
            isGenerating = false
            errorMessage = error.localizedDescription
            DesignSystem.Haptics.error()
            throw error
        }
    }

    // MARK: - Cancel Generation

    func cancelGeneration() {
        isGenerating = false
        generationProgress = 0
    }
}

// MARK: - Generation Error

enum GenerationError: LocalizedError {
    case noSourceImages
    case insufficientPhotos(minimum: Int, provided: Int)
    case apiError(String)
    case cancelled
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .noSourceImages:
            return "No source photos provided. Please upload at least 3 photos."
        case .insufficientPhotos(let min, let provided):
            return "Need at least \(min) photos, but only \(provided) provided."
        case .apiError(let message):
            return "Generation failed: \(message)"
        case .cancelled:
            return "Generation was cancelled."
        case .quotaExceeded:
            return "You've reached your daily photo limit. Upgrade to generate more!"
        }
    }
}
