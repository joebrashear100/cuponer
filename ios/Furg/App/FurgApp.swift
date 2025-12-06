//
//  FurgApp.swift
//  Furg
//
//  Chat-first financial AI with roasting personality
//

import SwiftUI

@main
struct FurgApp: App {
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

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    if authManager.hasCompletedOnboarding {
                        MainTabView()
                    } else {
                        OnboardingView()
                    }
                } else {
                    WelcomeView()
                }
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
        }
    }
}
