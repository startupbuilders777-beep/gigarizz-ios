import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var showTierComparison = false
    @State private var errorMessage: String?
    @AppStorage("dev_use_real_ai") private var useRealAI = false
    @AppStorage("gigarizz_keep_me_natural") private var keepMeNatural = true
    @AppStorage("gigarizz_naturalness_intensity") private var naturalnessIntensity = NaturalnessSettings.Level.conservative.intensityValue
    @AppStorage("dev_force_v2_upgrade_flow") private var forceV2UpgradeFlow = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                List {
                    Section {
                        settingsRow(icon: "person.circle.fill", title: "Email", subtitle: authManager.userEmail ?? "Not signed in", color: DesignSystem.Colors.flameOrange, accessibilityLabel: "Email address, \(authManager.userEmail ?? "Not signed in")")
                        Button { showTierComparison = true } label: {
                            settingsRow(icon: "crown.fill", title: "Plan", subtitle: subscriptionManager.currentTier.displayName, color: DesignSystem.Colors.goldAccent, accessibilityLabel: "Subscription plan, \(subscriptionManager.currentTier.displayName), tap to compare plans")
                        }
                        .buttonStyle(.plain)
                    } header: { Text("Account").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            Image(systemName: "hand.tap.fill").font(.system(size: 18)).foregroundStyle(DesignSystem.Colors.flameOrange).frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                                Text(UIAccessibility.isReduceMotionEnabled ? "Disabled (Reduce Motion)" : "Enabled").font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                            if !UIAccessibility.isReduceMotionEnabled {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.success)
                            }
                        }
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.medium) {
                                Image(systemName: "gear").font(.system(size: 18)).foregroundStyle(DesignSystem.Colors.textSecondary).frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reduce Motion Settings").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                                    Text("Open system accessibility").font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    } header: { Text("Accessibility").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        if subscriptionManager.currentTier == .free {
                            Button { showPaywall = true } label: {
                                settingsRow(icon: "flame.fill", title: "Upgrade to Pro", subtitle: "Unlock all features", color: DesignSystem.Colors.flameOrange, accessibilityLabel: "Upgrade to Pro, unlocks all features")
                            }
                            .accessibilityAddTraits(.isButton)
                        }
                        Button { Task { await subscriptionManager.restorePurchases() } } label: {
                            settingsRow(icon: "arrow.counterclockwise", title: "Restore Purchases", subtitle: "Recover previous subscription", color: DesignSystem.Colors.textSecondary, accessibilityLabel: "Restore Purchases, recover previous subscription")
                        }
                        .accessibilityAddTraits(.isButton)
                    } header: { Text("Subscription").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        Toggle(isOn: $keepMeNatural) {
                            settingsRow(
                                icon: "person.fill.checkmark",
                                title: "Keep me looking like me",
                                subtitle: keepMeNatural
                                    ? "Generations preserve your real face, skin, and age."
                                    : "Off — generations may take more creative liberties.",
                                color: DesignSystem.Colors.success,
                                accessibilityLabel: "Keep me looking like me, identity preservation toggle"
                            )
                        }
                        .tint(DesignSystem.Colors.flameOrange)
                        if keepMeNatural {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                HStack {
                                    Text("Naturalness")
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    Spacer()
                                    Text(NaturalnessSettings.currentLevel(forIntensity: naturalnessIntensity).displayName)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                                }
                                Slider(value: Binding(
                                    get: { Double(naturalnessIntensity) },
                                    set: { naturalnessIntensity = Int($0) }
                                ), in: 0...100, step: 5)
                                    .tint(DesignSystem.Colors.flameOrange)
                                    .accessibilityLabel("Naturalness intensity")
                                    .accessibilityValue("\(naturalnessIntensity) out of 100")
                                Text(NaturalnessSettings.currentLevel(forIntensity: naturalnessIntensity).subtitle)
                                    .font(DesignSystem.Typography.footnote)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            .padding(.vertical, DesignSystem.Spacing.small)
                        }
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(DesignSystem.Colors.success)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your photos stay yours")
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                Text("Auto-deleted after 30 days. Never used to train AI models.")
                                    .font(DesignSystem.Typography.footnote)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                        }
                        Link(destination: AppConstants.privacyURL) {
                            settingsRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "", color: DesignSystem.Colors.textSecondary, accessibilityLabel: "Privacy Policy")
                        }
                        .accessibilityAddTraits(.isLink)
                    } header: { Text("Trust & Privacy").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        settingsRow(icon: "info.circle.fill", title: "Version", subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", color: DesignSystem.Colors.textSecondary, accessibilityLabel: "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                        Link(destination: AppConstants.termsURL) {
                            settingsRow(icon: "doc.text.fill", title: "Terms of Service", subtitle: "", color: DesignSystem.Colors.textSecondary, accessibilityLabel: "Terms of Service")
                        }
                        .accessibilityAddTraits(.isLink)
                    } header: { Text("About").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    #if DEBUG
                    Section {
                        Toggle(isOn: $useRealAI) {
                            settingsRow(
                                icon: "sparkles.tv.fill",
                                title: "Use Real AI",
                                subtitle: useRealAI ? "Calling backend at \(AppConstants.backendBaseURL)" : "Mock mode — features return your input photo",
                                color: DesignSystem.Colors.flameOrange,
                                accessibilityLabel: "Use real AI in dev builds"
                            )
                        }
                        .tint(DesignSystem.Colors.flameOrange)

                        Toggle(isOn: $forceV2UpgradeFlow) {
                            settingsRow(
                                icon: "wand.and.sparkles.inverse",
                                title: "Force V2 Upgrade Flow",
                                subtitle: forceV2UpgradeFlow
                                    ? "Upgrade tab + audit-first flow shown regardless of backend flag"
                                    : "Off — respects the server's enable_v2_upgrade_flow flag",
                                color: DesignSystem.Colors.hinge,
                                accessibilityLabel: "Force V2 upgrade flow in dev builds"
                            )
                        }
                        .tint(DesignSystem.Colors.flameOrange)
                    } header: { Text("Developer").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)
                    #endif

                    Section {
                        Button {
                            do { try authManager.signOut(); dismiss() } catch { errorMessage = "Sign out failed. Please try again." }
                        } label: {
                            settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "", color: DesignSystem.Colors.warning, accessibilityLabel: "Sign Out")
                        }
                        .accessibilityAddTraits(.isButton)

                        Button { showDeleteConfirmation = true } label: {
                            settingsRow(icon: "trash.fill", title: "Delete Account", subtitle: "Permanently delete all data", color: DesignSystem.Colors.error, accessibilityLabel: "Delete Account, permanently delete all data")
                        }
                        .accessibilityAddTraits(.isButton)
                    } header: { Text("Account Actions").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)
                }
                .scrollContentBackground(.hidden).listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text("Done")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Double tap to close settings")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { Task { try? await authManager.deleteAccount(); dismiss() } }
            } message: { Text("This will permanently delete your account and all data. This cannot be undone.") }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showTierComparison) { TierComparisonView() }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String, color: Color, accessibilityLabel: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview { SettingsView().environmentObject(AuthManager.shared).environmentObject(SubscriptionManager.shared).preferredColorScheme(.dark) }
