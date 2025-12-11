//
//  FurgApp.swift
//  Furg
//
//  Chat-first financial AI with roasting personality
//

import SwiftUI
import UserNotifications
import os.log

private let appLogger = Logger(subsystem: "com.furg.app", category: "App")

// MARK: - App Container
/// Consolidates app dependencies for better memory management and testability
/// Managers are created on-demand rather than all at startup
@MainActor
final class AppContainer: ObservableObject {
    // Core managers (always needed)
    let authManager: AuthManager
    let apiClient: APIClient

    // Feature managers (lazy initialization)
    lazy var chatManager = ChatManager()
    lazy var financeManager = FinanceManager()
    lazy var plaidManager = PlaidManager()
    lazy var wishlistManager = WishlistManager()
    lazy var goalsManager = GoalsManager()
    lazy var subscriptionManager = SubscriptionManager()
    lazy var roundUpManager = RoundUpManager()
    lazy var forecastingManager = ForecastingManager()
    lazy var spendingLimitsManager = SpendingLimitsManager()
    lazy var rufusManager = RufusManager()

    // Singleton managers
    let healthKitManager = HealthKitManager.shared
    let notificationManager = NotificationManager.shared

    init() {
        self.authManager = AuthManager()
        self.apiClient = APIClient()

        // Validate configuration at startup
        let configErrors = Config.validate()
        for error in configErrors {
            appLogger.warning("Configuration issue: \(error.description)")
        }
    }

    /// Initialize app after authentication
    func initializePostAuth() async {
        await notificationManager.requestAuthorization()
        notificationManager.setupNotificationCategories()
        notificationManager.scheduleDailySummary()
        notificationManager.scheduleWeeklySummary()
        appLogger.info("App initialized for authenticated user")
    }
}

@main
struct FurgApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            Group {
                if container.authManager.isAuthenticated {
                    if container.authManager.hasCompletedOnboarding {
                        MainTabView()
                    } else {
                        OnboardingView()
                    }
                } else {
                    WelcomeView()
                }
            }
            // Core managers
            .environmentObject(container.authManager)
            .environmentObject(container.apiClient)
            // Feature managers (accessed lazily)
            .environmentObject(container.chatManager)
            .environmentObject(container.financeManager)
            .environmentObject(container.plaidManager)
            .environmentObject(container.wishlistManager)
            .environmentObject(container.goalsManager)
            .environmentObject(container.subscriptionManager)
            .environmentObject(container.roundUpManager)
            .environmentObject(container.forecastingManager)
            .environmentObject(container.spendingLimitsManager)
            .environmentObject(container.rufusManager)
            // Singleton managers
            .environmentObject(container.healthKitManager)
            .environmentObject(container.notificationManager)
            .task {
                await container.initializePostAuth()
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
