import Foundation
import SwiftUI
import UIKit

// MARK: - Share Service

/// Handles shareable content composition: photo + optional caption + optional watermark.
@MainActor
final class ShareService: ObservableObject {
    // MARK: - Singleton

    static let shared = ShareService()

    // MARK: - Published State

    @Published var isProcessing: Bool = false
    @Published var processedImage: UIImage?
    @Published var shareError: ShareError?

    // MARK: - Dependencies

    private let analytics = PostHogManager.shared

    // MARK: - Static Share Helper

    /// Quick share an image without watermark processing.
    static func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    /// Quick share with caption.
    static func shareImage(_ image: UIImage, caption: String?) {
        var items: [Any] = [image]
        if let caption {
            items.append(caption)
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    // MARK: - Share Items

    /// Prepares shareable items for UIActivityViewController.
    func prepareShareItems(
        image: UIImage,
        configuration: ShareConfiguration
    ) async -> [Any] {
        isProcessing = true
        shareError = nil

        // Process image (add watermark if needed)
        let processed = await processImage(image: image, configuration: configuration)
        processedImage = processed
        isProcessing = false

        // Build share items
        var items: [Any] = []

        // Add image
        items.append(processed)

        // Add caption if provided
        if let caption = configuration.caption {
            items.append(caption)
        }

        // Add deep link URL if available
        if let deepLink = configuration.deepLinkURL {
            items.append(deepLink)
        }

        return items
    }

    // MARK: - Image Processing

    /// Processes image with optional watermark and aspect ratio adjustment.
    private func processImage(
        image: UIImage,
        configuration: ShareConfiguration
    ) async -> UIImage {
        var result = image

        // Apply watermark if configured
        if configuration.includeWatermark {
            result = addWatermark(to: result, text: configuration.watermarkText)
        }

        // Adjust aspect ratio if needed
        if configuration.aspectRatio != .square {
            result = cropToAspectRatio(result, ratio: configuration.aspectRatio)
        }

        return result
    }

    /// Adds a subtle watermark to the bottom of the image.
    private func addWatermark(to image: UIImage, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Setup watermark text
            let fontSize: CGFloat = min(image.size.height * 0.035, 32)
            let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]

            // Calculate watermark position (bottom center)
            let textSize = (text as NSString).size(withAttributes: attributes)
            let padding: CGFloat = fontSize * 0.5
            let x = (image.size.width - textSize.width) / 2
            let y = image.size.height - textSize.height - padding

            // Draw watermark
            let rect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
            text.draw(in: rect, withAttributes: attributes)
        }
    }

    /// Crops image to specified aspect ratio.
    private func cropToAspectRatio(_ image: UIImage, ratio: ShareAspectRatio) -> UIImage {
        let targetSize = ratio.cropSize
        let originalSize = image.size

        // Calculate crop rect maintaining center
        let aspectRatio = targetSize.width / targetSize.height
        let originalRatio = originalSize.width / originalSize.height

        var cropRect: CGRect

        if originalRatio > aspectRatio {
            // Original is wider - crop sides
            let cropHeight = originalSize.height
            let cropWidth = cropHeight * aspectRatio
            let x = (originalSize.width - cropWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: cropWidth, height: cropHeight)
        } else {
            // Original is taller - crop top/bottom
            let cropWidth = originalSize.width
            let cropHeight = cropWidth / aspectRatio
            let y = (originalSize.height - cropHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: cropWidth, height: cropHeight)
        }

        // Crop and resize
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }

        let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Resize to target dimensions
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            cropped.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // MARK: - Share Completion

    /// Handles share completion with analytics tracking.
    func handleShareCompletion(
        activityType: UIActivity.ActivityType?,
        completed: Bool,
        photoId: String,
        style: String
    ) {
        guard completed else { return }

        DesignSystem.Haptics.medium()

        // Track analytics
        analytics.trackEvent("photo_shared", properties: [
            "photo_id": photoId,
            "style": style,
            "destination": activityType?.displayName ?? "unknown",
            "destination_type": (activityType?.isSocialMedia ?? false) ? "social" : "direct"
        ])
    }
}

// MARK: - Share Error

enum ShareError: LocalizedError {
    case imageProcessingFailed
    case noItemsToShare

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Could not process image for sharing."
        case .noItemsToShare:
            return "No items available to share."
        }
    }
}