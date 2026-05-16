import SwiftUI
import UIKit

// MARK: - BeforeAfterCompare
//
// Draggable curtain that reveals two images side-by-side. Used in
// BriefResultDetailSheet to let users visually verify a generated variant
// against their reference selfie — the "looks like you" claim made tactile.
//
// Implementation notes:
//   - Both images are stacked; the "after" image is masked by a dynamic
//     trailing rectangle whose width tracks the drag handle.
//   - The handle uses haptic selection feedback at the bounds.

struct BeforeAfterCompare: View {
    let before: UIImage
    let after: UIImage

    @State private var fraction: CGFloat = 0.5

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Image(uiImage: before)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: proxy.size.height)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        labelChip("Before")
                            .padding(8)
                    }

                Image(uiImage: after)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: proxy.size.height)
                    .clipped()
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: max(0, width * fraction))
                    }
                    .overlay(alignment: .topTrailing) {
                        labelChip("After")
                            .padding(8)
                    }

                handle(at: width * fraction, height: proxy.size.height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newFraction = min(1, max(0, value.location.x / width))
                        if abs(newFraction - fraction) > 0.01 {
                            fraction = newFraction
                        }
                    }
            )
        }
    }

    private func handle(at x: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.95))
            .frame(width: 2, height: height)
            .position(x: x, y: height / 2)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black)
                    )
                    .shadow(color: .black.opacity(0.30), radius: 4, x: 0, y: 2)
                    .position(x: x, y: height / 2)
            )
    }

    private func labelChip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(Color.white)
    }
}
