import ARKit
import Combine
import SwiftUI

// MARK: - Expression Coach View

/// Real-time camera coaching for dating photo expressions.
/// Uses ARKit face tracking to analyze smile, eye contact, head tilt, and jaw tension.
struct ExpressionCoachView: View {
    @StateObject private var viewModel = ExpressionCoachViewModel()
    @State private var showTips = true

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            if ARFaceTrackingConfiguration.isSupported {
                VStack(spacing: 0) {
                    // Camera preview
                    ARFaceTrackingPreview(viewModel: viewModel)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                        .overlay(cameraOverlay)
                        .padding(.horizontal, DesignSystem.Spacing.medium)

                    // Metrics dashboard
                    metricsSection
                        .padding(.top, DesignSystem.Spacing.medium)

                    // Coaching tip
                    if showTips {
                        coachingTipCard
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                            .padding(.top, DesignSystem.Spacing.small)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: DesignSystem.Spacing.medium)
                }
            } else {
                noARSupportView
            }
        }
        .navigationTitle("Expression Coach")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            PostHogManager.shared.trackEvent("expression_coach_opened")
        }
    }

    // MARK: - Camera Overlay

    private var cameraOverlay: some View {
        VStack {
            // Score badge
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", viewModel.overallScore))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(viewModel.overallScore))
                    Text("Score")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(DesignSystem.Spacing.small)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .padding(DesignSystem.Spacing.small)
            }

            Spacer()

            // Expression state indicator
            HStack {
                Image(systemName: viewModel.expressionIcon)
                    .font(.system(size: 14))
                Text(viewModel.expressionLabel)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(scoreColor(viewModel.overallScore).opacity(0.8))
            .clipShape(Capsule())
            .padding(.bottom, DesignSystem.Spacing.small)
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.small) {
                metricPill(
                    icon: "face.smiling",
                    label: "Smile",
                    value: viewModel.smileScore,
                    target: "Natural"
                )
                metricPill(
                    icon: "eye.fill",
                    label: "Eyes",
                    value: viewModel.eyeScore,
                    target: "Open"
                )
                metricPill(
                    icon: "arrow.up.and.down",
                    label: "Tilt",
                    value: viewModel.headTiltScore,
                    target: "Slight"
                )
                metricPill(
                    icon: "mouth.fill",
                    label: "Jaw",
                    value: viewModel.jawScore,
                    target: "Relaxed"
                )
                metricPill(
                    icon: "person.fill",
                    label: "Symmetry",
                    value: viewModel.symmetryScore,
                    target: "Even"
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
        }
    }

    private func metricPill(icon: String, label: String, value: Double, target: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.surface, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: value / 10)
                    .stroke(scoreColor(value), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(scoreColor(value))
            }
            .frame(width: 40, height: 40)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(String(format: "%.1f", value))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(width: 64)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Coaching Tip

    private var coachingTipCard: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coaching Tip")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(viewModel.coachingTip)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }

    // MARK: - No AR Support

    private var noARSupportView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: "face.dashed")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("Face Tracking Not Available")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("Expression Coach requires a device with TrueDepth camera (iPhone X or later).")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 8...: return DesignSystem.Colors.success
        case 6..<8: return DesignSystem.Colors.goldAccent
        case 4..<6: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }
}

// MARK: - Expression Coach ViewModel

@MainActor
final class ExpressionCoachViewModel: ObservableObject {
    @Published var smileScore: Double = 0
    @Published var eyeScore: Double = 0
    @Published var headTiltScore: Double = 0
    @Published var jawScore: Double = 0
    @Published var symmetryScore: Double = 0
    @Published var overallScore: Double = 0
    @Published var expressionLabel = "Analyzing..."
    @Published var expressionIcon = "face.dashed"
    @Published var coachingTip = "Position your face in the center of the frame"

    /// Update from ARKit blend shapes
    func updateFromBlendShapes(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        // Smile: inner + outer mouth smile blend shapes
        let smileLeft = blendShapes[.mouthSmileLeft]?.doubleValue ?? 0
        let smileRight = blendShapes[.mouthSmileRight]?.doubleValue ?? 0
        let smileRaw = (smileLeft + smileRight) / 2

        // Ideal smile is 0.3–0.6 range (natural, not forced)
        let smileIdeal = 1.0 - abs(smileRaw - 0.45) * 3.0
        smileScore = min(10, max(0, smileIdeal * 10))

        // Eyes: openness. Squint = engaged, too wide = surprised
        let eyeSquintLeft = blendShapes[.eyeSquintLeft]?.doubleValue ?? 0
        let eyeSquintRight = blendShapes[.eyeSquintRight]?.doubleValue ?? 0
        let eyeWideLeft = blendShapes[.eyeWideLeft]?.doubleValue ?? 0
        let eyeWideRight = blendShapes[.eyeWideRight]?.doubleValue ?? 0
        let squint = (eyeSquintLeft + eyeSquintRight) / 2
        let wide = (eyeWideLeft + eyeWideRight) / 2
        // Slight squint = engaged look, which is good
        let eyeIdeal = 1.0 - abs(squint - 0.15) * 2.0 - wide * 2.0
        eyeScore = min(10, max(0, eyeIdeal * 10))

        // Head tilt: slight tilt is attractive, too much is bad
        // We don't get head rotation directly from blend shapes; we'll use
        // eye level difference as a proxy for head tilt
        let browUpLeft = blendShapes[.browOuterUpLeft]?.doubleValue ?? 0
        let browUpRight = blendShapes[.browOuterUpRight]?.doubleValue ?? 0
        let browDiff = abs(browUpLeft - browUpRight)
        let tiltIdeal = 1.0 - browDiff * 5.0  // small diff = good
        headTiltScore = min(10, max(0, tiltIdeal * 10))

        // Jaw: relaxed jaw (not clenched or open)
        let jawOpen = blendShapes[.jawOpen]?.doubleValue ?? 0
        let mouthClose = blendShapes[.mouthClose]?.doubleValue ?? 0
        let jawIdeal = 1.0 - abs(jawOpen - 0.05) * 3.0 - mouthClose * 2.0
        jawScore = min(10, max(0, jawIdeal * 10))

        // Symmetry: compare left vs right blend shapes
        let symSmile = 1.0 - abs(smileLeft - smileRight) * 3.0
        let symSquint = 1.0 - abs(eyeSquintLeft - eyeSquintRight) * 3.0
        let symBrow = 1.0 - browDiff * 5.0
        symmetryScore = min(10, max(0, ((symSmile + symSquint + symBrow) / 3) * 10))

        // Overall weighted
        overallScore = smileScore * 0.3 + eyeScore * 0.25 + headTiltScore * 0.15 + jawScore * 0.1 + symmetryScore * 0.2

        // Expression label
        updateExpressionLabel(smileRaw: smileRaw, squint: squint, jawOpen: jawOpen)

        // Coaching tip - focus on weakest area
        updateCoachingTip()
    }

    private func updateExpressionLabel(smileRaw: Double, squint: Double, jawOpen: Double) {
        if overallScore >= 8 {
            expressionLabel = "Perfect Shot!"
            expressionIcon = "star.fill"
        } else if smileRaw > 0.7 {
            expressionLabel = "Too Much Smile"
            expressionIcon = "face.smiling"
        } else if smileRaw < 0.1 {
            expressionLabel = "Try Smiling"
            expressionIcon = "face.dashed"
        } else if jawOpen > 0.3 {
            expressionLabel = "Close Mouth Slightly"
            expressionIcon = "mouth.fill"
        } else if squint > 0.5 {
            expressionLabel = "Open Eyes More"
            expressionIcon = "eye.slash"
        } else if overallScore >= 6 {
            expressionLabel = "Looking Good"
            expressionIcon = "hand.thumbsup.fill"
        } else {
            expressionLabel = "Keep Adjusting"
            expressionIcon = "arrow.triangle.2.circlepath"
        }
    }

    private func updateCoachingTip() {
        let weakest = min(smileScore, eyeScore, headTiltScore, jawScore, symmetryScore)

        if weakest == smileScore && smileScore < 6 {
            coachingTip = "Think of something funny — a natural smile increases matches by 35%"
        } else if weakest == eyeScore && eyeScore < 6 {
            coachingTip = "Soft eye contact with a slight squint looks confident and engaged"
        } else if weakest == headTiltScore && headTiltScore < 6 {
            coachingTip = "Keep your head level — slight tilt is OK but don't overdo it"
        } else if weakest == jawScore && jawScore < 6 {
            coachingTip = "Relax your jaw and keep lips lightly together"
        } else if weakest == symmetryScore && symmetryScore < 6 {
            coachingTip = "Try to relax both sides of your face evenly"
        } else if overallScore >= 8 {
            coachingTip = "This is your moment — take the photo now!"
        } else {
            coachingTip = "You're getting close — relax and show personality"
        }
    }
}

// MARK: - ARKit Face Tracking Preview

struct ARFaceTrackingPreview: UIViewRepresentable {
    let viewModel: ExpressionCoachViewModel

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        let viewModel: ExpressionCoachViewModel
        private var lastUpdate: Date = .distantPast

        init(viewModel: ExpressionCoachViewModel) {
            self.viewModel = viewModel
        }

        func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }

            // Throttle to ~10 FPS for UI updates
            let now = Date()
            guard now.timeIntervalSince(lastUpdate) >= 0.1 else { return }
            lastUpdate = now

            let blendShapes = faceAnchor.blendShapes
            let vm = viewModel
            Task { @MainActor in
                vm.updateFromBlendShapes(blendShapes)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExpressionCoachView()
    }
    .preferredColorScheme(.dark)
}
