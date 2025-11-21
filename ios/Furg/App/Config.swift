//
//  Config.swift
//  Furg
//
//  App configuration and constants
//

import Foundation

struct Config {
    // MARK: - Backend Configuration

    #if DEBUG
    static let baseURL = "http://localhost:8000"
    #else
    static let baseURL = "https://api.furg.app" // Update with your production URL
    #endif

    // MARK: - API Endpoints

    struct API {
        static let auth = "/api/v1/auth/apple"
        static let me = "/api/v1/auth/me"
        static let chat = "/api/v1/chat"
        static let chatHistory = "/api/v1/chat/history"
        static let balance = "/api/v1/balance"
        static let hideMoney = "/api/v1/money/hide"
        static let revealMoney = "/api/v1/money/reveal"
        static let transactions = "/api/v1/transactions"
        static let bills = "/api/v1/bills"
        static let billsDetect = "/api/v1/bills/detect"
        static let plaidLinkToken = "/api/v1/plaid/link-token"
        static let plaidExchange = "/api/v1/plaid/exchange"
        static let plaidSync = "/api/v1/plaid/sync-all"
        static let profile = "/api/v1/profile"
        static let savingsGoal = "/api/v1/savings-goal"
    }

    // MARK: - App Settings

    static let appName = "Furg"
    static let tagline = "Your money, but smarter than you"

    // MARK: - UserDefaults Keys

    struct Keys {
        static let jwtToken = "jwt_token"
        static let userId = "user_id"
        static let hasSeenOnboarding = "has_seen_onboarding"
        static let isDarkMode = "is_dark_mode"
    }

    // MARK: - Plaid Configuration

    struct Plaid {
        #if DEBUG
        static let environment = "sandbox"
        #else
        static let environment = "production"
        #endif
    }
}
