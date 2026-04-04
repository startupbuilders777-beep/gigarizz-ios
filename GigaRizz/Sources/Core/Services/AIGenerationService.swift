import Foundation
import UIKit

// MARK: - Service Mode

/// Switch to `.production` when Cloud Functions are deployed.
/// In `.mock`, the app returns demo photos with simulated progress.
/// In `.production`, it calls Firebase Cloud Functions for real AI generation.
enum ServiceMode {
    case mock
    case production

    // LAUNCH TODO: Switch to .production when Cloud Functions are deployed
    static let current: ServiceMode = .mock
}

// MARK: - AI Generation Service

/// Service for generating AI-enhanced dating photos.
/// Uses ServiceMode to switch between mock and real API.
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
        count: Int = 4,
        allowSinglePhoto: Bool = false
    ) async throws -> GenerationResult {
        guard !sourceImages.isEmpty else {
            throw GenerationError.noSourceImages
        }

        if !allowSinglePhoto {
            guard sourceImages.count >= 3 else {
                throw GenerationError.insufficientPhotos(minimum: 3, provided: sourceImages.count)
            }
        }

        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        let startTime = Date()

        do {
            switch ServiceMode.current {
            case .mock:
                return try await generateMockPhotos(userId: userId, style: style, count: count, startTime: startTime)
            case .production:
                return try await generateViaBackend(userId: userId, style: style, count: count, startTime: startTime)
            }
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

    // MARK: - Mock Generation

    private func generateMockPhotos(userId: String, style: StylePreset, count: Int, startTime: Date) async throws -> GenerationResult {
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
    }

    // MARK: - Backend Generation

    private func generateViaBackend(userId: String, style: StylePreset, count: Int, startTime: Date) async throws -> GenerationResult {
        // 1. Submit job to backend
        generationProgress = 0.05
        let job = try await GigaRizzAPIClient.shared.submitGeneration(
            style: style.name.lowercased().replacingOccurrences(of: " ", with: "_"),
            prompt: style.prompt
        )

        // 2. Poll for completion
        let jobId = job.jobId
        var attempts = 0
        let maxAttempts = 120  // ~2 minutes at 1s intervals

        while attempts < maxAttempts {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            attempts += 1

            let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: jobId)

            if status.status == "completed" {
                generationProgress = 1.0
                let photos = status.resultUrls.map { _ in
                    GeneratedPhoto(userId: userId, style: style.name, createdAt: Date())
                }
                let processingTime = Date().timeIntervalSince(startTime)
                isGenerating = false
                DesignSystem.Haptics.success()
                return GenerationResult(photos: photos, style: style.name, processingTime: processingTime)
            } else if status.status == "failed" {
                throw GenerationError.apiError(status.error ?? "Generation failed on server")
            }

            // Update progress from server
            generationProgress = max(generationProgress, status.progress)
        }

        // Timed out
        try? await GigaRizzAPIClient.shared.cancelGeneration(jobId: jobId)
        throw GenerationError.apiError("Generation timed out")
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
