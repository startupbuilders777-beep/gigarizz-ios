import SwiftUI

// MARK: - Permission Type

enum PermissionType {
    case photo
    case notification
}

// MARK: - Onboarding V2 ViewModel — 30-Step Story Engine

/// Manages the 30-slide story-driven onboarding.
/// Slides are grouped into 5 phases: Pain → Dream → How → Proof → Close.
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var currentPage: Int = 0
    @Published var hasSeenOnboarding: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var selectedPlan: OnboardingPlan = .plus

    // MARK: - Slide Data — 30 Steps

    let slides: [OnboardingSlide] = {
        var s: [OnboardingSlide] = []

        // ── PHASE 1: PAIN (Slides 0-6) — Empathy hook, problem awareness ──

        s.append(OnboardingSlide(
            phase: .pain, type: .icon, icon: "heart.slash.fill",
            title: "Dating Is Hard.",
            subtitle: "Endless swiping. Ghosting. The same 5 matches. You deserve better.",
            accentColor: DesignSystem.Colors.error
        ))
        s.append(OnboardingSlide(
            phase: .pain, type: .stat, icon: "eye.fill",
            title: "First Impressions\nAre Everything",
            subtitle: "Before your bio, before your opener — they see your photo.",
            accentColor: DesignSystem.Colors.warning,
            stat: SlideStat(value: "7s", label: "to decide on a swipe", icon: "timer")
        ))
        s.append(OnboardingSlide(
            phase: .pain, type: .icon, icon: "camera.fill",
            title: "Your Photos Are\nHolding You Back",
            subtitle: "Bad lighting. Awkward selfies. Group photos where nobody knows which one is you.",
            accentColor: DesignSystem.Colors.error
        ))
        s.append(OnboardingSlide(
            phase: .pain, type: .stat, icon: "chart.line.downtrend.xyaxis",
            title: "The Harsh Truth",
            subtitle: "Most people swipe left within 3 seconds. Your phone camera isn't optimized for attraction.",
            accentColor: DesignSystem.Colors.error,
            stat: SlideStat(value: "83%", label: "judge by photos alone", icon: "chart.bar.fill")
        ))
        s.append(OnboardingSlide(
            phase: .pain, type: .icon, icon: "dollarsign.circle.fill",
            title: "Professional Shoots\nCost a Fortune",
            subtitle: "A photographer charges $300-$800 per session. And the results still might not work for dating apps.",
            accentColor: DesignSystem.Colors.warning
        ))
        s.append(OnboardingSlide(
            phase: .pain, type: .icon, icon: "person.fill.questionmark",
            title: "You Don't Know What\nMakes a Good Photo",
            subtitle: "Is it the angle? The lighting? The smile? The background? It's all of them — and more.",
            accentColor: DesignSystem.Colors.textSecondary
        ))
        s.append(OnboardingSlide(
            phase: .pain, type: .icon, icon: "lightbulb.fill",
            title: "What If There Was\na Better Way?",
            subtitle: "What if AI could analyze your face and create the exact photos that get right-swipes?",
            accentColor: DesignSystem.Colors.goldAccent
        ))

        // ── PHASE 2: DREAM (Slides 7-14) — Vision & possibility ──

        s.append(OnboardingSlide(
            phase: .dream, type: .icon, icon: "flame.fill",
            title: "Meet GigaRizz",
            subtitle: "The AI dating photo engine that turns your selfies into magazine-quality dating photos.",
            accentColor: DesignSystem.Colors.flameOrange
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .icon, icon: "wand.and.stars",
            title: "Magazine-Quality\nDating Photos",
            subtitle: "Professional lighting, perfect angles, stunning backgrounds — all generated from your face.",
            accentColor: DesignSystem.Colors.goldAccent
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .modelShowcase, icon: "cpu.fill",
            title: "16 AI Models.\n3 Providers.",
            subtitle: "From Flux Pro Ultra to GPT Image 1, RealVisXL to Recraft V3 — choose the one that makes you look best.",
            accentColor: DesignSystem.Colors.flameOrange
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .styleShowcase, icon: "paintpalette.fill",
            title: "10+ Styles.\nAny Vibe.",
            subtitle: "Confident, adventurous, golden hour, luxury, urban moody — express every side of yourself.",
            accentColor: DesignSystem.Colors.goldAccent
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .icon, icon: "person.crop.square.fill",
            title: "Professional\nHeadshots",
            subtitle: "Clean, confident, LinkedIn-meets-Hinge energy. The kind that says 'I have my life together.'",
            accentColor: Color(hex: "4A90D9")
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .icon, icon: "sun.max.fill",
            title: "Golden Hour\nMagic",
            subtitle: "That warm sunset glow that makes everyone look 10x more attractive. Generated in 60 seconds.",
            accentColor: Color(hex: "FFB347")
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .icon, icon: "building.2.fill",
            title: "Night Out &\nUrban Moody",
            subtitle: "Upscale bar vibes, neon city lights, rooftop energy. For when you want to look like the main character.",
            accentColor: Color(hex: "9B59B6")
        ))
        s.append(OnboardingSlide(
            phase: .dream, type: .icon, icon: "airplane",
            title: "Adventure &\nTravel Vibes",
            subtitle: "Mountain peaks, tropical beaches, European cafés. Show them you're someone worth exploring the world with.",
            accentColor: DesignSystem.Colors.success
        ))

        // ── PHASE 3: HOW IT WORKS (Slides 15-20) — Process ──

        s.append(OnboardingSlide(
            phase: .how, type: .icon, icon: "1.circle.fill",
            title: "Upload 3-5 Selfies",
            subtitle: "Just regular photos of your face. No fancy setup needed — your bathroom mirror selfie works.",
            accentColor: DesignSystem.Colors.flameOrange
        ))
        s.append(OnboardingSlide(
            phase: .how, type: .icon, icon: "2.circle.fill",
            title: "Pick Your Style",
            subtitle: "Choose from 10+ curated styles. Confident, adventurous, luxury — whatever matches your vibe.",
            accentColor: DesignSystem.Colors.goldAccent
        ))
        s.append(OnboardingSlide(
            phase: .how, type: .icon, icon: "3.circle.fill",
            title: "Choose Your\nAI Model",
            subtitle: "Fast models for quick results. Premium models for ultra-photorealistic quality. You control the output.",
            accentColor: DesignSystem.Colors.success
        ))
        s.append(OnboardingSlide(
            phase: .how, type: .stat, icon: "4.circle.fill",
            title: "AI Generates\nin 60 Seconds",
            subtitle: "Our multi-model engine processes your photos and generates stunning dating-optimized results.",
            accentColor: DesignSystem.Colors.flameOrange,
            stat: SlideStat(value: "60s", label: "average generation time", icon: "bolt.fill")
        ))
        s.append(OnboardingSlide(
            phase: .how, type: .icon, icon: "5.circle.fill",
            title: "Batch Generate\nAcross Models",
            subtitle: "Compare results from Flux Pro, DALL-E 3, and RealVisXL side-by-side. Pick the one that hits hardest.",
            accentColor: DesignSystem.Colors.goldAccent
        ))
        s.append(OnboardingSlide(
            phase: .how, type: .icon, icon: "6.circle.fill",
            title: "Download &\nDominate",
            subtitle: "Save to your camera roll. Upload to Tinder, Hinge, Bumble. Watch the matches roll in.",
            accentColor: DesignSystem.Colors.success
        ))

        // ── PHASE 4: PROOF (Slides 21-26) — Social proof & trust ──

        s.append(OnboardingSlide(
            phase: .proof, type: .comparison, icon: "arrow.left.arrow.right",
            title: "See the\nDifference",
            subtitle: "Real users. Real transformations. Same person, dramatically better photos.",
            accentColor: DesignSystem.Colors.flameOrange
        ))
        s.append(OnboardingSlide(
            phase: .proof, type: .testimonial, icon: "quote.opening",
            title: "Real Results",
            subtitle: "",
            accentColor: DesignSystem.Colors.goldAccent,
            testimonial: SlideTestimonial(quote: "Got 3x more matches in the first week. My friends thought I hired a photographer.", author: "— Alex, 28, San Francisco")
        ))
        s.append(OnboardingSlide(
            phase: .proof, type: .testimonial, icon: "quote.opening",
            title: "Life Changing",
            subtitle: "",
            accentColor: DesignSystem.Colors.success,
            testimonial: SlideTestimonial(quote: "I went from 2 matches a week to 15. The golden hour style is literally magic.", author: "— Jordan, 26, NYC")
        ))
        s.append(OnboardingSlide(
            phase: .proof, type: .stat, icon: "person.3.fill",
            title: "Join 10,000+\nUsers",
            subtitle: "A growing community of people who refuse to settle for bad dating photos.",
            accentColor: DesignSystem.Colors.flameOrange,
            stat: SlideStat(value: "10K+", label: "photos generated", icon: "photo.stack.fill")
        ))
        s.append(OnboardingSlide(
            phase: .proof, type: .icon, icon: "lock.shield.fill",
            title: "Your Privacy.\nOur Promise.",
            subtitle: "Photos are processed securely and never shared. Delete your data anytime. We don't store what we don't need.",
            accentColor: DesignSystem.Colors.platinum
        ))
        s.append(OnboardingSlide(
            phase: .proof, type: .icon, icon: "hand.raised.fill",
            title: "You Stay\nin Control",
            subtitle: "Choose which photos to keep. Download only what you love. Your face, your rules.",
            accentColor: DesignSystem.Colors.success
        ))

        // ── PHASE 5: CLOSE (Slides 27-29) — Pricing & CTA ──

        s.append(OnboardingSlide(
            phase: .close, type: .icon, icon: "crown.fill",
            title: "Choose Your Plan",
            subtitle: "Start free with 3 photos/day and 4 models. Upgrade for more power.",
            accentColor: DesignSystem.Colors.goldAccent
        ))
        s.append(OnboardingSlide(
            phase: .close, type: .paywall, icon: "flame.fill",
            title: "Unlock\nFull Power",
            subtitle: "Get access to all 16 AI models, batch generation, and unlimited photos.",
            accentColor: DesignSystem.Colors.flameOrange
        ))
        s.append(OnboardingSlide(
            phase: .close, type: .finalCTA, icon: "flame.fill",
            title: "Let's Make Your\nBest First Impression",
            subtitle: "Your dating life is about to change. Ready?",
            accentColor: DesignSystem.Colors.flameOrange
        ))

        return s
    }()

    var totalPages: Int { slides.count }

    var currentSlide: OnboardingSlide {
        guard currentPage >= 0 && currentPage < slides.count else {
            return slides[0]
        }
        return slides[currentPage]
    }

    // MARK: - Phase Helpers

    /// Get the index range for a given phase.
    func phaseRange(_ phase: OnboardingPhase) -> Range<Int> {
        let start = slides.firstIndex { $0.phase == phase } ?? 0
        let end = slides.lastIndex { $0.phase == phase }.map { $0 + 1 } ?? slides.count
        return start..<end
    }

    /// Skip to the end of the current phase and advance to next.
    func skipToPhaseEnd() {
        let currentPhase = currentSlide.phase
        let range = phaseRange(currentPhase)
        withAnimation(DesignSystem.Animation.smoothSpring) {
            currentPage = min(range.upperBound, totalPages - 1)
        }
        saveState()
        DesignSystem.Haptics.light()
    }

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

    // MARK: - Resume

    func shouldShowResumePrompt() -> Bool {
        hasSeenOnboarding && !hasCompletedOnboarding
    }

    func resumeOnboarding() {
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

// MARK: - PostHog Tracking Extensions

extension PostHogManager {
    func trackOnboardingPageViewed(page: Int) {
        track("onboarding_page_viewed", properties: [
            "page_number": page,
            "total_pages": 30,
        ])
    }

    func trackOnboardingCtaTapped(page: Int, cta: String) {
        track("onboarding_cta_tapped", properties: [
            "page_number": page,
            "cta_text": cta,
        ])
    }

    func trackOnboardingDemoPhotoTapped(photoId: Int, selected: Bool) {
        track("onboarding_demo_photo_tapped", properties: [
            "photo_id": photoId,
            "selected": selected,
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
        track("permission_requested", properties: ["permission_type": type])
    }

    func trackPermissionGranted(type: String) {
        track("permission_granted", properties: ["permission_type": type])
    }

    func trackPermissionDenied(type: String) {
        track("permission_denied", properties: ["permission_type": type])
    }

    func trackAppleSignInStarted() {
        track("apple_sign_in_started")
    }

    func trackAppleSignInCompleted() {
        track("apple_sign_in_completed")
    }
}
