import SwiftUI
import UIKit
import LinkPresentation

// MARK: - Share Sheet

/// UIViewControllerRepresentable wrapper for UIActivityViewController.
/// Provides native iOS share sheet with custom configuration for GigaRizz photos.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let completion: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)?

    init(
        items: [Any],
        completion: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil
    ) {
        self.items = items
        self.completion = completion
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Set completion handler
        controller.completionWithItemsHandler = completion

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Share Activity Type Extension

extension UIActivity.ActivityType {
    /// Instagram Stories activity type
    static let instagramStories = UIActivity.ActivityType(rawValue: "com.instagram.share.stories")

    /// Custom identifier for tracking
    var isSocialMedia: Bool {
        switch self {
        case .postToFacebook, .postToTwitter, .postToWeibo, .postToTencentWeibo:
            return true
        case .message, .mail, .copyToPasteboard:
            return false
        default:
            // Check for Instagram, TikTok, Snapchat
            return rawValue.contains("instagram") ||
                   rawValue.contains("tiktok") ||
                   rawValue.contains("snapchat")
        }
    }

    var displayName: String {
        switch self {
        case .postToFacebook: return "Facebook"
        case .postToTwitter: return "Twitter"
        case .message: return "Messages"
        case .mail: return "Mail"
        case .copyToPasteboard: return "Copy"
        case .postToWeibo: return "Weibo"
        default:
            if rawValue.contains("instagram") { return "Instagram" }
            if rawValue.contains("tiktok") { return "TikTok" }
            if rawValue.contains("snapchat") { return "Snapchat" }
            if rawValue.contains("whatsapp") { return "WhatsApp" }
            return "Other"
        }
    }
}

// MARK: - Share Item Provider

/// Custom item provider for sharing photos with metadata.
class ShareItemProvider: UIActivityItemProvider {
    private let image: UIImage
    private let caption: String?
    private let deepLinkURL: URL?

    init(image: UIImage, caption: String?, deepLinkURL: URL?) {
        self.image = image
        self.caption = caption
        self.deepLinkURL = deepLinkURL
        super.init(placeholderItem: image)
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        // Return image for all activities
        return image
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        // Subject for email
        return "My GigaRizz Photo"
    }

    override func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = caption ?? "My AI-generated dating photo"
        if let url = deepLinkURL {
            metadata.originalURL = url
            metadata.url = url
        }
        return metadata
    }
}