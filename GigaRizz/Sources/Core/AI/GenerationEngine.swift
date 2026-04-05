import Foundation
import UIKit

// MARK: - Generation Engine

/// Core engine for AI photo generation.
/// Coordinates upload, generation, and download pipeline with real-time progress.
@MainActor
@Observable
final class GenerationEngine {
    // MARK: - Singleton

    static let shared = GenerationEngine()

    // MARK: - Published State

    var state: GenerationState = .idle
    var progress: Double = 0
    var errorMessage: String?
    var generatedPhotos: [GeneratedPhoto] = []

    // MARK: - Private Properties

    private let storageManager = StorageManager.shared
    private let apiClient = GigaRizzAPIClient.shared
    private var currentJob: GenerationJob?
    private var cancellationRequested = false

    // MARK: - Constants

    private let maxDimension: CGFloat = 2048
    private let compressionQuality: CGFloat = 0.85
    private let generationTimeoutSeconds: TimeInterval = 90

    // MARK: - Init

    init() {}

    // MARK: - Generate

    /// Full generation pipeline: compress → upload → generate → crop → store.
    func generate(
        sourceImages: [UIImage],
        style: StylePreset,
        userId: String,
        model: AIModel = .default,
        aspectRatios: [AspectRatio] = AspectRatio.allCases,
        photoCount: Int = 4
    ) async throws -> [GeneratedPhoto] {
        guard !sourceImages.isEmpty else {
            throw GenerationPipelineError.noSourcePhotos
        }

        guard sourceImages.count >= 3 else {
            throw GenerationPipelineError.insufficientPhotos(minimum: 3, provided: sourceImages.count)
        }

        cancellationRequested = false
        errorMessage = nil
        generatedPhotos = []
        state = .uploading(progress: 0)
        progress = 0

        let startTime = Date()
        let requestId = UUID().uuidString

        // Step 1: Compress and prepare photos
        let compressed = try sourceImages.map { try compressImage($0) }
        let primaryPhoto = compressed[0]
        let primaryData = primaryPhoto.jpegData(compressionQuality: compressionQuality) ?? Data()
        let allData = compressed.compactMap { $0.jpegData(compressionQuality: compressionQuality) }

        // Step 2: Upload to Firebase Storage
        var uploadedURLs: [URL] = []
        for (index, data) in allData.enumerated() {
            if cancellationRequested { throw GenerationPipelineError.cancelled }

            state = .uploading(progress: Double(index) / Double(allData.count) * 0.3)
            progress = Double(index) / Double(allData.count) * 0.3

            let photoId = "\(requestId)_\(index)"
            let url = try await storageManager.uploadPhoto(
                image: UIImage(data: data) ?? sourceImages[index],
                userId: userId,
                photoId: photoId
            )
            uploadedURLs.append(url)
        }

        guard !cancellationRequested else { throw GenerationPipelineError.cancelled }

        // Step 3: Upload to backend (which calls Replicate)
        state = .uploadingComplete
        progress = 0.3

        let styleParams = StyleParameters.from(preset: style)

        let jobResponse = try await apiClient.submitGeneration(
            style: style.name.lowercased().replacingOccurrences(of: " ", with: "_"),
            prompt: style.prompt,
            model: model.id,
            sourceImageUrl: uploadedURLs.first?.absoluteString
        )

        // Step 4: Poll for completion
        state = .queued
        progress = 0.3

        var jobResult = try await apiClient.checkGeneration(jobId: jobResponse.jobId)
        var attempts = 0
        let maxAttempts = Int(generationTimeoutSeconds)

        while jobResult.status != "completed" && jobResult.status != "failed" {
            if cancellationRequested {
                try? await apiClient.cancelGeneration(jobId: jobResponse.jobId)
                throw GenerationPipelineError.cancelled
            }

            guard attempts < maxAttempts else {
                throw GenerationPipelineError.timeout
            }

            try await Task.sleep(nanoseconds: 1_000_000_000)
            attempts += 1

            jobResult = try await apiClient.checkGeneration(jobId: jobResponse.jobId)

            // Update progress
            let generationProgress = min(0.3 + (Double(attempts) / Double(maxAttempts)) * 0.5, 0.8)
            state = .generating(progress: generationProgress)
            progress = generationProgress

            if jobResult.status == "failed" {
                throw GenerationPipelineError.serverError(jobResult.error ?? "Generation failed")
            }
        }

        guard !cancellationRequested else { throw GenerationPipelineError.cancelled }

        // Step 5: Download generated photos
        state = .downloading(progress: 0)
        progress = 0.8

        var downloadedPhotos: [GeneratedPhoto] = []
        let resultURLs = jobResult.resultUrls

        for (index, urlString) in resultURLs.enumerated() {
            if cancellationRequested { throw GenerationPipelineError.cancelled }

            guard let url = URL(string: urlString) else { continue }

            let photoData = try await storageManager.downloadPhoto(url: url)
            guard let image = UIImage(data: photoData) else { continue }

            // Crop to required aspect ratios
            let crops = cropToAspectRatios(image: image, ratios: aspectRatios)

            for (ratio, croppedImage) in crops {
                let photo = GeneratedPhoto(
                    userId: userId,
                    style: style.name,
                    imageURL: url,
                    thumbnailURL: nil,
                    createdAt: Date(),
                    isFavorite: false
                )
                downloadedPhotos.append(photo)
            }

            progress = 0.8 + (Double(index + 1) / Double(resultURLs.count)) * 0.15
            state = .downloading(progress: progress)
        }

        // Step 6: Finalize
        let duration = Date().timeIntervalSince(startTime)
        generatedPhotos = downloadedPhotos
        state = .completed(photos: downloadedPhotos)
        progress = 1.0

        DesignSystem.Haptics.success()

        return downloadedPhotos
    }

    // MARK: - Cancel

    /// Cancel the current generation job.
    func cancel() {
        cancellationRequested = true
        state = .failed(reason: "Cancelled")
        progress = 0
        DesignSystem.Haptics.light()
    }

    // MARK: - Reset

    /// Reset engine to idle state.
    func reset() {
        state = .idle
        progress = 0
        errorMessage = nil
        generatedPhotos = []
        currentJob = nil
        cancellationRequested = false
    }

    // MARK: - Private Helpers

    private func compressImage(_ image: UIImage) throws -> UIImage {
        let size = image.size

        // If already within bounds, return as-is
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = size.width / size.height
        let newSize: CGSize

        if ratio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func cropToAspectRatios(image: UIImage, ratios: [AspectRatio]) -> [(AspectRatio, UIImage)] {
        var results: [(AspectRatio, UIImage)] = []

        for ratio in ratios {
            let cropRect = ratio.cropRect
            guard let cgImage = image.cgImage else { continue }

            // Calculate scale to get actual pixel rect
            let scale = image.scale
            let scaledRect = CGRect(
                x: cropRect.origin.x * scale,
                y: cropRect.origin.y * scale,
                width: cropRect.width * scale,
                height: cropRect.height * scale
            )

            // Ensure rect is within image bounds
            let clampedRect = scaledRect.intersection(CGRect(origin: .zero, size: image.size))

            if let croppedCGImage = cgImage.cropping(to: clampedRect) {
                let croppedImage = UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
                results.append((ratio, croppedImage))
            }
        }

        // If crop failed, return original for all ratios
        if results.isEmpty {
            return ratios.map { ($0, image) }
        }

        return results
    }
}

// MARK: - Pipeline Error

enum GenerationPipelineError: LocalizedError {
    case noSourcePhotos
    case insufficientPhotos(minimum: Int, provided: Int)
    case uploadFailed
    case serverError(String)
    case timeout
    case cancelled
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .noSourcePhotos:
            return "No source photos provided."
        case .insufficientPhotos(let min, let provided):
            return "Need at least \(min) photos, but only \(provided) provided."
        case .uploadFailed:
            return "Failed to upload photos. Check your connection."
        case .serverError(let message):
            return "Generation failed: \(message)"
        case .timeout:
            return "Generation timed out after 90 seconds."
        case .cancelled:
            return "Generation was cancelled."
        case .downloadFailed:
            return "Failed to download generated photos."
        }
    }
}
