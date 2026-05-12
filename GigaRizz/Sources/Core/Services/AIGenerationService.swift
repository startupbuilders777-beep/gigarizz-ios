import Foundation
import UIKit
import Vision

// MARK: - Service Mode

/// Switch to `.production` when backend is deployed.
/// In `.mock`, the app returns demo photos with simulated progress.
/// In `.production`, it calls the GigaRizz backend for real AI generation.
///
/// In DEBUG, `current` reads from UserDefaults("dev_use_real_ai") so devs can
/// exercise the real upload + AI pipeline against localhost:8000 without
/// shipping a Release build. Toggle from Settings or via:
///     xcrun simctl spawn <UDID> defaults write com.gigarizz.app dev_use_real_ai -bool YES
enum ServiceMode {
    case mock
    case production

    static let userDefaultsKey = "dev_use_real_ai"

    static var current: ServiceMode {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: userDefaultsKey) ? .production : .mock
        #else
        return .production
        #endif
    }
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
        model: AIModel = AIModel.default,
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
                return try await generateViaBackend(
                    sourceImages: sourceImages,
                    userId: userId,
                    style: style,
                    count: count,
                    model: model,
                    startTime: startTime
                )
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

    private func generateViaBackend(
        sourceImages: [UIImage],
        userId: String,
        style: StylePreset,
        count: Int,
        model: AIModel,
        startTime: Date
    ) async throws -> GenerationResult {
        // 1. Upload the strongest source image (the first selected) so the backend
        // can pass its URL to identity-aware models (InstantID, Nano Banana 2,
        // GPT Image 2, face_restore). Best-effort: if upload fails we still
        // attempt prompt-only generation so the user isn't blocked.
        generationProgress = 0.02
        var sourceImageURL: URL?
        if let firstImage = sourceImages.first {
            sourceImageURL = await PhotoUploadService.shared.tryUpload(firstImage, purpose: "source")
        }

        // 2. Submit job to backend
        generationProgress = 0.05
        let job = try await GigaRizzAPIClient.shared.submitGeneration(
            style: style.name.lowercased().replacingOccurrences(of: " ", with: "_"),
            prompt: style.prompt,
            model: model.id,
            sourceImageUrl: sourceImageURL?.absoluteString
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
                let photos: [GeneratedPhoto] = status.resultUrls.compactMap { urlString in
                    guard let url = URL(string: urlString) else { return nil }
                    return GeneratedPhoto(
                        userId: userId,
                        style: style.name,
                        imageURL: url,
                        thumbnailURL: url,
                        createdAt: Date()
                    )
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

    // MARK: - Face Restoration (CodeFormer)

    /// Run a single image through the backend's `face_restore` model (CodeFormer).
    /// Returns the URL of the enhanced image; callers download into a UIImage.
    /// Throws `GenerationError.faceNotDetected` when Vision can't see a face — saves
    /// a paid round-trip and surfaces the issue immediately in the UI.
    func restoreFace(image: UIImage, userId: String) async throws -> URL {
        // 1. Local face-detection gate. CodeFormer is only worth invoking if there's
        //    actually a face — saves a paid call and avoids confusing "enhanced" output
        //    on landscape/object photos.
        guard try await Self.detectsFace(in: image) else {
            throw GenerationError.faceNotDetected
        }

        isGenerating = true
        generationProgress = 0.05
        errorMessage = nil

        defer { isGenerating = false }

        // 2. Upload source. Face restore is meaningless without a fetchable URL;
        //    if upload fails we surface a clear error rather than degrading.
        guard let sourceURL = await PhotoUploadService.shared.tryUpload(image, purpose: "source") else {
            throw GenerationError.apiError("Couldn't upload your photo. Check your connection.")
        }
        generationProgress = 0.2

        // 3. Submit. CodeFormer ignores style/prompt; we send "custom" + nil so
        //    the existing backend schema accepts the request.
        let job = try await GigaRizzAPIClient.shared.submitGeneration(
            style: "custom",
            prompt: nil,
            model: "face_restore",
            sourceImageUrl: sourceURL.absoluteString
        )

        // 4. Poll. CodeFormer typically completes in 5–20s; 60s ceiling is generous.
        let jobId = job.jobId
        for _ in 0..<60 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: jobId)
            generationProgress = max(generationProgress, max(status.progress, 0.3))

            if status.status == "completed", let first = status.resultUrls.first, let url = URL(string: first) {
                generationProgress = 1.0
                DesignSystem.Haptics.success()
                return url
            } else if status.status == "failed" {
                throw GenerationError.apiError(status.error ?? "Face enhancement failed")
            }
        }

        try? await GigaRizzAPIClient.shared.cancelGeneration(jobId: jobId)
        throw GenerationError.apiError("Face enhancement timed out")
    }

    /// Vision-based face detection. Returns true when at least one face is found.
    private static func detectsFace(in image: UIImage) async throws -> Bool {
        guard let cgImage = image.cgImage else { return false }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectFaceRectanglesRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    continuation.resume(returning: !(request.results?.isEmpty ?? true))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Generation Error

enum GenerationError: LocalizedError {
    case noSourceImages
    case insufficientPhotos(minimum: Int, provided: Int)
    case apiError(String)
    case cancelled
    case quotaExceeded
    case faceNotDetected

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
        case .faceNotDetected:
            return "We couldn't find a face in this photo. Try a clear front-facing portrait."
        }
    }
}
