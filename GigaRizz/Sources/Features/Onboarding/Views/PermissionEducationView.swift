import SwiftUI
import Photos
import PhotosUI

// MARK: - Permission Education View

/// Educational screen shown BEFORE requesting system permissions.
/// Explains why we need access and how we use it.
struct PermissionEducationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: OnboardingViewModel
    
    let permissionType: PermissionType
    let onGranted: () -> Void
    let onDenied: () -> Void
    
    @State private var isRequesting = false
    @State private var wasDenied = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                // MARK: - Icon
                iconView
                    .padding(.top, DesignSystem.Spacing.xxl)
                
                // MARK: - Title & Explanation
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(explanation)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // MARK: - Privacy Note
                privacyNoteView
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // MARK: - CTA
                if wasDenied {
                    deniedStateView
                } else {
                    grantButton
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(explanation)")
    }
    
    // MARK: - Icon View
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: iconGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: iconGradient.first?.opacity(0.3) ?? .clear, radius: 16, y: 8)
            
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Privacy Note
    
    @ViewBuilder
    private var privacyNoteView: some View {
        GRCard(padding: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "lock.shield")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.success)
                
                Text(privacyNote)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Grant Button
    
    private var grantButton: some View {
        GRButton(
            title: buttonTitle,
            icon: buttonIcon,
            isLoading: isRequesting,
            accessibilityHint: "Opens system permission dialog"
        ) {
            requestPermission()
        }
    }
    
    // MARK: - Denied State
    
    @ViewBuilder
    private var deniedStateView: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text("Permission denied")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.warning)
            
            GRButton(
                title: "Open Settings",
                icon: "gear",
                style: .outline,
                accessibilityHint: "Opens Settings app where you can grant permission"
            ) {
                openSettings()
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            
            Button {
                dismiss()
                onDenied()
            } label: {
                Text("Continue without this feature")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Content by Permission Type
    
    private var title: String {
        switch permissionType {
        case .photo:
            return "Access Your Photos"
        case .notification:
            return "Stay Notified"
        }
    }
    
    private var explanation: String {
        switch permissionType {
        case .photo:
            return "To transform your photos, GigaRizz needs access to your camera roll. We only look at photos YOU select — nothing else."
        case .notification:
            return "Get notified when your AI photos are ready. We'll also remind you about new matches and reply suggestions."
        }
    }
    
    private var iconName: String {
        switch permissionType {
        case .photo:
            return "photo.on.rectangle"
        case .notification:
            return "bell.badge"
        }
    }
    
    private var iconGradient: [Color] {
        switch permissionType {
        case .photo:
            return [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent]
        case .notification:
            return [DesignSystem.Colors.success, .green.opacity(0.7)]
        }
    }
    
    private var privacyNote: String {
        switch permissionType {
        case .photo:
            return "Your photos stay private. We never scan your entire library."
        case .notification:
            return "You can adjust notification preferences anytime in Settings."
        }
    }
    
    private var buttonTitle: String {
        switch permissionType {
        case .photo:
            return "Allow Photo Access"
        case .notification:
            return "Allow Notifications"
        }
    }
    
    private var buttonIcon: String {
        switch permissionType {
        case .photo:
            return "photo"
        case .notification:
            return "bell"
        }
    }
    
    // MARK: - Permission Actions
    
    private func requestPermission() {
        isRequesting = true
        DesignSystem.Haptics.medium()
        
        Task {
            switch permissionType {
            case .photo:
                let status = await requestPhotoPermission()
                isRequesting = false
                if status == .authorized || status == .limited {
                    PostHogManager.shared.trackPermissionGranted(type: "photo")
                    dismiss()
                    onGranted()
                } else {
                    wasDenied = true
                    PostHogManager.shared.trackPermissionDenied(type: "photo")
                }
                
            case .notification:
                // Notifications requested post-first-generation per spec
                // This view handles the education, actual request done elsewhere
                dismiss()
                onGranted()
            }
        }
    }
    
    private func requestPhotoPermission() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        DesignSystem.Haptics.light()
    }
}

// MARK: - Preview

#Preview("Photo Permission") {
    PermissionEducationView(
        viewModel: OnboardingViewModel(),
        permissionType: .photo,
        onGranted: {},
        onDenied: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Notification Permission") {
    PermissionEducationView(
        viewModel: OnboardingViewModel(),
        permissionType: .notification,
        onGranted: {},
        onDenied: {}
    )
    .preferredColorScheme(.dark)
}