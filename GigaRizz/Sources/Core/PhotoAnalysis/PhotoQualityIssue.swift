import Foundation

// MARK: - Photo Quality Issue

/// Represents a detected quality issue with a photo.
enum PhotoQualityIssue: Identifiable, Equatable {
    case tooDark
    case blurry
    case faceTooSmall
    case motionBlur
    case poorLighting

    var id: String { description }

    /// Short human-readable description for UI display.
    var description: String {
        switch self {
        case .tooDark:
            return "Too dark"
        case .blurry:
            return "Blurry"
        case .faceTooSmall:
            return "Face too small"
        case .motionBlur:
            return "Motion blur"
        case .poorLighting:
            return "Poor lighting"
        }
    }

    /// SF Symbol icon name for this issue.
    var iconName: String {
        switch self {
        case .tooDark:
            return "moon.fill"
        case .blurry:
            return "aqi.medium"
        case .faceTooSmall:
            return "person.fill"
        case .motionBlur:
            return "figure.walk.motion"
        case .poorLighting:
            return "sun.min.fill"
        }
    }
}
