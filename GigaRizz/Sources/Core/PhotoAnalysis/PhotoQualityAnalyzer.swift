import CoreImage
import UIKit
import Vision

// MARK: - Pixel Color

/// Represents a pixel color with RGB components.
private struct PixelColor {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    /// Computed brightness value (0.0 to 1.0).
    var brightness: Double {
        0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
    }
}

// MARK: - Photo Quality Analyzer

/// Analyzes photo quality using Vision framework.
/// Detects blur, faces, and lighting conditions.
enum PhotoQualityAnalyzer {
    // MARK: - Constants

    /// Minimum face bounding box area ratio (face area / image area).
    private static let minimumFaceAreaRatio: Float = 0.02

    /// Maximum acceptable Laplacian variance for blur detection.
    private static let blurThreshold: Double = 100.0

    /// Minimum average brightness for acceptable lighting.
    private static let minimumBrightness: Double = 0.25

    /// Maximum brightness for detecting over-exposure.
    private static let maximumBrightness: Double = 0.95

    // MARK: - Analysis

    /// Analyzes a single image and returns detected quality issues.
    /// - Parameter image: The UIImage to analyze.
    /// - Returns: An array of detected PhotoQualityIssue values.
    static func analyze(image: UIImage) async -> [PhotoQualityIssue] {
        guard let cgImage = image.cgImage else { return [] }

        var issues: [PhotoQualityIssue] = []

        // Run all checks in parallel for performance
        async let brightnessIssue = checkBrightness(cgImage: cgImage)
        async let blurIssue = checkBlur(cgImage: cgImage)
        async let faceIssues = checkFaces(cgImage: cgImage)

        let (brightnessResult, blurResult, faceResults) = await (brightnessIssue, blurIssue, faceIssues)

        if let brightnessIssue = brightnessResult {
            issues.append(brightnessIssue)
        }

        if let blurIssue = blurResult {
            issues.append(blurIssue)
        }

        issues.append(contentsOf: faceResults)

        return issues
    }

    // MARK: - Brightness Check

    /// Checks image brightness to detect too-dark or over-exposed photos.
    private static func checkBrightness(cgImage: CGImage) async -> PhotoQualityIssue? {
        let ciImage = CIImage(cgImage: cgImage)

        let extent = ciImage.extent
        var totalBrightness: Double = 0
        var pixelCount: Double = 0

        // Sample a grid of pixels for brightness
        let sampleSize = 50
        let widthStep = max(1, Int(extent.width) / sampleSize)
        let heightStep = max(1, Int(extent.height) / sampleSize)

        for pixelX in stride(from: 0, to: Int(extent.width), by: widthStep) {
            for pixelY in stride(from: 0, to: Int(extent.height), by: heightStep) {
                let pixel = cgImage.getPixelColor(pixelX: pixelX, pixelY: pixelY)
                let brightness = pixel.brightness
                totalBrightness += brightness
                pixelCount += 1
            }
        }

        let averageBrightness = totalBrightness / pixelCount

        if averageBrightness < minimumBrightness {
            return .tooDark
        } else if averageBrightness > maximumBrightness {
            return .poorLighting
        }

        return nil
    }

    // MARK: - Blur Check (Laplacian Variance)

    /// Detects blur using Laplacian variance method.
    /// Higher variance = sharper image. Low variance = blurry.
    private static func checkBlur(cgImage: CGImage) async -> PhotoQualityIssue? {
        let ciImage = CIImage(cgImage: cgImage)

        // Apply Laplacian filter to detect edges
        guard let filter = CIFilter(name: "CILaplacian") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else { return nil }

        // Calculate variance of the Laplacian output
        var totalVariance: Double = 0
        var pixelCount: Double = 0

        let extent = outputImage.extent
        let sampleSize = 30
        let widthStep = max(1, Int(extent.width) / sampleSize)
        let heightStep = max(1, Int(extent.height) / sampleSize)

        // Create a context to render the CIImage
        let context = CIContext()
        var sampledValues: [Double] = []

        for pixelX in stride(from: 0, to: Int(extent.width), by: widthStep) {
            for pixelY in stride(from: 0, to: Int(extent.height), by: heightStep) {
                if let pixel = context.extractPixelColor(from: outputImage, pixelX: pixelX, pixelY: pixelY) {
                    let gray = pixel.brightness
                    sampledValues.append(gray)
                    totalVariance += gray
                    pixelCount += 1
                }
            }
        }

        guard pixelCount > 0 else { return .blurry }

        let mean = totalVariance / pixelCount

        // Calculate variance
        var variance: Double = 0
        for value in sampledValues {
            variance += (value - mean) * (value - mean)
        }
        variance /= pixelCount

        // Laplacian variance threshold
        if variance < blurThreshold {
            return .blurry
        }

        return nil
    }

    // MARK: - Face Detection

    /// Detects faces and checks if they meet minimum size requirements.
    private static func checkFaces(cgImage: CGImage) async -> [PhotoQualityIssue] {
        var issues: [PhotoQualityIssue] = []

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])

            guard let results = request.results else { return issues }

            let imageArea = Float(cgImage.width) * Float(cgImage.height)

            for observation in results {
                let faceArea = Float(observation.boundingBox.width) * Float(observation.boundingBox.height)
                let faceAreaRatio = faceArea / imageArea

                if faceAreaRatio < minimumFaceAreaRatio {
                    issues.append(.faceTooSmall)
                    break
                }
            }
        } catch {
            // Face detection failed, no face issues to report
        }

        return issues
    }
}

// MARK: - CGImage Pixel Color Extension

private extension CGImage {
    /// Gets the color of a specific pixel.
    func getPixelColor(pixelX: Int, pixelY: Int) -> PixelColor {
        guard let dataProvider = dataProvider,
              let data = dataProvider.data,
              let pointer = CFDataGetBytePtr(data) else {
            return PixelColor(red: 0, green: 0, blue: 0)
        }

        let bytesPerPixel = bitsPerPixel / 8
        let bytesPerRow = bytesPerRow
        let pixelOffset = pixelY * bytesPerRow + pixelX * bytesPerPixel

        let red = CGFloat(pointer[pixelOffset]) / 255.0
        let green = CGFloat(pointer[pixelOffset + 1]) / 255.0
        let blue = CGFloat(pointer[pixelOffset + 2]) / 255.0

        return PixelColor(red: red, green: green, blue: blue)
    }
}

// MARK: - CIContext Pixel Color Extension

private extension CIContext {
    /// Extracts a single pixel color from a CIImage at the given coordinates.
    func extractPixelColor(from image: CIImage, pixelX: Int, pixelY: Int) -> PixelColor? {
        let extent = image.extent

        var pixel = [UInt8](repeating: 0, count: 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

        guard let cgImage = createCGImage(image, from: extent) else { return nil }

        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return PixelColor(
            red: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0
        )
    }
}
