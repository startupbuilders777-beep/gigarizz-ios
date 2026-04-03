import Foundation
import SwiftUI
import UIKit

// MARK: - Transformation Preview ViewModel

@MainActor
final class TransformationPreviewViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var beforeImage: UIImage?
    @Published var afterImage: UIImage?
    @Published var styleName: String = "Confident"
    @Published var hasRecentGeneration: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let storageManager = StorageManager.shared
    private var recentBatchId: String?
    private var generatedAt: Date?

    // MARK: - Computed Properties

    var timeAgoText: String {
        guard let date = generatedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Fetch Recent Generation

    func fetchRecentGeneration(userId: String) {
        isLoading = true
        errorMessage = nil

        // In production, this would fetch from Firestore/Firebase
        // For now, use UserDefaults to track recent generations
        Task {
            await loadFromLocalStorage(userId: userId)
        }
    }

    // MARK: - Local Storage Loading

    private func loadFromLocalStorage(userId: String) async {
        isLoading = false

        // Check UserDefaults for recent generation data
        let hasPhotos = UserDefaults.standard.bool(forKey: "hasGeneratedPhotos")
        let lastBatchDate = UserDefaults.standard.object(forKey: "lastGenerationDate") as? Date
        let lastStyle = UserDefaults.standard.string(forKey: "lastGenerationStyle") ?? "Confident"
        let lastBatchId = UserDefaults.standard.string(forKey: "lastBatchId")

        if hasPhotos && lastBatchDate != nil {
            generatedAt = lastBatchDate
            styleName = lastStyle
            recentBatchId = lastBatchId
            hasRecentGeneration = true

            // In production, fetch actual images from Firebase Storage
            // For now, generate placeholder transformation images
            await generatePlaceholderImages()
        } else {
            hasRecentGeneration = false
            beforeImage = nil
            afterImage = nil
        }
    }

    // MARK: - Placeholder Images (for demo/preview)

    private func generatePlaceholderImages() async {
        // Create realistic-looking placeholder images
        // In production, these would be fetched from Firebase Storage

        let before = createBeforePlaceholder()
        let after = createAfterPlaceholder()

        beforeImage = before
        afterImage = after
    }

    private func createBeforePlaceholder() -> UIImage {
        let size = CGSize(width: 300, height: 280)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Simulate a selfie-like background
            let colors = [
                UIColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0),
                UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
            ]

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { $0.cgColor } as CFArray,
                locations: [0.3, 1.0]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Desaturated look for "before"
            let overlay = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 0.3)
            overlay.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // "BEFORE" label
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.systemGray
            ]
            NSAttributedString(string: "BEFORE", attributes: attrs)
                .draw(at: CGPoint(x: 12, y: 12))

            // Silhouette icon
            if let personIcon = UIImage(systemName: "person.crop.circle.fill") {
                let tinted = personIcon.withTintColor(
                    UIColor.systemGray.withAlphaComponent(0.4),
                    renderingMode: .alwaysOriginal
                )
                let iconRect = CGRect(
                    x: size.width / 2 - 50,
                    y: size.height / 2 - 50,
                    width: 100,
                    height: 100
                )
                tinted.draw(in: iconRect)
            }
        }
    }

    private func createAfterPlaceholder() -> UIImage {
        let size = CGSize(width: 300, height: 280)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Warm, vibrant background
            let colors = [
                UIColor(red: 0.22, green: 0.15, blue: 0.1, alpha: 1.0),
                UIColor(red: 0.12, green: 0.1, blue: 0.08, alpha: 1.0)
            ]

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { $0.cgColor } as CFArray,
                locations: [0.2, 1.0]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // "AFTER" label with flame orange
            let flameOrange = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: flameOrange
            ]
            NSAttributedString(string: "AFTER", attributes: attrs)
                .draw(at: CGPoint(x: size.width - 50, y: 12))

            // Sparkles icon
            if let sparkles = UIImage(systemName: "sparkles") {
                let tinted = sparkles.withTintColor(
                    flameOrange.withAlphaComponent(0.8),
                    renderingMode: .alwaysOriginal
                )
                let iconRect = CGRect(
                    x: size.width / 2 - 50,
                    y: size.height / 2 - 50,
                    width: 100,
                    height: 100
                )
                tinted.draw(in: iconRect)
            }

            // Add a subtle glow effect around the icon
            let glowColor = flameOrange.withAlphaComponent(0.2)
            glowColor.setFill()
            let glowRect = CGRect(
                x: size.width / 2 - 60,
                y: size.height / 2 - 60,
                width: 120,
                height: 120
            )
            context.cgContext.fillEllipse(in: glowRect)
        }
    }

    // MARK: - Update After Generation

    func updateAfterGeneration(
        before: UIImage,
        after: UIImage,
        style: String,
        batchId: String,
        date: Date
    ) {
        beforeImage = before
        afterImage = after
        styleName = style
        recentBatchId = batchId
        generatedAt = date
        hasRecentGeneration = true

        // Store in UserDefaults for persistence
        UserDefaults.standard.set(true, forKey: "hasGeneratedPhotos")
        UserDefaults.standard.set(date, forKey: "lastGenerationDate")
        UserDefaults.standard.set(style, forKey: "lastGenerationStyle")
        UserDefaults.standard.set(batchId, forKey: "lastBatchId")
    }

    // MARK: - Clear

    func clear() {
        beforeImage = nil
        afterImage = nil
        styleName = "Confident"
        recentBatchId = nil
        generatedAt = nil
        hasRecentGeneration = false
    }
}

// MARK: - Preview Support

extension TransformationPreviewViewModel {
    /// Creates a demo view model with sample data for previews
    static func preview() -> TransformationPreviewViewModel {
        let vm = TransformationPreviewViewModel()
        vm.hasRecentGeneration = true
        vm.styleName = "Confident"
        vm.generatedAt = Date().addingTimeInterval(-3600) // 1 hour ago
        vm.beforeImage = vm.createBeforePlaceholder()
        vm.afterImage = vm.createAfterPlaceholder()
        return vm
    }
}