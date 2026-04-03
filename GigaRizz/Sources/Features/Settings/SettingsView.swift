import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false
    @State private var showRating = false
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                List {
                    accountSection
                    subscriptionSection
                    supportSection
                    dangerSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showRating) { AppRatingView() }
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authManager.signOut()
                    dismiss()
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Forever", role: .destructive) {
                    Task {
                        try? await authManager.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("This permanently deletes your account and all data. This cannot be undone.")
            }
        }
    }

    private var accountSection: some View {
        Section {
            HStack {
                Label("Email", systemImage: "envelope.fill")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(authManager.userEmail ?? "Not signed in")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Account")
        }
    }

    private var subscriptionSection: some View {
        Section {
            HStack {
                Label("Current Plan", systemImage: "crown.fill")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(subscriptionManager.currentTier.displayName)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            if subscriptionManager.currentTier == .free {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "flame.fill")
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                .listRowBackground(DesignSystem.Colors.surface)
            }

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Subscription")
        }
    }

    private var supportSection: some View {
        Section {
            Button {
                showRating = true
            } label: {
                Label("Rate GigaRizz", systemImage: "star.fill")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            Button {
                // Open support email
            } label: {
                Label("Contact Support", systemImage: "envelope")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            Button {
                // Share app
            } label: {
                Label("Share GigaRizz", systemImage: "square.and.arrow.up")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Support")
        }
    }

    private var dangerSection: some View {
        Section {
            Button {
                showSignOutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(DesignSystem.Colors.warning)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            Button {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Account", systemImage: "trash.fill")
                    .foregroundStyle(DesignSystem.Colors.error)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Account Actions")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            Button { } label: {
                Text("Terms of Service")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .listRowBackground(DesignSystem.Colors.surface)

            Button { } label: {
                Text("Privacy Policy")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("About")
        } footer: {
            Text("Made with \u{1F525} by GigaRizz")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, DesignSystem.Spacing.m)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}
