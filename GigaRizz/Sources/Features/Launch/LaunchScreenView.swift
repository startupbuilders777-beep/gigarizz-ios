import SwiftUI

/// Animated launch screen shown while app initializes
struct LaunchScreenView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.l) {
                Spacer()

                // Animated logo
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignSystem.Colors.flameOrange.opacity(0.3),
                                    DesignSystem.Colors.flameOrange.opacity(0.0),
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(scale * 1.2)

                    // Icon circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.4), radius: 20, y: 10)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                // App name
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("GigaRizz")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(opacity)

                    Text("AI Dating Photos That Actually Work")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .opacity(taglineOpacity)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                taglineOpacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
        .preferredColorScheme(.dark)
}
