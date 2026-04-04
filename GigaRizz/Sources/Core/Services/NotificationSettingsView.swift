import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var reminderService = ReplyReminderService.shared
    @State private var dailyReminder = true
    @State private var weeklyReport = true
    @State private var streakReminder = true
    @State private var matchUpdates = true
    @State private var reminderTime = Date()
    @State private var showIntervalPicker = false
    
    // Reply reminder interval options
    private let intervalOptions: [(label: String, hours: Int)] = [
        ("12 hours", 12),
        ("24 hours", 24),
        ("48 hours", 48)
    ]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            List {
                // MARK: - Authorization Status
                Section {
                    if notificationManager.isAuthorized {
                        Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.success)
                    } else {
                        Button {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge.fill")
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                // MARK: - Reply Reminders (New Section)
                Section {
                    Toggle(isOn: Binding(
                        get: { reminderService.config.isEnabled },
                        set: { reminderService.toggleReminders($0) }
                    )) {
                        Label("Reply Reminders", systemImage: "bubble.left.and.exclamationmark.bubble.right.fill")
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    .tint(DesignSystem.Colors.flameOrange)
                    
                    if reminderService.config.isEnabled {
                        // Interval picker
                        HStack {
                            Text("Remind after")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Menu {
                                ForEach(intervalOptions, id: \.hours) { option in
                                    Button {
                                        reminderService.setReminderInterval(option.hours)
                                    } label: {
                                        HStack {
                                            Text(option.label)
                                            if reminderService.config.reminderIntervalHours == option.hours {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(reminderService.config.reminderIntervalHours)h")
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.small)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.surfaceSecondary)
                                .clipShape(Capsule())
                            }
                        }
                        
                        // Info row
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.7))
                            Text("Gentle nudges when you haven't replied to a match")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                } header: {
                    Text("Match Reply Reminders")
                } footer: {
                    Text("Never cringe. Reminders are friendly wingman prompts, not alerts.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.7))
                }
                
                // MARK: - Standard Notification Types
                Section {
                    Toggle(isOn: $dailyReminder) {
                        Label("Daily Reminder", systemImage: "clock.fill")
                    }
                    .tint(DesignSystem.Colors.flameOrange)
                    .onChange(of: dailyReminder) { _, _ in
                        DesignSystem.Haptics.light()
                    }
                    
                    if dailyReminder {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .tint(DesignSystem.Colors.flameOrange)
                    }
                    
                    Toggle(isOn: $weeklyReport) {
                        Label("Weekly Report", systemImage: "chart.bar.fill")
                    }
                    .tint(DesignSystem.Colors.flameOrange)
                    .onChange(of: weeklyReport) { _, _ in
                        DesignSystem.Haptics.light()
                    }
                    
                    Toggle(isOn: $streakReminder) {
                        Label("Streak Reminder", systemImage: "flame.fill")
                    }
                    .tint(DesignSystem.Colors.flameOrange)
                    .onChange(of: streakReminder) { _, _ in
                        DesignSystem.Haptics.light()
                    }
                    
                    Toggle(isOn: $matchUpdates) {
                        Label("Match Updates", systemImage: "heart.fill")
                    }
                    .tint(DesignSystem.Colors.flameOrange)
                    .onChange(of: matchUpdates) { _, _ in
                        DesignSystem.Haptics.light()
                    }
                } header: {
                    Text("Notification Types")
                }
                
                // MARK: - Management
                Section {
                    Button(role: .destructive) {
                        notificationManager.removeAllNotifications()
                        DesignSystem.Haptics.medium()
                    } label: {
                        Label("Remove All Notifications", systemImage: "bell.slash.fill")
                    }
                    
                    Button {
                        Task {
                            await notificationManager.clearBadge()
                            DesignSystem.Haptics.light()
                        }
                    } label: {
                        Label("Clear Badge", systemImage: "badge.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                } header: {
                    Text("Management")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notifications")
        .onAppear {
            // Load saved preferences
            dailyReminder = UserDefaults.standard.bool(forKey: "daily_reminder_enabled")
            weeklyReport = UserDefaults.standard.bool(forKey: "weekly_report_enabled")
            streakReminder = UserDefaults.standard.bool(forKey: "streak_reminder_enabled")
            matchUpdates = UserDefaults.standard.bool(forKey: "match_updates_enabled")
        }
        .onChange(of: dailyReminder) { _, _ in
            UserDefaults.standard.set(dailyReminder, forKey: "daily_reminder_enabled")
        }
        .onChange(of: weeklyReport) { _, _ in
            UserDefaults.standard.set(weeklyReport, forKey: "weekly_report_enabled")
        }
        .onChange(of: streakReminder) { _, _ in
            UserDefaults.standard.set(streakReminder, forKey: "streak_reminder_enabled")
        }
        .onChange(of: matchUpdates) { _, _ in
            UserDefaults.standard.set(matchUpdates, forKey: "match_updates_enabled")
        }
    }
}

// MARK: - Match Reminder Mute Control (For use in MatchDetailView)

struct MatchReminderMuteButton: View {
    let matchId: String
    @StateObject private var reminderService = ReplyReminderService.shared
    @State private var isMuted: Bool = false
    
    var body: some View {
        Button {
            if isMuted {
                reminderService.unmuteMatch(matchId)
                isMuted = false
            } else {
                reminderService.muteMatch(matchId)
                isMuted = true
            }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: isMuted ? "bell.slash.fill" : "bell.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isMuted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.flameOrange)
                Text(isMuted ? "Reminders Off" : "Reminders On")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(isMuted ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.flameOrange)
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isMuted ? DesignSystem.Colors.divider : DesignSystem.Colors.flameOrange.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .onAppear {
            isMuted = MatchReminderState.forMatch(matchId).isMuted
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Match Mute Button") {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        VStack {
            MatchReminderMuteButton(matchId: "test-match-123")
            MatchReminderMuteButton(matchId: "test-match-456")
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}