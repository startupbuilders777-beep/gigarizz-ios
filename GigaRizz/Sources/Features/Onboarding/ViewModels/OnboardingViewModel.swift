import SwiftUI

// MARK: - Onboarding State Manager

/// Manages onboarding state persistence and progression.
/// Uses UserDefaults for persistence across app launches.
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var currentPage: Int = 0
    @Published var selectedDemoPhotos: Set<Int> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showPermissionEducation: Bool = false
    @Published var permissionType: PermissionType = .photo
    
    // MARK: - Constants
    
    let totalPages = 3
    
    // MARK: - Demo Photos (Sample data for interactive mini-picker)
    
    let demoPhotos: [DemoPhoto] = [
        DemoPhoto(id: 0, imageName: "demo_photo_1", description: "Casual outdoor selfie"),
        DemoPhoto(id: 1, imageName: "demo_photo_2", description: "Professional headshot"),
        DemoPhoto(id: 2, imageName: "demo_photo_3", description: "Golden hour portrait")
    ]
    
    // MARK: - UserDefaults Keys
    
    private let hasSeenOnboardingKey = "onboarding_has_seen"
    private let hasCompletedOnboardingKey = "onboarding_has_completed"
    private let lastOnboardingPageKey = "onboarding_last_page"
    
    // MARK: - Init
    
    init() {
        loadState()
    }
    
    // MARK: - State Persistence
    
    private func loadState() {
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        
        // Resume from last page if mid-onboarding
        if hasSeenOnboarding && !hasCompletedOnboarding {
            currentPage = UserDefaults.standard.integer(forKey: lastOnboardingPageKey)
        }
    }
    
    private func saveState() {
        UserDefaults.standard.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey)
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.set(currentPage, forKey: lastOnboardingPageKey)
    }
    
    // MARK: - Navigation
    
    func advancePage() {
        if currentPage < totalPages - 1 {
            withAnimation(DesignSystem.Animation.smoothSpring) {
                currentPage += 1
            }
            hasSeenOnboarding = true
            saveState()
            PostHogManager.shared.trackOnboardingPageViewed(page: currentPage + 1)
            DesignSystem.Haptics.selection()
        } else {
            completeOnboarding()
        }
    }
    
    func skipOnboarding() {
        hasCompletedOnboarding = true
        saveState()
        PostHogManager.shared.trackOnboardingSkipped()
        DesignSystem.Haptics.light()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        hasSeenOnboarding = true
        saveState()
        PostHogManager.shared.trackOnboardingCompleted()
        DesignSystem.Haptics.success()
    }
    
    // MARK: - Demo Photo Selection
    
    func toggleDemoPhoto(id: Int) {
        withAnimation(DesignSystem.Animation.quickSpring) {
            if selectedDemoPhotos.contains(id) {
                selectedDemoPhotos.remove(id)
            } else {
                selectedDemoPhotos.insert(id)
            }
        }
        DesignSystem.Haptics.light()
        PostHogManager.shared.trackOnboardingDemoPhotoTapped(photoId: id, selected: selectedDemoPhotos.contains(id))
    }
    
    // MARK: - Permission Flow
    
    func requestPhotoPermission() {
        showPermissionEducation = true
        permissionType = .photo
        PostHogManager.shared.trackPermissionRequested(type: "photo")
    }
    
    func requestNotificationPermission() {
        showPermissionEducation = true
        permissionType = .notification
        PostHogManager.shared.trackPermissionRequested(type: "notification")
    }
    
    // MARK: - Resume Prompt
    
    func shouldShowResumePrompt() -> Bool {
        return hasSeenOnboarding && !hasCompletedOnboarding
    }
    
    func resumeOnboarding() {
        // Continue from where they left off
        PostHogManager.shared.trackOnboardingResumed()
        DesignSystem.Haptics.medium()
    }
    
    func restartOnboarding() {
        currentPage = 0
        hasSeenOnboarding = false
        saveState()
        PostHogManager.shared.trackOnboardingRestarted()
        DesignSystem.Haptics.light()
    }
}

// MARK: - Supporting Types

struct DemoPhoto: Identifiable {
    let id: Int
    let imageName: String
    let description: String
}

enum PermissionType {
    case photo
    case notification
}

// MARK: - PostHog Tracking Extensions

extension PostHogManager {
    func trackOnboardingPageViewed(page: Int) {
        track("onboarding_page_viewed", properties: [
            "page_number": page,
            "page_name": pageName(for: page)
        ])
    }
    
    func trackOnboardingCtaTapped(page: Int, cta: String) {
        track("onboarding_cta_tapped", properties: [
            "page_number": page,
            "cta_text": cta
        ])
    }
    
    func trackOnboardingDemoPhotoTapped(photoId: Int, selected: Bool) {
        track("onboarding_demo_photo_tapped", properties: [
            "photo_id": photoId,
            "selected": selected
        ])
    }
    
    func trackOnboardingSkipped() {
        track("onboarding_skipped")
    }
    
    func trackOnboardingResumed() {
        track("onboarding_resumed")
    }
    
    func trackOnboardingRestarted() {
        track("onboarding_restarted")
    }
    
    func trackPermissionRequested(type: String) {
        track("permission_requested", properties: [
            "permission_type": type
        ])
    }
    
    func trackPermissionGranted(type: String) {
        track("permission_granted", properties: [
            "permission_type": type
        ])
    }
    
    func trackPermissionDenied(type: String) {
        track("permission_denied", properties: [
            "permission_type": type
        ])
    }
    
    func trackAppleSignInStarted() {
        track("apple_sign_in_started")
    }
    
    func trackAppleSignInCompleted() {
        track("apple_sign_in_completed")
    }
    
    private func pageName(for page: Int) -> String {
        switch page {
        case 1: return "promise"
        case 2: return "how_it_works"
        case 3: return "demo_picker"
        default: return "unknown"
        }
    }
}