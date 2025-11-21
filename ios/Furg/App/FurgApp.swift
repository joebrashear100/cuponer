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

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(apiClient)
                    .environmentObject(chatManager)
                    .environmentObject(financeManager)
                    .environmentObject(plaidManager)
            } else {
                WelcomeView()
                    .environmentObject(authManager)
            }
        }
    }
}
