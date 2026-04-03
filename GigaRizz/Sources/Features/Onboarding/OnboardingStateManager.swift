import SwiftUI

// MARK: - Onboarding State Manager

/// Manages onboarding state persistence for returning user detection and resume experience.
@MainActor
final class OnboardingStateManager: ObservableObject {
    // MARK: - Singleton

    static let shared = OnboardingStateManager()

    // MARK: - Published Properties

    @Published var currentStep: OnboardingStep = .welcome
    @Published var hasCompletedOnboarding: Bool = false
    @Published var lastCompletedStep: Int = 0
    @Published var showResumePrompt: Bool = false

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastCompletedStep = "onboarding_lastCompletedStep"
        static let hasSeenPhotoTutorial = "onboarding_hasSeenPhotoTutorial"
        static let onboardingStartedAt = "onboarding_startedAt"
    }

    // MARK: - Init

    private init() {
        loadState()
    }

    // MARK: - Public Methods

    /// Called on app launch to determine onboarding state.
    func determineLaunchState() -> OnboardingLaunchState {
        if hasCompletedOnboarding {
            return .completed
        }

        if lastCompletedStep > 0 && lastCompletedStep < OnboardingStep.allCases.count - 1 {
            showResumePrompt = true
            return .partial(lastCompletedStep)
        }

        return .fresh
    }

    /// Start fresh onboarding (reset all state).
    func startFresh() {
        lastCompletedStep = 0
        currentStep = .welcome
        showResumePrompt = false
        UserDefaults.standard.removeObject(forKey: Keys.lastCompletedStep)
        UserDefaults.standard.removeObject(forKey: Keys.hasSeenPhotoTutorial)
        UserDefaults.standard.removeObject(forKey: Keys.onboardingStartedAt)
        PostHogManager.shared.track("onboarding_started", properties: ["type": "fresh"])
    }

    /// Resume from last completed step.
    func resumeFromLastStep() {
        let resumeStep = OnboardingStep.fromIndex(lastCompletedStep + 1)
        currentStep = resumeStep
        showResumePrompt = false
        PostHogManager.shared.track("onboarding_resumed", properties: [
            "resume_step": resumeStep.rawValue,
            "last_completed": lastCompletedStep
        ])
    }

    /// Mark step as completed.
    func completeStep(_ step: OnboardingStep) {
        lastCompletedStep = step.index
        UserDefaults.standard.set(step.index, forKey: Keys.lastCompletedStep)

        // Track step completion
        PostHogManager.shared.track("onboarding_step_completed", properties: [
            "step": step.rawValue,
            "step_index": step.index,
            "total_steps": OnboardingStep.allCases.count
        ])
    }

    /// Complete entire onboarding flow.
    func completeOnboarding() {
        hasCompletedOnboarding = true
        lastCompletedStep = OnboardingStep.allCases.count - 1
        showResumePrompt = false

        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.set(lastCompletedStep, forKey: Keys.lastCompletedStep)

        PostHogManager.shared.trackOnboardingCompleted()
        DesignSystem.Haptics.success()
    }

    /// Reset onboarding for re-entry from Settings (Photo Tutorial only).
    func resetForPhotoTutorial() {
        // Only reset to photo tutorial step (step 1), not full flow
        hasCompletedOnboarding = false
        lastCompletedStep = 0
        currentStep = .photoTutorial
        showResumePrompt = false

        UserDefaults.standard.set(false, forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.set(0, forKey: Keys.lastCompletedStep)

        PostHogManager.shared.track("onboarding_retake_photo_tutorial")
    }

    /// Check if user has seen photo tutorial.
    var hasSeenPhotoTutorial: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasSeenPhotoTutorial) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasSeenPhotoTutorial) }
    }

    // MARK: - Private Methods

    private func loadState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        lastCompletedStep = UserDefaults.standard.integer(forKey: Keys.lastCompletedStep)

        // If completed, set last step to max
        if hasCompletedOnboarding {
            lastCompletedStep = OnboardingStep.allCases.count - 1
        }
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: String, CaseIterable {
    case welcome = "Welcome"
    case photoTutorial = "Photo Tutorial"
    case permissions = "Permissions"
    case completion = "Completion"

    var index: Int {
        OnboardingStep.allCases.firstIndex(of: self) ?? 0
    }

    static func fromIndex(_ index: Int) -> OnboardingStep {
        guard index >= 0, index < allCases.count else { return .welcome }
        return allCases[index]
    }

    /// Step 3 (permissions) cannot be skipped.
    var canSkip: Bool {
        self != .permissions
    }
}

// MARK: - Onboarding Launch State

enum OnboardingLaunchState {
    case fresh
    case partial(Int)
    case completed
}