import SwiftUI

// MARK: - Tier Comparison View

/// Full feature comparison table: Free vs Plus vs Gold.
/// Accessible from Settings → Subscription and from the Paywall.
struct TierComparisonView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Feature Row

    struct FeatureRow: Identifiable {
        let id = UUID()
        let category: String
        let feature: String
        let free: String
        let plus: String
        let gold: String
        let freeIcon: String
        let plusIcon: String
        let goldIcon: String
    }

    // MARK: - Plan Header

    private let plans = [
        ("Free", "person.fill", Color.gray, "$0"),
        ("Plus", "sparkles", DesignSystem.Colors.flameOrange, "$9.99/mo"),
        ("Gold", "star.fill", DesignSystem.Colors.goldAccent, "$19.99/mo")
    ]

    private var rows: [FeatureRow] {
        [
            // Photo Generation
            FeatureRow(category: "Photo Generation", feature: "Daily Photos", free: "3", plus: "30", gold: "Unlimited", freeIcon: "3.circle", plusIcon: "30.circle", goldIcon: "infinity.circle"),
            FeatureRow(category: "Photo Generation", feature: "Style Presets", free: "1", plus: "10", gold: "All", freeIcon: "1.circle", plusIcon: "10.circle", goldIcon: "infinity.circle"),
            FeatureRow(category: "Photo Generation", feature: "HD Downloads", free: "—", plus: "✓", gold: "✓ + Original", freeIcon: "xmark.circle", plusIcon: "checkmark.circle.fill", goldIcon: "star.circle.fill"),
            FeatureRow(category: "Photo Generation", feature: "Background Replacer", free: "—", plus: "✓", gold: "✓", freeIcon: "xmark.circle", plusIcon: "checkmark.circle.fill", goldIcon: "checkmark.circle.fill"),
            FeatureRow(category: "Photo Generation", feature: "Save to Camera Roll", free: "✓", plus: "✓", gold: "✓", freeIcon: "checkmark.circle.fill", plusIcon: "checkmark.circle.fill", goldIcon: "checkmark.circle.fill"),
            // AI Engine
            FeatureRow(category: "AI Engine", feature: "Generation Speed", free: "Standard", plus: "Priority", gold: "Fastest", freeIcon: "hare", plusIcon: "hare.fill", goldIcon: "bolt.fill"),
            FeatureRow(category: "AI Engine", feature: "Face Consistency", free: "Basic", plus: "Advanced", gold: "Pro", freeIcon: "person.crop.circle", plusIcon: "person.crop.circle.fill", goldIcon: "person.crop.circle.badge.checkmark"),
            FeatureRow(category: "AI Engine", feature: "Style Customization", free: "—", plus: "✓", gold: "✓", freeIcon: "xmark.circle", plusIcon: "checkmark.circle.fill", goldIcon: "checkmark.circle.fill"),
            // App Experience
            FeatureRow(category: "App Experience", feature: "Ads", free: "Yes", plus: "No", gold: "No", freeIcon: "rectangle.on.rectangle", plusIcon: "xmark.circle", goldIcon: "xmark.circle"),
            FeatureRow(category: "App Experience", feature: "Onboarding Tips", free: "✓", plus: "✓", gold: "✓", freeIcon: "checkmark.circle.fill", plusIcon: "checkmark.circle.fill", goldIcon: "checkmark.circle.fill"),
            FeatureRow(category: "App Experience", feature: "Rizz Coach Dashboard", free: "Basic", plus: "Full", gold: "Full + Insights", freeIcon: "chart.bar", plusIcon: "chart.bar.fill", goldIcon: "chart.line.uptrend.xyaxis"),
            FeatureRow(category: "App Experience", feature: "Match Inbox", free: "✓", plus: "✓", gold: "✓", freeIcon: "checkmark.circle.fill", plusIcon: "checkmark.circle.fill", goldIcon: "checkmark.circle.fill"),
            FeatureRow(category: "App Experience", feature: "Chat Suggestions", free: "—", plus: "✓", gold: "✓", freeIcon: "xmark.circle", plusIcon: "checkmark.circle.fill", goldIcon: "checkmark.circle.fill"),
            FeatureRow(category: "App Experience", feature: "Priority Support", free: "—", plus: "—", gold: "✓", freeIcon: "xmark.circle", plusIcon: "xmark.circle", goldIcon: "checkmark.circle.fill"),
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // Plan header row
                        planHeaderRow
                            .padding(.bottom, DesignSystem.Spacing.medium)

                        // Feature rows grouped by category
                        ForEach(groupedRows, id: \.category) { group in
                            Section {
                                ForEach(group.rows) { row in
                                    featureRow(row)
                                }
                            } header: {
                                categoryHeader(group.category)
                            }
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationTitle("Compare Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }

    // MARK: - Plan Header Row

    private var planHeaderRow: some View {
        HStack(spacing: 0) {
            // Feature label column
            Text("")
                .frame(width: 120)

            ForEach(plans, id: \.0) { plan in
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: plan.1)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(plan.2)

                    Text(plan.0)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(plan.3)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Category Header

    private func categoryHeader(_ category: String) -> some View {
        HStack {
            Text(category.uppercased())
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .tracking(1.5)
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Feature Row

    private func featureRow(_ row: FeatureRow) -> some View {
        HStack(spacing: 0) {
            // Feature name
            Text(row.feature)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)
                .padding(.leading, DesignSystem.Spacing.small)

            // Free tier
            featureCell(icon: row.freeIcon, color: .gray)

            // Plus tier
            featureCell(icon: row.plusIcon, color: DesignSystem.Colors.flameOrange)

            // Gold tier
            featureCell(icon: row.goldIcon, color: DesignSystem.Colors.goldAccent)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface.opacity(0.3))
    }

    private func featureCell(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Grouped Rows

    private var groupedRows: [FeatureGroup] {
        var groups: [FeatureGroup] = []
        var currentCategory = ""
        var currentRows: [FeatureRow] = []

        for row in rows {
            if row.category != currentCategory {
                if !currentRows.isEmpty {
                    groups.append(FeatureGroup(category: currentCategory, rows: currentRows))
                }
                currentCategory = row.category
                currentRows = [row]
            } else {
                currentRows.append(row)
            }
        }
        if !currentRows.isEmpty {
            groups.append(FeatureGroup(category: currentCategory, rows: currentRows))
        }
        return groups
    }

    struct FeatureGroup {
        let category: String
        let rows: [FeatureRow]
    }
}

// MARK: - Preview

#Preview {
    TierComparisonView()
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}
