import Foundation
import SwiftUI

// MARK: - Milestone Level

enum MilestoneLevel: Int, CaseIterable, Identifiable {
    case bareProfile = 25
    case gettingStarted = 50
    case almostThere = 75
    case profilePowerhouse = 90
    case matchMagnet = 100
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .bareProfile: return "Bare Profile"
        case .gettingStarted: return "Getting Started"
        case .almostThere: return "Almost There"
        case .profilePowerhouse: return "Profile Powerhouse"
        case .matchMagnet: return "Match Magnet"
        }
    }
    
    var icon: String {
        switch self {
        case .bareProfile: return "person.crop.circle"
        case .gettingStarted: return "person.crop.circle.badge.checkmark"
        case .almostThere: return "person.crop.circle.badge.clock"
        case .profilePowerhouse: return "star.circle"
        case .matchMagnet: return "flame.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .bareProfile: return DesignSystem.Colors.textSecondary
        case .gettingStarted: return Color(hex: "CD7F32") // Bronze
        case .almostThere: return Color(hex: "C0C0C0") // Silver
        case .profilePowerhouse: return DesignSystem.Colors.goldAccent
        case .matchMagnet: return DesignSystem.Colors.flameOrange
        }
    }
    
    var rewardCredits: Int {
        switch self {
        case .almostThere: return 1
        case .matchMagnet: return 3
        default: return 0
        }
    }
    
    static func levelForScore(_ score: Int) -> MilestoneLevel {
        let sorted = MilestoneLevel.allCases.sorted(by: { $0.rawValue < $1.rawValue })
        for level in sorted.reversed() {
            if score >= level.rawValue {
                return level
            }
        }
        return .bareProfile
    }
    
    static func nextLevelForScore(_ score: Int) -> MilestoneLevel? {
        let sorted = MilestoneLevel.allCases.sorted(by: { $0.rawValue < $1.rawValue })
        for level in sorted {
            if score < level.rawValue {
                return level
            }
        }
        return nil
    }
}

// MARK: - Completeness Item

struct CompletenessItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let weight: Int
    let isComplete: Bool
    let icon: String
    let actionTitle: String?
    let actionDestination: String?
}

// MARK: - Profile Completeness ViewModel

@MainActor
final class ProfileCompletenessViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var completenessScore: Int = 0
    @Published var currentLevel: MilestoneLevel = .bareProfile
    @Published var nextLevel: MilestoneLevel?
    @Published var completenessItems: [CompletenessItem] = []
    @Published var hasUploadedPhotos: Bool = false
    @Published var photoCount: Int = 0
    @Published var hasWrittenBio: Bool = false
    @Published var hasSelectedStyle: Bool = false
    @Published var hasSavedMultipleRatios: Bool = false
    @Published var savedRatioCount: Int = 0
    @Published var isVerified: Bool = false
    @Published var earnedCredits: Int = 0
    @Published var showRewardBanner: Bool = false
    
    // MARK: - UserDefaults Keys
    
    private let photosUploadedKey = "profile_photos_uploaded"
    private let photoCountKey = "profile_photo_count"
    private let bioWrittenKey = "profile_bio_written"
    private let styleSelectedKey = "profile_style_selected"
    private let ratiosSavedKey = "profile_ratios_saved"
    private let savedRatioCountKey = "profile_saved_ratio_count"
    private let verifiedKey = "profile_verified"
    private let earnedCreditsKey = "profile_earned_credits"
    private let claimedMilestonesKey = "profile_claimed_milestones"
    
    // MARK: - Weights
    
    private let photosWeight = 30
    private let bioWeight = 20
    private let styleWeight = 20
    private let ratiosWeight = 15
    private let verifiedWeight = 15
    
    // MARK: - Init
    
    init() {
        loadFromStorage()
        computeScore()
    }
    
    // MARK: - Load From Storage
    
    private func loadFromStorage() {
        let defaults = UserDefaults.standard
        hasUploadedPhotos = defaults.bool(forKey: photosUploadedKey)
        photoCount = defaults.integer(forKey: photoCountKey)
        hasWrittenBio = defaults.bool(forKey: bioWrittenKey)
        hasSelectedStyle = defaults.bool(forKey: styleSelectedKey)
        hasSavedMultipleRatios = defaults.bool(forKey: ratiosSavedKey)
        savedRatioCount = defaults.integer(forKey: savedRatioCountKey)
        isVerified = defaults.bool(forKey: verifiedKey)
        earnedCredits = defaults.integer(forKey: earnedCreditsKey)
    }
    
    // MARK: - Compute Score
    
    func computeScore() {
        var score = 0
        
        // Photos (30%): Need at least 3 photos for full credit
        if hasUploadedPhotos {
            let photoScore = min(photoCount, 3) * (photosWeight / 3)
            score += photoScore
        }
        
        // Bio (20%)
        if hasWrittenBio {
            score += bioWeight
        }
        
        // Style (20%)
        if hasSelectedStyle {
            score += styleWeight
        }
        
        // Multiple Ratios (15%): Need at least 2 ratios saved
        if hasSavedMultipleRatios && savedRatioCount >= 2 {
            score += ratiosWeight
        } else if savedRatioCount == 1 {
            score += ratiosWeight / 2
        }
        
        // Verified (15%)
        if isVerified {
            score += verifiedWeight
        }
        
        completenessScore = score
        currentLevel = MilestoneLevel.levelForScore(score)
        nextLevel = MilestoneLevel.nextLevelForScore(score)
        
        updateCompletenessItems()
        checkForRewards()
    }
    
    // MARK: - Update Completeness Items
    
    private func updateCompletenessItems() {
        completenessItems = [
            CompletenessItem(
                name: "Photos Uploaded",
                description: photoCount >= 3 ? "\(photoCount) photos uploaded" : "Upload \(max(0, 3 - photoCount)) more photos",
                weight: photosWeight,
                isComplete: photoCount >= 3,
                icon: "photo.on.rectangle.angled",
                actionTitle: photoCount < 3 ? "Add Photos" : nil,
                actionDestination: photoCount < 3 ? "generate" : nil
            ),
            CompletenessItem(
                name: "Bio Written",
                description: hasWrittenBio ? "Bio added to profile" : "Write a bio to attract matches",
                weight: bioWeight,
                isComplete: hasWrittenBio,
                icon: "text.quote",
                actionTitle: hasWrittenBio ? nil : "Write Bio",
                actionDestination: hasWrittenBio ? nil : "coach"
            ),
            CompletenessItem(
                name: "Style Selected",
                description: hasSelectedStyle ? "Style preset chosen" : "Pick your photo style",
                weight: styleWeight,
                isComplete: hasSelectedStyle,
                icon: "sparkles",
                actionTitle: hasSelectedStyle ? nil : "Choose Style",
                actionDestination: hasSelectedStyle ? nil : "generate"
            ),
            CompletenessItem(
                name: "Multiple Ratios",
                description: savedRatioCount >= 2 ? "\(savedRatioCount) aspect ratios saved" : "Save photos for Tinder, Hinge, Bumble",
                weight: ratiosWeight,
                isComplete: savedRatioCount >= 2,
                icon: "aspectratio",
                actionTitle: savedRatioCount < 2 ? "Save Ratios" : nil,
                actionDestination: savedRatioCount < 2 ? "generate" : nil
            ),
            CompletenessItem(
                name: "Profile Verified",
                description: isVerified ? "Account verified" : "Verify your account for trust",
                weight: verifiedWeight,
                isComplete: isVerified,
                icon: "checkmark.seal.fill",
                actionTitle: isVerified ? nil : "Verify",
                actionDestination: nil
            )
        ]
    }
    
    // MARK: - Check For Rewards
    
    private func checkForRewards() {
        let defaults = UserDefaults.standard
        var claimedMilestones = defaults.stringArray(forKey: claimedMilestonesKey) ?? []
        
        // Check if user reached 75% and hasn't claimed
        if completenessScore >= 75 && !claimedMilestones.contains("75") {
            showRewardBanner = true
            earnedCredits += MilestoneLevel.almostThere.rewardCredits
            claimedMilestones.append("75")
            defaults.set(claimedMilestones, forKey: claimedMilestonesKey)
            defaults.set(earnedCredits, forKey: earnedCreditsKey)
            DesignSystem.Haptics.success()
        }
        
        // Check if user reached 100% and hasn't claimed
        if completenessScore >= 100 && !claimedMilestones.contains("100") {
            showRewardBanner = true
            earnedCredits += MilestoneLevel.matchMagnet.rewardCredits
            claimedMilestones.append("100")
            defaults.set(claimedMilestones, forKey: claimedMilestonesKey)
            defaults.set(earnedCredits, forKey: earnedCreditsKey)
            DesignSystem.Haptics.success()
        }
    }
    
    // MARK: - Next Step
    
    var nextStep: CompletenessItem? {
        // Find the first incomplete item with highest weight
        let incomplete = completenessItems.filter { !$0.isComplete }
        return incomplete.max(by: { $0.weight < $1.weight })
    }
    
    var nextStepPointsGain: Int {
        guard let next = nextStep else { return 0 }
        return next.weight
    }
    
    // MARK: - Update Actions
    
    func markPhotosUploaded(count: Int) {
        let defaults = UserDefaults.standard
        hasUploadedPhotos = count > 0
        photoCount = count
        defaults.set(hasUploadedPhotos, forKey: photosUploadedKey)
        defaults.set(photoCount, forKey: photoCountKey)
        computeScore()
    }
    
    func markBioWritten() {
        let defaults = UserDefaults.standard
        hasWrittenBio = true
        defaults.set(true, forKey: bioWrittenKey)
        computeScore()
    }
    
    func markStyleSelected() {
        let defaults = UserDefaults.standard
        hasSelectedStyle = true
        defaults.set(true, forKey: styleSelectedKey)
        computeScore()
    }
    
    func markRatiosSaved(count: Int) {
        let defaults = UserDefaults.standard
        hasSavedMultipleRatios = count >= 2
        savedRatioCount = count
        defaults.set(hasSavedMultipleRatios, forKey: ratiosSavedKey)
        defaults.set(savedRatioCount, forKey: savedRatioCountKey)
        computeScore()
    }
    
    func markVerified() {
        let defaults = UserDefaults.standard
        isVerified = true
        defaults.set(true, forKey: verifiedKey)
        computeScore()
    }
    
    func dismissRewardBanner() {
        showRewardBanner = false
    }
    
    // MARK: - Progress to Next Milestone
    
    var progressToNextMilestone: Double {
        guard let next = nextLevel else { return 1.0 }
        let current = currentLevel.rawValue
        let target = next.rawValue
        return Double(completenessScore - current) / Double(target - current)
    }
}
