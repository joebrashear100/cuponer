//
//  FurgApp.swift
//  Furg
//
//  Chat-first financial AI with roasting personality
//

import SwiftUI
import UserNotifications

@main
struct FurgApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var chatManager = ChatManager()
    @StateObject private var financeManager = FinanceManager()
    @StateObject private var plaidManager = PlaidManager()
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var goalsManager = GoalsManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var roundUpManager = RoundUpManager()
    @StateObject private var forecastingManager = ForecastingManager()
    @StateObject private var spendingLimitsManager = SpendingLimitsManager()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                // V2 Design Preview - Remove this to go back to normal auth flow
                FurgAppV2()

                // Original auth flow (uncomment to restore):
                // if authManager.isAuthenticated {
                //     if authManager.hasCompletedOnboarding {
                //         MainTabView()
                //     } else {
                //         OnboardingView()
                //     }
                // } else {
                //     WelcomeView()
                // }
            }
            .environmentObject(authManager)
            .environmentObject(apiClient)
            .environmentObject(chatManager)
            .environmentObject(financeManager)
            .environmentObject(plaidManager)
            .environmentObject(wishlistManager)
            .environmentObject(goalsManager)
            .environmentObject(subscriptionManager)
            .environmentObject(roundUpManager)
            .environmentObject(forecastingManager)
            .environmentObject(spendingLimitsManager)
            .environmentObject(healthKitManager)
            .environmentObject(notificationManager)
            .task {
                // Request notification permissions on launch
                await notificationManager.requestAuthorization()
                notificationManager.setupNotificationCategories()

                // Set up daily/weekly summaries if enabled
                notificationManager.scheduleDailySummary()
                notificationManager.scheduleWeeklySummary()
            }
        }
    }
}

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        // Handle different notification types
        switch categoryIdentifier {
        case "SPENDING_ALERT", "BUDGET_WARNING":
            // Navigate to spending view
            NotificationCenter.default.post(name: .openSpendingView, object: nil)
        case "BILL_REMINDER", "BILL_DUE_TODAY":
            // Navigate to bills view
            NotificationCenter.default.post(name: .openBillsView, object: nil)
        case "GOAL_MILESTONE":
            // Navigate to goals view
            NotificationCenter.default.post(name: .openGoalsView, object: nil)
        case "DAILY_SUMMARY", "WEEKLY_SUMMARY":
            // Navigate to dashboard
            NotificationCenter.default.post(name: .openDashboard, object: nil)
        default:
            break
        }

        completionHandler()
    }

    // Register for remote notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
        // Send token to your server for push notifications
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSpendingView = Notification.Name("openSpendingView")
    static let openBillsView = Notification.Name("openBillsView")
    static let openGoalsView = Notification.Name("openGoalsView")
    static let openDashboard = Notification.Name("openDashboard")
}
