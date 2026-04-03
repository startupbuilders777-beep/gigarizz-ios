import SwiftUI

// MARK: - Home ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    // Published State
    @Published var photosGenerated: Int = 0
    @Published var daysActive: Int = 0
    @Published var profilesUpdated: Int = 0
    @Published var onboardingComplete: Bool = true
    @Published var recentGenerations: [GenerationRecord] = []
    @Published var dailyTip: String = ""
    @Published var isRefreshing: Bool = false

    // Computed Properties
    var hasRecentGenerations: Bool {
        !recentGenerations.isEmpty
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        switch hour {
        case 6..<12: greeting = "Good morning"
        case 12..<18: greeting = "Good afternoon"
        case 18..<22: greeting = "Good evening"
        default: greeting = "Hey there"
        }
        return "\(greeting)! 👋"
    }

    var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Data Loading

    func loadDashboardData() {
        loadStats()
        loadRecentGenerations()
        loadDailyTip()
        checkOnboardingStatus()
    }

    func refresh() async {
        isRefreshing = true
        loadDashboardData()
        try? await Task.sleep(for: .milliseconds(500))
        isRefreshing = false
    }

    // MARK: - Private Methods

    private func loadStats() {
        // Load from UserDefaults or Firestore
        let defaults = UserDefaults.standard
        photosGenerated = defaults.integer(forKey: "photosGenerated")
        daysActive = defaults.integer(forKey: "daysActive")
        profilesUpdated = defaults.integer(forKey: "profilesUpdated")

        // Update days active if last active date is today
        updateDaysActive()
    }

    private func updateDaysActive() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let lastActiveDate = defaults.object(forKey: "lastActiveDate") as? Date ?? today

        if lastActiveDate < today {
            daysActive += 1
            defaults.set(daysActive, forKey: "daysActive")
            defaults.set(today, forKey: "lastActiveDate")
        }
    }

    private func loadRecentGenerations() {
        // Load generation history from UserDefaults or Firestore
        // For now, use demo data if empty
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "recentGenerations"),
           let decoded = try? JSONDecoder().decode([GenerationRecord].self, from: data) {
            recentGenerations = decoded
        } else {
            // Empty state for new users
            recentGenerations = []
        }
    }

    private func loadDailyTip() {
        // Rotate daily tips based on calendar day
        let tips = [
            "Smile naturally in photos — a genuine smile gets 20% more matches than forced poses.",
            "Show your hobbies in action shots. Photos doing what you love are 3x more engaging.",
            "Lead with your best photo. The first photo determines 80% of your profile's success.",
            "Good lighting beats good cameras. Natural light during golden hour creates magazine-quality shots.",
            "Eye contact matters. Looking at the camera creates connection; looking away can seem distant.",
            "Avoid group photos as your main shot. Users scroll past when they can't identify you.",
            "Update photos every 3 months. Fresh content signals active engagement and keeps profiles interesting.",
            "Your bio should match your photos. Consistency between visual and written personality attracts aligned matches."
        ]

        // Use day of year to rotate tips
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let tipIndex = (dayOfYear - 1) % tips.count
        dailyTip = tips[tipIndex]
    }

    private func checkOnboardingStatus() {
        let defaults = UserDefaults.standard
        onboardingComplete = defaults.bool(forKey: "hasCompletedOnboarding")
    }

    // MARK: - Save Methods (for external updates)

    func saveGeneration(_ record: GenerationRecord) {
        recentGenerations.insert(record, at: 0)
        photosGenerated += record.photoCount

        // Keep only last 10 generations
        if recentGenerations.count > 10 {
            recentGenerations = Array(recentGenerations.prefix(10))
        }

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(recentGenerations) {
            UserDefaults.standard.set(data, forKey: "recentGenerations")
        }
        UserDefaults.standard.set(photosGenerated, forKey: "photosGenerated")
    }

    func markProfileUpdated() {
        profilesUpdated += 1
        UserDefaults.standard.set(profilesUpdated, forKey: "profilesUpdated")
    }

    func markOnboardingComplete() {
        onboardingComplete = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Generation Record Codable Extension

extension GenerationRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, styleName, createdAt, photoCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        styleName = try container.decode(String.self, forKey: .styleName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        photoCount = try container.decode(Int.self, forKey: .photoCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(styleName, forKey: .styleName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(photoCount, forKey: .photoCount)
    }
}