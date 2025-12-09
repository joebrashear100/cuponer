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
    let availableBalance: Double
    let hiddenBalance: Double
    let pendingBalance: Double
    let safetyBuffer: Double
    let lastUpdated: String?
    let hiddenAccounts: [ShadowAccount]?

    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case availableBalance = "available_balance"
        case hiddenBalance = "hidden_balance"
        case pendingBalance = "pending_balance"
        case safetyBuffer = "safety_buffer"
        case lastUpdated = "last_updated"
        case hiddenAccounts = "hidden_accounts"
    }

    init(totalBalance: Double, availableBalance: Double, hiddenBalance: Double, pendingBalance: Double, safetyBuffer: Double, lastUpdated: String?, hiddenAccounts: [ShadowAccount]? = nil) {
        self.totalBalance = totalBalance
        self.availableBalance = availableBalance
        self.hiddenBalance = hiddenBalance
        self.pendingBalance = pendingBalance
        self.safetyBuffer = safetyBuffer
        self.lastUpdated = lastUpdated
        self.hiddenAccounts = hiddenAccounts
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
    let category: String
    let isBill: Bool
    let isPending: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case amount
        case merchant
        case category
        case isBill = "is_bill"
        case isPending = "is_pending"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        amount = try container.decode(Double.self, forKey: .amount)
        merchant = try container.decode(String.self, forKey: .merchant)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Other"
        isBill = try container.decodeIfPresent(Bool.self, forKey: .isBill) ?? false
        isPending = try container.decodeIfPresent(Bool.self, forKey: .isPending) ?? false
    }

    init(id: String = UUID().uuidString, date: String, amount: Double, merchant: String, category: String, isBill: Bool = false, isPending: Bool = false) {
        self.id = id
        self.date = date
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.isBill = isBill
        self.isPending = isPending
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
    let frequency: String?
    let frequencyDays: Int?
    let nextDue: String
    let confidence: Double
    let category: String?

    enum CodingKeys: String, CodingKey {
        case id
        case merchant
        case amount
        case frequency
        case frequencyDays = "frequency_days"
        case nextDue = "next_due"
        case confidence
        case category
    }

    init(id: String?, merchant: String, amount: Double, frequency: String? = nil, frequencyDays: Int? = nil, nextDue: String, category: String?, confidence: Double) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.frequency = frequency
        self.frequencyDays = frequencyDays
        self.nextDue = nextDue
        self.category = category
        self.confidence = confidence
    }

    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }

    var frequencyText: String {
        if let frequency = frequency {
            return frequency.capitalized
        }
        guard let days = frequencyDays else { return "Unknown" }
        switch days {
        case 7: return "Weekly"
        case 14: return "Bi-weekly"
        case 28...31: return "Monthly"
        case 84...97: return "Quarterly"
        case 350...380: return "Yearly"
        default: return "\(days) days"
        }
    }
}

struct BillsResponse: Codable {
    let bills: [Bill]
}

struct UpcomingBillsResponse: Codable {
    let total: Double?
    let totalDue: Double?
    let count: Int?
    let daysAhead: Int?
    let byCategory: [String: Double]?
    let bills: [Bill]

    enum CodingKeys: String, CodingKey {
        case total
        case totalDue = "total_due"
        case count
        case daysAhead = "days_ahead"
        case byCategory = "by_category"
        case bills
    }

    init(bills: [Bill], totalDue: Double, daysAhead: Int) {
        self.bills = bills
        self.totalDue = totalDue
        self.total = totalDue
        self.daysAhead = daysAhead
        self.count = bills.count
        self.byCategory = nil
    }

    var totalAmount: Double {
        return totalDue ?? total ?? bills.reduce(0) { $0 + $1.amount }
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
    var name: String?
    var location: String?
    var employer: String?
    var salary: Double?
    var savingsGoal: SavingsGoal?
    var intensityMode: String?
    var emergencyBuffer: Double?
    var learnedInsights: [String]?

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

// MARK: - Common Enums

/// Shared date range enum for filtering transactions and exports
enum DateRange: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
    case allTime = "All Time"

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return 365
        }
    }
}
