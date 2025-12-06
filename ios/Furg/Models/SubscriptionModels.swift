//
//  SubscriptionModels.swift
//  Furg
//
//  Models for subscription tracking, bill negotiation, and recurring patterns
//

import Foundation

// MARK: - Subscription

struct Subscription: Identifiable, Codable {
    let id: String
    let merchantName: String
    let merchantLogo: String?
    let category: SubscriptionCategory
    let amount: Decimal
    let frequency: RecurringFrequency
    let nextBillingDate: Date
    let startDate: Date?
    let freeTrialEnds: Date?
    let status: SubscriptionStatus
    let cancellationUrl: String?
    let cancellationDifficulty: CancellationDifficulty
    let usageMetrics: SubscriptionUsage?
    let lastUsedDate: Date?

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSNumber) ?? "$\(amount)"
    }

    var monthlyEquivalent: Decimal {
        switch frequency {
        case .weekly: return amount * 4
        case .biweekly: return amount * 2
        case .monthly: return amount
        case .quarterly: return amount / 3
        case .annual: return amount / 12
        }
    }

    var annualCost: Decimal {
        return monthlyEquivalent * 12
    }

    var valueScore: Float {
        guard let usage = usageMetrics else { return 0.5 }
        return usage.valueScore
    }

    var isUnused: Bool {
        guard let lastUsed = lastUsedDate else { return true }
        let daysSinceUse = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
        return daysSinceUse > 30
    }
}

enum SubscriptionCategory: String, Codable, CaseIterable {
    case streaming
    case music
    case gaming
    case productivity
    case news
    case fitness
    case storage
    case dating
    case learning
    case software
    case membership
    case other

    var label: String {
        switch self {
        case .streaming: return "Streaming"
        case .music: return "Music"
        case .gaming: return "Gaming"
        case .productivity: return "Productivity"
        case .news: return "News & Media"
        case .fitness: return "Fitness"
        case .storage: return "Cloud Storage"
        case .dating: return "Dating"
        case .learning: return "Learning"
        case .software: return "Software"
        case .membership: return "Membership"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .streaming: return "play.tv"
        case .music: return "music.note"
        case .gaming: return "gamecontroller"
        case .productivity: return "doc.text"
        case .news: return "newspaper"
        case .fitness: return "figure.run"
        case .storage: return "icloud"
        case .dating: return "heart.circle"
        case .learning: return "book"
        case .software: return "app.badge"
        case .membership: return "person.crop.circle"
        case .other: return "creditcard"
        }
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case weekly
    case biweekly
    case monthly
    case quarterly
    case annual

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annual: return "Annual"
        }
    }

    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .annual: return 365
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active
    case paused
    case cancelled
    case trialEnding
    case priceIncrease
}

enum CancellationDifficulty: String, Codable {
    case easy        // One-click online
    case moderate    // Online but buried
    case hard        // Requires phone call
    case veryHard    // Requires written letter or in-person

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "checkmark.circle"
        case .moderate: return "exclamationmark.circle"
        case .hard: return "phone.circle"
        case .veryHard: return "xmark.circle"
        }
    }
}

struct SubscriptionUsage: Codable {
    let lastUsedDate: Date?
    let usageFrequency: String?
    let valueScore: Float // 0-1
}

// MARK: - Cancellation Guide

struct CancellationGuide: Identifiable, Codable {
    let id: String
    let merchantName: String
    let method: CancellationMethod
    let url: String?
    let phoneNumber: String?
    let steps: [String]
    let script: String?
    let averageTimeMinutes: Int
    let successRate: Float
    let tips: [String]
    let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case merchantName = "merchant_name"
        case method
        case url
        case phoneNumber = "phone_number"
        case steps
        case script
        case averageTimeMinutes = "average_time_minutes"
        case successRate = "success_rate"
        case tips
        case warnings
    }
}

enum CancellationMethod: String, Codable {
    case onlineOneClick
    case onlineMultiStep
    case phoneCancellation
    case emailCancellation
    case inPersonRequired
    case chatSupport

    var label: String {
        switch self {
        case .onlineOneClick: return "One-Click Online"
        case .onlineMultiStep: return "Online (Multi-Step)"
        case .phoneCancellation: return "Phone Call Required"
        case .emailCancellation: return "Email Required"
        case .inPersonRequired: return "In-Person Required"
        case .chatSupport: return "Chat Support"
        }
    }
}

// MARK: - Bill Negotiation

struct NegotiationScript: Identifiable, Codable {
    let id: String
    let merchantName: String
    let openingLine: String
    let valueStatements: [String]
    let competitorMentions: [CompetitorMention]
    let askAmount: Decimal
    let fallbackAsks: [Decimal]
    let retentionCounters: [RetentionCounter]
    let closingLine: String
    let doNotSay: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case merchantName = "merchant_name"
        case openingLine = "opening_line"
        case valueStatements = "value_statements"
        case competitorMentions = "competitor_mentions"
        case askAmount = "ask_amount"
        case fallbackAsks = "fallback_asks"
        case retentionCounters = "retention_counters"
        case closingLine = "closing_line"
        case doNotSay = "do_not_say"
    }
}

struct CompetitorMention: Codable {
    let competitorName: String
    let competitorPrice: Decimal
    let competitorOffer: String

    enum CodingKeys: String, CodingKey {
        case competitorName = "competitor_name"
        case competitorPrice = "competitor_price"
        case competitorOffer = "competitor_offer"
    }
}

struct RetentionCounter: Codable {
    let offerType: String
    let response: String

    enum CodingKeys: String, CodingKey {
        case offerType = "offer_type"
        case response
    }
}

struct NegotiationPotential: Codable {
    let billId: String
    let merchantName: String
    let currentAmount: Decimal
    let marketAverage: Decimal
    let marketLow: Decimal
    let potentialMonthlySavings: Decimal
    let successRate: Float
    let bestTimeToCall: String?
    let retentionOffers: [String]?

    enum CodingKeys: String, CodingKey {
        case billId = "bill_id"
        case merchantName = "merchant_name"
        case currentAmount = "current_amount"
        case marketAverage = "market_average"
        case marketLow = "market_low"
        case potentialMonthlySavings = "potential_monthly_savings"
        case successRate = "success_rate"
        case bestTimeToCall = "best_time_to_call"
        case retentionOffers = "retention_offers"
    }

    var annualSavings: Decimal {
        return potentialMonthlySavings * 12
    }
}

struct NegotiationAttempt: Identifiable, Codable {
    let id: String
    let billId: String
    let merchantName: String
    let originalAmount: Decimal
    let targetAmount: Decimal
    let status: NegotiationStatus
    let method: NegotiationMethod
    let startedAt: Date
    let completedAt: Date?
    let resultAmount: Decimal?
    let monthlySavings: Decimal?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case billId = "bill_id"
        case merchantName = "merchant_name"
        case originalAmount = "original_amount"
        case targetAmount = "target_amount"
        case status
        case method
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case resultAmount = "result_amount"
        case monthlySavings = "monthly_savings"
        case notes
    }
}

enum NegotiationStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case succeeded
    case partialSuccess = "partial_success"
    case failed
    case userCancelled = "user_cancelled"
}

enum NegotiationMethod: String, Codable {
    case userPhoneCall = "user_phone_call"
    case userEmail = "user_email"
    case userChat = "user_chat"
}

// MARK: - Subscription Summary

struct SubscriptionSummary: Codable {
    let totalMonthly: Decimal
    let totalAnnual: Decimal
    let subscriptionCount: Int
    let unusedCount: Int
    let potentialSavings: Decimal
    let byCategory: [String: Decimal]

    enum CodingKeys: String, CodingKey {
        case totalMonthly = "total_monthly"
        case totalAnnual = "total_annual"
        case subscriptionCount = "subscription_count"
        case unusedCount = "unused_count"
        case potentialSavings = "potential_savings"
        case byCategory = "by_category"
    }
}

// MARK: - API Response Models

struct SubscriptionsResponse: Codable {
    let subscriptions: [Subscription]
    let summary: SubscriptionSummary?
}

struct CancellationGuideResponse: Codable {
    let guide: CancellationGuide
}

struct NegotiationScriptResponse: Codable {
    let script: NegotiationScript
    let potential: NegotiationPotential?
}
