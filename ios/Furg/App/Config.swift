//
//  Config.swift
//  Furg
//
//  App configuration and constants
//  SECURITY: API keys and secrets should be loaded from environment or Keychain
//

import Foundation
import os.log

private let configLogger = Logger(subsystem: "com.furg.app", category: "Config")

struct Config {
    // MARK: - Backend Configuration

    /// Base URL loaded from environment or defaults
    /// Set FURG_API_URL environment variable in scheme for custom URL
    static var baseURL: String {
        if let envURL = ProcessInfo.processInfo.environment["FURG_API_URL"] {
            return envURL
        }
        #if DEBUG
        // Use localhost for simulator, configure your IP in scheme environment variables
        return "http://localhost:8000"
        #else
        return "https://api.furg.app"
        #endif
    }

    // MARK: - Claude AI Configuration

    struct Claude {
        /// API key loaded from Keychain or environment
        /// NEVER hardcode API keys in source code
        static var apiKey: String {
            // Try Keychain first (set during onboarding or settings)
            if let keychainKey = KeychainService.shared.getStringOptional(for: .claudeApiKey) {
                return keychainKey
            }
            // Try environment variable (for development)
            if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
                return envKey
            }
            // Return empty - will fail gracefully at runtime
            configLogger.warning("Claude API key not configured. Set CLAUDE_API_KEY env var or configure in Keychain.")
            return ""
        }

        static let baseURL = "https://api.anthropic.com/v1/messages"
        static let model = "claude-sonnet-4-20250514"
        static let maxTokens = 1024

        /// Check if Claude is properly configured
        static var isConfigured: Bool {
            !apiKey.isEmpty
        }
    }

    // MARK: - Configuration Validation

    /// Validates configuration at app startup
    /// Call this early in app lifecycle to catch misconfigurations
    static func validate() -> [ConfigurationError] {
        var errors: [ConfigurationError] = []

        if Claude.apiKey.isEmpty {
            errors.append(.missingClaudeApiKey)
        }

        if URL(string: baseURL) == nil {
            errors.append(.invalidBaseURL)
        }

        return errors
    }

    enum ConfigurationError: Error, CustomStringConvertible {
        case missingClaudeApiKey
        case invalidBaseURL
        case missingPlaidConfig

        var description: String {
            switch self {
            case .missingClaudeApiKey:
                return "Claude API key not configured. AI features will be disabled."
            case .invalidBaseURL:
                return "Invalid API base URL configured."
            case .missingPlaidConfig:
                return "Plaid configuration missing. Bank linking will be disabled."
            }
        }
    }

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

        // Shopping Assistant (ChatGPT-style shopping mode)
        static let shoppingChat = "/api/v1/shopping/chat"
        static let shoppingSearch = "/api/v1/shopping/search"
        static let shoppingDeals = "/api/v1/shopping/deals"
        static let shoppingCompare = "/api/v1/shopping/compare"
        static let shoppingList = "/api/v1/shopping/list"
        static let shoppingPriceAlert = "/api/v1/shopping/price-alert"
        static let shoppingRecommendations = "/api/v1/shopping/recommendations"
        static let shoppingBestCard = "/api/v1/shopping/best-card"
        static let shoppingLoyaltyPoints = "/api/v1/shopping/loyalty-points"
        static let shoppingReorderSuggestions = "/api/v1/shopping/reorder-suggestions"
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
