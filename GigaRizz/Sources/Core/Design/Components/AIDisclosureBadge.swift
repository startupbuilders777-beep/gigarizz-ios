import SwiftUI

// MARK: - AI Disclosure Badge
//
// App Store / iOS 17.4 expectation: AI-generated imagery should be disclosed on
// the result surface. We turn the compliance requirement into a brand beat —
// the disclosure also restates our trust contract ("still you"), which is the
// exact thing FaceApp/Facetune don't say. Drop this under any grid of generated
// results.

struct AIDisclosureBadge: View {
    /// When true, adds the identity-lock half of the message (use on surfaces
    /// that run identity-preserving generation).
    var identityLocked: Bool = true

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel(message)
    }

    private var message: String {
        identityLocked
            ? "AI-generated · identity-locked to your real face. Not a different person."
            : "AI-generated image."
    }
}

#Preview {
    VStack(spacing: 12) {
        AIDisclosureBadge()
        AIDisclosureBadge(identityLocked: false)
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
