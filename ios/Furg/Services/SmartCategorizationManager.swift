//
//  SmartCategorizationManager.swift
//  Furg
//
//  AI-powered intelligent transaction categorization with confidence scoring
//

import Foundation
import SwiftUI
import Combine
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "SmartCategorization")

// MARK: - Models

struct CategorizationResult: Identifiable, Codable {
    let id: UUID
    let transactionId: String
    let suggestedCategory: String
    let confidence: Double // 0.0 to 1.0
    let alternativeCategories: [CategorySuggestion]
    let reasoning: String
    let needsUserInput: Bool
    let merchantPatterns: [String]
    let timestamp: Date

    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.9...1.0: return .veryHigh
        case 0.75..<0.9: return .high
        case 0.5..<0.75: return .medium
        case 0.25..<0.5: return .low
        default: return .veryLow
        }
    }
}

struct CategorySuggestion: Codable, Identifiable {
    var id: String { category }
    let category: String
    let confidence: Double
    let reason: String
}

enum ConfidenceLevel: String, Codable {
    case veryHigh = "Very High"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case veryLow = "Very Low"

    var color: Color {
        switch self {
        case .veryHigh: return .furgSuccess
        case .high: return .furgMint
        case .medium: return .yellow
        case .low: return .orange
        case .veryLow: return .furgDanger
        }
    }

    var shouldAutoApply: Bool {
        switch self {
        case .veryHigh, .high: return true
        default: return false
        }
    }

    var needsNotification: Bool {
        switch self {
        case .veryLow, .low: return true
        default: return false
        }
    }
}

struct MerchantLearning: Codable, Identifiable {
    let id: UUID
    let merchantName: String
    let normalizedName: String
    var categoryMappings: [String: Int] // category -> count
    var lastCategory: String
    var lastUpdated: Date
    var userOverrideCount: Int

    var primaryCategory: String {
        categoryMappings.max(by: { $0.value < $1.value })?.key ?? lastCategory
    }

    var confidence: Double {
        guard let maxCount = categoryMappings.values.max() else { return 0.5 }
        let totalCount = categoryMappings.values.reduce(0, +)
        return Double(maxCount) / Double(totalCount)
    }
}

struct TransactionClarification: Identifiable, Codable {
    let id: UUID
    let transactionId: String
    let merchantName: String
    let amount: Double
    let date: Date
    var suggestedCategories: [CategorySuggestion]
    var userResponse: String?
    var selectedCategory: String?
    var isResolved: Bool
    let createdAt: Date
}

struct CategoryPattern: Codable {
    let keywords: [String]
    let merchantPrefixes: [String]
    let amountRange: ClosedRange<Double>?
    let timePatterns: [Int]? // hours when typically occurs
}

// MARK: - Smart Categorization Manager

@MainActor
class SmartCategorizationManager: ObservableObject {
    static let shared = SmartCategorizationManager()

    @Published var pendingClarifications: [TransactionClarification] = []
    @Published var recentCategorizationResults: [CategorizationResult] = []
    @Published var isProcessing = false
    @Published var learningStats: LearningStats = LearningStats()

    private var merchantLearnings: [String: MerchantLearning] = [:]
    private var categoryPatterns: [String: CategoryPattern] = [:]
    private var cancellables = Set<AnyCancellable>()

    private let userDefaults = UserDefaults.standard
    private let merchantLearningsKey = "furg_merchant_learnings"
    private let clarificationsKey = "furg_pending_clarifications"

    struct LearningStats: Codable {
        var totalTransactionsProcessed: Int = 0
        var autoCategorizationRate: Double = 0.0
        var userCorrectionRate: Double = 0.0
        var merchantsLearned: Int = 0
        var accuracyScore: Double = 0.85
    }

    // Category definitions with intelligence patterns
    private let categoryIntelligence: [String: CategoryIntelligence] = [
        "Food & Dining": CategoryIntelligence(
            keywords: ["restaurant", "cafe", "coffee", "pizza", "burger", "sushi", "thai", "mexican", "chinese", "indian", "diner", "grill", "kitchen", "eatery", "bistro", "tavern", "pub", "bar", "doordash", "ubereats", "grubhub", "postmates", "seamless", "caviar", "starbucks", "dunkin", "mcdonald", "chipotle", "panera", "subway", "wendy", "taco bell", "chick-fil-a", "popeyes", "five guys", "shake shack", "sweetgreen"],
            merchantPrefixes: ["TST*", "SQ *", "DOORDASH", "UBER EATS", "GRUBHUB"],
            typicalAmountRange: 5...150,
            icon: "fork.knife",
            color: .orange
        ),
        "Groceries": CategoryIntelligence(
            keywords: ["grocery", "supermarket", "market", "foods", "fresh", "organic", "trader joe", "whole foods", "safeway", "kroger", "publix", "wegmans", "aldi", "costco", "sam's club", "walmart", "target", "heb", "meijer", "food lion", "stop & shop", "giant", "shoprite", "sprouts", "instacart"],
            merchantPrefixes: ["WHOLEFDS", "TRADER JOE", "INSTACART"],
            typicalAmountRange: 20...400,
            icon: "cart.fill",
            color: .green
        ),
        "Transportation": CategoryIntelligence(
            keywords: ["uber", "lyft", "taxi", "cab", "transit", "metro", "subway", "bus", "train", "parking", "garage", "toll", "gas", "fuel", "shell", "exxon", "chevron", "bp", "mobil", "speedway", "wawa", "sheetz", "quiktrip", "amtrak", "greyhound"],
            merchantPrefixes: ["UBER *TRIP", "LYFT *", "SHELL", "EXXON", "CHEVRON"],
            typicalAmountRange: 3...200,
            icon: "car.fill",
            color: .blue
        ),
        "Shopping": CategoryIntelligence(
            keywords: ["amazon", "target", "walmart", "best buy", "apple", "nike", "adidas", "zara", "h&m", "uniqlo", "nordstrom", "macy's", "bloomingdale", "sephora", "ulta", "home depot", "lowe's", "ikea", "wayfair", "etsy", "ebay", "wish", "shein", "fashion", "clothing", "apparel", "electronics", "furniture"],
            merchantPrefixes: ["AMZN", "AMAZON", "TARGET", "WALMART", "BESTBUY"],
            typicalAmountRange: 10...1000,
            icon: "bag.fill",
            color: .pink
        ),
        "Entertainment": CategoryIntelligence(
            keywords: ["netflix", "spotify", "hulu", "disney", "hbo", "amazon prime", "apple tv", "youtube", "movie", "theater", "cinema", "concert", "ticket", "ticketmaster", "stubhub", "seatgeek", "game", "steam", "playstation", "xbox", "nintendo", "twitch", "audible", "kindle"],
            merchantPrefixes: ["NETFLIX", "SPOTIFY", "HULU", "DISNEY+", "HBO"],
            typicalAmountRange: 5...200,
            icon: "film.fill",
            color: .purple
        ),
        "Utilities": CategoryIntelligence(
            keywords: ["electric", "power", "water", "gas", "utility", "internet", "cable", "phone", "mobile", "wireless", "verizon", "at&t", "t-mobile", "sprint", "comcast", "xfinity", "spectrum", "cox", "fios", "pge", "conedison", "duke energy"],
            merchantPrefixes: ["VERIZON", "ATT", "TMOBILE", "COMCAST", "XFINITY"],
            typicalAmountRange: 30...500,
            icon: "bolt.fill",
            color: .yellow
        ),
        "Health & Medical": CategoryIntelligence(
            keywords: ["pharmacy", "cvs", "walgreens", "rite aid", "doctor", "hospital", "clinic", "medical", "dental", "dentist", "vision", "optometrist", "health", "wellness", "fitness", "gym", "yoga", "pilates", "therapy", "urgent care", "labcorp", "quest diagnostics"],
            merchantPrefixes: ["CVS", "WALGREENS", "RITEAID"],
            typicalAmountRange: 10...500,
            icon: "heart.fill",
            color: .red
        ),
        "Subscriptions": CategoryIntelligence(
            keywords: ["subscription", "membership", "monthly", "annual", "premium", "pro", "plus", "cloud", "storage", "icloud", "dropbox", "google one", "microsoft 365", "adobe", "canva", "notion", "slack", "zoom", "patreon", "substack"],
            merchantPrefixes: ["APPLE.COM/BILL", "GOOGLE *", "MICROSOFT*"],
            typicalAmountRange: 5...100,
            icon: "repeat.circle.fill",
            color: .indigo
        ),
        "Travel": CategoryIntelligence(
            keywords: ["airline", "flight", "hotel", "airbnb", "vrbo", "booking", "expedia", "kayak", "delta", "united", "american airlines", "southwest", "jetblue", "marriott", "hilton", "hyatt", "ihg", "hertz", "enterprise", "avis", "turo"],
            merchantPrefixes: ["DELTA", "UNITED", "SOUTHWEST", "AIRBNB", "MARRIOTT"],
            typicalAmountRange: 50...2000,
            icon: "airplane",
            color: .cyan
        ),
        "Education": CategoryIntelligence(
            keywords: ["school", "university", "college", "tuition", "course", "class", "udemy", "coursera", "skillshare", "masterclass", "linkedin learning", "books", "textbook", "chegg", "quizlet"],
            merchantPrefixes: ["UDEMY", "COURSERA", "SKILLSHARE"],
            typicalAmountRange: 10...5000,
            icon: "book.fill",
            color: .brown
        ),
        "Personal Care": CategoryIntelligence(
            keywords: ["salon", "spa", "haircut", "barber", "nail", "massage", "beauty", "skincare", "cosmetics", "grooming", "wax", "facial"],
            merchantPrefixes: ["SUPERCUTS", "GREATCLIPS"],
            typicalAmountRange: 15...300,
            icon: "sparkles",
            color: .mint
        ),
        "Pets": CategoryIntelligence(
            keywords: ["pet", "petco", "petsmart", "chewy", "vet", "veterinary", "animal", "dog", "cat", "grooming", "boarding", "kennel"],
            merchantPrefixes: ["PETCO", "PETSMART", "CHEWY"],
            typicalAmountRange: 20...500,
            icon: "pawprint.fill",
            color: .orange
        ),
        "Insurance": CategoryIntelligence(
            keywords: ["insurance", "geico", "progressive", "state farm", "allstate", "liberty mutual", "nationwide", "farmers", "usaa", "premium", "policy"],
            merchantPrefixes: ["GEICO", "PROGRESSIVE", "STATEFARM"],
            typicalAmountRange: 50...500,
            icon: "shield.fill",
            color: .gray
        ),
        "Fees & Charges": CategoryIntelligence(
            keywords: ["fee", "charge", "atm", "overdraft", "interest", "late", "penalty", "service charge", "maintenance"],
            merchantPrefixes: ["ATM", "FEE"],
            typicalAmountRange: 1...100,
            icon: "exclamationmark.triangle.fill",
            color: .red
        ),
        "Income": CategoryIntelligence(
            keywords: ["payroll", "direct deposit", "salary", "wage", "payment received", "transfer from", "refund", "cashback", "dividend", "interest earned"],
            merchantPrefixes: ["PAYROLL", "DIRECT DEP", "ACH CREDIT"],
            typicalAmountRange: 100...10000,
            icon: "arrow.down.circle.fill",
            color: .furgSuccess
        )
    ]

    struct CategoryIntelligence {
        let keywords: [String]
        let merchantPrefixes: [String]
        let typicalAmountRange: ClosedRange<Double>
        let icon: String
        let color: Color
    }

    init() {
        loadMerchantLearnings()
        loadPendingClarifications()
    }

    // MARK: - Core Categorization

    func categorizeTransaction(
        merchantName: String,
        amount: Double,
        date: Date,
        existingCategory: String? = nil,
        transactionId: String
    ) -> CategorizationResult {
        isProcessing = true
        defer { isProcessing = false }

        let normalizedMerchant = normalizeMerchantName(merchantName)
        var suggestions: [CategorySuggestion] = []
        var primaryCategory = "Uncategorized"
        var confidence = 0.0
        var reasoning = ""

        // 1. Check learned merchant patterns first (highest confidence)
        if let learning = merchantLearnings[normalizedMerchant] {
            primaryCategory = learning.primaryCategory
            confidence = min(0.95, learning.confidence + 0.1 * Double(learning.userOverrideCount))
            reasoning = "Based on your previous categorization of \(learning.categoryMappings.values.reduce(0, +)) similar transactions"

            // Add alternatives from learning
            for (category, count) in learning.categoryMappings.sorted(by: { $0.value > $1.value }).prefix(3) {
                if category != primaryCategory {
                    suggestions.append(CategorySuggestion(
                        category: category,
                        confidence: Double(count) / Double(learning.categoryMappings.values.reduce(0, +)),
                        reason: "Previously used \(count) times"
                    ))
                }
            }
        }

        // 2. Pattern matching against intelligence database
        var patternMatches: [(String, Double, String)] = []

        for (category, intel) in categoryIntelligence {
            var matchScore = 0.0
            var matchReasons: [String] = []

            // Keyword matching
            let merchantLower = merchantName.lowercased()
            for keyword in intel.keywords {
                if merchantLower.contains(keyword.lowercased()) {
                    matchScore += 0.3
                    matchReasons.append("Contains '\(keyword)'")
                    break
                }
            }

            // Prefix matching
            for prefix in intel.merchantPrefixes {
                if merchantName.uppercased().hasPrefix(prefix) {
                    matchScore += 0.25
                    matchReasons.append("Matches merchant pattern")
                    break
                }
            }

            // Amount range matching
            if intel.typicalAmountRange.contains(abs(amount)) {
                matchScore += 0.15
                matchReasons.append("Amount fits typical range")
            }

            if matchScore > 0 {
                patternMatches.append((category, matchScore, matchReasons.joined(separator: ", ")))
            }
        }

        // Sort by score and use best match if we don't have learned data
        patternMatches.sort { $0.1 > $1.1 }

        if confidence == 0, let bestMatch = patternMatches.first {
            primaryCategory = bestMatch.0
            confidence = min(0.85, bestMatch.1 + 0.2)
            reasoning = bestMatch.2
        }

        // Add pattern-based alternatives
        for match in patternMatches.prefix(4) where match.0 != primaryCategory {
            suggestions.append(CategorySuggestion(
                category: match.0,
                confidence: match.1,
                reason: match.2
            ))
        }

        // 3. If still no match, use amount-based heuristics
        if confidence == 0 {
            let amountBasedCategory = guessFromAmount(amount)
            primaryCategory = amountBasedCategory.0
            confidence = amountBasedCategory.1
            reasoning = "Based on transaction amount pattern"
        }

        let result = CategorizationResult(
            id: UUID(),
            transactionId: transactionId,
            suggestedCategory: primaryCategory,
            confidence: confidence,
            alternativeCategories: suggestions,
            reasoning: reasoning,
            needsUserInput: confidence < 0.5,
            merchantPatterns: extractPatterns(from: merchantName),
            timestamp: Date()
        )

        recentCategorizationResults.append(result)
        learningStats.totalTransactionsProcessed += 1

        // Create clarification if needed
        if result.needsUserInput {
            createClarificationRequest(
                transactionId: transactionId,
                merchantName: merchantName,
                amount: amount,
                date: date,
                suggestions: [CategorySuggestion(category: primaryCategory, confidence: confidence, reason: reasoning)] + suggestions
            )
        }

        return result
    }

    // MARK: - Learning

    func learnFromUserCorrection(
        merchantName: String,
        correctedCategory: String,
        originalCategory: String?
    ) {
        let normalizedMerchant = normalizeMerchantName(merchantName)

        if var learning = merchantLearnings[normalizedMerchant] {
            // Update existing learning
            learning.categoryMappings[correctedCategory, default: 0] += 1
            learning.lastCategory = correctedCategory
            learning.lastUpdated = Date()
            learning.userOverrideCount += (originalCategory != nil && originalCategory != correctedCategory) ? 1 : 0
            merchantLearnings[normalizedMerchant] = learning
        } else {
            // Create new learning
            let learning = MerchantLearning(
                id: UUID(),
                merchantName: merchantName,
                normalizedName: normalizedMerchant,
                categoryMappings: [correctedCategory: 1],
                lastCategory: correctedCategory,
                lastUpdated: Date(),
                userOverrideCount: 0
            )
            merchantLearnings[normalizedMerchant] = learning
        }

        learningStats.merchantsLearned = merchantLearnings.count
        saveMerchantLearnings()
    }

    func bulkRecategorize(transactions: [(id: String, merchant: String, currentCategory: String)], toCategory: String) {
        for transaction in transactions {
            learnFromUserCorrection(
                merchantName: transaction.merchant,
                correctedCategory: toCategory,
                originalCategory: transaction.currentCategory
            )
        }
    }

    // MARK: - Clarifications

    private func createClarificationRequest(
        transactionId: String,
        merchantName: String,
        amount: Double,
        date: Date,
        suggestions: [CategorySuggestion]
    ) {
        let clarification = TransactionClarification(
            id: UUID(),
            transactionId: transactionId,
            merchantName: merchantName,
            amount: amount,
            date: date,
            suggestedCategories: suggestions,
            userResponse: nil,
            selectedCategory: nil,
            isResolved: false,
            createdAt: Date()
        )

        pendingClarifications.append(clarification)
        savePendingClarifications()

        // Trigger notification
        sendClarificationNotification(clarification)
    }

    func resolveClarification(id: UUID, selectedCategory: String, userNote: String? = nil) {
        guard let index = pendingClarifications.firstIndex(where: { $0.id == id }) else { return }

        var clarification = pendingClarifications[index]
        clarification.selectedCategory = selectedCategory
        clarification.userResponse = userNote
        clarification.isResolved = true

        // Learn from this
        learnFromUserCorrection(
            merchantName: clarification.merchantName,
            correctedCategory: selectedCategory,
            originalCategory: clarification.suggestedCategories.first?.category
        )

        pendingClarifications.remove(at: index)
        savePendingClarifications()
    }

    private func sendClarificationNotification(_ clarification: TransactionClarification) {
        NotificationManager.shared.scheduleTransactionClarificationNotification(
            merchantName: clarification.merchantName,
            amount: clarification.amount,
            suggestions: clarification.suggestedCategories.prefix(3).map { $0.category }
        )
    }

    // MARK: - Smart Suggestions

    func getSimilarMerchants(to merchantName: String, limit: Int = 5) -> [MerchantLearning] {
        let normalized = normalizeMerchantName(merchantName)

        return merchantLearnings.values
            .filter { $0.normalizedName.contains(normalized.prefix(4)) || normalized.contains($0.normalizedName.prefix(4)) }
            .sorted { $0.categoryMappings.values.reduce(0, +) > $1.categoryMappings.values.reduce(0, +) }
            .prefix(limit)
            .map { $0 }
    }

    func getTopCategoriesForTimeOfDay(_ hour: Int) -> [String] {
        // Heuristic: certain categories are more common at certain times
        switch hour {
        case 6..<11: return ["Food & Dining", "Transportation", "Groceries"] // Morning
        case 11..<14: return ["Food & Dining", "Shopping"] // Lunch
        case 14..<18: return ["Shopping", "Personal Care", "Entertainment"] // Afternoon
        case 18..<22: return ["Food & Dining", "Entertainment", "Groceries"] // Evening
        default: return ["Entertainment", "Food & Dining", "Transportation"] // Night
        }
    }

    // MARK: - Helpers

    private func normalizeMerchantName(_ name: String) -> String {
        var normalized = name.lowercased()

        // Remove common prefixes
        let prefixes = ["sq *", "tst*", "pp*", "paypal *", "google *", "apple.com/bill", "amzn mktp", "amazon.com*"]
        for prefix in prefixes {
            if normalized.hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count))
            }
        }

        // Remove trailing numbers and special chars
        normalized = normalized.replacingOccurrences(of: #"[0-9#*]+"#, with: "", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)

        return normalized
    }

    private func extractPatterns(from merchantName: String) -> [String] {
        var patterns: [String] = []

        // Extract prefix pattern
        if merchantName.count > 3 {
            patterns.append(String(merchantName.prefix(4)).uppercased())
        }

        // Extract word patterns
        let words = merchantName.components(separatedBy: .whitespaces)
        for word in words where word.count > 3 {
            patterns.append(word.lowercased())
        }

        return patterns
    }

    private func guessFromAmount(_ amount: Double) -> (String, Double) {
        let absAmount = abs(amount)

        // Income detection
        if amount > 0 && absAmount > 500 {
            return ("Income", 0.6)
        }

        // Common amount ranges
        switch absAmount {
        case 0..<10: return ("Food & Dining", 0.3) // Coffee, snacks
        case 10..<30: return ("Food & Dining", 0.35) // Meals
        case 30..<100: return ("Shopping", 0.25)
        case 100..<300: return ("Shopping", 0.2)
        default: return ("Uncategorized", 0.1)
        }
    }

    // MARK: - Persistence

    private func saveMerchantLearnings() {
        if let data = try? JSONEncoder().encode(Array(merchantLearnings.values)) {
            userDefaults.set(data, forKey: merchantLearningsKey)
        }
    }

    private func loadMerchantLearnings() {
        guard let data = userDefaults.data(forKey: merchantLearningsKey),
              let learnings = try? JSONDecoder().decode([MerchantLearning].self, from: data) else {
            return
        }

        merchantLearnings = Dictionary(uniqueKeysWithValues: learnings.map { ($0.normalizedName, $0) })
        learningStats.merchantsLearned = merchantLearnings.count
    }

    private func savePendingClarifications() {
        if let data = try? JSONEncoder().encode(pendingClarifications) {
            userDefaults.set(data, forKey: clarificationsKey)
        }
    }

    private func loadPendingClarifications() {
        guard let data = userDefaults.data(forKey: clarificationsKey),
              let clarifications = try? JSONDecoder().decode([TransactionClarification].self, from: data) else {
            return
        }

        pendingClarifications = clarifications
    }

    // MARK: - Analytics

    func getCategorizationAccuracy() -> Double {
        guard learningStats.totalTransactionsProcessed > 0 else { return 0.85 }

        let correctionRate = Double(merchantLearnings.values.filter { $0.userOverrideCount > 0 }.count) /
                            Double(max(1, merchantLearnings.count))

        return max(0, 1.0 - correctionRate)
    }

    func getMostConfidentCategories() -> [(String, Double)] {
        var categoryConfidence: [String: [Double]] = [:]

        for learning in merchantLearnings.values {
            let category = learning.primaryCategory
            categoryConfidence[category, default: []].append(learning.confidence)
        }

        return categoryConfidence.map { ($0.key, $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.1 > $1.1 }
    }
}
