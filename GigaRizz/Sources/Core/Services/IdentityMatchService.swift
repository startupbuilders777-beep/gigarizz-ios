import CoreImage
import UIKit
import Vision

// MARK: - IdentityMatchService
//
// On-device face-similarity scorer used to gate generated photos against the
// V2 "Keep me looking like me" trust contract. Every generated image can be
// scored against the user's reference selfie; outputs below the threshold
// are flagged in the gallery and (in stricter modes) hidden entirely.
//
// Pipeline:
//   1. Detect the largest face in both candidate and reference image.
//   2. Crop each image to its face bounding box (with padding).
//   3. Generate a VNFeaturePrintObservation for each crop.
//   4. Compute Vision's feature-print distance.
//   5. Map distance to a 0–1 similarity score with band thresholds.
//
// All work happens on-device. Nothing leaves the user's phone.

enum IdentityMatchService {

    // MARK: - Tunables

    /// Face crop padding as a fraction of the face bounding box (each side).
    private static let cropPadding: CGFloat = 0.25

    /// Minimum face area ratio (face area / image area) to consider valid.
    private static let minFaceAreaRatio: Float = 0.005

    /// Distance below which a candidate is considered an excellent match (≥0.85).
    private static let distanceExcellent: Float = 0.55

    /// Distance below which a candidate is considered an acceptable match (≥0.70).
    private static let distanceAcceptable: Float = 0.85

    /// Distance below which a candidate is considered a borderline match (≥0.55).
    private static let distanceBorderline: Float = 1.20

    // MARK: - Result Type

    /// A scored similarity result.
    struct MatchResult: Equatable {
        /// Raw Vision feature-print distance. Lower = more similar.
        let rawDistance: Float
        /// Normalized similarity in [0, 1]. 1 = identical face crop.
        let similarity: Double
        /// Categorical band derived from `similarity`.
        let band: Band

        var passedDefault: Bool { band != .rejected }
    }

    enum Band: String, Equatable {
        case excellent  // ≥ 0.85 — visually identical
        case acceptable // 0.70–0.85 — clearly the same person
        case borderline // 0.55–0.70 — recognizable but drifting
        case rejected   // < 0.55 — does not look like the user

        var displayName: String {
            switch self {
            case .excellent: return "Identity Match: Excellent"
            case .acceptable: return "Identity Match: Passed"
            case .borderline: return "Identity Match: Borderline"
            case .rejected: return "Identity Match: Failed"
            }
        }

        var shortLabel: String {
            switch self {
            case .excellent: return "Looks like you"
            case .acceptable: return "Looks like you"
            case .borderline: return "Slightly off"
            case .rejected: return "Doesn't look like you"
            }
        }

        var iconName: String {
            switch self {
            case .excellent, .acceptable: return "checkmark.seal.fill"
            case .borderline: return "exclamationmark.triangle.fill"
            case .rejected: return "xmark.octagon.fill"
            }
        }
    }

    // MARK: - Errors

    enum MatchError: LocalizedError {
        case noFaceInReference
        case noFaceInCandidate
        case visionFailed(Error)

        var errorDescription: String? {
            switch self {
            case .noFaceInReference: return "Reference selfie has no detectable face."
            case .noFaceInCandidate: return "Generated photo has no detectable face."
            case .visionFailed(let underlying): return underlying.localizedDescription
            }
        }
    }

    // MARK: - Public API

    /// Compare two images and return the identity-match result.
    /// - Parameters:
    ///   - candidate: the generated or edited photo to evaluate.
    ///   - reference: the user's baseline selfie.
    static func match(candidate: UIImage, against reference: UIImage) async throws -> MatchResult {
        guard let candidateCG = candidate.cgImage else { throw MatchError.noFaceInCandidate }
        guard let referenceCG = reference.cgImage else { throw MatchError.noFaceInReference }

        // Vision work is wrapped in a detached task so the non-Sendable
        // VNFeaturePrintObservation values never cross actor isolation.
        // The distance is the only value that escapes — Float is Sendable.
        let distance: Float = try await Task.detached(priority: .userInitiated) {
            let candObs = try featurePrint(for: candidateCG, role: .candidate)
            let refObs = try featurePrint(for: referenceCG, role: .reference)
            var d: Float = 0
            do {
                try candObs.computeDistance(&d, to: refObs)
            } catch {
                throw MatchError.visionFailed(error)
            }
            return d
        }.value

        let similarity = similarityFromDistance(distance)
        return MatchResult(
            rawDistance: distance,
            similarity: similarity,
            band: bandFor(similarity: similarity)
        )
    }

    /// Convenience for batch scoring (used by the generation result grid).
    static func matchAll(candidates: [UIImage], against reference: UIImage) async -> [Result<MatchResult, Error>] {
        await withTaskGroup(of: (Int, Result<MatchResult, Error>).self) { group in
            for (idx, image) in candidates.enumerated() {
                group.addTask {
                    do {
                        let result = try await match(candidate: image, against: reference)
                        return (idx, .success(result))
                    } catch {
                        return (idx, .failure(error))
                    }
                }
            }
            var results: [(Int, Result<MatchResult, Error>)] = []
            for await pair in group { results.append(pair) }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // MARK: - Internals

    private enum Role { case candidate, reference }

    /// Synchronous worker — must run inside the detached task in `match` so the
    /// non-Sendable observation never escapes a single isolation domain.
    private static func featurePrint(for cgImage: CGImage, role: Role) throws -> VNFeaturePrintObservation {
        // Step 1 — detect face
        let faceRequest = VNDetectFaceRectanglesRequest()
        let faceHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do { try faceHandler.perform([faceRequest]) }
        catch { throw MatchError.visionFailed(error) }

        guard let face = largestFace(in: faceRequest.results, imageSize: CGSize(width: cgImage.width, height: cgImage.height)) else {
            throw role == .reference ? MatchError.noFaceInReference : MatchError.noFaceInCandidate
        }

        // Step 2 — crop face with padding
        let croppedCG = cropFace(cgImage: cgImage, normalizedRect: face)

        // Step 3 — generate feature print
        let printRequest = VNGenerateImageFeaturePrintRequest()
        printRequest.imageCropAndScaleOption = .scaleFill
        let printHandler = VNImageRequestHandler(cgImage: croppedCG, options: [:])
        do { try printHandler.perform([printRequest]) }
        catch { throw MatchError.visionFailed(error) }

        guard let observation = printRequest.results?.first as? VNFeaturePrintObservation else {
            throw MatchError.visionFailed(NSError(domain: "IdentityMatchService", code: -1))
        }
        return observation
    }

    private static func largestFace(in observations: [VNFaceObservation]?, imageSize: CGSize) -> CGRect? {
        guard let observations, !observations.isEmpty else { return nil }
        let area = imageSize.width * imageSize.height
        let valid = observations.filter { obs in
            let face = CGFloat(obs.boundingBox.width) * CGFloat(obs.boundingBox.height) * area
            return Float(face / area) >= minFaceAreaRatio
        }
        let pool = valid.isEmpty ? observations : valid
        return pool.max(by: { $0.boundingBox.area < $1.boundingBox.area })?.boundingBox
    }

    private static func cropFace(cgImage: CGImage, normalizedRect: CGRect) -> CGImage {
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)

        // Vision's normalized rect uses bottom-left origin; CG uses top-left.
        let pixelRect = CGRect(
            x: normalizedRect.origin.x * imgWidth,
            y: (1.0 - normalizedRect.origin.y - normalizedRect.height) * imgHeight,
            width: normalizedRect.width * imgWidth,
            height: normalizedRect.height * imgHeight
        )

        let padX = pixelRect.width * cropPadding
        let padY = pixelRect.height * cropPadding
        let padded = pixelRect.insetBy(dx: -padX, dy: -padY)
        let clamped = padded.intersection(CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight))

        return cgImage.cropping(to: clamped) ?? cgImage
    }

    /// Convert Vision feature-print distance to a 0–1 similarity score.
    /// Mapping is monotonically decreasing and tuned against face-crop test data.
    private static func similarityFromDistance(_ distance: Float) -> Double {
        let d = max(0, distance)
        // Sigmoid-like mapping: 0 → 1.0, 0.55 → 0.85, 0.85 → 0.70, 1.20 → 0.55, 2.0 → ~0.20
        let similarity = 1.0 / (1.0 + Double(d * d) * 0.55)
        return min(1.0, max(0.0, similarity))
    }

    private static func bandFor(similarity: Double) -> Band {
        switch similarity {
        case 0.85...: return .excellent
        case 0.70..<0.85: return .acceptable
        case 0.55..<0.70: return .borderline
        default: return .rejected
        }
    }
}

// MARK: - Helpers

private extension CGRect {
    var area: CGFloat { width * height }
}
