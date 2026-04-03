import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var dailyReminder = true
    @State private var weeklyReport = true
    @State private var streakReminder = true
    @State private var matchUpdates = true
    @State private var reminderTime = Date()

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            List {
                Section {
                    if notificationManager.isAuthorized {
                        Label("Notifications Enabled", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button {
                            DesignSystem.Haptics.medium()
                            Task { await notificationManager.requestAuthorization() }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge.fill").foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                } header: { Text("Status") }

                Section {
                    Toggle(isOn: $dailyReminder) { Label("Daily Reminder", systemImage: "clock.fill") }.tint(DesignSystem.Colors.flameOrange)
                    if dailyReminder { DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute) }
                    Toggle(isOn: $weeklyReport) { Label("Weekly Report", systemImage: "chart.bar.fill") }.tint(DesignSystem.Colors.flameOrange)
                    Toggle(isOn: $streakReminder) { Label("Streak Reminder", systemImage: "flame.fill") }.tint(DesignSystem.Colors.flameOrange)
                    Toggle(isOn: $matchUpdates) { Label("Match Updates", systemImage: "heart.fill") }.tint(DesignSystem.Colors.flameOrange)
                } header: { Text("Notification Types") }

                Section {
                    Button(role: .destructive) {
                        DesignSystem.Haptics.heavy()
                        notificationManager.removeAllNotifications()
                    } label: {
                        Label("Remove All Notifications", systemImage: "bell.slash.fill")
                    }
                } header: { Text("Management") }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notifications")
    }
}

#Preview { NavigationStack { NotificationSettingsView() }.preferredColorScheme(.dark) }
