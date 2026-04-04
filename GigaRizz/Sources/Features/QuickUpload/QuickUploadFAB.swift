import SwiftUI

// MARK: - Quick Upload FAB

/// Floating action button for Quick Upload Mode - power user single-photo express generation.
/// Design: 64pt circle, FlameOrange gradient, sparkle icon, elevated shadow.
struct QuickUploadFAB: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button {
            isPresented = true
            DesignSystem.Haptics.medium()
        } label: {
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.flameOrange,
                                DesignSystem.Colors.goldAccent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                // Icon
                Image(systemName: "sparkle")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-15))
            }
        }
        .elevatedShadow()
        .scaleEffect(isPresented ? 0.9 : 1.0)
        .animation(
            reduceMotion ? .none : DesignSystem.Animation.quickSpring,
            value: isPresented
        )
        .accessibilityLabel("Quick upload")
        .accessibilityHint("Double tap for fast photo generation")
    }
}

// MARK: - FAB Container View

/// Container view that positions the FAB correctly relative to safe areas.
struct FABContainer<Content: View>: View {
    let content: Content
    let fabPosition: FABPosition
    @Binding var showQuickUpload: Bool

    enum FABPosition {
        case bottomRight
        case bottomCenter
    }

    init(
        fabPosition: FABPosition = .bottomRight,
        showQuickUpload: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.fabPosition = fabPosition
        self._showQuickUpload = showQuickUpload
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            // FAB positioned based on config
            switch fabPosition {
            case .bottomRight:
                QuickUploadFAB(isPresented: $showQuickUpload)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.large)
            case .bottomCenter:
                QuickUploadFAB(isPresented: $showQuickUpload)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, DesignSystem.Spacing.large)
            }
        }
    }
}

// MARK: - Preview

#Preview("FAB Button") {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()

        VStack {
            Text("Home Screen Content")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()
        }

        QuickUploadFAB(isPresented: .constant(false))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.large)
    }
    .preferredColorScheme(.dark)
}

#Preview("FAB Container") {
    FABContainer(showQuickUpload: .constant(false)) {
        NavigationStack {
            VStack {
                Text("Content View")
                    .font(DesignSystem.Typography.title)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Home")
        }
    }
    .preferredColorScheme(.dark)
}