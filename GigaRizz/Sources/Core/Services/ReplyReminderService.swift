import Foundation
import UserNotifications
import SwiftUI

// MARK: - Reply Reminder Configuration

/// Configuration for reply reminder behavior
struct ReplyReminderConfig: Codable {
    /// Minimum hours since last message before reminder triggers
    var reminderIntervalHours: Int = 24
    
    /// Hours to defer when user taps "Remind me later"
    var deferHours: Int = 4
    
    /// Maximum reminders per match before auto-muting
    var maxRemindersPerMatch: Int = 2
    
    /// Whether reply reminders are globally enabled
    var isEnabled: Bool = true
    
    /// UserDefaults key
    static let storageKey = "reply_reminder_config"
    
    /// Load from UserDefaults
    static var current: ReplyReminderConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(ReplyReminderConfig.self, from: data) else {
            return ReplyReminderConfig()
        }
        return config
    }
    
    /// Save to UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

// MARK: - Match Reminder State

/// Tracks reminder state per match
struct MatchReminderState: Codable {
    let matchId: String
    var reminderCount: Int = 0
    var isMuted: Bool = false
    var lastReminderDate: Date?
    var deferredUntil: Date?
    
    /// UserDefaults key prefix
    static let storageKeyPrefix = "match_reminder_state_"
    
    /// Load for a specific match
    static func forMatch(_ matchId: String) -> MatchReminderState {
        let key = storageKeyPrefix + matchId
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(MatchReminderState.self, from: data) else {
            return MatchReminderState(matchId: matchId)
        }
        return state
    }
    
    /// Save state
    func save() {
        let key = Self.storageKeyPrefix + matchId
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Increment reminder count and save
    func incrementAndSave() -> MatchReminderState {
        var newState = self
        newState.reminderCount += 1
        newState.lastReminderDate = Date()
        
        // Auto-mute after max reminders
        if newState.reminderCount >= ReplyReminderConfig.current.maxRemindersPerMatch {
            newState.isMuted = true
        }
        
        newState.save()
        return newState
    }
    
    /// Mute reminders for this match
    func mute() {
        var newState = self
        newState.isMuted = true
        newState.save()
    }
    
    /// Unmute reminders for this match
    func unmute() {
        var newState = self
        newState.isMuted = false
        newState.reminderCount = 0
        newState.save()
    }
    
    /// Defer reminder by specified hours
    func deferBy(_ hours: Int) {
        var newState = self
        newState.deferredUntil = Date().addingTimeInterval(Double(hours) * 3600)
        newState.save()
    }
    
    /// Check if reminder should be sent
    var canSendReminder: Bool {
        guard !isMuted else { return false }
        guard reminderCount < ReplyReminderConfig.current.maxRemindersPerMatch else { return false }
        
        // Check if deferred
        if let deferred = deferredUntil, deferred > Date() {
            return false
        }
        
        return true
    }
}

// MARK: - Reply Reminder Service

/// Background service that checks for stale matches and sends reminder notifications
@MainActor
final class ReplyReminderService: ObservableObject {
    static let shared = ReplyReminderService()
    
    @Published var config: ReplyReminderConfig = .current
    @Published var isChecking = false
    
    private let notificationManager = NotificationManager.shared
    private let backgroundTaskIdentifier = "com.gigarizz.reply-reminder-check"
    
    // MARK: - Background Task Registration
    
    /// Register background task handler (call from AppDelegate or App init)
    func registerBackgroundTask() {
        // Note: For SwiftUI apps on iOS 16+, use .backgroundTask modifier
        // This method is for reference - actual registration happens in GigaRizzApp
    }
    
    /// Schedule next background check
    func scheduleNextBackgroundCheck() async {
        // BGAppRefreshTask requires actual app refresh scheduling via BGTaskScheduler
        // For now, we use a simplified approach with notification triggers
        let config = ReplyReminderConfig.current
        guard config.isEnabled else { return }
        
        // Schedule a local notification to trigger background check
        // In production, this would use BGTaskScheduler.shared.submit()
        let content = UNMutableNotificationContent()
        content.title = "Checking for stale matches..."
        content.body = ""
        content.categoryIdentifier = NotificationManager.Category.replyReminder.rawValue
        content.sound = .none
        content.interruptionLevel = .passive
        
        // Schedule every 4 hours
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 4 * 3600,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "reply_reminder_background_check",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Stale Match Detection
    
    /// Check for stale matches and send reminders
    func checkForStaleMatches(matches: [Match]) async {
        guard config.isEnabled else { return }
        isChecking = true
        
        let staleMatches = matches.filter { shouldSendReminder(for: $0) }
        
        for match in staleMatches {
            await sendReminderNotification(for: match)
        }
        
        isChecking = false
        
        // Schedule next check
        await scheduleNextBackgroundCheck()
        
        // Track analytics
        PostHogManager.shared.trackEvent("reply_reminder_check_completed", properties: [
            "stale_count": staleMatches.count,
            "total_matches": matches.count
        ])
    }
    
    /// Determine if a match should receive a reminder
    private func shouldSendReminder(for match: Match) -> Bool {
        // Must have unread messages
        guard match.hasUnread else { return false }
        
        // Must have a last message date
        guard let lastMessageDate = match.lastMessageDate else { return false }
        
        // Calculate hours since last message
        let hoursSinceMessage = Date().timeIntervalSince(lastMessageDate) / 3600
        
        // Must exceed minimum interval
        guard hoursSinceMessage >= Double(config.reminderIntervalHours) else { return false }
        
        // Check per-match reminder state
        let state = MatchReminderState.forMatch(match.id)
        guard state.canSendReminder else { return false }
        
        return true
    }
    
    // MARK: - Notification Sending
    
    /// Send a reminder notification for a specific match
    private func sendReminderNotification(for match: Match) async {
        let state = MatchReminderState.forMatch(match.id)
        
        // Create notification content
        let title = "You and \(match.firstName) had a vibe 👋"
        let body = reminderBody(for: match)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationManager.Category.replyReminder.rawValue
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "match_id": match.id,
            "deep_link": "gigarizz://match/\(match.id)"
        ]
        
        // Immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "reply_reminder_\(match.id)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        
        // Update reminder state
        state.incrementAndSave().save()
        
        // Track analytics
        PostHogManager.shared.trackEvent("reply_reminder_sent", properties: [
            "match_id": match.id,
            "match_name": match.name,
            "reminder_count": state.reminderCount + 1,
            "hours_since_message": match.hoursSinceLastMessage ?? 0
        ])
    }
    
    /// Generate reminder body text
    private func reminderBody(for match: Match) -> String {
        let hours = match.hoursSinceLastMessage ?? 0
        
        if let lastMessage = match.lastMessage, !lastMessage.isEmpty {
            let preview = lastMessage.count > 50 ? lastMessage.prefix(50) + "..." : lastMessage
            return "Message from \(hours)h ago: \"\(preview)\" — worth a reply?"
        } else {
            return "\(match.name) is waiting for your reply. Don't let this one ghost!"
        }
    }
    
    // MARK: - Configuration Updates
    
    func updateConfig(_ newConfig: ReplyReminderConfig) {
        config = newConfig
        config.save()
        
        // Reschedule background checks
        Task {
            await scheduleNextBackgroundCheck()
        }
        
        PostHogManager.shared.trackEvent("reply_reminder_config_updated", properties: [
            "interval_hours": newConfig.reminderIntervalHours,
            "max_reminders": newConfig.maxRemindersPerMatch,
            "is_enabled": newConfig.isEnabled
        ])
    }
    
    /// Set reminder interval (12h, 24h, 48h)
    func setReminderInterval(_ hours: Int) {
        var newConfig = config
        newConfig.reminderIntervalHours = hours
        updateConfig(newConfig)
    }
    
    /// Toggle global reminders
    func toggleReminders(_ enabled: Bool) {
        var newConfig = config
        newConfig.isEnabled = enabled
        updateConfig(newConfig)
    }
    
    // MARK: - Per-Match Controls
    
    /// Mute reminders for a specific match
    func muteMatch(_ matchId: String) {
        MatchReminderState.forMatch(matchId).mute()
    }
    
    /// Unmute reminders for a specific match
    func unmuteMatch(_ matchId: String) {
        MatchReminderState.forMatch(matchId).unmute()
    }
    
    /// Defer reminder for a match by 4 hours
    func deferReminder(for matchId: String) {
        let state = MatchReminderState.forMatch(matchId)
        state.deferBy(config.deferHours)
        
        PostHogManager.shared.trackEvent("reply_reminder_deferred", properties: [
            "match_id": matchId,
            "defer_hours": config.deferHours
        ])
    }
}

// MARK: - Match Extensions for Reminder Support

extension Match {
    /// First name extraction for notifications
    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
    
    /// Hours since last message
    var hoursSinceLastMessage: Int? {
        guard let last = lastMessageDate else { return nil }
        return Int(Date().timeIntervalSince(last) / 3600)
    }
    
    /// Reminder state for this match
    var reminderState: MatchReminderState {
        MatchReminderState.forMatch(id)
    }
    
    /// Can receive reminder
    var canReceiveReminder: Bool {
        reminderState.canSendReminder
    }
    
    /// Is reminder muted
    var isReminderMuted: Bool {
        reminderState.isMuted
    }
}