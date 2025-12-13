//
//  RealTimeTransactionManager.swift
//  Furg
//
//  Real-time transaction monitoring for FinanceKit (Apple Card) and Plaid
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Models

struct RealTimeTransaction: Identifiable, Codable {
    let id: UUID
    let externalId: String
    let source: TransactionSource
    let merchantName: String
    let amount: Double
    let date: Date
    let accountId: String
    let accountName: String
    let cardLast4: String?
    var category: String
    var categorizationConfidence: Double
    var isProcessed: Bool
    var needsClarification: Bool

    enum TransactionSource: String, Codable {
        case financeKit = "Apple Card"
        case plaid = "Plaid"
        case manual = "Manual"
    }
}

struct TransactionAlert: Identifiable {
    let id: UUID
    let transaction: RealTimeTransaction
    let alertType: AlertType
    let timestamp: Date

    enum AlertType {
        case newTransaction
        case largeTransaction
        case unusualMerchant
        case duplicateSuspected
        case categoryUncertain
    }
}

struct CardRoundUpSettings: Codable, Identifiable {
    var id: String { cardId }
    let cardId: String
    let cardName: String
    let cardLast4: String
    let source: RealTimeTransaction.TransactionSource
    var isEnabled: Bool
    var roundUpAmount: RoundUpLevel
    var multiplier: Double

    enum RoundUpLevel: String, Codable, CaseIterable {
        case nearest1 = "$1"
        case nearest2 = "$2"
        case nearest5 = "$5"

        var value: Double {
            switch self {
            case .nearest1: return 1.0
            case .nearest2: return 2.0
            case .nearest5: return 5.0
            }
        }
    }
}

// MARK: - Real-Time Transaction Manager

class RealTimeTransactionManager: ObservableObject {
    static let shared = RealTimeTransactionManager()

    @Published var recentTransactions: [RealTimeTransaction] = []
    @Published var pendingAlerts: [TransactionAlert] = []
    @Published var isMonitoring = false
    @Published var connectedCards: [CardRoundUpSettings] = []
    @Published var totalRoundUpsToday: Double = 0
    @Published var lastSyncTime: Date?

    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard

    private let recentTransactionsKey = "furg_recent_transactions"
    private let cardSettingsKey = "furg_card_roundup_settings"
    private let roundUpsTodayKey = "furg_roundups_today"

    // Thresholds
    let largeTransactionThreshold: Double = 500.0
    let duplicateTimeWindow: TimeInterval = 3600 // 1 hour

    init() {
        loadRecentTransactions()
        loadCardSettings()
        loadRoundUpsToday()
        setupNotificationCategories()
    }

    deinit {
        // CRITICAL: Clean up timer to prevent memory leaks
        pollingTimer?.invalidate()
        pollingTimer = nil
        cancellables.removeAll()
    }

    // MARK: - Monitoring Control

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Invalidate any existing timer first
        pollingTimer?.invalidate()

        // Poll for new transactions every 30 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkForNewTransactions()
        }

        // Initial check
        checkForNewTransactions()
    }

    func stopMonitoring() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isMonitoring = false
    }

    // MARK: - Transaction Processing

    private func checkForNewTransactions() {
        // Check FinanceKit transactions (Apple Card)
        checkFinanceKitTransactions()

        // Check Plaid transactions
        checkPlaidTransactions()

        lastSyncTime = Date()
    }

    private func checkFinanceKitTransactions() {
        // In a real implementation, this would use FinanceKit framework
        // For demo, we'll simulate occasional transactions

        #if DEBUG
        // Simulate a new transaction occasionally for testing
        if Int.random(in: 0..<10) == 0 {
            let demoTransaction = RealTimeTransaction(
                id: UUID(),
                externalId: "FK_\(UUID().uuidString.prefix(8))",
                source: .financeKit,
                merchantName: ["Starbucks", "Target", "Whole Foods", "Uber", "Amazon"].randomElement()!,
                amount: -Double.random(in: 5...150),
                date: Date(),
                accountId: "apple_card_001",
                accountName: "Apple Card",
                cardLast4: "4242",
                category: "Uncategorized",
                categorizationConfidence: 0,
                isProcessed: false,
                needsClarification: false
            )
            processNewTransaction(demoTransaction)
        }
        #endif
    }

    private func checkPlaidTransactions() {
        // In a real implementation, this would use Plaid webhooks or polling
        // The Plaid manager would notify us of new transactions

        #if DEBUG
        // Simulate occasional Plaid transactions for testing
        if Int.random(in: 0..<15) == 0 {
            let demoTransaction = RealTimeTransaction(
                id: UUID(),
                externalId: "PL_\(UUID().uuidString.prefix(8))",
                source: .plaid,
                merchantName: ["Chipotle", "Netflix", "Spotify", "Gas Station", "CVS Pharmacy"].randomElement()!,
                amount: -Double.random(in: 8...75),
                date: Date(),
                accountId: "plaid_checking_001",
                accountName: "Chase Checking",
                cardLast4: "1234",
                category: "Uncategorized",
                categorizationConfidence: 0,
                isProcessed: false,
                needsClarification: false
            )
            processNewTransaction(demoTransaction)
        }
        #endif
    }

    func processNewTransaction(_ transaction: RealTimeTransaction) {
        var processedTransaction = transaction

        // 1. Smart categorization
        // TODO: Fix MainActor isolation error for Smart categorization
        let categorizationResult = (suggestedCategory: "Unknown", confidence: 0.5, needsUserInput: false)

        processedTransaction.category = "Unknown"  // categorizationResult.suggestedCategory
        processedTransaction.categorizationConfidence = 0.5  // categorizationResult.confidence
        processedTransaction.needsClarification = false  // categorizationResult.needsUserInput
        processedTransaction.isProcessed = true

        // 2. Add to recent transactions
        recentTransactions.insert(processedTransaction, at: 0)
        if recentTransactions.count > 100 {
            recentTransactions = Array(recentTransactions.prefix(100))
        }

        // 3. Process round-ups if enabled for this card
        processRoundUp(for: processedTransaction)

        // 4. Check for alerts
        // checkAndCreateAlerts(for: processedTransaction, categorizationResult: categorizationResult)

        // 5. Send notification
        // sendTransactionNotification(processedTransaction, categorizationResult: categorizationResult)

        // 6. Save
        saveRecentTransactions()
    }

    // MARK: - Round-Ups

    private func processRoundUp(for transaction: RealTimeTransaction) {
        // Only process expenses (negative amounts)
        guard transaction.amount < 0 else { return }

        // Find card settings
        guard let cardSettings = connectedCards.first(where: {
            $0.cardId == transaction.accountId && $0.isEnabled
        }) else { return }

        let roundUpAmount = calculateRoundUp(
            amount: abs(transaction.amount),
            level: cardSettings.roundUpAmount,
            multiplier: cardSettings.multiplier
        )

        if roundUpAmount > 0 {
            totalRoundUpsToday += roundUpAmount
            saveRoundUpsToday()

            // Notify round-up manager
            NotificationCenter.default.post(
                name: NSNotification.Name("FurgRoundUpProcessed"),
                object: nil,
                userInfo: [
                    "amount": roundUpAmount,
                    "transactionId": transaction.externalId,
                    "cardId": transaction.accountId
                ]
            )
        }
    }

    private func calculateRoundUp(amount: Double, level: CardRoundUpSettings.RoundUpLevel, multiplier: Double) -> Double {
        let roundTo = level.value
        let rounded = ceil(amount / roundTo) * roundTo
        let roundUp = (rounded - amount) * multiplier
        return roundUp
    }

    // MARK: - Card Management

    func addCard(cardId: String, cardName: String, cardLast4: String, source: RealTimeTransaction.TransactionSource) {
        let settings = CardRoundUpSettings(
            cardId: cardId,
            cardName: cardName,
            cardLast4: cardLast4,
            source: source,
            isEnabled: false,
            roundUpAmount: .nearest1,
            multiplier: 1.0
        )

        if !connectedCards.contains(where: { $0.cardId == cardId }) {
            connectedCards.append(settings)
            saveCardSettings()
        }
    }

    func updateCardSettings(_ settings: CardRoundUpSettings) {
        if let index = connectedCards.firstIndex(where: { $0.cardId == settings.cardId }) {
            connectedCards[index] = settings
            saveCardSettings()
        }
    }

    func toggleRoundUp(for cardId: String, enabled: Bool) {
        if let index = connectedCards.firstIndex(where: { $0.cardId == cardId }) {
            connectedCards[index].isEnabled = enabled
            saveCardSettings()
        }
    }

    func setRoundUpLevel(for cardId: String, level: CardRoundUpSettings.RoundUpLevel) {
        if let index = connectedCards.firstIndex(where: { $0.cardId == cardId }) {
            connectedCards[index].roundUpAmount = level
            saveCardSettings()
        }
    }

    func setMultiplier(for cardId: String, multiplier: Double) {
        if let index = connectedCards.firstIndex(where: { $0.cardId == cardId }) {
            connectedCards[index].multiplier = max(1, min(10, multiplier))
            saveCardSettings()
        }
    }

    // MARK: - Alerts

    private func checkAndCreateAlerts(for transaction: RealTimeTransaction, categorizationResult: CategorizationResult) {
        var alertType: TransactionAlert.AlertType?

        // Large transaction
        if abs(transaction.amount) >= largeTransactionThreshold {
            alertType = .largeTransaction
        }
        // Category uncertain
        else if categorizationResult.needsUserInput {
            alertType = .categoryUncertain
        }
        // Check for duplicate
        else if isDuplicateSuspected(transaction) {
            alertType = .duplicateSuspected
        }
        // Unusual merchant (first time seeing this merchant)
        // TODO: Fix MainActor isolation error for getSimilarMerchants
        else if false {  // SmartCategorizationManager.shared.getSimilarMerchants(to: transaction.merchantName).isEmpty
            alertType = .unusualMerchant
        }
        // Standard new transaction
        else {
            alertType = .newTransaction
        }

        if let type = alertType {
            let alert = TransactionAlert(
                id: UUID(),
                transaction: transaction,
                alertType: type,
                timestamp: Date()
            )
            pendingAlerts.insert(alert, at: 0)

            // Keep only recent alerts
            if pendingAlerts.count > 50 {
                pendingAlerts = Array(pendingAlerts.prefix(50))
            }
        }
    }

    private func isDuplicateSuspected(_ transaction: RealTimeTransaction) -> Bool {
        let recentSimilar = recentTransactions.filter {
            $0.id != transaction.id &&
            $0.merchantName == transaction.merchantName &&
            abs($0.amount - transaction.amount) < 0.01 &&
            abs($0.date.timeIntervalSince(transaction.date)) < duplicateTimeWindow
        }
        return !recentSimilar.isEmpty
    }

    // MARK: - Notifications

    private func setupNotificationCategories() {
        let categoryAction = UNNotificationAction(
            identifier: "CATEGORIZE_ACTION",
            title: "Categorize",
            options: .foreground
        )

        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Details",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )

        let transactionCategory = UNNotificationCategory(
            identifier: "TRANSACTION_ALERT",
            actions: [categoryAction, viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let clarificationCategory = UNNotificationCategory(
            identifier: "CLARIFICATION_REQUEST",
            actions: [categoryAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([transactionCategory, clarificationCategory])
    }

    private func sendTransactionNotification(_ transaction: RealTimeTransaction, categorizationResult: CategorizationResult) {
        let content = UNMutableNotificationContent()

        let formattedAmount = String(format: "$%.2f", abs(transaction.amount))
        let isExpense = transaction.amount < 0

        if categorizationResult.needsUserInput {
            // Clarification needed
            content.title = "🤔 What did you buy?"
            content.body = "\(formattedAmount) at \(transaction.merchantName)\nTap to categorize this transaction"
            content.categoryIdentifier = "CLARIFICATION_REQUEST"
            content.sound = .default
        } else if abs(transaction.amount) >= largeTransactionThreshold {
            // Large transaction
            content.title = "💰 Large \(isExpense ? "Purchase" : "Deposit")"
            content.body = "\(formattedAmount) at \(transaction.merchantName)"
            content.categoryIdentifier = "TRANSACTION_ALERT"
            content.sound = UNNotificationSound.defaultCritical
        } else {
            // Standard transaction
            content.title = isExpense ? "💳 New Purchase" : "💵 Money Received"
            content.body = "\(formattedAmount) at \(transaction.merchantName) • \(categorizationResult.suggestedCategory)"
            content.categoryIdentifier = "TRANSACTION_ALERT"
            content.sound = .default
        }

        content.userInfo = [
            "transactionId": transaction.externalId,
            "category": categorizationResult.suggestedCategory,
            "confidence": categorizationResult.confidence
        ]

        // Add round-up info if applicable
        if let cardSettings = connectedCards.first(where: { $0.cardId == transaction.accountId && $0.isEnabled }),
           transaction.amount < 0 {
            let roundUp = calculateRoundUp(
                amount: abs(transaction.amount),
                level: cardSettings.roundUpAmount,
                multiplier: cardSettings.multiplier
            )
            if roundUp > 0 {
                content.subtitle = String(format: "+$%.2f round-up saved", roundUp)
            }
        }

        let request = UNNotificationRequest(
            identifier: "transaction_\(transaction.externalId)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence

    private func saveRecentTransactions() {
        if let data = try? JSONEncoder().encode(recentTransactions) {
            userDefaults.set(data, forKey: recentTransactionsKey)
        }
    }

    private func loadRecentTransactions() {
        guard let data = userDefaults.data(forKey: recentTransactionsKey),
              let transactions = try? JSONDecoder().decode([RealTimeTransaction].self, from: data) else {
            return
        }
        recentTransactions = transactions
    }

    private func saveCardSettings() {
        if let data = try? JSONEncoder().encode(connectedCards) {
            userDefaults.set(data, forKey: cardSettingsKey)
        }
    }

    private func loadCardSettings() {
        guard let data = userDefaults.data(forKey: cardSettingsKey),
              let settings = try? JSONDecoder().decode([CardRoundUpSettings].self, from: data) else {
            // Add demo cards
            addDemoCards()
            return
        }
        connectedCards = settings
    }

    private func addDemoCards() {
        connectedCards = [
            CardRoundUpSettings(
                cardId: "apple_card_001",
                cardName: "Apple Card",
                cardLast4: "4242",
                source: .financeKit,
                isEnabled: true,
                roundUpAmount: .nearest1,
                multiplier: 1.0
            ),
            CardRoundUpSettings(
                cardId: "plaid_checking_001",
                cardName: "Chase Sapphire",
                cardLast4: "1234",
                source: .plaid,
                isEnabled: false,
                roundUpAmount: .nearest1,
                multiplier: 1.0
            ),
            CardRoundUpSettings(
                cardId: "plaid_checking_002",
                cardName: "Bank of America",
                cardLast4: "5678",
                source: .plaid,
                isEnabled: false,
                roundUpAmount: .nearest2,
                multiplier: 2.0
            )
        ]
        saveCardSettings()
    }

    private func saveRoundUpsToday() {
        // Reset if new day
        let lastDate = userDefaults.object(forKey: "furg_roundups_date") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastDate) {
            totalRoundUpsToday = 0
        }

        userDefaults.set(totalRoundUpsToday, forKey: roundUpsTodayKey)
        userDefaults.set(Date(), forKey: "furg_roundups_date")
    }

    private func loadRoundUpsToday() {
        let lastDate = userDefaults.object(forKey: "furg_roundups_date") as? Date ?? Date.distantPast
        if Calendar.current.isDateInToday(lastDate) {
            totalRoundUpsToday = userDefaults.double(forKey: roundUpsTodayKey)
        } else {
            totalRoundUpsToday = 0
        }
    }

    // MARK: - Statistics

    func getTodaysTransactionCount() -> Int {
        recentTransactions.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    func getTodaysSpending() -> Double {
        recentTransactions
            .filter { Calendar.current.isDateInToday($0.date) && $0.amount < 0 }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func getTransactionsBySource() -> [RealTimeTransaction.TransactionSource: Int] {
        Dictionary(grouping: recentTransactions, by: { $0.source })
            .mapValues { $0.count }
    }
}

// MARK: - NotificationManager Extension

extension NotificationManager {
    func scheduleTransactionClarificationNotification(
        merchantName: String,
        amount: Double,
        suggestions: [String]
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🤔 Help categorize this"
        content.body = "What was your $\(String(format: "%.2f", abs(amount))) purchase at \(merchantName)?"
        content.subtitle = "Suggested: \(suggestions.joined(separator: ", "))"
        content.sound = .default
        content.categoryIdentifier = "CLARIFICATION_REQUEST"
        content.userInfo = [
            "merchantName": merchantName,
            "amount": amount,
            "suggestions": suggestions
        ]

        let request = UNNotificationRequest(
            identifier: "clarification_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
