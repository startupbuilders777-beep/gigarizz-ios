import SwiftUI

// MARK: - Deep Link Destination

/// Represents all possible deep link destinations in GigaRizz.
/// Each destination carries associated values for parameterized routing.
enum DeepLinkDestination: Identifiable, Equatable {
    case photo(photoId: String)
    case generation(batchId: String)
    case match(matchId: String)
    case paywall(tier: TierOption?, promoCode: String?)
    case gallery
    case onboarding
    case coach
    case profile
    case settings
    case unknown

    var id: String {
        switch self {
        case .photo(photoId: let id): return "photo-\(id)"
        case .generation(batchId: let id): return "generation-\(id)"
        case .match(matchId: let id): return "match-\(id)"
        case .paywall(tier: let tier, promoCode: let promo): return "paywall-\(tier?.rawValue ?? "none")-\(promo ?? "none")"
        case .gallery: return "gallery"
        case .onboarding: return "onboarding"
        case .coach: return "coach"
        case .profile: return "profile"
        case .settings: return "settings"
        case .unknown: return "unknown"
        }
    }
}

// MARK: - Deep Link Manager

/// Singleton manager handling URL parsing and navigation routing for deep links.
/// Supports both custom URL scheme (gigarizz://) and universal links (https://gigarizz.app).
@MainActor
final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    // MARK: - Published Properties

    /// The current deep link destination to navigate to.
    @Published var destination: DeepLinkDestination?

    /// Whether a deep link is pending (waiting for authentication).
    @Published var hasPendingDeepLink = false

    /// Error message for invalid/deleted resources.
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Stored destination for deferred deep linking (unauthenticated users).
    private var deferredDestination: DeepLinkDestination?

    /// PostHog analytics manager for tracking.
    private let postHogManager = PostHogManager.shared

    // MARK: - URL Scheme Constants

    static let customScheme = "gigarizz"
    static let universalLinkHost = "gigarizz.app"

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Handles a URL and parses it into a destination.
    /// Returns true if the URL was successfully parsed.
    func handleURL(_ url: URL) -> Bool {
        // Reset error state
        errorMessage = nil

        // Parse the URL
        let destination = parseURL(url)

        // Track analytics
        trackDeepLinkOpened(url: url, destination: destination)

        // Check if user is authenticated (deferred deep linking)
        let isAuthenticated = AuthManager.shared.isAuthenticated

        if !isAuthenticated && requiresAuthentication(destination) {
            // Store for later routing
            deferredDestination = destination
            hasPendingDeepLink = true
            return true
        }

        // Route immediately
        routeToDestination(destination)
        return true
    }

    /// Routes any deferred deep link after authentication completes.
    func routeDeferredDeepLink() {
        guard let deferred = deferredDestination else { return }

        deferredDestination = nil
        hasPendingDeepLink = false
        routeToDestination(deferred)
    }

    /// Clears any pending deep link state.
    func clearPendingDeepLink() {
        deferredDestination = nil
        hasPendingDeepLink = false
        destination = nil
        errorMessage = nil
    }

    /// Sets an error message and redirects to a safe fallback.
    func showError(message: String, fallbackDestination: DeepLinkDestination = .gallery) {
        errorMessage = message
        destination = fallbackDestination
    }

    // MARK: - URL Parsing

    private func parseURL(_ url: URL) -> DeepLinkDestination {
        // Handle custom URL scheme
        if url.scheme == Self.customScheme {
            return parseCustomSchemeURL(url)
        }

        // Handle universal links
        if url.scheme == "https" || url.scheme == "http" {
            if url.host == Self.universalLinkHost {
                return parseUniversalLinkURL(url)
            }
        }

        return .unknown
    }

    private func parseCustomSchemeURL(_ url: URL) -> DeepLinkDestination {
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let firstComponent = pathComponents.first else {
            // gigarizz:// with no path → home
            return .unknown
        }

        switch firstComponent.lowercased() {
        case "photo":
            // gigarizz://photo/{photoId}
            if let photoId = pathComponents.dropFirst().first {
                return .photo(photoId: photoId)
            }

        case "generation":
            // gigarizz://generation/{batchId}
            if let batchId = pathComponents.dropFirst().first {
                return .generation(batchId: batchId)
            }

        case "match":
            // gigarizz://match/{matchId}
            if let matchId = pathComponents.dropFirst().first {
                return .match(matchId: matchId)
            }

        case "paywall":
            // gigarizz://paywall?tier=plus&promo=GRIZZ-XXXX
            let tier = parseTierFromQueryItems(url.queryItems)
            let promo = parsePromoFromQueryItems(url.queryItems)
            return .paywall(tier: tier, promoCode: promo)

        case "gallery":
            // gigarizz://gallery
            return .gallery

        case "onboarding":
            // gigarizz://onboarding
            return .onboarding

        case "coach":
            // gigarizz://coach
            return .coach

        case "profile":
            // gigarizz://profile
            return .profile

        case "settings":
            // gigarizz://settings
            return .settings

        default:
            break
        }

        return .unknown
    }

    private func parseUniversalLinkURL(_ url: URL) -> DeepLinkDestination {
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let firstComponent = pathComponents.first else {
            return .unknown
        }

        switch firstComponent.lowercased() {
        case "photo":
            // https://gigarizz.app/photo/{id}
            if let photoId = pathComponents.dropFirst().first {
                return .photo(photoId: photoId)
            }

        case "promo":
            // https://gigarizz.app/promo/{code}
            if let promoCode = pathComponents.dropFirst().first {
                return .paywall(tier: nil, promoCode: promoCode)
            }

        case "paywall":
            // https://gigarizz.app/paywall?tier=plus
            let tier = parseTierFromQueryItems(url.queryItems)
            let promo = parsePromoFromQueryItems(url.queryItems)
            return .paywall(tier: tier, promoCode: promo)

        case "gallery":
            return .gallery

        case "coach":
            return .coach

        case "onboarding":
            return .onboarding

        default:
            break
        }

        return .unknown
    }

    // MARK: - Query Item Parsing

    private func parseTierFromQueryItems(_ items: [URLQueryItem]?) -> TierOption? {
        guard let items = items else { return nil }

        for item in items where item.name.lowercased() == "tier" {
            let value = item.value?.lowercased() ?? ""
            switch value {
            case "free": return .free
            case "plus": return .plus
            case "gold": return .gold
            default: return nil
            }
        }

        return nil
    }

    private func parsePromoFromQueryItems(_ items: [URLQueryItem]?) -> String? {
        guard let items = items else { return nil }

        for item in items where item.name.lowercased() == "promo" {
            return item.value
        }

        return nil
    }

    // MARK: - Routing

    private func routeToDestination(_ destination: DeepLinkDestination) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            self.destination = destination
        }
    }

    private func requiresAuthentication(_ destination: DeepLinkDestination) -> Bool {
        // Only paywall and onboarding can be accessed without authentication
        switch destination {
        case .paywall, .onboarding, .unknown:
            return false
        default:
            return true
        }
    }

    // MARK: - Analytics

    private func trackDeepLinkOpened(url: URL, destination: DeepLinkDestination) {
        let destinationName: String
        switch destination {
        case .photo: destinationName = "photo"
        case .generation: destinationName = "generation"
        case .match: destinationName = "match"
        case .paywall: destinationName = "paywall"
        case .gallery: destinationName = "gallery"
        case .onboarding: destinationName = "onboarding"
        case .coach: destinationName = "coach"
        case .profile: destinationName = "profile"
        case .settings: destinationName = "settings"
        case .unknown: destinationName = "unknown"
        }

        PostHogManager.shared.trackEvent(
            "deep_link_opened",
            properties: [
                "url_scheme": url.scheme ?? "unknown",
                "url_host": url.host ?? "unknown",
                "url_path": url.path,
                "destination": destinationName,
                "is_deferred": deferredDestination != nil
            ]
        )
    }
}

// MARK: - URL Extension

extension URL {
    /// Extracts query items from the URL's query string.
    var queryItems: [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return nil }
        return components.queryItems
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension DeepLinkManager {
    /// Test URLs for debugging deep link handling.
    static let testURLs: [URL] = [
        URL(string: "gigarizz://photo/test-photo-id")!,
        URL(string: "gigarizz://paywall?tier=plus")!,
        URL(string: "gigarizz://paywall?tier=gold&promo=GRIZZ-TEST")!,
        URL(string: "gigarizz://gallery")!,
        URL(string: "gigarizz://coach")!,
        URL(string: "gigarizz://onboarding")!,
        URL(string: "https://gigarizz.app/photo/test-photo-id")!,
        URL(string: "https://gigarizz.app/promo/GRIZZ-PROMO")!
    ]
}
#endif