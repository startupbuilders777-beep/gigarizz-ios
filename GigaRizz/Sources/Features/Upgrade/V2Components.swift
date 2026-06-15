import SwiftUI

// MARK: - V2 Component Library
//
// Unified design language for the V2 Profile Upgrade flow.
// Every view in Features/Upgrade composes from these atoms so the
// experience reads as one designed system, not a stack of one-offs.
//
// Hierarchy:
//   V2HeroCard       - top-of-screen statement: score, summary, big number
//   V2SectionHeader  - "Top Fixes", "Photo order" — consistent rhythm
//   V2Card           - default content card (per-photo, fix, missing slot)
//   V2PrimaryButton  - flame→hinge gradient, the next-action CTA
//   V2SecondaryButton- surface bg, white text — restore / regenerate
//   V2DestructiveButton - red on transparent for delete-style actions
//   V2TrustBadge     - lock + privacy reassurance copy
//   V2EmptyState     - vector icon + headline + subtitle for no-data sections
//   V2ScoreRing      - animated circular reveal of the audit score
//   V2PlatformPill   - selector capsule for Hinge/Tinder/Bumble
//   V2Toast          - in-view confirmation banner

// MARK: - Layout primitives

struct V2HeroCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.large)
        .background(
            ZStack {
                DesignSystem.Colors.surface
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.flameOrange.opacity(0.10),
                        DesignSystem.Colors.surface.opacity(0)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
        )
        .cardShadow()
    }
}

struct V2Card<Content: View>: View {
    let padding: CGFloat
    let content: Content
    init(padding: CGFloat = DesignSystem.Spacing.medium, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
            )
    }
}

struct V2BottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.background.opacity(0),
                        DesignSystem.Colors.background.opacity(0.94),
                        DesignSystem.Colors.background,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

struct V2SectionHeader: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?

    init(_ title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}

// MARK: - Buttons

struct V2PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button {
            DesignSystem.Haptics.medium()
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(DesignSystem.Typography.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(DesignSystem.Gradients.flameCTA)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.45), radius: 16, x: 0, y: 8)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("v2_primary_\(title.accessibilitySlug)")
    }
}

struct V2SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button {
            DesignSystem.Haptics.light()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 15, weight: .semibold))
                }
                Text(title).font(DesignSystem.Typography.button)
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
            )
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("v2_secondary_\(title.accessibilitySlug)")
    }
}

private extension String {
    var accessibilitySlug: String {
        lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

struct V2TextButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button {
            DesignSystem.Haptics.selection()
            action()
        } label: {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 12, weight: .semibold)) }
                Text(title).font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(DesignSystem.Colors.flameOrange)
        }
    }
}

// MARK: - Trust badge

struct V2TrustBadge: View {
    let title: String
    let subtitle: String

    init(
        title: String = "Photos auto-delete in 30 days",
        subtitle: String = "Never used to train AI. Delete anytime in Settings."
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(subtitle)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(DesignSystem.Colors.success.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Empty state

struct V2EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.large)
    }
}

// MARK: - Score Ring

struct V2ScoreRing: View {
    let score: Int           // 0-100
    let lineWidth: CGFloat
    let diameter: CGFloat
    @State private var animatedProgress: CGFloat = 0

    init(score: Int, diameter: CGFloat = 168, lineWidth: CGFloat = 14) {
        self.score = score
        self.diameter = diameter
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Colors.divider, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            scoreColor.opacity(0.5),
                            scoreColor,
                            scoreColor.opacity(0.9),
                            scoreColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor.opacity(0.45), radius: 12, x: 0, y: 0)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(scoreColor)
                    .contentTransition(.numericText(value: Double(score)))
                Text("/ 100")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = CGFloat(score) / 100.0
            }
        }
    }

    private var scoreColor: Color {
        switch score {
        case 0..<50: return DesignSystem.Colors.error
        case 50..<70: return DesignSystem.Colors.flameOrange
        case 70..<85: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.success
        }
    }
}

// MARK: - Platform pill

struct V2PlatformPill: View {
    let platform: DatingPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            DesignSystem.Haptics.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(platform.rawValue)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? platform.color : DesignSystem.Colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? platform.color : DesignSystem.Colors.divider,
                    lineWidth: 1
                )
            )
        }
    }
}

// MARK: - Toast

struct V2ToastBanner: View {
    let text: String
    let icon: String

    init(_ text: String, icon: String = "checkmark.circle.fill") {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(DesignSystem.Colors.success)
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.black.opacity(0.85))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}
