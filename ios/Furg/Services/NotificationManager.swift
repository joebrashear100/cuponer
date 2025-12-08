//
//  NotificationManager.swift
//  Furg
//
//  Push notification management for spending alerts, bill reminders, and insights
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings()

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    // MARK: - Spending Alerts

    func scheduleSpendingAlert(amount: Double, category: String, budgetLimit: Double) {
        guard notificationSettings.spendingAlerts else { return }

        let content = UNMutableNotificationContent()
        content.title = "Spending Alert 🔥"
        content.body = "You just spent $\(Int(amount)) on \(category). You've used \(Int((amount / budgetLimit) * 100))% of your \(category) budget."
        content.sound = .default
        content.categoryIdentifier = "SPENDING_ALERT"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )

        center.add(request)
    }

    func scheduleBudgetWarning(category: String, percentUsed: Double, remaining: Double) {
        guard notificationSettings.budgetWarnings else { return }

        let content = UNMutableNotificationContent()

        if percentUsed >= 100 {
            content.title = "Budget Exceeded! 😬"
            content.body = "You've exceeded your \(category) budget. Time to cool it."
        } else if percentUsed >= 80 {
            content.title = "Budget Warning ⚠️"
            content.body = "You've used \(Int(percentUsed))% of your \(category) budget. Only $\(Int(remaining)) left."
        }

        content.sound = .default
        content.categoryIdentifier = "BUDGET_WARNING"

        let request = UNNotificationRequest(
            identifier: "budget_\(category)_\(Int(percentUsed))",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - Bill Reminders

    func scheduleBillReminder(billName: String, amount: Double, dueDate: Date, daysBefore: Int = 3) {
        guard notificationSettings.billReminders else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bill Due Soon 📅"
        content.body = "\(billName) payment of $\(String(format: "%.2f", amount)) is due in \(daysBefore) days."
        content.sound = .default
        content.categoryIdentifier = "BILL_REMINDER"

        let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate) ?? dueDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "bill_\(billName)_\(dueDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func scheduleBillDueToday(billName: String, amount: Double) {
        guard notificationSettings.billReminders else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bill Due Today! 🚨"
        content.body = "\(billName) payment of $\(String(format: "%.2f", amount)) is due today. Don't forget!"
        content.sound = .defaultCritical
        content.categoryIdentifier = "BILL_DUE_TODAY"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - Goal Notifications

    func scheduleGoalMilestone(goalName: String, percentComplete: Double) {
        guard notificationSettings.goalUpdates else { return }

        let content = UNMutableNotificationContent()

        if percentComplete >= 100 {
            content.title = "Goal Achieved! 🎉"
            content.body = "Congratulations! You've reached your \(goalName) goal!"
        } else if percentComplete >= 75 {
            content.title = "Almost There! 🏃"
            content.body = "You're \(Int(percentComplete))% of the way to your \(goalName) goal!"
        } else if percentComplete >= 50 {
            content.title = "Halfway There! 💪"
            content.body = "You've reached 50% of your \(goalName) goal. Keep going!"
        } else if percentComplete >= 25 {
            content.title = "Great Progress! ⭐"
            content.body = "You're 25% of the way to your \(goalName) goal!"
        }

        content.sound = .default
        content.categoryIdentifier = "GOAL_MILESTONE"

        let request = UNNotificationRequest(
            identifier: "goal_\(goalName)_\(Int(percentComplete))",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - Daily/Weekly Summaries

    func scheduleDailySummary(hour: Int = 20, minute: Int = 0) {
        guard notificationSettings.dailySummary else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Money Check-In 📊"
        content.body = "Tap to see how you did today and plan for tomorrow."
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func scheduleWeeklySummary(weekday: Int = 1, hour: Int = 9) { // Sunday at 9 AM
        guard notificationSettings.weeklySummary else { return }

        let content = UNMutableNotificationContent()
        content.title = "Weekly Money Report 📈"
        content.body = "Your weekly financial summary is ready. See how you did!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Smart Insights

    func scheduleInsightNotification(title: String, message: String, delay: TimeInterval = 0) {
        guard notificationSettings.smartInsights else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "INSIGHT"

        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Unusual Activity

    func scheduleUnusualActivityAlert(merchant: String, amount: Double, reason: String) {
        guard notificationSettings.unusualActivity else { return }

        let content = UNMutableNotificationContent()
        content.title = "Unusual Activity Detected 🔍"
        content.body = "$\(Int(amount)) at \(merchant). \(reason)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "UNUSUAL_ACTIVITY"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - Management

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelBillReminders(for billName: String) {
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.starts(with: "bill_\(billName)") }
                .map { $0.identifier }

            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    // MARK: - Setup Notification Categories

    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Details",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Remind Me Later",
            options: []
        )

        let payBillAction = UNNotificationAction(
            identifier: "PAY_BILL_ACTION",
            title: "Mark as Paid",
            options: []
        )

        let spendingCategory = UNNotificationCategory(
            identifier: "SPENDING_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )

        let budgetCategory = UNNotificationCategory(
            identifier: "BUDGET_WARNING",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )

        let billCategory = UNNotificationCategory(
            identifier: "BILL_REMINDER",
            actions: [payBillAction, snoozeAction, viewAction],
            intentIdentifiers: []
        )

        let billDueCategory = UNNotificationCategory(
            identifier: "BILL_DUE_TODAY",
            actions: [payBillAction, viewAction],
            intentIdentifiers: []
        )

        let goalCategory = UNNotificationCategory(
            identifier: "GOAL_MILESTONE",
            actions: [viewAction],
            intentIdentifiers: []
        )

        let summaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )

        let weeklySummaryCategory = UNNotificationCategory(
            identifier: "WEEKLY_SUMMARY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )

        let insightCategory = UNNotificationCategory(
            identifier: "INSIGHT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )

        let unusualCategory = UNNotificationCategory(
            identifier: "UNUSUAL_ACTIVITY",
            actions: [viewAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([
            spendingCategory,
            budgetCategory,
            billCategory,
            billDueCategory,
            goalCategory,
            summaryCategory,
            weeklySummaryCategory,
            insightCategory,
            unusualCategory
        ])
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var spendingAlerts: Bool = true
    var budgetWarnings: Bool = true
    var billReminders: Bool = true
    var goalUpdates: Bool = true
    var dailySummary: Bool = false
    var weeklySummary: Bool = true
    var smartInsights: Bool = true
    var unusualActivity: Bool = true

    // Quiet hours
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Int = 22 // 10 PM
    var quietHoursEnd: Int = 8   // 8 AM
}
