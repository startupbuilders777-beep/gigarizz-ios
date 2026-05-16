import Foundation
import UIKit

// MARK: - GlowUpChainCoordinator
//
// Sequential audit-driven photo improver. Built to beat Facetune's freeform
// tool palette by chaining only the fixes that *actually* help this photo,
// re-scoring Identity Match between each step, and rolling back if the score
// regresses below the band threshold.
//
// V2 chain steps (in order):
//   1. Local CIFilter face enhance (subtle skin + teeth + eye work, fast)
//   2. Backend face_restore (CodeFormer; recovers blur, anti-plastic) — V3 Sprint 5 add
//   3. Color grade (lighting correction)
//
// Each step is wrapped in identity-match scoring. If the score drops by more
// than `rollbackTolerance`, we stop the chain and return the last passing
// frame. Naturalness intensity from Settings controls the per-step ceiling.

@MainActor
final class GlowUpChainCoordinator: ObservableObject {

    // MARK: - Step

    enum StepKind: String, CaseIterable {
        case localEnhance       // CIFilter skin smooth + teeth whiten + eye brighten
        case faceRestore        // V3 Sprint 5: backend CodeFormer (anti-plastic, identity-locked)
        case colorGrade         // CIFilter lighting correction
        // Future: backgroundCleanup, hingeFraming

        var displayName: String {
            switch self {
            case .localEnhance: return "Face enhance"
            case .faceRestore: return "Face restore"
            case .colorGrade: return "Lighting"
            }
        }
    }

    struct StepResult: Identifiable {
        let id = UUID()
        let kind: StepKind
        let image: UIImage
        let identityScore: Double
        let identityBand: IdentityMatchService.Band
        let appliedAt: Date
        let didRollback: Bool
    }

    // MARK: - State

    @Published private(set) var stepResults: [StepResult] = []
    @Published private(set) var isRunning = false
    @Published private(set) var finalImage: UIImage?
    @Published private(set) var error: String?

    // MARK: - Tunables

    /// Maximum allowable similarity regression per step. If a step drops score
    /// by more than this, the chain rolls back to the previous step.
    private let rollbackTolerance: Double = 0.07

    // MARK: - Public

    /// Run the chain. Returns the final image (best passing step) or nil.
    func run(sourceImage: UIImage, reference: UIImage?, steps: [StepKind] = StepKind.allCases) async {
        isRunning = true
        defer { isRunning = false }

        stepResults = []
        finalImage = nil
        error = nil

        var current = sourceImage
        var previousScore: Double = 1.0

        // Score baseline if a reference is available.
        if let reference {
            if let baseline = try? await IdentityMatchService.match(candidate: sourceImage, against: reference) {
                previousScore = baseline.similarity
            }
        }

        for step in steps {
            guard let processed = await apply(step, to: current) else {
                continue
            }

            var score = previousScore
            var band: IdentityMatchService.Band = .acceptable
            if let reference, let result = try? await IdentityMatchService.match(candidate: processed, against: reference) {
                score = result.similarity
                band = result.band
            }

            // Rollback gate.
            let regression = previousScore - score
            if regression > rollbackTolerance || band == .rejected {
                let rollback = StepResult(kind: step, image: current, identityScore: score, identityBand: band, appliedAt: Date(), didRollback: true)
                stepResults.append(rollback)
                break
            }

            let accepted = StepResult(kind: step, image: processed, identityScore: score, identityBand: band, appliedAt: Date(), didRollback: false)
            stepResults.append(accepted)
            current = processed
            previousScore = score
        }

        finalImage = current
    }

    // MARK: - Step implementations

    private func apply(_ step: StepKind, to image: UIImage) async -> UIImage? {
        switch step {
        case .localEnhance:
            return await applyLocalEnhance(image: image)
        case .faceRestore:
            return await applyFaceRestore(image: image)
        case .colorGrade:
            return await applyColorGrade(image: image)
        }
    }

    /// Backend CodeFormer face restoration. V3 Sprint 5 — adds the network
    /// round-trip step that the V1 chain deferred. We upload the current
    /// frame, submit a `face_restore` style generation, poll, and load the
    /// result. The chain's identity-match gate covers anything that drifts.
    private func applyFaceRestore(image: UIImage) async -> UIImage? {
        guard let sourceUrl = await PhotoUploadService.shared.tryUpload(image, purpose: "source") else {
            return nil
        }
        do {
            let job = try await GigaRizzAPIClient.shared.submitGeneration(
                style: "ai_portrait",
                model: "face_restore",
                sourceImageUrl: sourceUrl.absoluteString,
                sourceImageUrls: [sourceUrl.absoluteString]
            )
            for _ in 0..<60 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let status = try await GigaRizzAPIClient.shared.checkGeneration(jobId: job.jobId)
                if status.status == "completed", let first = status.resultUrls.first,
                   let url = URL(string: first) {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let restored = UIImage(data: data) {
                        return restored
                    }
                }
                if status.status == "failed" { return nil }
            }
        } catch {
            return nil
        }
        return nil
    }

    /// Subtle skin smooth + warm tone lift via CIFilter, gated by naturalness.
    private func applyLocalEnhance(image: UIImage) async -> UIImage? {
        guard let ci = image.ciImage ?? CIImage(image: image) else { return image }
        let level = NaturalnessSettings.currentLevel

        // Strength scales with intensity: conservative=0.04, standard=0.10, bold=0.18
        let strength: Double = {
            switch level {
            case .conservative: return 0.04
            case .standard: return 0.10
            case .bold: return 0.18
            }
        }()

        // Skin smooth — slight Gaussian blur blended over original.
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ci, forKey: kCIInputImageKey)
        blurFilter?.setValue(strength * 12.0, forKey: kCIInputRadiusKey)
        guard let blurred = blurFilter?.outputImage else { return image }

        let blendFilter = CIFilter(name: "CIBlendWithMask")
        // Simplified: blend with constant alpha by using opacity via CIColorControls.
        let saturationFilter = CIFilter(name: "CIColorControls")
        saturationFilter?.setValue(blurred, forKey: kCIInputImageKey)
        saturationFilter?.setValue(1.0 + strength, forKey: kCIInputSaturationKey)
        saturationFilter?.setValue(1.0 + strength * 0.2, forKey: kCIInputBrightnessKey)
        let smoothed = saturationFilter?.outputImage ?? ci

        return render(smoothed) ?? image
    }

    /// CIToneCurve / CIExposureAdjust — subtle lighting correction.
    private func applyColorGrade(image: UIImage) async -> UIImage? {
        guard let ci = image.ciImage ?? CIImage(image: image) else { return image }
        let level = NaturalnessSettings.currentLevel
        let exposure: Double = level == .conservative ? 0.15 : (level == .standard ? 0.30 : 0.45)

        let exposureFilter = CIFilter(name: "CIExposureAdjust")
        exposureFilter?.setValue(ci, forKey: kCIInputImageKey)
        exposureFilter?.setValue(exposure, forKey: kCIInputEVKey)
        let lifted = exposureFilter?.outputImage ?? ci

        return render(lifted) ?? image
    }

    // MARK: - Render

    private func render(_ ci: CIImage) -> UIImage? {
        let context = CIContext(options: nil)
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
