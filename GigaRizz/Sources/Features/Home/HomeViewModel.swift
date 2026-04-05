import Foundation
import SwiftUI

// MARK: - Home View Model

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var userGreeting: String = "Hey! 👋"
    @Published var photosGenerated: Int = 0
    @Published var daysActive: Int = 0
    @Published var profilesUpdated: Int = 0
    @Published var recentGenerations: [RecentGeneration] = []
    @Published var dailyTip: HomeDailyTip = .defaultTip
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var showOnboardingBanner: Bool = false
    
    // MARK: - Services
    
    private let storageManager = StorageManager.shared
    private var tipIndex: Int = 0
    
    // MARK: - Computed Properties
    
    var stats: UserStats {
        UserStats(
            photosGenerated: photosGenerated,
            daysActive: daysActive,
            profilesUpdated: profilesUpdated
        )
    }
    
    // MARK: - Init
    
    init() {
        loadDashboardData()
        updateDailyTip()
    }
    
    // MARK: - Public Methods
    
    func refresh() async {
        isRefreshing = true
        // Simulate network fetch
        try? await Task.sleep(nanoseconds: 500_000_000)
        loadDashboardData()
        isRefreshing = false
        DesignSystem.Haptics.success()
    }
    
    func loadDashboardData() {
        // Load from UserDefaults for demo
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding_has_completed")
        showOnboardingBanner = !hasCompletedOnboarding
        
        // Load stats
        photosGenerated = UserDefaults.standard.integer(forKey: "home_photos_generated")
        daysActive = UserDefaults.standard.integer(forKey: "home_days_active")
        profilesUpdated = UserDefaults.standard.integer(forKey: "home_profiles_updated")
        
        // Load user name for greeting
        if let userName = UserDefaults.standard.string(forKey: "user_display_name"), !userName.isEmpty {
            userGreeting = "Hey \(userName)! 👋"
        }
        
        // Load recent generations (mock data for demo)
        loadRecentGenerations()
    }
    
    func incrementPhotoCount() {
        photosGenerated += 1
        UserDefaults.standard.set(photosGenerated, forKey: "home_photos_generated")
    }
    
    func incrementDaysActive() {
        daysActive += 1
        UserDefaults.standard.set(daysActive, forKey: "home_days_active")
    }
    
    // MARK: - Daily Tip Rotation
    
    func updateDailyTip() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastTipDate = UserDefaults.standard.object(forKey: "last_tip_date") as? Date

        if let lastTipDate, Calendar.current.isDate(lastTipDate, inSameDayAs: today) {
            // Use stored tip index
            tipIndex = UserDefaults.standard.integer(forKey: "tip_index")
            dailyTip = HomeDailyTip.allTips[tipIndex]
        } else {
            // Rotate to next tip
            tipIndex = (tipIndex + 1) % HomeDailyTip.allTips.count
            dailyTip = HomeDailyTip.allTips[tipIndex]
            UserDefaults.standard.set(today, forKey: "last_tip_date")
            UserDefaults.standard.set(tipIndex, forKey: "tip_index")
        }
    }

    // MARK: - Recent Generations
    
    private func loadRecentGenerations() {
        // Load from gallery persistent storage (shared with GalleryViewModel)
        let photosKey = "gigarizz_generated_photos"
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data),
           !photos.isEmpty {
            // Group by style and take the most recent of each
            let sorted = photos.sorted { $0.createdAt > $1.createdAt }
            let grouped = Dictionary(grouping: sorted, by: { $0.style })
            recentGenerations = grouped.prefix(5).compactMap { style, photos in
                guard let latest = photos.first else { return nil }
                return RecentGeneration(
                    id: latest.id,
                    style: style,
                    date: latest.createdAt,
                    photoCount: photos.count
                )
            }.sorted { $0.date > $1.date }
        } else {
            recentGenerations = []
        }
    }
    
    func clearOnboardingBanner() {
        showOnboardingBanner = false
    }
}

// MARK: - Models

struct UserStats {
    let photosGenerated: Int
    let daysActive: Int
    let profilesUpdated: Int
}

struct RecentGeneration: Identifiable {
    let id: String
    let style: String
    let date: Date
    let photoCount: Int
    
    var dateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct HomeDailyTip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let icon: String
    
    static let defaultTip = HomeDailyTip(
        title: "Photo Tip",
        content: "Natural lighting during golden hour creates the most flattering photos.",
        icon: "sun.max.fill"
    )
    
    static let allTips: [HomeDailyTip] = [
        HomeDailyTip(
            title: "Photo Tip",
            content: "Natural lighting during golden hour creates the most flattering photos.",
            icon: "sun.max.fill"
        ),
        HomeDailyTip(
            title: "Profile Tip",
            content: "Show your hobbies in photos — people with activity photos get 40% more matches.",
            icon: "figure.run"
        ),
        HomeDailyTip(
            title: "Bio Tip",
            content: "Keep your bio under 3 lines. Short bios are read 2x more often.",
            icon: "text.quote"
        ),
        HomeDailyTip(
            title: "Style Tip",
            content: "Solid colors photograph better than patterns. Avoid busy prints.",
            icon: "tshirt.fill"
        ),
        HomeDailyTip(
            title: "Match Tip",
            content: "Respond within 24 hours. Fast responses lead to 3x more conversations.",
            icon: "bubble.left.and.bubble.right.fill"
        ),
        HomeDailyTip(
            title: "Opening Tip",
            content: "Ask about something in their profile. Personalized opens get 65% more replies.",
            icon: "text.bubble.fill"
        ),
        HomeDailyTip(
            title: "Confidence Tip",
            content: "Smile naturally — forced smiles look awkward. Think of something funny.",
            icon: "face.smiling.fill"
        )
    ]
}

// MARK: - Quick Action

enum QuickAction: Identifiable, CaseIterable {
    case photoPicker
    case rizzCoach
    case profileScore
    case myGallery
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .photoPicker: return "Generate"
        case .rizzCoach: return "Coach"
        case .profileScore: return "Score"
        case .myGallery: return "Gallery"
        }
    }
    
    var subtitle: String {
        switch self {
        case .photoPicker: return "New photos"
        case .rizzCoach: return "Get advice"
        case .profileScore: return "Audit profile"
        case .myGallery: return "View all"
        }
    }
    
    var icon: String {
        switch self {
        case .photoPicker: return "wand.and.stars"
        case .rizzCoach: return "brain.head.profile"
        case .profileScore: return "chart.bar.fill"
        case .myGallery: return "photo.on.rectangle.angled"
        }
    }
    
    /// Returns the tab to switch to, or nil if this action should push via NavigationLink
    var switchesTab: MainTabView.Tab? {
        switch self {
        case .photoPicker: return .generate
        case .rizzCoach: return .coach
        case .profileScore: return nil
        case .myGallery: return nil
        }
    }
}