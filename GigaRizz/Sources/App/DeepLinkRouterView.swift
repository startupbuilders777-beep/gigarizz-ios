import SwiftUI

// MARK: - Deep Link Router View

/// Handles navigation routing from deep links.
/// Observes DeepLinkManager and navigates to the appropriate destination.
struct DeepLinkRouterView: View {
    @ObservedObject var deepLinkManager = DeepLinkManager.shared
    @Binding var selectedTab: MainTabView.Tab
    @State private var navigationPath = NavigationPath()
    
    // Sheet states for modal destinations
    @State private var showPaywall = false
    @State private var paywallTier: TierOption?
    @State private var paywallPromo: String?
    @State private var showPhotoPreview = false
    @State private var previewPhotoId: String?
    
    var body: some View {
        content
            .onChange(of: deepLinkManager.destination) { _, destination in
                handleDestination(destination)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(initialTier: paywallTier, promoCode: paywallPromo)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        // Empty view - just handles routing logic
        EmptyView()
    }
    
    private func handleDestination(_ destination: DeepLinkDestination?) {
        guard let destination = destination else { return }
        
        // Clear the destination after handling
        deepLinkManager.destination = nil
        
        switch destination {
        case .photo(photoId: let photoId):
            handlePhotoDeepLink(photoId: photoId)
            
        case .generation(batchId: let batchId):
            handleGenerationDeepLink(batchId: batchId)
            
        case .match(matchId: let matchId):
            handleMatchDeepLink(matchId: matchId)
            
        case .paywall(tier: let tier, promoCode: let promo):
            handlePaywallDeepLink(tier: tier, promo: promo)
            
        case .gallery:
            selectedTab = .generate
            
        case .onboarding:
            // Handled at app level - would reset onboarding state
            // This is already managed in GigaRizzApp
            break
            
        case .coach:
            selectedTab = .coach
            
        case .profile:
            selectedTab = .home
            
        case .settings:
            selectedTab = .home
            
        case .unknown:
            // Route to home as fallback
            selectedTab = .home
        }
    }
    
    private func handlePhotoDeepLink(photoId: String) {
        // In production, would fetch photo from Firestore
        // For now, show preview with placeholder
        previewPhotoId = photoId
        showPhotoPreview = true
        
        // Navigate to gallery first
        selectedTab = .generate
    }
    
    private func handleGenerationDeepLink(batchId: String) {
        // Navigate to generation results
        selectedTab = .generate
        // In production, would show GenerationResultsView with batchId
    }
    
    private func handleMatchDeepLink(matchId: String) {
        // Navigate to matches tab and open chat
        selectedTab = .matches
        // In production, would open ChatView with matchId
    }
    
    private func handlePaywallDeepLink(tier: TierOption?, promo: String?) {
        paywallTier = tier ?? .plus
        paywallPromo = promo
        showPaywall = true
    }
}

// MARK: - Deep Link Toast View

/// Shows error/error messages from deep link handling.
struct DeepLinkToastView: View {
    @ObservedObject var deepLinkManager = DeepLinkManager.shared
    @State private var showToast = false
    
    var body: some View {
        if let message = deepLinkManager.errorMessage {
            toast(message: message)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    showToast = true
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            deepLinkManager.errorMessage = nil
                            showToast = false
                        }
                    }
                }
        }
    }
    
    private func toast(message: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.warning)
            
            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(Capsule())
        .cardShadow()
        .padding(.top, DesignSystem.Spacing.large)
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DeepLinkRouterView(selectedTab: .constant(.home))
    }
}
#endif