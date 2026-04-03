import SwiftUI

// MARK: - Generation Step

enum GenerationStep: Int, CaseIterable {
    case uploading = 0
    case analyzing = 1
    case generating = 2
    case styling = 3
    case enhancing = 4
    case finalizing = 5
    
    var title: String {
        switch self {
        case .uploading: return "Uploading photos"
        case .analyzing: return "Analyzing faces"
        case .generating: return "Generating your photos"
        case .styling: return "Applying style"
        case .enhancing: return "Enhancing details"
        case .finalizing: return "Final polish"
        }
    }
    
    var icon: String {
        switch self {
        case .uploading: return "icloud.and.arrow.up"
        case .analyzing: return "eye"
        case .generating: return "wand.and.stars"
        case .styling: return "paintbrush"
        case .enhancing: return "sparkles"
        case .finalizing: return "checkmark.circle"
        }
    }
    
    var progressRange: ClosedRange<Double> {
        switch self {
        case .uploading: return 0.0...0.15
        case .analyzing: return 0.15...0.30
        case .generating: return 0.30...0.70
        case .styling: return 0.70...0.85
        case .enhancing: return 0.85...0.95
        case .finalizing: return 0.95...1.0
        }
    }
    
    static func fromProgress(_ progress: Double) -> GenerationStep {
        for step in GenerationStep.allCases where progress <= step.progressRange.upperBound {
            return step
        }
        return .finalizing
    }
}

// MARK: - Generation Loading View

struct GenerationLoadingView: View {
    @Binding var progress: Double
    @Binding var isGenerating: Bool
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    @State private var currentStep: GenerationStep = .uploading
    @State private var showCompletionFlash = false
    @State private var particles: [FlameParticle] = []
    @State private var showCancelConfirmation = false
    @State private var estimatedTimeRemaining = 30
    @State private var hasCompleted = false
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background with animated gradient
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            // Flame particles (Canvas-based for battery efficiency)
            FlameParticleCanvas(particles: particles)
                .ignoresSafeArea()
                .opacity(0.15)
            
            // Main content
            VStack(spacing: DesignSystem.Spacing.large) {
                Spacer()
                
                // Progress indicator
                ProgressStepIndicator(
                    currentStep: currentStep,
                    progress: progress
                )
                
                // Main progress display
                MainProgressDisplay(
                    progress: progress,
                    currentStep: currentStep,
                    estimatedTime: estimatedTimeRemaining
                )
                
                // Tips carousel
                GenerationTipsView()
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                
                Spacer()
                
                // Cancel button
                CancelButton(onTap: {
                    showCancelConfirmation = true
                })
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
            
            // Completion flash overlay
            if showCompletionFlash {
                CompletionFlashOverlay()
            }
            
            // Cancel confirmation dialog
            if showCancelConfirmation {
                CancelConfirmationDialog(
                    onConfirm: {
                        showCancelConfirmation = false
                        onCancel()
                    },
                    onDismiss: {
                        showCancelConfirmation = false
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            updateState()
        }
        .onChange(of: progress) {
            currentStep = GenerationStep.fromProgress(progress)
            estimatedTimeRemaining = Int((1.0 - progress) * 30)
            
            // Trigger completion when progress reaches 100%
            if progress >= 1.0 && !hasCompleted {
                hasCompleted = true
                triggerCompletion()
            }
        }
        .onAppear {
            initializeParticles()
        }
    }
    
    // MARK: - State Updates
    
    private func updateState() {
        // Update particles
        updateParticles()
        
        // Haptic feedback on step transitions
        let newStep = GenerationStep.fromProgress(progress)
        if newStep != currentStep {
            currentStep = newStep
            DesignSystem.Haptics.light()
        }
    }
    
    private func triggerCompletion() {
        // Flash animation
        withAnimation(.easeOut(duration: 0.15)) {
            showCompletionFlash = true
        }
        
        // Success haptic
        DesignSystem.Haptics.success()
        
        // Delay then call completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.15)) {
                showCompletionFlash = false
            }
            onComplete()
        }
    }
    
    // MARK: - Particle System
    
    private func initializeParticles() {
        particles = (0..<25).map { _ in FlameParticle() }
    }
    
    private func updateParticles() {
        for index in particles.indices {
            particles[index].update()
        }
    }
}

// MARK: - Progress Step Indicator

struct ProgressStepIndicator: View {
    let currentStep: GenerationStep
    let progress: Double
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(GenerationStep.allCases, id: \.self) { step in
                StepDot(
                    step: step,
                    isCompleted: step.rawValue < currentStep.rawValue,
                    isCurrent: step == currentStep,
                    progress: step == currentStep ? stepProgress(for: step) : 1.0
                )
                
                if step.rawValue < GenerationStep.allCases.count - 1 {
                    StepConnector(
                        isCompleted: step.rawValue < currentStep.rawValue,
                        isActive: step == currentStep || step.rawValue < currentStep.rawValue
                    )
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
    }
    
    private func stepProgress(for step: GenerationStep) -> Double {
        let range = step.progressRange
        let normalizedProgress = (progress - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(normalizedProgress, 0), 1)
    }
}

struct StepDot: View {
    let step: GenerationStep
    let isCompleted: Bool
    let isCurrent: Bool
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isCompleted || isCurrent
                        ? DesignSystem.Colors.flameOrange
                        : DesignSystem.Colors.textSecondary.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: 32, height: 32)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            } else if isCurrent {
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        DesignSystem.Colors.flameOrange,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: step.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
    }
}

struct StepConnector: View {
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(
                isCompleted
                    ? DesignSystem.Colors.flameOrange
                    : isActive
                        ? DesignSystem.Colors.flameOrange.opacity(0.3)
                        : DesignSystem.Colors.textSecondary.opacity(0.2)
            )
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Main Progress Display

struct MainProgressDisplay: View {
    let progress: Double
    let currentStep: GenerationStep
    let estimatedTime: Int
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(DesignSystem.Typography.scoreDisplay)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: progress)
            
            // Current step title
            Text(currentStep.title)
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .transition(.opacity)
                .id(currentStep)
            
            // Progress bar
            ProgressBar(progress: progress)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
            
            // Estimated time
            if estimatedTime > 0 {
                Text("About \(estimatedTime) seconds remaining")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            } else {
                Text("Finalizing...")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .frame(height: 8)
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.snappy(duration: 0.3), value: progress)
                
                // Glow effect
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.flameOrange.opacity(0.3))
                    .frame(width: geometry.size.width * progress + 10, height: 12)
                    .blur(radius: 4)
                    .animation(.snappy(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: [
                DesignSystem.Colors.deepNight,
                DesignSystem.Colors.background,
                DesignSystem.Colors.deepNight.opacity(0.8)
            ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5 + sin(phase) * 0.1, y: 1)
        )
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                phase = .pi * 0.3
            }
        }
    }
}

// MARK: - Flame Particle System

struct FlameParticle: Equatable {
    var posX: CGFloat
    var posY: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    
    init() {
        posX = CGFloat.random(in: 0...1)
        posY = CGFloat.random(in: 0.5...1.2)
        size = CGFloat.random(in: 3...8)
        opacity = CGFloat.random(in: 0.1...0.3)
        speed = CGFloat.random(in: 0.002...0.008)
    }
    
    func update() -> FlameParticle {
        var new = self
        new.posY -= speed
        
        // Reset when reaching top
        if new.posY < -0.2 {
            new.posY = CGFloat.random(in: 1.0...1.2)
            new.posX = CGFloat.random(in: 0...1)
            new.opacity = CGFloat.random(in: 0.1...0.3)
        }
        
        // Fade out near top
        if new.posY < 0.2 {
            new.opacity *= 0.98
        }
        
        return new
    }
    
    static func == (lhs: FlameParticle, rhs: FlameParticle) -> Bool {
        lhs.posX == rhs.posX && lhs.posY == rhs.posY
    }
}

struct FlameParticleCanvas: View {
    let particles: [FlameParticle]
    
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                for particle in particles {
                    let canvasX = particle.posX * size.width
                    let canvasY = particle.posY * size.height
                    
                    var path = Path()
                    path.addEllipse(in: CGRect(
                        x: canvasX - particle.size / 2,
                        y: canvasY - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    ))
                    
                    context.fill(
                        path,
                        with: .color(DesignSystem.Colors.flameOrange.opacity(particle.opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Cancel Button

struct CancelButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("Cancel")
                .font(DesignSystem.Typography.smallButton)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                )
        }
    }
}

// MARK: - Cancel Confirmation Dialog

struct CancelConfirmationDialog: View {
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.Colors.warning)
                
                Text("Cancel Generation?")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("Your photos will be lost and you'll return to the photo picker.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: DesignSystem.Spacing.medium) {
                    Button {
                        onDismiss()
                        DesignSystem.Haptics.light()
                    } label: {
                        Text("Continue Waiting")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.medium)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        onConfirm()
                        DesignSystem.Haptics.medium()
                    } label: {
                        Text("Yes, Cancel")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.error)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.medium)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge))
            .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
    }
}

// MARK: - Completion Flash Overlay

struct CompletionFlashOverlay: View {
    var body: some View {
        Color.white
            .ignoresSafeArea()
            .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    GenerationLoadingView(
        progress: .constant(0.45),
        isGenerating: .constant(true),
        onCancel: {},
        onComplete: {}
    )
}
