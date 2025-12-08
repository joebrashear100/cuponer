//
//  CardOptimizer.swift
//  Furg
//
//  Smart card recommendations - which card to use for each purchase
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct UserCard: Identifiable, Codable {
    let id: UUID
    var nickname: String
    var issuer: String
    var cardName: String
    var last4: String
    var cardType: CardType
    var rewardsStructure: [String: CardReward]
    var annualFee: Double
    var isActive: Bool
    var cardColor: String
    var addedDate: Date

    enum CardType: String, Codable, CaseIterable {
        case credit = "Credit"
        case debit = "Debit"
        case prepaid = "Prepaid"
    }

    var primaryCategory: String? {
        rewardsStructure.max(by: { $0.value.multiplier < $1.value.multiplier })?.key
    }
}

struct CardReward: Codable {
    let multiplier: Double // e.g., 3 for 3x points or 3% cash back
    let rewardType: RewardType
    let cap: Double? // Monthly or quarterly cap
    let capPeriod: CapPeriod?
    let isRotating: Bool
    let validUntil: Date?

    enum RewardType: String, Codable {
        case points = "Points"
        case miles = "Miles"
        case cashback = "Cash Back"
    }

    enum CapPeriod: String, Codable {
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case annual = "Annual"
    }
}

struct CardRecommendation: Identifiable {
    let id = UUID()
    let card: UserCard
    let category: String
    let reward: CardReward
    let estimatedValue: Double // Monthly estimated value
    let explanation: String
    let alternativeCards: [(UserCard, CardReward)]
}

struct PurchaseRecommendation: Identifiable {
    let id = UUID()
    let merchantName: String
    let category: String
    let recommendedCard: UserCard
    let reward: CardReward
    let valuePerDollar: Double
    let reasoning: String
}

struct RotatingCategory: Identifiable, Codable {
    let id: UUID
    let cardId: UUID
    let category: String
    let multiplier: Double
    let startDate: Date
    let endDate: Date
    var isActivated: Bool
}

struct CardUsageStats: Identifiable {
    let id = UUID()
    let cardId: UUID
    let cardName: String
    let totalSpent: Double
    let totalRewardsEarned: Double
    let effectiveRewardsRate: Double
    let topCategories: [(String, Double)]
}

// MARK: - Card Optimizer

class CardOptimizer: ObservableObject {
    static let shared = CardOptimizer()

    @Published var userCards: [UserCard] = []
    @Published var rotatingCategories: [RotatingCategory] = []
    @Published var categoryRecommendations: [String: CardRecommendation] = [:]
    @Published var recentPurchaseRecommendations: [PurchaseRecommendation] = []
    @Published var cardUsageStats: [CardUsageStats] = []
    @Published var totalOptimizedValue: Double = 0

    // Category mappings for merchant detection
    private let merchantCategories: [String: String] = [
        // Grocery
        "whole foods": "Groceries",
        "trader joe": "Groceries",
        "safeway": "Groceries",
        "kroger": "Groceries",
        "publix": "Groceries",
        "wegmans": "Groceries",
        "costco": "Groceries",
        "sam's club": "Groceries",
        "aldi": "Groceries",
        "instacart": "Groceries",

        // Dining
        "starbucks": "Food & Dining",
        "mcdonald": "Food & Dining",
        "chipotle": "Food & Dining",
        "doordash": "Food & Dining",
        "uber eats": "Food & Dining",
        "grubhub": "Food & Dining",
        "restaurant": "Food & Dining",

        // Gas
        "shell": "Gas",
        "exxon": "Gas",
        "chevron": "Gas",
        "bp": "Gas",
        "speedway": "Gas",

        // Travel
        "airline": "Travel",
        "delta": "Travel",
        "united": "Travel",
        "southwest": "Travel",
        "hotel": "Travel",
        "marriott": "Travel",
        "hilton": "Travel",
        "airbnb": "Travel",
        "uber": "Transportation",
        "lyft": "Transportation",

        // Shopping
        "amazon": "Shopping",
        "target": "Shopping",
        "walmart": "Shopping",
        "best buy": "Shopping",

        // Entertainment
        "netflix": "Streaming",
        "spotify": "Streaming",
        "hulu": "Streaming",
        "disney": "Streaming",
        "hbo": "Streaming",
        "apple.com/bill": "Streaming",

        // Utilities
        "verizon": "Phone",
        "at&t": "Phone",
        "t-mobile": "Phone",
        "comcast": "Internet",
        "xfinity": "Internet"
    ]

    private let userDefaults = UserDefaults.standard
    private let cardsKey = "furg_user_cards"
    private let rotatingKey = "furg_rotating_categories"

    init() {
        loadUserCards()
        loadRotatingCategories()
        generateCategoryRecommendations()
    }

    // MARK: - Card Management

    func addCard(_ card: UserCard) {
        userCards.append(card)
        saveUserCards()
        generateCategoryRecommendations()
    }

    func updateCard(_ card: UserCard) {
        if let index = userCards.firstIndex(where: { $0.id == card.id }) {
            userCards[index] = card
            saveUserCards()
            generateCategoryRecommendations()
        }
    }

    func removeCard(_ card: UserCard) {
        userCards.removeAll { $0.id == card.id }
        saveUserCards()
        generateCategoryRecommendations()
    }

    func addRewardCategory(to cardId: UUID, category: String, reward: CardReward) {
        if let index = userCards.firstIndex(where: { $0.id == cardId }) {
            userCards[index].rewardsStructure[category] = reward
            saveUserCards()
            generateCategoryRecommendations()
        }
    }

    // MARK: - Rotating Categories

    func addRotatingCategory(_ rotating: RotatingCategory) {
        rotatingCategories.append(rotating)
        saveRotatingCategories()
        generateCategoryRecommendations()
    }

    func activateRotatingCategory(_ id: UUID) {
        if let index = rotatingCategories.firstIndex(where: { $0.id == id }) {
            rotatingCategories[index].isActivated = true
            saveRotatingCategories()
        }
    }

    func getCurrentRotatingCategories() -> [RotatingCategory] {
        let now = Date()
        return rotatingCategories.filter { $0.startDate <= now && $0.endDate >= now }
    }

    // MARK: - Recommendations

    func generateCategoryRecommendations() {
        var recommendations: [String: CardRecommendation] = [:]

        let categories = Set(userCards.flatMap { $0.rewardsStructure.keys })

        for category in categories {
            // Find the best card for this category
            var bestCard: UserCard?
            var bestReward: CardReward?
            var alternatives: [(UserCard, CardReward)] = []

            for card in userCards where card.isActive {
                if let reward = card.rewardsStructure[category] {
                    // Check if rotating category is active
                    var effectiveReward = reward
                    if reward.isRotating {
                        let activeRotating = getCurrentRotatingCategories().first {
                            $0.cardId == card.id && $0.category == category && $0.isActivated
                        }
                        if activeRotating == nil {
                            continue // Skip if rotating not activated
                        }
                    }

                    if bestReward == nil || effectiveReward.multiplier > bestReward!.multiplier {
                        if let currentBest = bestCard, let currentReward = bestReward {
                            alternatives.append((currentBest, currentReward))
                        }
                        bestCard = card
                        bestReward = effectiveReward
                    } else {
                        alternatives.append((card, effectiveReward))
                    }
                }
            }

            if let card = bestCard, let reward = bestReward {
                // Estimate monthly value based on typical spending
                let estimatedMonthlySpending = getEstimatedSpending(for: category)
                let estimatedValue = estimatedMonthlySpending * reward.multiplier * 0.01 // Convert to dollars

                recommendations[category] = CardRecommendation(
                    card: card,
                    category: category,
                    reward: reward,
                    estimatedValue: estimatedValue,
                    explanation: generateExplanation(card: card, category: category, reward: reward),
                    alternativeCards: alternatives.sorted { $0.1.multiplier > $1.1.multiplier }
                )
            }
        }

        categoryRecommendations = recommendations

        // Calculate total optimized value
        totalOptimizedValue = recommendations.values.reduce(0) { $0 + $1.estimatedValue * 12 }
    }

    func getRecommendation(for merchantName: String, amount: Double) -> PurchaseRecommendation? {
        let category = detectCategory(from: merchantName)

        guard let categoryRec = categoryRecommendations[category] else {
            // Fall back to best overall card
            return getBestOverallCard(for: amount, merchant: merchantName)
        }

        let recommendation = PurchaseRecommendation(
            merchantName: merchantName,
            category: category,
            recommendedCard: categoryRec.card,
            reward: categoryRec.reward,
            valuePerDollar: categoryRec.reward.multiplier * 0.01,
            reasoning: "Use your \(categoryRec.card.nickname) for \(categoryRec.reward.multiplier)x \(categoryRec.reward.rewardType.rawValue.lowercased()) on \(category.lowercased())"
        )

        // Store recent recommendation
        recentPurchaseRecommendations.insert(recommendation, at: 0)
        if recentPurchaseRecommendations.count > 20 {
            recentPurchaseRecommendations = Array(recentPurchaseRecommendations.prefix(20))
        }

        return recommendation
    }

    func getBestCard(for category: String) -> (UserCard, CardReward)? {
        guard let recommendation = categoryRecommendations[category] else {
            return nil
        }
        return (recommendation.card, recommendation.reward)
    }

    private func getBestOverallCard(for amount: Double, merchant: String) -> PurchaseRecommendation? {
        // Find card with best base rate
        var bestCard: UserCard?
        var bestBaseRate = 0.0

        for card in userCards where card.isActive {
            // Check for a general "All Purchases" category
            if let allReward = card.rewardsStructure["All Purchases"] ?? card.rewardsStructure["Everything"] {
                if allReward.multiplier > bestBaseRate {
                    bestBaseRate = allReward.multiplier
                    bestCard = card
                }
            }
        }

        guard let card = bestCard else { return nil }

        return PurchaseRecommendation(
            merchantName: merchant,
            category: "Other",
            recommendedCard: card,
            reward: CardReward(multiplier: bestBaseRate, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
            valuePerDollar: bestBaseRate * 0.01,
            reasoning: "Use your \(card.nickname) for \(bestBaseRate)% back on all purchases"
        )
    }

    // MARK: - Category Detection

    func detectCategory(from merchantName: String) -> String {
        let lowercased = merchantName.lowercased()

        for (keyword, category) in merchantCategories {
            if lowercased.contains(keyword) {
                return category
            }
        }

        // Use SmartCategorizationManager as fallback
        return "Other"
    }

    // MARK: - Usage Stats

    func calculateUsageStats() {
        var stats: [CardUsageStats] = []

        let transactions = RealTimeTransactionManager.shared.recentTransactions

        for card in userCards {
            // Filter transactions for this card (simplified - in real app would match by card ID)
            let cardTransactions = transactions.filter { $0.cardLast4 == card.last4 }

            let totalSpent = cardTransactions.reduce(0) { $0 + abs($1.amount) }

            // Calculate rewards earned
            var totalRewards = 0.0
            var categorySpending: [String: Double] = [:]

            for transaction in cardTransactions where transaction.amount < 0 {
                let category = transaction.category
                let amount = abs(transaction.amount)

                categorySpending[category, default: 0] += amount

                if let reward = card.rewardsStructure[category] {
                    totalRewards += amount * reward.multiplier * 0.01
                } else if let baseReward = card.rewardsStructure["All Purchases"] {
                    totalRewards += amount * baseReward.multiplier * 0.01
                }
            }

            let effectiveRate = totalSpent > 0 ? (totalRewards / totalSpent) * 100 : 0

            let topCategories = categorySpending.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }

            stats.append(CardUsageStats(
                cardId: card.id,
                cardName: card.nickname,
                totalSpent: totalSpent,
                totalRewardsEarned: totalRewards,
                effectiveRewardsRate: effectiveRate,
                topCategories: topCategories
            ))
        }

        cardUsageStats = stats
    }

    // MARK: - Optimization Opportunities

    func findMissedOpportunities() -> [(transaction: RealTimeTransaction, betterCard: UserCard, missedValue: Double)] {
        var opportunities: [(RealTimeTransaction, UserCard, Double)] = []

        let transactions = RealTimeTransactionManager.shared.recentTransactions

        for transaction in transactions where transaction.amount < 0 {
            let category = transaction.category
            let amount = abs(transaction.amount)

            // Find what card was used (by last4)
            let usedCard = userCards.first { $0.last4 == transaction.cardLast4 }

            // Find the best card for this category
            guard let (bestCard, bestReward) = getBestCard(for: category) else { continue }

            // Calculate value difference
            let usedCardReward = usedCard?.rewardsStructure[category]?.multiplier ?? 1.0
            let bestCardReward = bestReward.multiplier

            if bestCard.id != usedCard?.id && bestCardReward > usedCardReward {
                let missedValue = amount * (bestCardReward - usedCardReward) * 0.01
                if missedValue > 0.25 { // Only show if missed at least $0.25
                    opportunities.append((transaction, bestCard, missedValue))
                }
            }
        }

        return opportunities.sorted { $0.2 > $1.2 }
    }

    // MARK: - Alerts & Reminders

    func getRotatingCategoryReminders() -> [String] {
        var reminders: [String] = []

        // Check for expiring rotations
        let now = Date()
        let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        for rotation in rotatingCategories {
            if rotation.endDate <= oneWeekFromNow && rotation.endDate > now {
                let daysLeft = Calendar.current.dateComponents([.day], from: now, to: rotation.endDate).day ?? 0
                let card = userCards.first { $0.id == rotation.cardId }
                reminders.append("⚠️ \(rotation.category) bonus on \(card?.nickname ?? "card") ends in \(daysLeft) days!")
            }
        }

        // Check for unactivated rotations
        for rotation in getCurrentRotatingCategories() where !rotation.isActivated {
            let card = userCards.first { $0.id == rotation.cardId }
            reminders.append("🔔 Activate \(rotation.multiplier)x \(rotation.category) on your \(card?.nickname ?? "card")!")
        }

        return reminders
    }

    // MARK: - Helpers

    private func getEstimatedSpending(for category: String) -> Double {
        let spending = RealTimeTransactionManager.shared.recentTransactions
            .filter { $0.category == category && $0.amount < 0 }
            .reduce(0) { $0 + abs($1.amount) }

        // If we have data, use it; otherwise use estimates
        if spending > 0 {
            return spending / 3 // Assume 3 months of data, return monthly average
        }

        // Default estimates
        let estimates: [String: Double] = [
            "Groceries": 400,
            "Food & Dining": 300,
            "Gas": 150,
            "Travel": 200,
            "Shopping": 250,
            "Streaming": 50,
            "Transportation": 100,
            "Phone": 80,
            "Internet": 70
        ]

        return estimates[category] ?? 100
    }

    private func generateExplanation(card: UserCard, category: String, reward: CardReward) -> String {
        var explanation = "Use \(card.nickname) for \(reward.multiplier)x \(reward.rewardType.rawValue.lowercased()) on \(category.lowercased())"

        if let cap = reward.cap, let period = reward.capPeriod {
            explanation += " (up to $\(Int(cap)) \(period.rawValue.lowercased()))"
        }

        if reward.isRotating {
            explanation += " - rotating bonus category"
        }

        return explanation
    }

    // MARK: - Persistence

    private func saveUserCards() {
        if let data = try? JSONEncoder().encode(userCards) {
            userDefaults.set(data, forKey: cardsKey)
        }
    }

    private func loadUserCards() {
        guard let data = userDefaults.data(forKey: cardsKey),
              let loaded = try? JSONDecoder().decode([UserCard].self, from: data) else {
            addDemoCards()
            return
        }
        userCards = loaded
    }

    private func saveRotatingCategories() {
        if let data = try? JSONEncoder().encode(rotatingCategories) {
            userDefaults.set(data, forKey: rotatingKey)
        }
    }

    private func loadRotatingCategories() {
        guard let data = userDefaults.data(forKey: rotatingKey),
              let loaded = try? JSONDecoder().decode([RotatingCategory].self, from: data) else {
            return
        }
        rotatingCategories = loaded
    }

    private func addDemoCards() {
        userCards = [
            UserCard(
                id: UUID(),
                nickname: "Sapphire",
                issuer: "Chase",
                cardName: "Sapphire Preferred",
                last4: "4521",
                cardType: .credit,
                rewardsStructure: [
                    "Travel": CardReward(multiplier: 5, rewardType: .points, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "Food & Dining": CardReward(multiplier: 3, rewardType: .points, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "Streaming": CardReward(multiplier: 3, rewardType: .points, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "All Purchases": CardReward(multiplier: 1, rewardType: .points, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil)
                ],
                annualFee: 95,
                isActive: true,
                cardColor: "blue",
                addedDate: Date()
            ),
            UserCard(
                id: UUID(),
                nickname: "Blue Cash",
                issuer: "American Express",
                cardName: "Blue Cash Preferred",
                last4: "3782",
                cardType: .credit,
                rewardsStructure: [
                    "Groceries": CardReward(multiplier: 6, rewardType: .cashback, cap: 6000, capPeriod: .annual, isRotating: false, validUntil: nil),
                    "Streaming": CardReward(multiplier: 6, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "Gas": CardReward(multiplier: 3, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "Transportation": CardReward(multiplier: 3, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "All Purchases": CardReward(multiplier: 1, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil)
                ],
                annualFee: 95,
                isActive: true,
                cardColor: "cyan",
                addedDate: Date()
            ),
            UserCard(
                id: UUID(),
                nickname: "Discover",
                issuer: "Discover",
                cardName: "Discover it",
                last4: "6011",
                cardType: .credit,
                rewardsStructure: [
                    "Rotating": CardReward(multiplier: 5, rewardType: .cashback, cap: 1500, capPeriod: .quarterly, isRotating: true, validUntil: nil),
                    "All Purchases": CardReward(multiplier: 1, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil)
                ],
                annualFee: 0,
                isActive: true,
                cardColor: "orange",
                addedDate: Date()
            ),
            UserCard(
                id: UUID(),
                nickname: "Apple Card",
                issuer: "Apple",
                cardName: "Apple Card",
                last4: "4242",
                cardType: .credit,
                rewardsStructure: [
                    "Apple": CardReward(multiplier: 3, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "Apple Pay": CardReward(multiplier: 2, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil),
                    "All Purchases": CardReward(multiplier: 1, rewardType: .cashback, cap: nil, capPeriod: nil, isRotating: false, validUntil: nil)
                ],
                annualFee: 0,
                isActive: true,
                cardColor: "gray",
                addedDate: Date()
            )
        ]

        // Add current quarter's rotating categories
        let quarterEnd = getQuarterEndDate()
        rotatingCategories = [
            RotatingCategory(
                id: UUID(),
                cardId: userCards[2].id, // Discover
                category: "Gas",
                multiplier: 5,
                startDate: getQuarterStartDate(),
                endDate: quarterEnd,
                isActivated: true
            ),
            RotatingCategory(
                id: UUID(),
                cardId: userCards[2].id, // Discover
                category: "Wholesale Clubs",
                multiplier: 5,
                startDate: getQuarterStartDate(),
                endDate: quarterEnd,
                isActivated: true
            )
        ]

        saveUserCards()
        saveRotatingCategories()
    }

    private func getQuarterStartDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let quarterMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: now)
        components.month = quarterMonth
        components.day = 1
        return calendar.date(from: components)!
    }

    private func getQuarterEndDate() -> Date {
        let calendar = Calendar.current
        let start = getQuarterStartDate()
        return calendar.date(byAdding: .month, value: 3, to: start)!
    }
}
