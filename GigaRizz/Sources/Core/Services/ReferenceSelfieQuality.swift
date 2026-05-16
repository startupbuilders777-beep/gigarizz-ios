import Foundation
import UIKit

// MARK: - ReferenceSelfieQuality
//
// Scores a candidate reference selfie against the bar Identity Match needs to
// work well. A bad reference (dark / blurry / face too small) will hurt every
// downstream IdentityMatch comparison — surfacing the issues up front saves
// the user from generating 4 photos with low confidence chips that they
// don't understand.
//
// Built on top of the existing PhotoQualityAnalyzer so we don't duplicate
// Vision plumbing. The wrapper translates each `PhotoQualityIssue` into
// reference-selfie-specific guidance text the user can act on.

enum ReferenceSelfieQuality {

    // MARK: - Verdict

    enum Verdict: String, Equatable {
        case excellent  // no issues
        case acceptable // minor issues only — Identity Match should still work
        case poor       // critical issues that hurt every Identity Match check

        var displayName: String {
            switch self {
            case .excellent: return "Reference selfie: Excellent"
            case .acceptable: return "Reference selfie: Usable"
            case .poor: return "Reference selfie: Poor"
            }
        }

        var iconName: String {
            switch self {
            case .excellent: return "checkmark.seal.fill"
            case .acceptable: return "info.circle.fill"
            case .poor: return "exclamationmark.triangle.fill"
            }
        }
    }

    // MARK: - Issue

    struct Issue: Identifiable, Equatable {
        let id: String
        let title: String
        let advice: String
        let isCritical: Bool
    }

    // MARK: - Report

    struct Report: Equatable {
        let verdict: Verdict
        let issues: [Issue]
    }

    // MARK: - Public

    /// Score the stored reference selfie. Returns an excellent verdict + zero
    /// issues for a sharp, well-lit, face-prominent selfie.
    static func evaluate(image: UIImage) async -> Report {
        let raw = await PhotoQualityAnalyzer.analyze(image: image)
        let translated = raw.map { issue(for: $0) }
        let critical = translated.filter { $0.isCritical }
        let verdict: Verdict
        if translated.isEmpty {
            verdict = .excellent
        } else if critical.isEmpty {
            verdict = .acceptable
        } else {
            verdict = .poor
        }
        return Report(verdict: verdict, issues: translated)
    }

    // MARK: - Internals

    private static func issue(for raw: PhotoQualityIssue) -> Issue {
        switch raw {
        case .tooDark:
            return Issue(
                id: "too_dark",
                title: "Too dark",
                advice: "Identity Match needs a well-lit reference. Re-shoot near a window or in daylight.",
                isCritical: true
            )
        case .poorLighting:
            return Issue(
                id: "poor_lighting",
                title: "Highlights blown out",
                advice: "Reference selfie is over-exposed. Move out of direct sun and use even soft light.",
                isCritical: false
            )
        case .blurry, .motionBlur:
            return Issue(
                id: "blurry",
                title: "Blurry",
                advice: "Vision can't lock features on a soft photo. Re-shoot held still, focused on your eyes.",
                isCritical: true
            )
        case .faceTooSmall:
            return Issue(
                id: "face_too_small",
                title: "Face too small in frame",
                advice: "Hold the phone so your face fills at least the top half of the frame.",
                isCritical: true
            )
        }
    }
}
