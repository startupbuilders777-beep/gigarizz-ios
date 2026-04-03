import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedPlan: PlanOption = .monthly
    @State private var isRestoring = false
    @Environment(\.dismiss) private var dismiss

    enum PlanOption: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case lifetime = "Lifetime"

        var price: String {
            switch self {
            case .weekly: return "$4.99"
            case .monthly: return "$9.99"
            case .lifetime: return "$49.99"
            }
        }

        var period: String {
            switch self {
            case .weekly: return "/week"
            case .monthly: return "/month"
            case .lifetime: return "one-time"
            }
        }

        var savings: String? {
            switch self {
            case .weekly: return nil
            case .monthly: return "Save 50%"
            case .lifetime: return "Best Value"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        heroSection
                        featuresSection
                        planSelection
                        ctaSection
                        footerSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            HStack(spacing: DesignSystem.Spacing.m) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Colors.surfaceSecondary)
                            .frame(width: 140, height: 180)
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(DesignSystem.Colors.textSecondary)
                            Text("\u{1F610}").font(.system(size: 24))
                        }
                    }
                    Text("Before").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Image(systemName: "arrow.right").font(.system(size: 24, weight: .bold)).foregroundStyle(DesignSystem.Colors.flameOrange)
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(LinearGradient(colors: [DesignSystem.Colors.flameOrange.opacity(0.3), DesignSystem.Colors.goldAccent.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 140, height: 180)
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(DesignSystem.Colors.flameOrange)
                            Text("\u{1F525}").font(.system(size: 24))
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).strokeBorder(DesignSystem.Colors.flameOrange, lineWidth: 2))
                    Text("After").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }.padding(.top, DesignSystem.Spacing.l)
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Unlock Your Full Rizz").font(DesignSystem.Typography.headline).foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("10x your matches with AI-powered dating photos").font(DesignSystem.Typography.subheadline).foregroundStyle(DesignSystem.Colors.textSecondary).multilineTextAlignment(.center)
            }
        }
    }

    private var featuresSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            featureRow(icon: "wand.and.stars", title: "Unlimited AI Photos", subtitle: "Generate as many dating photos as you want")
            featureRow(icon: "paintpalette.fill", title: "All 10 Style Presets", subtitle: "Confident, Adventurous, Golden Hour, and more")
            featureRow(icon: "arrow.down.circle.fill", title: "HD Downloads", subtitle: "Full resolution photos with no watermark")
            featureRow(icon: "brain.head.profile", title: "Rizz Coach", subtitle: "AI-powered bios, openers, and conversation tips")
            featureRow(icon: "bolt.fill", title: "Priority Queue", subtitle: "Skip the line — your photos generate first")
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(DesignSystem.Colors.flameOrange).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(subtitle).font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.success)
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    private var planSelection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Text("Choose Your Plan").font(DesignSystem.Typography.title).foregroundStyle(DesignSystem.Colors.textPrimary)
            HStack(spacing: DesignSystem.Spacing.s) {
                ForEach(PlanOption.allCases, id: \.self) { plan in planCard(plan) }
            }
        }
    }

    private func planCard(_ plan: PlanOption) -> some View {
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) { selectedPlan = plan }
            DesignSystem.Haptics.light()
        } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
                if let savings = plan.savings {
                    Text(savings).font(DesignSystem.Typography.caption)
                        .foregroundStyle(plan == .lifetime ? DesignSystem.Colors.goldAccent : DesignSystem.Colors.success)
                        .padding(.horizontal, DesignSystem.Spacing.xs).padding(.vertical, 2)
                        .background(Capsule().fill((plan == .lifetime ? DesignSystem.Colors.goldAccent : DesignSystem.Colors.success).opacity(0.15)))
                }
                Text(plan.rawValue).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(plan.price).font(DesignSystem.Typography.headline).foregroundStyle(selectedPlan == plan ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                Text(plan.period).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.Spacing.m)
            .background(selectedPlan == plan ? DesignSystem.Colors.flameOrange.opacity(0.1) : DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).strokeBorder(selectedPlan == plan ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.divider, lineWidth: selectedPlan == plan ? 2 : 1))
        }
    }

    private var ctaSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            GRButton(title: "Start 3-Day Free Trial", icon: "flame.fill") {
                DesignSystem.Haptics.medium()
                PostHogManager.shared.trackPaywallViewed(trigger: "paywall_cta")
            }
            Text("Cancel anytime. You won't be charged during the trial.").font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary).multilineTextAlignment(.center)
        }
    }

    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Button {
                isRestoring = true
                Task { await subscriptionManager.restorePurchases(); isRestoring = false }
            } label: {
                Text(isRestoring ? "Restoring..." : "Restore Purchases").font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
            }.disabled(isRestoring)
            HStack(spacing: DesignSystem.Spacing.m) {
                Button { } label: { Text("Terms of Service").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary) }
                Button { } label: { Text("Privacy Policy").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary) }
            }
        }
    }
}

#Preview {
    PaywallView().environmentObject(SubscriptionManager()).preferredColorScheme(.dark)
}
