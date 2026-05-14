import Foundation
import UIKit
@preconcurrency import Vision

// MARK: - ScreenshotOCRService
//
// On-device Vision OCR for dating-profile / chat screenshots. Returns the
// extracted text in reading order, joined with newlines. Free, fast, and
// keeps user content off the network until the user explicitly asks for
// suggestions.
//
// The Coach API endpoints (/api/v1/coach/openers, /api/v1/coach/reply) take
// a `profileContext` or `theirMessage` string — this service produces those
// inputs from a screenshot the user pastes or imports.

enum ScreenshotOCRService {

    enum OCRError: LocalizedError {
        case imageConversionFailed
        case visionFailure(underlying: Error)
        case noText

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Couldn't read that image."
            case .visionFailure(let e):
                return "Text extraction failed: \(e.localizedDescription)"
            case .noText:
                return "No text found in the screenshot."
            }
        }
    }

    /// Extract text from a UIImage using Vision's `VNRecognizeTextRequest`.
    /// Concurrency-safe: called from any actor; the Vision request runs on
    /// a background queue and resumes the continuation when complete.
    static func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.visionFailure(underlying: error))
                    return
                }
                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                if lines.isEmpty {
                    continuation.resume(throwing: OCRError.noText)
                } else {
                    continuation.resume(returning: lines.joined(separator: "\n"))
                }
            }

            // accurate > fast for dating profiles — text is small and varied.
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.visionFailure(underlying: error))
                }
            }
        }
    }

    /// Best-effort extraction that returns nil instead of throwing — convenient
    /// when callers want to gracefully degrade to a manual paste-text input.
    static func tryExtractText(from image: UIImage) async -> String? {
        do { return try await extractText(from: image) } catch { return nil }
    }
}
