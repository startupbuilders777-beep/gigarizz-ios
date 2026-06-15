import Foundation

// MARK: - Magic Edit Planner (V5 flagship — "complex operations")
//
// Turns ONE plain-English compound request into an ordered, transparent list of
// edit operations, then composes a single identity-locked prompt for the
// generation pipeline. This is the FaceApp/Facetune killer: those apps are
// single-op and manual ("smooth skin", then "swap background", then ...). The
// user asked for complex operations — "put me on a rooftop at golden hour,
// change my hoodie to a white linen shirt, fix the harsh lighting, and remove
// the guy behind me" — executed as one plan, with every step shown so the user
// can see exactly what the AI is doing to their photo.
//
// Pure and deterministic so it is unit-testable and renders a live preview as
// the user types. Steps are emitted in a sensible canonical order regardless of
// the order the user typed them in.

struct MagicEditPlan: Equatable {
    let steps: [MagicEditStep]
    /// Single identity-preserving instruction composed from all steps, sent to
    /// the backend `/generate` endpoint (the `_wrap_natural` wrapper still adds
    /// naturalness language on top at the user's chosen intensity).
    let composedPrompt: String
    /// Backend style key. Mirrors PhotoBriefStudio's default; the real intent
    /// rides in `composedPrompt`.
    let sceneStyle: String

    var isEmpty: Bool { steps.isEmpty }
}

struct MagicEditStep: Identifiable, Equatable {
    enum Kind: String, CaseIterable {
        case scene        // put me in / change the background to <place>
        case outfit       // change clothes
        case hair         // hair / beard
        case expression   // smile / serious
        case lighting     // fix lighting / brighten
        case color        // color grade / cinematic / warm
        case retouch      // skin / blemish / teeth / eyes
        case cleanup      // remove a person / object

        /// Order steps run in, independent of how the user phrased them.
        var canonicalOrder: Int {
            switch self {
            case .scene: return 0
            case .cleanup: return 1
            case .outfit: return 2
            case .hair: return 3
            case .expression: return 4
            case .lighting: return 5
            case .color: return 6
            case .retouch: return 7
            }
        }

        var systemImage: String {
            switch self {
            case .scene: return "mountain.2.fill"
            case .outfit: return "tshirt.fill"
            case .hair: return "comb.fill"
            case .expression: return "face.smiling.fill"
            case .lighting: return "sun.max.fill"
            case .color: return "camera.filters"
            case .retouch: return "sparkles"
            case .cleanup: return "wand.and.rays"
            }
        }

        var title: String {
            switch self {
            case .scene: return "Place in scene"
            case .outfit: return "Change outfit"
            case .hair: return "Adjust hair"
            case .expression: return "Tune expression"
            case .lighting: return "Fix lighting"
            case .color: return "Color grade"
            case .retouch: return "Natural retouch"
            case .cleanup: return "Clean up"
            }
        }

        /// How much this operation risks pulling the result away from the user's
        /// real face. Drives the per-step lock badge — our trust differentiator.
        var identityImpact: IdentityImpact {
            switch self {
            case .scene, .cleanup, .color, .lighting: return .none   // doesn't touch the face
            case .outfit, .hair: return .low
            case .retouch, .expression: return .medium               // gated hardest by naturalness
            }
        }
    }

    enum IdentityImpact: Equatable { case none, low, medium }

    let id = UUID()
    let kind: Kind
    /// The user's own words that triggered this step (shown back to them).
    let phrase: String

    var title: String { kind.title }

    static func == (lhs: MagicEditStep, rhs: MagicEditStep) -> Bool {
        lhs.kind == rhs.kind && lhs.phrase == rhs.phrase
    }
}

enum MagicEditPlanner {
    /// Keyword → kind. First match per kind wins; the matched clause becomes the
    /// step's phrase so the plan echoes the user's intent.
    private static let triggers: [(MagicEditStep.Kind, [String])] = [
        (.scene, ["rooftop", "beach", "cafe", "café", "coffee shop", "coffee", "gym", "bar ",
                  "street", "mountain", "office", "park", "city", "sunset", "golden hour",
                  "studio", "yacht", "ski", "restaurant", "vineyard", "desert", "forest",
                  "library", "museum", "pool", "downtown", "skyline", "background to",
                  "put me", "place me", "in front of", "in a ", "on a ", "at the", "scene"]),
        (.cleanup, ["remove the", "remove ", "delete the", "erase", "get rid of", "photobomb",
                    "person behind", "guy behind", "clutter", "object"]),
        (.outfit, ["shirt", "hoodie", "suit", "jacket", "blazer", "linen", "t-shirt", "tshirt",
                   "tee", "sweater", "dress", "outfit", "clothes", "wear", "tux", "henley", "coat"]),
        (.hair, ["hair", "haircut", "beard", "stubble", "shave", "fade", "buzz cut"]),
        (.expression, ["smile", "smiling", "serious", "laugh", "grin", "confident look",
                       "soft smile", "expression"]),
        (.lighting, ["lighting", "harsh light", "brighten", "shadows", "underexposed",
                     "overexposed", "too dark", "too bright", "exposure", "well lit"]),
        (.color, ["color grade", "cinematic", "warm tone", "cool tone", "filter", "moody",
                  "vibrant", "film look", "teal", "warmer", "cooler"]),
        (.retouch, ["skin", "blemish", "acne", "smooth", "glow", "teeth", "whiten",
                    "eye bags", "under eye", "spots", "complexion", "retouch"]),
    ]

    static func plan(from rawText: String) -> MagicEditPlan {
        let text = rawText.lowercased()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return MagicEditPlan(steps: [], composedPrompt: "", sceneStyle: "scene_coffee_shop")
        }

        var steps: [MagicEditStep] = []
        for (kind, keywords) in triggers {
            if let hit = keywords.first(where: { text.contains($0) }) {
                let phrase = clause(containing: hit, in: rawText) ?? hit.trimmingCharacters(in: .whitespaces)
                steps.append(MagicEditStep(kind: kind, phrase: phrase))
            }
        }

        // If nothing matched a known operation, treat the whole request as a
        // freeform scene edit so the user is never blocked.
        if steps.isEmpty {
            steps.append(MagicEditStep(kind: .scene, phrase: rawText.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        steps.sort { $0.kind.canonicalOrder < $1.kind.canonicalOrder }
        return MagicEditPlan(
            steps: steps,
            composedPrompt: composePrompt(from: steps, original: rawText),
            sceneStyle: "scene_coffee_shop"
        )
    }

    /// Compose one identity-preserving instruction. Identity-lock language first
    /// (mirrors PhotoBriefStudio), then the user's request verbatim, then an
    /// itemized operation list so the model executes every step.
    private static func composePrompt(from steps: [MagicEditStep], original: String) -> String {
        let trimmed = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let ops = steps.map { "- \($0.title): \($0.phrase)" }.joined(separator: "\n")
        return """
        Same person as the reference photo — identical face, identity, and bone structure. \
        Photorealistic, natural result. Do not alter facial features.
        User request: \(trimmed)
        Apply these operations in order:
        \(ops)
        """
    }

    /// Extract the surrounding clause (between commas/conjunctions) for a hit so
    /// the step echoes the user's phrasing rather than a bare keyword.
    private static func clause(containing keyword: String, in text: String) -> String? {
        let lower = text.lowercased()
        guard let range = lower.range(of: keyword) else { return nil }
        let separators = CharacterSet(charactersIn: ",.;\n")
        // Walk left to the previous separator / "and".
        var start = range.lowerBound
        while start > text.startIndex {
            let prev = text.index(before: start)
            if let scalar = text[prev].unicodeScalars.first, separators.contains(scalar) { break }
            start = prev
        }
        var end = range.upperBound
        while end < text.endIndex {
            if let scalar = text[end].unicodeScalars.first, separators.contains(scalar) { break }
            end = text.index(after: end)
        }
        let clause = text[start..<end]
            .replacingOccurrences(of: " and ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clause.isEmpty ? nil : clause
    }
}
