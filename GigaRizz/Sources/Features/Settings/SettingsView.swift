import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                List {
                    Section {
                        settingsRow(icon: "person.circle.fill", title: "Email", subtitle: authManager.userEmail ?? "Not signed in", color: DesignSystem.Colors.flameOrange)
                        settingsRow(icon: "crown.fill", title: "Plan", subtitle: subscriptionManager.currentTier.displayName, color: DesignSystem.Colors.goldAccent)
                    } header: { Text("Account").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        if subscriptionManager.currentTier == .free {
                            Button { showPaywall = true } label: {
                                settingsRow(icon: "flame.fill", title: "Upgrade to Pro", subtitle: "Unlock all features", color: DesignSystem.Colors.flameOrange)
                            }
                        }
                        Button { Task { await subscriptionManager.restorePurchases() } } label: {
                            settingsRow(icon: "arrow.counterclockwise", title: "Restore Purchases", subtitle: "Recover previous subscription", color: DesignSystem.Colors.textSecondary)
                        }
                    } header: { Text("Subscription").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        settingsRow(icon: "info.circle.fill", title: "Version", subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", color: DesignSystem.Colors.textSecondary)
                        settingsRow(icon: "doc.text.fill", title: "Terms of Service", subtitle: "", color: DesignSystem.Colors.textSecondary)
                        settingsRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "", color: DesignSystem.Colors.textSecondary)
                    } header: { Text("About").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)

                    Section {
                        Button {
                            do { try authManager.signOut(); dismiss() } catch { }
                        } label: {
                            settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "", color: DesignSystem.Colors.warning)
                        }
                        Button { showDeleteConfirmation = true } label: {
                            settingsRow(icon: "trash.fill", title: "Delete Account", subtitle: "Permanently delete all data", color: DesignSystem.Colors.error)
                        }
                    } header: { Text("Account Actions").foregroundStyle(DesignSystem.Colors.textSecondary) }
                    .listRowBackground(DesignSystem.Colors.surface)
                }
                .scrollContentBackground(.hidden).listStyle(.insetGrouped)
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Text("Done").font(DesignSystem.Typography.smallButton).foregroundStyle(DesignSystem.Colors.flameOrange) }
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { Task { try? await authManager.deleteAccount(); dismiss() } }
            } message: { Text("This will permanently delete your account and all data. This cannot be undone.") }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                if !subtitle.isEmpty { Text(subtitle).font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary) }
            }
            Spacer()
        }
    }
}

#Preview { SettingsView().environmentObject(AuthManager()).environmentObject(SubscriptionManager()).preferredColorScheme(.dark) }
