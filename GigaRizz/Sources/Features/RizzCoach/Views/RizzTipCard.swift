import SwiftUI

// MARK: - Rizz Tip Card

/// Daily actionable dating tip card with Flame Orange accent bar.
struct RizzTipCard: View {
    let tip: DailyTip
    var onDismiss: () -> Void = {}
    var onAction: () -> Void = {}
    var onGetNewTip: () -> Void = {}

    var body: some View {
        GRCard(padding: 0) {
            HStack(spacing: 0) {
                // Flame Orange accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.flameOrange)
                    .frame(width: 4)

                VStack(spacing: DesignSystem.Spacing.s) {
                    // Header with category
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        categoryBadge
                        Text("Daily Tip")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }

                    // Tip content
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(tip.title)
                            .font(DesignSystem.Typography.title)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(tip.description)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }

                    // Actions
                    HStack(spacing: DesignSystem.Spacing.s) {
                        GRButton(
                            title: tip.actionTitle,
                            icon: actionIcon,
                            style: .primary
                        ) {
                            onAction()
                        }
                        .frame(height: 44)

                        Button {
                            onGetNewTip()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.micro) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14))
                                Text("New Tip")
                                    .font(DesignSystem.Typography.smallButton)
                            }
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.s)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(DesignSystem.Colors.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.chip))
                        }
                    }
                }
                .padding(DesignSystem.Spacing.m)
            }
        }
    }

    private var categoryBadge: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: categoryIcon)
                .font(.system(size: 10))
            Text(tip.category.rawValue)
                .font(DesignSystem.Typography.caption)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.micro)
        .background(categoryColor.opacity(0.2))
        .foregroundStyle(categoryColor)
        .clipShape(Capsule())
    }

    private var categoryIcon: String {
        switch tip.category {
        case .photo: return "photo.fill"
        case .bio: return "text.quote"
        case .conversation: return "bubble.left.fill"
        case .activity: return "figure.walk"
        case .timing: return "clock.fill"
        }
    }

    private var categoryColor: Color {
        switch tip.category {
        case .photo: return DesignSystem.Colors.flameOrange
        case .bio: return DesignSystem.Colors.hinge
        case .conversation: return DesignSystem.Colors.success
        case .activity: return DesignSystem.Colors.bumble
        case .timing: return DesignSystem.Colors.goldAccent
        }
    }

    private var actionIcon: String {
        switch tip.category {
        case .photo: return "camera.fill"
        case .bio: return "pencil.line"
        case .conversation: return "bubble.left.and.exclamationmark.bubble.right.fill"
        case .activity: return "calendar.badge.plus"
        case .timing: return "bell.fill"
        }
    }
}

// MARK: - Tip Category Icons View

/// Compact view showing tip categories with icons.
struct TipCategoryIcons: View {
    let categories: [DailyTip.TipCategory]

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            ForEach(categories, id: \.self) { category in
                VStack(spacing: DesignSystem.Spacing.micro) {
                    Image(systemName: iconFor(category))
                        .font(.system(size: 16))
                        .foregroundStyle(colorFor(category))
                    Text(category.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            }
        }
    }

    private func iconFor(_ category: DailyTip.TipCategory) -> String {
        switch category {
        case .photo: return "photo.fill"
        case .bio: return "text.quote"
        case .conversation: return "bubble.left.fill"
        case .activity: return "figure.walk"
        case .timing: return "clock.fill"
        }
    }

    private func colorFor(_ category: DailyTip.TipCategory) -> Color {
        switch category {
        case .photo: return DesignSystem.Colors.flameOrange
        case .bio: return DesignSystem.Colors.hinge
        case .conversation: return DesignSystem.Colors.success
        case .activity: return DesignSystem.Colors.bumble
        case .timing: return DesignSystem.Colors.goldAccent
        }
    }
}

// MARK: - Previews

#Preview("Rizz Tip Card") {
    VStack(spacing: 20) {
        RizzTipCard(
            tip: DailyTip.demo,
            onDismiss: {},
            onAction: {},
            onGetNewTip: {}
        )

        RizzTipCard(
            tip: DailyTip(
                title: "Eye Contact Wins",
                description: "Photos with direct eye contact receive 35% more right swipes. Look at the camera lens, not the screen.",
                category: .photo,
                actionTitle: "Learn More"
            ),
            onDismiss: {},
            onAction: {},
            onGetNewTip: {}
        )

        RizzTipCard(
            tip: DailyTip(
                title: "Reply Within 2 Hours",
                description: "Responding quickly to new matches increases conversation continuation by 60%. Don't let them fade away.",
                category: .conversation,
                actionTitle: "View Matches"
            ),
            onDismiss: {},
            onAction: {},
            onGetNewTip: {}
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Tip Categories") {
    TipCategoryIcons(categories: [.photo, .bio, .conversation, .activity, .timing])
        .padding()
        .background(DesignSystem.Colors.background)
        .preferredColorScheme(.dark)
}
