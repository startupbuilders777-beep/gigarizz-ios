import Foundation
import UserNotifications

/// Manages push notifications for smart reminders, engagement nudges, and generation alerts.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    enum Category: String {
        case generationComplete = "GENERATION_COMPLETE"
        case dailyReminder = "DAILY_REMINDER"
        case matchUpdate = "MATCH_UPDATE"
        case weeklyReport = "WEEKLY_REPORT"
        case streakReminder = "STREAK_REMINDER"
        case promoOffer = "PROMO_OFFER"
        case replyReminder = "REPLY_REMINDER"
    }

    init() { Task { await checkAuthorizationStatus() } }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            isAuthorized = granted
            if granted {
                registerNotificationCategories()
                await scheduleDefaultReminders()
                PostHogManager.shared.trackEvent("notifications_authorized")
            }
            return granted
        } catch { print("Notification authorization error: \(error)"); return false }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    private func registerNotificationCategories() {
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", title: "View", options: [.foreground])
        let generateAction = UNNotificationAction(identifier: "GENERATE_ACTION", title: "Generate Now", options: [.foreground])
        let dismissAction = UNNotificationAction(identifier: "DISMISS_ACTION", title: "Later", options: [.destructive])
        
        // Reply reminder actions
        let replyAction = UNNotificationAction(identifier: "REPLY_ACTION", title: "Reply Now", options: [.foreground])
        let remindLaterAction = UNNotificationAction(identifier: "REMIND_LATER_ACTION", title: "Remind Me Later", options: [])
        let muteMatchAction = UNNotificationAction(identifier: "MUTE_MATCH_ACTION", title: "Stop Reminders", options: [.destructive])

        let generationCategory = UNNotificationCategory(identifier: Category.generationComplete.rawValue, actions: [viewAction, dismissAction], intentIdentifiers: [])
        let reminderCategory = UNNotificationCategory(identifier: Category.dailyReminder.rawValue, actions: [generateAction, dismissAction], intentIdentifiers: [])
        let matchCategory = UNNotificationCategory(identifier: Category.matchUpdate.rawValue, actions: [viewAction, dismissAction], intentIdentifiers: [])
        let weeklyCategory = UNNotificationCategory(identifier: Category.weeklyReport.rawValue, actions: [viewAction], intentIdentifiers: [])
        
        // Reply reminder category with 4 actions
        let replyReminderCategory = UNNotificationCategory(
            identifier: Category.replyReminder.rawValue,
            actions: [replyAction, remindLaterAction, muteMatchAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([
            generationCategory,
            reminderCategory,
            matchCategory,
            weeklyCategory,
            replyReminderCategory
        ])
    }

    func scheduleDefaultReminders() async {
        await scheduleDailyReminder(hour: 19, minute: 0)
        await scheduleWeeklyReport(weekday: 1, hour: 10)
        await scheduleStreakReminder(hour: 9)
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        let messages = [
            ("Your dating photos are waiting \u{1F525}", "Generate new AI photos and boost your matches today!"),
            ("Rizz check \u{1F4AA}", "Time to update your profile photos. Your matches will thank you."),
            ("Don\u{2019}t let your profile go stale \u{1F609}", "Fresh photos = more matches. Generate yours now!"),
            ("Photo upgrade time \u{2728}", "New styles just dropped. Come check them out!"),
            ("Your dating game needs you \u{1F3AF}", "3 minutes to better photos. Let\u{2019}s go!")
        ]
        let (title, body) = messages[Int.random(in: 0..<messages.count)]
        var dc = DateComponents(); dc.hour = hour; dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let content = makeContent(title: title, body: body, category: .dailyReminder)
        try? await center.add(UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger))
    }

    func scheduleWeeklyReport(weekday: Int, hour: Int) async {
        var dc = DateComponents(); dc.weekday = weekday; dc.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let content = makeContent(title: "Weekly Rizz Report \u{1F4CA}", body: "See how your photos performed this week. Tap to view your match analytics!", category: .weeklyReport)
        try? await center.add(UNNotificationRequest(identifier: "weekly_report", content: content, trigger: trigger))
    }

    func scheduleStreakReminder(hour: Int) async {
        var dc = DateComponents(); dc.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let content = makeContent(title: "Keep your streak alive \u{1F525}", body: "You\u{2019}re on a roll! Don\u{2019}t break your generation streak.", category: .streakReminder)
        try? await center.add(UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger))
    }

    func notifyGenerationComplete(photoCount: Int, style: String) async {
        let content = makeContent(title: "Photos Ready! \u{1F389}", body: "Your \(photoCount) \(style) photos are ready. Come see your new look!", category: .generationComplete)
        content.badge = NSNumber(value: photoCount)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "generation_complete_\(UUID().uuidString)", content: content, trigger: trigger))
    }

    func notifyMatchUpdate(matchName: String, platform: String) async {
        let content = makeContent(title: "Match Update on \(platform) \u{1F496}", body: "\(matchName) activity detected! Check your match tracker.", category: .matchUpdate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "match_update_\(UUID().uuidString)", content: content, trigger: trigger))
    }

    func refreshPendingNotifications() async { pendingNotifications = await center.pendingNotificationRequests() }
    func removeAllNotifications() { center.removeAllPendingNotificationRequests(); center.removeAllDeliveredNotifications(); pendingNotifications = [] }
    func removeNotifications(for category: Category) { center.removePendingNotificationRequests(withIdentifiers: [category.rawValue]) }
    func clearBadge() async { try? await center.setBadgeCount(0) }

    private func makeContent(title: String, body: String, category: Category) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body
        content.categoryIdentifier = category.rawValue
        content.sound = .default; content.interruptionLevel = .timeSensitive
        return content
    }
}
