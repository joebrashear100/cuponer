//
//  RecurringTransactionManager.swift
//  Furg
//
//  Quick-add recurring transaction templates for common purchases
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct TransactionTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var merchant: String
    var category: String
    var defaultAmount: Double?
    var icon: String
    var color: String
    var usageCount: Int
    var lastUsed: Date?
    var isSystemTemplate: Bool
    var tags: [String]
    var notes: String?

    var displayAmount: String {
        if let amount = defaultAmount {
            return String(format: "$%.2f", amount)
        }
        return "Variable"
    }
}

struct QuickTransaction: Identifiable, Codable {
    let id: UUID
    let templateId: UUID
    let amount: Double
    let date: Date
    let notes: String?
    let location: String?
}

struct TemplateCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let templates: [TransactionTemplate]
}

// MARK: - Recurring Transaction Manager

class RecurringTransactionManager: ObservableObject {
    static let shared = RecurringTransactionManager()

    @Published var templates: [TransactionTemplate] = []
    @Published var recentQuickTransactions: [QuickTransaction] = []
    @Published var favoriteTemplates: [UUID] = []

    private let userDefaults = UserDefaults.standard
    private let templatesKey = "furg_transaction_templates"
    private let quickTransactionsKey = "furg_quick_transactions"
    private let favoritesKey = "furg_favorite_templates"

    // MARK: - Computed Properties

    var frequentlyUsed: [TransactionTemplate] {
        templates
            .filter { $0.usageCount > 0 }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(6)
            .map { $0 }
    }

    var recentlyUsed: [TransactionTemplate] {
        templates
            .filter { $0.lastUsed != nil }
            .sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            .prefix(6)
            .map { $0 }
    }

    var favorites: [TransactionTemplate] {
        templates.filter { favoriteTemplates.contains($0.id) }
    }

    var templatesByCategory: [TemplateCategory] {
        let grouped = Dictionary(grouping: templates) { $0.category }
        return grouped.map { category, templates in
            TemplateCategory(
                name: category,
                icon: getCategoryIcon(category),
                templates: templates.sorted { $0.usageCount > $1.usageCount }
            )
        }.sorted { $0.templates.reduce(0) { $0 + $1.usageCount } > $1.templates.reduce(0) { $0 + $1.usageCount } }
    }

    init() {
        loadTemplates()
        loadQuickTransactions()
        loadFavorites()
    }

    // MARK: - Template Management

    func addTemplate(_ template: TransactionTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: TransactionTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: TransactionTemplate) {
        templates.removeAll { $0.id == template.id }
        favoriteTemplates.removeAll { $0 == template.id }
        saveTemplates()
        saveFavorites()
    }

    func toggleFavorite(_ templateId: UUID) {
        if favoriteTemplates.contains(templateId) {
            favoriteTemplates.removeAll { $0 == templateId }
        } else {
            favoriteTemplates.append(templateId)
        }
        saveFavorites()
    }

    // MARK: - Quick Add

    func quickAdd(templateId: UUID, amount: Double? = nil, notes: String? = nil, location: String? = nil) -> QuickTransaction? {
        guard let index = templates.firstIndex(where: { $0.id == templateId }) else { return nil }

        let template = templates[index]
        let finalAmount = amount ?? template.defaultAmount ?? 0

        // Update template usage
        templates[index].usageCount += 1
        templates[index].lastUsed = Date()
        saveTemplates()

        // Create quick transaction
        let transaction = QuickTransaction(
            id: UUID(),
            templateId: templateId,
            amount: finalAmount,
            date: Date(),
            notes: notes,
            location: location
        )

        recentQuickTransactions.insert(transaction, at: 0)
        if recentQuickTransactions.count > 50 {
            recentQuickTransactions = Array(recentQuickTransactions.prefix(50))
        }
        saveQuickTransactions()

        // Process with real-time transaction manager
        let realTimeTransaction = RealTimeTransaction(
            id: UUID(),
            externalId: "QT_\(transaction.id.uuidString.prefix(8))",
            source: .manual,
            merchantName: template.merchant,
            amount: -finalAmount, // Expense
            date: Date(),
            accountId: "manual",
            accountName: "Quick Add",
            cardLast4: nil,
            category: template.category,
            categorizationConfidence: 1.0,
            isProcessed: true,
            needsClarification: false
        )

        RealTimeTransactionManager.shared.processNewTransaction(realTimeTransaction)

        return transaction
    }

    func suggestTemplates(forMerchant merchant: String) -> [TransactionTemplate] {
        let normalizedMerchant = merchant.lowercased()
        return templates.filter {
            $0.merchant.lowercased().contains(normalizedMerchant) ||
            normalizedMerchant.contains($0.merchant.lowercased())
        }.sorted { $0.usageCount > $1.usageCount }
    }

    func suggestTemplates(forCategory category: String) -> [TransactionTemplate] {
        templates
            .filter { $0.category == category }
            .sorted { $0.usageCount > $1.usageCount }
    }

    // MARK: - Smart Suggestions

    func getContextualSuggestions() -> [TransactionTemplate] {
        let hour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())

        var suggestions: [TransactionTemplate] = []

        // Time-based suggestions
        switch hour {
        case 6..<10:
            // Morning - coffee, breakfast
            suggestions += templates.filter { $0.tags.contains("morning") || $0.tags.contains("coffee") || $0.tags.contains("breakfast") }
        case 11..<14:
            // Lunch time
            suggestions += templates.filter { $0.tags.contains("lunch") || $0.category == "Food & Dining" }
        case 17..<21:
            // Dinner time
            suggestions += templates.filter { $0.tags.contains("dinner") || $0.tags.contains("evening") }
        default:
            break
        }

        // Weekend suggestions
        if dayOfWeek == 1 || dayOfWeek == 7 {
            suggestions += templates.filter { $0.tags.contains("weekend") || $0.category == "Entertainment" }
        }

        // Add frequently used if we don't have enough
        if suggestions.count < 4 {
            suggestions += frequentlyUsed.filter { !suggestions.contains(where: { s in s.id == $0.id }) }
        }

        return Array(suggestions.prefix(6))
    }

    func learnFromTransaction(merchant: String, amount: Double, category: String) {
        // Check if we should auto-create a template
        let similarTransactions = recentQuickTransactions.filter {
            guard let template = templates.first(where: { t in t.id == $0.templateId }) else { return false }
            return template.merchant.lowercased() == merchant.lowercased()
        }

        // If we've seen this merchant 3+ times without a template, suggest creating one
        if similarTransactions.count >= 3 && !templates.contains(where: { $0.merchant.lowercased() == merchant.lowercased() }) {
            // Could trigger a notification to suggest creating a template
            print("Consider creating a template for \(merchant)")
        }
    }

    // MARK: - Helpers

    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "Food & Dining": return "fork.knife"
        case "Groceries": return "cart.fill"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "film.fill"
        case "Utilities": return "bolt.fill"
        case "Health & Medical": return "heart.fill"
        case "Subscriptions": return "repeat.circle.fill"
        case "Travel": return "airplane"
        case "Personal Care": return "sparkles"
        default: return "dollarsign.circle.fill"
        }
    }

    // MARK: - Persistence

    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            userDefaults.set(data, forKey: templatesKey)
        }
    }

    private func loadTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey),
              let loaded = try? JSONDecoder().decode([TransactionTemplate].self, from: data) else {
            addDefaultTemplates()
            return
        }
        templates = loaded
    }

    private func saveQuickTransactions() {
        if let data = try? JSONEncoder().encode(recentQuickTransactions) {
            userDefaults.set(data, forKey: quickTransactionsKey)
        }
    }

    private func loadQuickTransactions() {
        guard let data = userDefaults.data(forKey: quickTransactionsKey),
              let loaded = try? JSONDecoder().decode([QuickTransaction].self, from: data) else {
            return
        }
        recentQuickTransactions = loaded
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteTemplates) {
            userDefaults.set(data, forKey: favoritesKey)
        }
    }

    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: favoritesKey),
              let loaded = try? JSONDecoder().decode([UUID].self, from: data) else {
            return
        }
        favoriteTemplates = loaded
    }

    private func addDefaultTemplates() {
        templates = [
            // Coffee
            TransactionTemplate(id: UUID(), name: "Morning Coffee", merchant: "Starbucks", category: "Food & Dining", defaultAmount: 6.50, icon: "cup.and.saucer.fill", color: "brown", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["morning", "coffee", "daily"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Coffee Run", merchant: "Dunkin'", category: "Food & Dining", defaultAmount: 4.50, icon: "cup.and.saucer.fill", color: "orange", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["morning", "coffee"], notes: nil),

            // Food
            TransactionTemplate(id: UUID(), name: "Lunch", merchant: "Various", category: "Food & Dining", defaultAmount: 15.00, icon: "fork.knife", color: "orange", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["lunch", "daily"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Dinner Out", merchant: "Restaurant", category: "Food & Dining", defaultAmount: 45.00, icon: "fork.knife", color: "red", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["dinner", "evening"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Fast Food", merchant: "Fast Food", category: "Food & Dining", defaultAmount: 12.00, icon: "takeoutbag.and.cup.and.straw.fill", color: "yellow", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["lunch", "quick"], notes: nil),

            // Transportation
            TransactionTemplate(id: UUID(), name: "Uber/Lyft", merchant: "Rideshare", category: "Transportation", defaultAmount: nil, icon: "car.fill", color: "black", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["transport", "rideshare"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Gas", merchant: "Gas Station", category: "Transportation", defaultAmount: 45.00, icon: "fuelpump.fill", color: "green", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["transport", "car", "weekly"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Parking", merchant: "Parking", category: "Transportation", defaultAmount: nil, icon: "p.circle.fill", color: "blue", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["transport", "parking"], notes: nil),

            // Groceries
            TransactionTemplate(id: UUID(), name: "Weekly Groceries", merchant: "Grocery Store", category: "Groceries", defaultAmount: 120.00, icon: "cart.fill", color: "green", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["groceries", "weekly", "weekend"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Quick Grocery Run", merchant: "Grocery Store", category: "Groceries", defaultAmount: 35.00, icon: "basket.fill", color: "green", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["groceries", "quick"], notes: nil),

            // Shopping
            TransactionTemplate(id: UUID(), name: "Amazon", merchant: "Amazon", category: "Shopping", defaultAmount: nil, icon: "shippingbox.fill", color: "orange", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["online", "shopping"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Target Run", merchant: "Target", category: "Shopping", defaultAmount: nil, icon: "bag.fill", color: "red", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["shopping", "weekend"], notes: nil),

            // Entertainment
            TransactionTemplate(id: UUID(), name: "Movies", merchant: "Movie Theater", category: "Entertainment", defaultAmount: 18.00, icon: "film.fill", color: "purple", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["entertainment", "weekend", "evening"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Drinks", merchant: "Bar", category: "Entertainment", defaultAmount: 30.00, icon: "wineglass.fill", color: "purple", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["entertainment", "evening", "weekend"], notes: nil),

            // Health
            TransactionTemplate(id: UUID(), name: "Pharmacy", merchant: "CVS/Walgreens", category: "Health & Medical", defaultAmount: nil, icon: "cross.case.fill", color: "red", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["health", "pharmacy"], notes: nil),
            TransactionTemplate(id: UUID(), name: "Gym", merchant: "Gym", category: "Health & Medical", defaultAmount: 50.00, icon: "dumbbell.fill", color: "blue", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["health", "fitness", "monthly"], notes: nil),

            // Personal Care
            TransactionTemplate(id: UUID(), name: "Haircut", merchant: "Barber/Salon", category: "Personal Care", defaultAmount: 35.00, icon: "scissors", color: "mint", usageCount: 0, lastUsed: nil, isSystemTemplate: true, tags: ["personal", "monthly"], notes: nil)
        ]
        saveTemplates()
    }
}
