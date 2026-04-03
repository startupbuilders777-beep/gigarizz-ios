import SwiftUI
import UIKit

// MARK: - HapticManager

/// Centralized haptic feedback manager.
/// All methods are safe to call from any thread.
/// Respects the system Reduce Motion accessibility setting.
enum HapticManager {
    
    // MARK: - Impact Haptics
    
    /// Light haptic for subtle button taps and minor interactions.
    static func light() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium haptic for card swipes, snaps, and moderate interactions.
    static func medium() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy haptic for significant actions like destructive operations.
    static func heavy() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Soft haptic for gentle feedback (paywall taps, delicate UI).
    static func soft() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Rigid haptic for sharp, mechanical feedback.
    static func rigid() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Selection Haptics
    
    /// Selection changed haptic for pickers, segmented controls, and selections.
    static func selection() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Notification Haptics
    
    /// Success haptic for completed actions (photo generated, purchase completed).
    static func success() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning haptic for cautionary states (limit reached, attention needed).
    static func warning() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error haptic for failed operations (upload failed, purchase error).
    static func error() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Pattern Haptics
    
    /// Double tap pattern for attention-getting feedback.
    static func doubleTap() {
        light()
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            light()
        }
    }
    
    /// Triple pulse for success celebrations.
    static func triplePulse() {
        medium()
        Task {
            try? await Task.sleep(nanoseconds: 80_000_000)
            medium()
            try? await Task.sleep(nanoseconds: 80_000_000)
            medium()
        }
    }
    
    /// Purchase celebration haptic sequence.
    static func purchaseCelebration() {
        heavy()
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            success()
        }
    }
}

// MARK: - HapticButtonStyle

/// ButtonStyle that automatically provides haptic feedback on tap.
/// Integrates with the design system's spring animation patterns.
struct HapticButtonStyle: ButtonStyle {
    var hapticStyle: HapticStyle = .light
    
    enum HapticStyle {
        case light, medium, heavy, soft, selection
        case success, warning, error
        
        func trigger() {
            switch self {
            case .light: HapticManager.light()
            case .medium: HapticManager.medium()
            case .heavy: HapticManager.heavy()
            case .soft: HapticManager.soft()
            case .selection: HapticManager.selection()
            case .success: HapticManager.success()
            case .warning: HapticManager.warning()
            case .error: HapticManager.error()
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if !isPressed {
                    hapticStyle.trigger()
                }
            }
    }
}

// MARK: - View Extension for Haptics

extension View {
    /// Adds haptic feedback when the view appears.
    func hapticOnAppear(_ style: HapticButtonStyle.HapticStyle = .light) -> some View {
        onAppear { style.trigger() }
    }
    
    /// Adds haptic feedback when the view is tapped.
    func hapticTap(_ style: HapticButtonStyle.HapticStyle = .light) -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in style.trigger() }
        )
    }
}

// MARK: - Preview

#Preview("HapticManager Demo") {
    VStack(spacing: 24) {
        Text("Haptic Demo")
            .font(DesignSystem.Typography.largeTitle)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        
        Group {
            Button("Light Tap") { HapticManager.light() }
            Button("Medium Snap") { HapticManager.medium() }
            Button("Heavy Action") { HapticManager.heavy() }
            Button("Soft Touch") { HapticManager.soft() }
            Button("Selection") { HapticManager.selection() }
            Button("Success ✓") { HapticManager.success() }
            Button("Warning ⚠️") { HapticManager.warning() }
            Button("Error ❌") { HapticManager.error() }
        }
        .buttonStyle(HapticButtonStyle())
        .padding(.horizontal, 40)
        
        Divider()
            .background(DesignSystem.Colors.divider)
            .padding(.vertical, 16)
        
        Text("Button Styles")
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        
        Button("Haptic Light Button") { }
            .buttonStyle(HapticButtonStyle(hapticStyle: .light))
        
        Button("Haptic Medium Button") { }
            .buttonStyle(HapticButtonStyle(hapticStyle: .medium))
        
        Button("Haptic Success Button") { }
            .buttonStyle(HapticButtonStyle(hapticStyle: .success))
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}