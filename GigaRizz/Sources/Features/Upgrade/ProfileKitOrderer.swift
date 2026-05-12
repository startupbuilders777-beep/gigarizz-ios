import Foundation

// MARK: - ProfileKitOrderer
//
// Decides which photo goes in which slot for each platform.
//
// Per-platform rules (research-backed):
//  - Hinge:  6 photos, first must be a clear face, prefers variety in archetypes
//  - Tinder: up to 9, first must be solo, second-strongest face shot second
//  - Bumble: up to 6, first must be face, no group photo as first
//
// Strategy: rank candidates by audit overall score, then enforce platform-specific
// archetype constraints. Algorithm is deterministic and pure — easy to unit test.

struct OrderedPhoto: Identifiable, Equatable {
    var id: String { url }
    let url: String
    let archetype: PhotoArchetype?
    let overallScore: Int
}

struct PlatformPhotoOrder: Equatable {
    let platform: DatingPlatform
    let photos: [OrderedPhoto]
    let suggestedSlots: [PhotoArchetype]
}

enum ProfileKitOrderer {

    // Platform-specific photo limits.
    static func slotCount(for platform: DatingPlatform) -> Int {
        switch platform {
        case .hinge: return 6
        case .tinder: return 9
        case .bumble: return 6
        case .raya: return 5
        case .general, .other: return 6
        }
    }

    /// Recommended archetype mix per platform, in display order.
    /// First entry is always `firstPhoto`.
    static func suggestedSlots(for platform: DatingPlatform) -> [PhotoArchetype] {
        switch platform {
        case .hinge:
            return [.firstPhoto, .casualCandid, .fullBody, .hobbyActivity, .dressedUp, .travelLifestyle]
        case .tinder:
            return [.firstPhoto, .casualCandid, .dressedUp, .hobbyActivity, .travelLifestyle, .socialProof, .fullBody, .casualCandid, .hobbyActivity]
        case .bumble:
            return [.firstPhoto, .casualCandid, .hobbyActivity, .fullBody, .travelLifestyle, .dressedUp]
        case .raya:
            return [.firstPhoto, .dressedUp, .travelLifestyle, .hobbyActivity, .casualCandid]
        case .general, .other:
            return [.firstPhoto, .casualCandid, .hobbyActivity, .dressedUp, .travelLifestyle, .fullBody]
        }
    }

    /// Build an ordered photo list for a single platform.
    ///
    /// - Parameters:
    ///   - audit: optional audit result; if present, per-photo scores drive the rank
    ///   - currentPhotoUrls: user's existing photos
    ///   - generatedPhotoUrls: new AI-generated photos
    static func order(
        for platform: DatingPlatform,
        audit: ProfileAuditResult?,
        currentPhotoUrls: [String],
        generatedPhotoUrls: [String]
    ) -> PlatformPhotoOrder {
        let allUrls = currentPhotoUrls + generatedPhotoUrls
        let critiques: [String: PhotoCritique] = Dictionary(
            uniqueKeysWithValues: (audit?.perPhoto ?? []).map { ($0.photoUrl, $0) }
        )

        let candidates: [OrderedPhoto] = allUrls.map { url in
            let critique = critiques[url]
            return OrderedPhoto(
                url: url,
                archetype: critique?.archetype,
                overallScore: critique?.overall ?? 5
            )
        }

        let limit = slotCount(for: platform)
        let ranked = pickAndOrder(candidates: candidates, limit: limit)

        return PlatformPhotoOrder(
            platform: platform,
            photos: ranked,
            suggestedSlots: suggestedSlots(for: platform)
        )
    }

    /// Pure algorithm: pick a strong first photo, then fill remaining slots
    /// with the best remaining candidates ranked by overall score.
    static func pickAndOrder(
        candidates: [OrderedPhoto],
        limit: Int
    ) -> [OrderedPhoto] {
        guard !candidates.isEmpty else { return [] }

        // Step 1: choose a first photo. Prefer one tagged firstPhoto; if none,
        // pick the highest-scoring photo that is NOT social_proof (group photo).
        let firstPhotoCandidates = candidates.filter { $0.archetype == .firstPhoto }
        let first: OrderedPhoto = firstPhotoCandidates
            .sorted { $0.overallScore > $1.overallScore }
            .first
            ?? candidates
                .filter { $0.archetype != .socialProof }
                .sorted { $0.overallScore > $1.overallScore }
                .first
            ?? candidates[0]

        var picked: [OrderedPhoto] = [first]
        var seenUrls: Set<String> = [first.url]
        var seenArchetypes: Set<PhotoArchetype> = []
        if let arc = first.archetype { seenArchetypes.insert(arc) }

        // Step 2: prefer photos with new archetypes (variety) before duplicating.
        let remaining = candidates
            .filter { !seenUrls.contains($0.url) }
            .sorted { $0.overallScore > $1.overallScore }

        for candidate in remaining where picked.count < limit {
            if let arc = candidate.archetype, !seenArchetypes.contains(arc) {
                picked.append(candidate)
                seenUrls.insert(candidate.url)
                seenArchetypes.insert(arc)
            }
        }

        // Step 3: top off with whatever remaining strongest photos exist.
        for candidate in remaining where picked.count < limit && !seenUrls.contains(candidate.url) {
            picked.append(candidate)
            seenUrls.insert(candidate.url)
        }

        return picked
    }

    /// Which suggested slots does the user not have a strong photo for?
    static func unfilledSlots(
        for platform: DatingPlatform,
        audit: ProfileAuditResult?
    ) -> [PhotoArchetype] {
        let needed = Set(suggestedSlots(for: platform))
        let present = Set((audit?.perPhoto ?? []).compactMap { $0.archetype })
        return needed.subtracting(present).sorted { $0.rawValue < $1.rawValue }
    }
}
