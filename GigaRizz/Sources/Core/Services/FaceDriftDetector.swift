import CoreImage
import UIKit
import Vision

// MARK: - FaceDriftDetector
//
// Companion to IdentityMatchService. Where IdentityMatchService gives a single
// scalar similarity score, FaceDriftDetector returns a list of *named* drift
// signals — the specific ways the generated photo has drifted from the user's
// reference face. These are the signals that cause Hinge Selfie Verification
// and Tinder Face Check to fail.
//
// All work happens on-device using Vision framework.
//
// Signals detected:
//   - oversmoothing      — candidate skin variance is too low vs reference
//   - eyeWidening        — eye-to-eye distance / face width grew significantly
//   - jawNarrowing       — jaw width / face width shrank significantly
//   - brightnessShift    — mean brightness changed by > threshold
//   - faceSizeShift      — face area ratio changed by > threshold (re-cropping detected)
//   - mouthOpenChange    — mouth opening differs significantly (smile-added signal)

@MainActor
enum FaceDriftDetector {

    // MARK: - Tunables

    /// Skin variance ratio below which we flag oversmoothing.
    private static let oversmoothingRatio: Double = 0.35

    /// Eye-distance ratio shift that triggers eyeWidening.
    private static let eyeWidenThreshold: Double = 1.12

    /// Jaw-width ratio shift that triggers jawNarrowing.
    private static let jawNarrowThreshold: Double = 0.88

    /// Absolute mean-brightness delta for the brightnessShift signal.
    private static let brightnessDeltaThreshold: Double = 0.18

    /// Face area ratio delta for faceSizeShift.
    private static let faceSizeRatioDelta: Double = 0.30

    /// Mouth opening ratio delta for mouthOpenChange.
    private static let mouthOpenDelta: Double = 0.12

    /// Skin variance ratio above which we suspect added age texture.
    private static let agingTextureUpperRatio: Double = 1.5

    /// Combined-signal aging threshold (lower variance bump + face darkening).
    private static let agingTextureSoftRatio: Double = 1.2

    /// Face brightness drop that, paired with extra texture, suggests an
    /// aged-looking output. Sway AI's #1 complaint cluster.
    private static let agingDarkenThreshold: Double = 0.15

    // MARK: - Signal

    enum Signal: String, Equatable, Identifiable {
        case oversmoothing
        case eyeWidening
        case jawNarrowing
        case brightnessShift
        case faceSizeShift
        case mouthOpenChange
        // V3 Sprint 5 — Age-Faithful Lock. Composite of skin texture amplification
        // + face darkening. Direct counter to Sway AI's "looks older than actual
        // age" complaint cluster.
        case apparentAgeShift

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .oversmoothing: return "Over-smoothed skin"
            case .eyeWidening: return "Eyes widened"
            case .jawNarrowing: return "Jaw narrowed"
            case .brightnessShift: return "Brightness shifted"
            case .faceSizeShift: return "Face framing changed"
            case .mouthOpenChange: return "Mouth shape changed"
            case .apparentAgeShift: return "Looks older than your reference"
            }
        }

        var explanation: String {
            switch self {
            case .oversmoothing:
                return "Skin texture looks unnaturally smooth. Hinge and Tinder verification flag heavily retouched skin."
            case .eyeWidening:
                return "Eyes look wider than your reference photo. Face Check models trained against this exact artifact."
            case .jawNarrowing:
                return "Jaw looks narrower than your reference. Common identity-drift signal."
            case .brightnessShift:
                return "Lighting on the face changed significantly — verification may not recognize you."
            case .faceSizeShift:
                return "Your face is framed differently. Re-crop or regenerate to match your reference framing."
            case .mouthOpenChange:
                return "Mouth shape changed (e.g. smile added). Some verification models flag this."
            case .apparentAgeShift:
                return "Skin texture and lighting added perceived age. Most common AI photo complaint — re-roll at lower naturalness intensity."
            }
        }

        var iconName: String {
            switch self {
            case .oversmoothing: return "drop.fill"
            case .eyeWidening: return "eye.fill"
            case .jawNarrowing: return "person.crop.rectangle.fill"
            case .brightnessShift: return "sun.max.fill"
            case .faceSizeShift: return "rectangle.dashed"
            case .mouthOpenChange: return "mouth.fill"
            case .apparentAgeShift: return "hourglass"
            }
        }
    }

    // MARK: - Report

    struct Report: Equatable {
        let signals: [Signal]
        let oversmoothingRatio: Double?
        let eyeRatioDelta: Double?
        let jawRatioDelta: Double?
        let brightnessDelta: Double?
        let faceSizeDelta: Double?
        let mouthOpenDelta: Double?

        static let empty = Report(
            signals: [],
            oversmoothingRatio: nil,
            eyeRatioDelta: nil,
            jawRatioDelta: nil,
            brightnessDelta: nil,
            faceSizeDelta: nil,
            mouthOpenDelta: nil
        )
    }

    // MARK: - Public

    /// Compare candidate against reference and return any detected drift signals.
    /// Designed to never throw — if Vision fails to find one of the inputs, the
    /// detector returns whatever signals it could compute.
    static func detect(candidate: UIImage, reference: UIImage) async -> Report {
        guard let candidateCG = candidate.cgImage, let referenceCG = reference.cgImage else {
            return .empty
        }

        async let candidateMetrics = computeMetrics(for: candidateCG)
        async let referenceMetrics = computeMetrics(for: referenceCG)

        let (cand, ref) = await (candidateMetrics, referenceMetrics)
        guard let cand, let ref else { return .empty }

        var signals: [Signal] = []
        var oversmoothing: Double?
        var eyeDelta: Double?
        var jawDelta: Double?
        var brightDelta: Double?
        var sizeDelta: Double?
        var mouthDelta: Double?

        // Oversmoothing — candidate skin variance / reference
        if let candVar = cand.skinVariance, let refVar = ref.skinVariance, refVar > 0 {
            let ratio = candVar / refVar
            oversmoothing = ratio
            if ratio < oversmoothingRatio {
                signals.append(.oversmoothing)
            }
        }

        // Eye widening — eye distance / face width
        if let candRatio = cand.eyeFaceRatio, let refRatio = ref.eyeFaceRatio, refRatio > 0 {
            let delta = candRatio / refRatio
            eyeDelta = delta
            if delta > eyeWidenThreshold {
                signals.append(.eyeWidening)
            }
        }

        // Jaw narrowing
        if let candRatio = cand.jawFaceRatio, let refRatio = ref.jawFaceRatio, refRatio > 0 {
            let delta = candRatio / refRatio
            jawDelta = delta
            if delta < jawNarrowThreshold {
                signals.append(.jawNarrowing)
            }
        }

        // Brightness shift
        if let candBright = cand.faceBrightness, let refBright = ref.faceBrightness {
            let delta = abs(candBright - refBright)
            brightDelta = delta
            if delta > brightnessDeltaThreshold {
                signals.append(.brightnessShift)
            }
        }

        // Face size shift
        if let candArea = cand.faceAreaRatio, let refArea = ref.faceAreaRatio, refArea > 0 {
            let delta = abs(candArea - refArea) / refArea
            sizeDelta = delta
            if delta > faceSizeRatioDelta {
                signals.append(.faceSizeShift)
            }
        }

        // Mouth opening change — useful for catching smile-add artifacts.
        if let candOpen = cand.mouthOpenRatio, let refOpen = ref.mouthOpenRatio {
            let delta = abs(candOpen - refOpen)
            mouthDelta = delta
            if delta > mouthOpenDelta {
                signals.append(.mouthOpenChange)
            }
        }

        // Apparent-age shift (Sway AI counter). Skin variance ratio above 1.5
        // means the candidate carries significantly more wrinkle/line detail
        // than the reference — a near-perfect proxy for "looks older." A
        // softer ratio bump combined with face darkening also triggers it,
        // because the dating-photo failure mode is "more wrinkles + heavier
        // shadows" rather than either alone.
        if let ratio = oversmoothing {
            let darkening: Double = {
                guard let candBright = cand.faceBrightness, let refBright = ref.faceBrightness else { return 0 }
                return refBright - candBright
            }()
            let hardSignal = ratio > agingTextureUpperRatio
            let softSignal = ratio > agingTextureSoftRatio && darkening > agingDarkenThreshold
            if hardSignal || softSignal {
                signals.append(.apparentAgeShift)
            }
        }

        return Report(
            signals: signals,
            oversmoothingRatio: oversmoothing,
            eyeRatioDelta: eyeDelta,
            jawRatioDelta: jawDelta,
            brightnessDelta: brightDelta,
            faceSizeDelta: sizeDelta,
            mouthOpenDelta: mouthDelta
        )
    }

    // MARK: - Metrics

    private struct Metrics {
        let faceBox: CGRect            // normalized
        let faceBrightness: Double?
        let faceAreaRatio: Double?     // face area / image area
        let skinVariance: Double?      // Laplacian variance on cheek region
        let eyeFaceRatio: Double?      // eye distance / face width
        let jawFaceRatio: Double?      // jaw width / face width
        let mouthOpenRatio: Double?    // mouth opening / face height
    }

    private static func computeMetrics(for cgImage: CGImage) async -> Metrics? {
        let landmarksRequest = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do { try handler.perform([landmarksRequest]) } catch { return nil }
        guard let face = (landmarksRequest.results)?.max(by: { $0.boundingBox.area < $1.boundingBox.area }) else {
            return nil
        }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)
        let faceArea = face.boundingBox.width * face.boundingBox.height
        let faceAreaRatio = Double(faceArea)

        let pixelFace = CGRect(
            x: face.boundingBox.origin.x * imgW,
            y: (1.0 - face.boundingBox.origin.y - face.boundingBox.height) * imgH,
            width: face.boundingBox.width * imgW,
            height: face.boundingBox.height * imgH
        )

        let brightness = computeBrightness(cgImage: cgImage, region: pixelFace)
        let variance = computeSkinVariance(cgImage: cgImage, faceRect: pixelFace)

        // Eye and jaw ratios from landmarks
        var eyeRatio: Double?
        var jawRatio: Double?
        var mouthOpen: Double?

        if let landmarks = face.landmarks {
            let faceWidth = face.boundingBox.width
            let faceHeight = face.boundingBox.height

            if let left = landmarks.leftEye, let right = landmarks.rightEye,
               let leftCentroid = centroid(of: left, in: face.boundingBox),
               let rightCentroid = centroid(of: right, in: face.boundingBox) {
                let eyeDistance = abs(rightCentroid.x - leftCentroid.x)
                if faceWidth > 0 {
                    eyeRatio = Double(eyeDistance / faceWidth)
                }
            }

            if let contour = landmarks.faceContour {
                let points = contour.normalizedPoints
                if !points.isEmpty {
                    let xs = points.map { $0.x }
                    if let minX = xs.min(), let maxX = xs.max() {
                        let jawWidth = maxX - minX
                        if faceWidth > 0 {
                            jawRatio = Double(jawWidth / faceWidth) * Double(face.boundingBox.width)
                        }
                    }
                }
            }

            if let outer = landmarks.outerLips, let inner = landmarks.innerLips,
               let outerC = centroid(of: outer, in: face.boundingBox),
               let innerC = centroid(of: inner, in: face.boundingBox) {
                // Mouth openness as inner-vs-outer vertical extent
                _ = outerC; _ = innerC
                let outerPoints = outer.normalizedPoints
                let innerPoints = inner.normalizedPoints
                let outerYs = outerPoints.map { $0.y }
                let innerYs = innerPoints.map { $0.y }
                if let outerMin = outerYs.min(), let outerMax = outerYs.max(),
                   let innerMin = innerYs.min(), let innerMax = innerYs.max() {
                    let outerHeight = outerMax - outerMin
                    let innerHeight = innerMax - innerMin
                    if outerHeight > 0, faceHeight > 0 {
                        mouthOpen = Double((innerHeight / outerHeight))
                    }
                }
            }
        }

        return Metrics(
            faceBox: face.boundingBox,
            faceBrightness: brightness,
            faceAreaRatio: faceAreaRatio,
            skinVariance: variance,
            eyeFaceRatio: eyeRatio,
            jawFaceRatio: jawRatio,
            mouthOpenRatio: mouthOpen
        )
    }

    private static func centroid(of region: VNFaceLandmarkRegion2D, in faceBoundingBox: CGRect) -> CGPoint? {
        let points = region.normalizedPoints
        guard !points.isEmpty else { return nil }
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        return CGPoint(x: xs.reduce(0, +) / CGFloat(xs.count), y: ys.reduce(0, +) / CGFloat(ys.count))
    }

    // MARK: - Pixel sampling

    private static func computeBrightness(cgImage: CGImage, region: CGRect) -> Double? {
        let clamped = region.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard clamped.width > 4, clamped.height > 4 else { return nil }
        guard let cropped = cgImage.cropping(to: clamped) else { return nil }

        let context = CIContext()
        let ci = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ci.extent), forKey: "inputExtent")
        guard let output = filter.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    private static func computeSkinVariance(cgImage: CGImage, faceRect: CGRect) -> Double? {
        // Sample a cheek region: middle-vertical, left+right thirds horizontally.
        // Heuristic but cheap. Apply Laplacian and measure variance.
        let cheekHeight = faceRect.height * 0.25
        let cheekY = faceRect.midY - cheekHeight * 0.25
        let cheekWidth = faceRect.width * 0.20
        let leftCheek = CGRect(x: faceRect.minX + faceRect.width * 0.15, y: cheekY, width: cheekWidth, height: cheekHeight)
        let rightCheek = CGRect(x: faceRect.maxX - faceRect.width * 0.15 - cheekWidth, y: cheekY, width: cheekWidth, height: cheekHeight)

        let v1 = laplacianVariance(cgImage: cgImage, region: leftCheek)
        let v2 = laplacianVariance(cgImage: cgImage, region: rightCheek)
        guard let a = v1, let b = v2 else { return v1 ?? v2 }
        return (a + b) / 2.0
    }

    private static func laplacianVariance(cgImage: CGImage, region: CGRect) -> Double? {
        let clamped = region.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard clamped.width > 8, clamped.height > 8 else { return nil }
        guard let cropped = cgImage.cropping(to: clamped) else { return nil }

        let ci = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CILaplacian") else { return nil }
        filter.setValue(ci, forKey: kCIInputImageKey)
        guard let output = filter.outputImage else { return nil }

        let extent = output.extent
        let sampleSize = 20
        let widthStep = max(1, Int(extent.width) / sampleSize)
        let heightStep = max(1, Int(extent.height) / sampleSize)

        let context = CIContext()
        var samples: [Double] = []

        for x in stride(from: 0, to: Int(extent.width), by: widthStep) {
            for y in stride(from: 0, to: Int(extent.height), by: heightStep) {
                var pixel = [UInt8](repeating: 0, count: 4)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.render(output, toBitmap: &pixel, rowBytes: 4, bounds: rect, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
                let r = Double(pixel[0]) / 255.0
                let g = Double(pixel[1]) / 255.0
                let b = Double(pixel[2]) / 255.0
                samples.append(0.299 * r + 0.587 * g + 0.114 * b)
            }
        }

        guard samples.count > 1 else { return nil }
        let mean = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(samples.count)
        return variance * 1000.0 // scale to a comparable magnitude
    }
}

private extension CGRect {
    var area: CGFloat { width * height }
}
