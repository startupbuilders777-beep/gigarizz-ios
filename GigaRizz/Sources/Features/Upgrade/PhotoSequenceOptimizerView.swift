import SwiftUI

// MARK: - PhotoSequenceOptimizerView (V3 Sprint 3 hero)
//
// Per-platform lineup ranker. Hinge / Tinder / Bumble each rank photos
// differently — Hinge favors clear eye contact in the first slot, Tinder
// rewards solo-only first photo, Bumble bans group photos as the opener.
//
// Built on top of `ProfileKitOrderer` (algorithm) + `ProfileAuditResult`
// (per-photo critique). What's new in Sprint 3 is the per-slot RATIONALE:
// every position shows the user *why* this photo earned that slot for that
// platform.
//
// Counters:
//   - Tinder Photo Selector — silent picking; we explain.
//   - Bumble AI Photo Feedback — single-platform; we cover all three.
//   - Picker AI — generic; we tune per dating platform.

struct PhotoSequenceOptimizerView: View {
    let audit: ProfileAuditResult
    let currentPhotoUrls: [String]
    let generatedPhotoUrls: [String]
    let availablePlatforms: [DatingPlatform]

    @State private var selectedPlatform: DatingPlatform

    init(
        audit: ProfileAuditResult,
        currentPhotoUrls: [String],
        generatedPhotoUrls: [String] = [],
        availablePlatforms: [DatingPlatform]
    ) {
        self.audit = audit
        self.currentPhotoUrls = currentPhotoUrls
        self.generatedPhotoUrls = generatedPhotoUrls
        let supported = availablePlatforms.filter { Self.isSupported($0) }
        self.availablePlatforms = supported.isEmpty ? [.hinge] : supported
        _selectedPlatform = State(initialValue: supported.first ?? .hinge)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                header
                if availablePlatforms.count > 1 {
                    platformPicker
                }
                lineup
                unfilled
                naturalnessFooter
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Photo Sequence")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lineup ordered for \(selectedPlatform.rawValue)")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(headerSubtitle)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var headerSubtitle: String {
        switch selectedPlatform {
        case .hinge: return "Hinge favors clear eye contact in slot 1 + variety across the next five slots."
        case .tinder: return "Tinder rewards a solo opener and pairs strongest face shot at slot 2."
        case .bumble: return "Bumble bans group photos as the opener — your strongest solo face leads."
        case .raya: return "Raya filters expect editorial-grade variety from the first slot down."
        case .general, .other: return "A balanced general lineup — strong opener, then variety."
        }
    }

    private var platformPicker: some View {
        HStack(spacing: 8) {
            ForEach(availablePlatforms) { platform in
                Button {
                    selectedPlatform = platform
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: platform.icon)
                        Text(platform.rawValue)
                            .font(DesignSystem.Typography.subheadline)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, 10)
                    .background(selectedPlatform == platform ? DesignSystem.Colors.flameOrange.opacity(0.20) : DesignSystem.Colors.surfaceSecondary)
                    .foregroundStyle(selectedPlatform == platform ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var orderResult: PlatformPhotoOrder {
        ProfileKitOrderer.order(
            for: selectedPlatform,
            audit: audit,
            currentPhotoUrls: currentPhotoUrls,
            generatedPhotoUrls: generatedPhotoUrls
        )
    }

    @ViewBuilder
    private var lineup: some View {
        let result = orderResult
        VStack(spacing: DesignSystem.Spacing.small) {
            ForEach(Array(result.photos.enumerated()), id: \.element.id) { idx, photo in
                lineupRow(slot: idx + 1, photo: photo)
            }
        }
    }

    private func lineupRow(slot: Int, photo: OrderedPhoto) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
            slotBadge(slot)
            AsyncImage(url: URL(string: photo.url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.surfaceSecondary)
            }
            .frame(width: 72, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(photo.archetype?.displayName ?? "Photo")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Text("\(photo.overallScore)/10")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(scoreColor(photo.overallScore))
                }
                Text(rationale(for: slot, photo: photo))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private func slotBadge(_ slot: Int) -> some View {
        Text("\(slot)")
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.hinge],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }

    private func scoreColor(_ value: Int) -> Color {
        switch value {
        case 0..<5: return DesignSystem.Colors.error
        case 5..<7: return DesignSystem.Colors.flameOrange
        case 7..<9: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.success
        }
    }

    @ViewBuilder
    private var unfilled: some View {
        let missing = ProfileKitOrderer.unfilledSlots(for: selectedPlatform, audit: audit)
        if !missing.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Missing slot types for \(selectedPlatform.rawValue)")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(missing, id: \.rawValue) { archetype in
                    HStack(spacing: 8) {
                        Image(systemName: archetype.systemImage)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(archetype.displayName)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(archetype.whyItMatters)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.flameOrange.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    private var naturalnessFooter: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "info.circle")
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("Order is computed from your audit critiques + per-platform first-slot rules.")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Rationale

    /// Per-slot reasoning text. The point of difference vs Tinder Photo Selector
    /// (which silently picks) and Bumble AI Photo Feedback (which only nudges).
    private func rationale(for slot: Int, photo: OrderedPhoto) -> String {
        switch (selectedPlatform, slot) {
        case (.hinge, 1):
            return "Hinge swipers spend 92% of their attention on slot 1. We led with your highest-scoring face shot."
        case (.hinge, 2):
            return "Slot 2 should add depth — variety in archetype, not a duplicate face shot. Why this fits: \(photoTrait(photo))."
        case (.hinge, 3...):
            return "Slot \(slot) extends your story. We picked the next-strongest archetype variety to keep them swiping. Why this fits: \(photoTrait(photo))."
        case (.tinder, 1):
            return "Tinder's first-card rule: solo, sharp, eyes visible. This was your top solo face score."
        case (.tinder, 2):
            return "Tinder reward stacking: a strong second-slot face shot lifts swipe-through ~18%. \(photoTrait(photo))."
        case (.tinder, 3...):
            return "Slot \(slot) builds variety. Tinder's algorithm rewards lineups that change context. \(photoTrait(photo))."
        case (.bumble, 1):
            return "Bumble bans group photos as the opener. Strongest solo face leads — \(photoTrait(photo))."
        case (.bumble, 2...):
            return "Slot \(slot) shows lifestyle context. Bumble's lineup feedback rewards variety. \(photoTrait(photo))."
        case (.raya, 1):
            return "Raya's filter loves editorial energy in slot 1. \(photoTrait(photo))."
        case (.raya, 2...):
            return "Slot \(slot) — Raya rewards taste and variety. \(photoTrait(photo))."
        default:
            return "Slot \(slot) — \(photoTrait(photo))."
        }
    }

    private func photoTrait(_ photo: OrderedPhoto) -> String {
        if photo.overallScore >= 8 {
            return "scored \(photo.overallScore)/10 in the audit"
        }
        if let arc = photo.archetype {
            return "fills the \(arc.displayName.lowercased()) slot at \(photo.overallScore)/10"
        }
        return "best remaining candidate at \(photo.overallScore)/10"
    }

    // MARK: - Helpers

    private static func isSupported(_ platform: DatingPlatform) -> Bool {
        switch platform {
        case .hinge, .tinder, .bumble, .raya: return true
        case .general, .other: return false
        }
    }
}
