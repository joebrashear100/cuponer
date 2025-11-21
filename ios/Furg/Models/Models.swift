//
//  Models.swift
//  Furg
//
//  Data models for API responses and app state
//

import Foundation

// MARK: - Authentication Models

struct AuthResponse: Codable {
    let jwt: String
    let userId: String
    let isNewUser: Bool

    enum CodingKeys: String, CodingKey {
        case jwt
        case userId = "user_id"
        case isNewUser = "is_new_user"
    }
}

struct AppleAuthRequest: Codable {
    let appleToken: String
    let userIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case appleToken = "apple_token"
        case userIdentifier = "user_identifier"
    }
}

// MARK: - Chat Models

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: String, Codable {
        case user
        case assistant
    }

    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct ChatRequest: Codable {
    let message: String
    let includeContext: Bool

    enum CodingKeys: String, CodingKey {
        case message
        case includeContext = "include_context"
    }
}

struct ChatResponse: Codable {
    let message: String
    let tokensUsed: TokenUsage?

    enum CodingKeys: String, CodingKey {
        case message
        case tokensUsed = "tokens_used"
    }
}

struct TokenUsage: Codable {
    let input: Int
    let output: Int
}

struct ChatHistoryResponse: Codable {
    let messages: [HistoryMessage]
}

struct HistoryMessage: Codable {
    let role: String
    let content: String
    let timestamp: String
}

// MARK: - Balance Models

struct BalanceSummary: Codable {
    let totalBalance: Double
    let visibleBalance: Double
    let hiddenBalance: Double
    let safetyBuffer: Double
    let trulyAvailable: Double
    let hiddenAccounts: [ShadowAccount]

    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case visibleBalance = "visible_balance"
        case hiddenBalance = "hidden_balance"
        case safetyBuffer = "safety_buffer"
        case trulyAvailable = "truly_available"
        case hiddenAccounts = "hidden_accounts"
    }
}

struct ShadowAccount: Codable, Identifiable {
    let id: String
    let balance: Double
    let purpose: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case balance
        case purpose
        case createdAt = "created_at"
    }
}

struct HideMoneyRequest: Codable {
    let amount: Double
    let purpose: String
}

struct HideMoneyResponse: Codable {
    let success: Bool
    let message: String
    let hiddenAmount: Double?
    let totalHidden: Double?
    let reason: String?
    let shortfall: Double?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case hiddenAmount = "hidden_amount"
        case totalHidden = "total_hidden"
        case reason
        case shortfall
    }
}

// MARK: - Transaction Models

struct Transaction: Codable, Identifiable {
    let id: String
    let date: String
    let amount: Double
    let merchant: String
    let category: String?
    let isBill: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case amount
        case merchant
        case category
        case isBill = "is_bill"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: date) {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
        return date
    }

    var formattedAmount: String {
        let absAmount = abs(amount)
        return String(format: "$%.2f", absAmount)
    }

    var isExpense: Bool {
        return amount < 0
    }
}

struct TransactionsResponse: Codable {
    let transactions: [Transaction]
}

struct SpendingSummaryResponse: Codable {
    let totalSpent: Double
    let byCategory: [String: Double]
    let periodDays: Int

    enum CodingKeys: String, CodingKey {
        case totalSpent = "total_spent"
        case byCategory = "by_category"
        case periodDays = "period_days"
    }
}

// MARK: - Bill Models

struct Bill: Codable, Identifiable {
    let id: String?
    let merchant: String
    let amount: Double
    let frequencyDays: Int
    let nextDue: String
    let confidence: Double
    let category: String?

    enum CodingKeys: String, CodingKey {
        case id
        case merchant
        case amount
        case frequencyDays = "frequency_days"
        case nextDue = "next_due"
        case confidence
        case category
    }

    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }

    var frequencyText: String {
        switch frequencyDays {
        case 7: return "Weekly"
        case 14: return "Bi-weekly"
        case 28...31: return "Monthly"
        case 84...97: return "Quarterly"
        case 350...380: return "Yearly"
        default: return "\(frequencyDays) days"
        }
    }
}

struct BillsResponse: Codable {
    let bills: [Bill]
}

struct UpcomingBillsResponse: Codable {
    let total: Double
    let count: Int
    let byCategory: [String: Double]
    let bills: [Bill]

    enum CodingKeys: String, CodingKey {
        case total
        case count
        case byCategory = "by_category"
        case bills
    }
}

// MARK: - Plaid Models

struct PlaidLinkTokenResponse: Codable {
    let linkToken: String

    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
    }
}

struct PlaidExchangeRequest: Codable {
    let publicToken: String

    enum CodingKeys: String, CodingKey {
        case publicToken = "public_token"
    }
}

struct PlaidExchangeResponse: Codable {
    let itemId: String
    let institutionName: String

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case institutionName = "institution_name"
    }
}

// MARK: - User Profile Models

struct UserProfile: Codable {
    let userId: String?
    let name: String?
    let location: String?
    let employer: String?
    let salary: Double?
    let savingsGoal: SavingsGoal?
    let intensityMode: String?
    let emergencyBuffer: Double?
    let learnedInsights: [String]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case location
        case employer
        case salary
        case savingsGoal = "savings_goal"
        case intensityMode = "intensity_mode"
        case emergencyBuffer = "emergency_buffer"
        case learnedInsights = "learned_insights"
    }
}

struct SavingsGoal: Codable {
    let amount: Double
    let deadline: String
    let purpose: String
    let frequency: String?
    let amountPerPeriod: Double?

    enum CodingKeys: String, CodingKey {
        case amount
        case deadline
        case purpose
        case frequency
        case amountPerPeriod = "amount_per_period"
    }
}

struct SavingsGoalRequest: Codable {
    let goalAmount: Double
    let deadline: String
    let purpose: String
    let frequency: String

    enum CodingKeys: String, CodingKey {
        case goalAmount = "goal_amount"
        case deadline
        case purpose
        case frequency
    }
}

// MARK: - Error Models

struct APIError: Codable {
    let detail: String
}
