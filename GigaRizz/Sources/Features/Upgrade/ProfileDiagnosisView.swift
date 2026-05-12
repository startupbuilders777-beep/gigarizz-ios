import SwiftUI

// MARK: - ProfileDiagnosisView
//
// The "magic moment" of V2. The user just uploaded their photos and ran an
// audit — this screen is what they came for. Everything is composed from
// V2Components so the visual language stays unified end-to-end.

struct ProfileDiagnosisView: View {
    let audit: ProfileAuditResult
    let photoUrls: [String]

    @StateObject private var kitStore = ProfileKitStore.shared
    @State private var showKit = false
    @State private var slotSheet: PhotoArchetype?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                heroSection
                buildKitCTA
                topFixesSection
                if !audit.missingArchetypes.isEmpty {
                    missingArchetypesSection
                }
                bestWorstSection
                perPhotoSection
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Your Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showKit) {
            if let kit = kitStore.current {
                ProfileKitView(kit: kit)
            }
        }
        .sheet(item: $slotSheet) { archetype in
            MissingSlotActionSheet(archetype: archetype) {
                slotSheet = nil
            }
        }
    }

    // MARK: - Hero (animated score ring + summary)

    private var heroSection: some View {
        V2HeroCard {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.large) {
                V2ScoreRing(score: audit.overallScore, diameter: 132, lineWidth: 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Score")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(scoreHeadline)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if !audit.summary.isEmpty {
                        Text(audit.summary)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(4)
                    }
                }
            }
        }
    }

    private var scoreHeadline: String {
        switch audit.overallScore {
        case 0..<50: return "Major lifts available."
        case 50..<70: return "Solid base — leaving matches on the table."
        case 70..<85: return "Strong profile. A few moves make it elite."
        default: return "Top tier — small refinements only."
        }
    }

    // MARK: - Build kit CTA

    private var buildKitCTA: some View {
        V2PrimaryButton("Build my Profile Kit", systemImage: "wand.and.sparkles.inverse") {
            showKit = true
        }
    }

    // MARK: - Top fixes

    private var topFixesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(
                "Top Fixes",
                subtitle: "What to change first for the biggest match-rate lift."
            )
            ForEach(Array(audit.topFixes.enumerated()), id: \.offset) { index, fix in
                fixCard(index: index + 1, fix: fix)
            }
        }
    }

    private func fixCard(index: Int, fix: ProfileFix) -> some View {
        V2Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.hinge],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fix.title)
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(fix.detail)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                if let archetype = fix.targetArchetype {
                    HStack(spacing: 6) {
                        Image(systemName: archetype.systemImage)
                            .font(.system(size: 12, weight: .semibold))
                        Text(archetype.displayName)
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.flameOrange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Missing archetypes (slot grid)

    private var missingArchetypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(
                "Missing Photo Slots",
                subtitle: "Generate one of each to complete your profile."
            )
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(audit.missingArchetypes) { archetype in
                    Button {
                        DesignSystem.Haptics.medium()
                        slotSheet = archetype
                    } label: {
                        missingSlotTile(archetype)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func missingSlotTile(_ archetype: PhotoArchetype) -> some View {
        V2Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.hinge.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: archetype.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.hinge)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                Text(archetype.displayName)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(archetype.whyItMatters)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(3)
                Text("Tap to generate")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
    }

    // MARK: - Best / Weakest

    private var bestWorstSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader("Spotlight")
            HStack(spacing: 10) {
                spotlightCard(
                    label: "Strongest",
                    color: DesignSystem.Colors.success,
                    photoIndex: audit.bestPhotoIndex
                )
                spotlightCard(
                    label: "Weakest",
                    color: DesignSystem.Colors.error,
                    photoIndex: audit.weakestPhotoIndex
                )
            }
        }
    }

    private func spotlightCard(label: String, color: Color, photoIndex: Int) -> some View {
        let url = photoUrls.indices.contains(photoIndex) ? photoUrls[photoIndex] : nil
        let critique = audit.perPhoto.first(where: { $0.photoIndex == photoIndex })

        return V2Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: url.flatMap(URL.init(string:))) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(DesignSystem.Colors.surfaceSecondary)
                    }
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Text(label.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(color.opacity(0.95))
                        .clipShape(Capsule())
                        .padding(10)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Photo \(photoIndex + 1)")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        if let critique {
                            Text("\(critique.overall)/10")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(color)
                        }
                    }
                    if let archetype = critique?.archetype {
                        Text(archetype.displayName)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
        }
    }

    // MARK: - Per-photo

    private var perPhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader("Per-Photo Scores")
            VStack(spacing: 8) {
                ForEach(audit.perPhoto) { critique in
                    perPhotoCard(critique)
                }
            }
        }
    }

    private func perPhotoCard(_ critique: PhotoCritique) -> some View {
        V2Card {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: critique.photoUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(DesignSystem.Colors.surfaceSecondary)
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Photo \(critique.photoIndex + 1)")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text("\(critique.overall)/10")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(scoreColor(for: critique.overall))
                    }
                    if let archetype = critique.archetype {
                        Text(archetype.displayName)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    if let firstIssue = critique.issues.first {
                        Text(firstIssue)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.error.opacity(0.85))
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    private func scoreColor(for value: Int) -> Color {
        switch value {
        case 0..<5: return DesignSystem.Colors.error
        case 5..<7: return DesignSystem.Colors.flameOrange
        case 7..<9: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.success
        }
    }
}
