import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Delegate Handler

/// Handles notification responses and actions for the GigaRizz app.
/// Processes reply reminder actions and routes deep links.
final class NotificationDelegateHandler: NSObject, UNUserNotificationCenterDelegate {
    nonisolated(unsafe) static let shared = NotificationDelegateHandler()
    
    // MARK: - Notification Received (Foreground)
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let category = notification.request.content.categoryIdentifier
        
        if category == NotificationManager.Category.replyReminder.rawValue {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.banner, .sound])
        }
        
        // Track notification received
        let categoryIdentifier = notification.request.content.categoryIdentifier
        let identifier = notification.request.identifier
        let title = notification.request.content.title
        
        Task { @MainActor in
            PostHogManager.shared.trackEvent(
                "notification_received",
                properties: ["category": categoryIdentifier, "identifier": identifier, "title": title]
            )
        }
    }
    
    // MARK: - Notification Response (User Tapped)
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let category = response.notification.request.content.categoryIdentifier
        let actionIdentifier = response.actionIdentifier
        let responseIdentifier = response.notification.request.identifier
        
        // Extract match-related values
        let matchId = userInfo["match_id"] as? String
        let deepLink = userInfo["deep_link"] as? String
        let batchId = userInfo["batch_id"] as? String
        
        Task { @MainActor in
            switch category {
            case NotificationManager.Category.replyReminder.rawValue:
                if let matchId = matchId {
                    switch actionIdentifier {
                    case "REPLY_ACTION":
                        if let deepLink = deepLink, let url = URL(string: deepLink) {
                            _ = DeepLinkManager.shared.handleURL(url)
                        }
                        DesignSystem.Haptics.light()
                        
                    case "REMIND_LATER_ACTION":
                        ReplyReminderService.shared.deferReminder(for: matchId)
                        
                    case "MUTE_MATCH_ACTION":
                        ReplyReminderService.shared.muteMatch(matchId)
                        
                    case UNNotificationDefaultActionIdentifier:
                        if let deepLink = deepLink, let url = URL(string: deepLink) {
                            _ = DeepLinkManager.shared.handleURL(url)
                        }
                        
                    default:
                        break
                    }
                }
                
            case NotificationManager.Category.matchUpdate.rawValue:
                if actionIdentifier == "VIEW_ACTION" || actionIdentifier == UNNotificationDefaultActionIdentifier {
                    if let deepLink = deepLink, let url = URL(string: deepLink) {
                        _ = DeepLinkManager.shared.handleURL(url)
                    } else {
                        _ = DeepLinkManager.shared.handleURL(URL(string: "gigarizz://matches")!) // Known-valid literal
                    }
                }
                
            case NotificationManager.Category.generationComplete.rawValue:
                if actionIdentifier == "VIEW_ACTION" || actionIdentifier == UNNotificationDefaultActionIdentifier {
                    if let batchId = batchId {
                        _ = DeepLinkManager.shared.handleURL(URL(string: "gigarizz://generation/\(batchId)")!) // Known-valid literal
                    } else {
                        _ = DeepLinkManager.shared.handleURL(URL(string: "gigarizz://gallery")!) // Known-valid literal
                    }
                }
                
            default:
                if let deepLink = deepLink, let url = URL(string: deepLink) {
                    _ = DeepLinkManager.shared.handleURL(url)
                }
            }
            
            // Track analytics
            PostHogManager.shared.trackEvent(
                "notification_response",
                properties: ["category": category, "action": actionIdentifier, "identifier": responseIdentifier]
            )
        }
        
        completionHandler()
    }
}