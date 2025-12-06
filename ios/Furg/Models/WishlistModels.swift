//
//  WishlistModels.swift
//  Furg
//
//  Models for purchase planning, wishlist, and financing options
//

import Foundation

// MARK: - Wishlist Item

struct WishlistItem: Identifiable, Codable {
    let id: String
    var name: String
    var price: Double
    var priority: Priority
    var category: ItemCategory
    var url: String?
    var notes: String?
    var dateAdded: Date
    var targetDate: Date?
    var isPurchased: Bool
    var purchasedDate: Date?

    init(
        id: String = UUID().uuidString,
        name: String,
        price: Double,
        priority: Priority = .medium,
        category: ItemCategory = .other,
        url: String? = nil,
        notes: String? = nil,
        dateAdded: Date = Date(),
        targetDate: Date? = nil,
        isPurchased: Bool = false,
        purchasedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.priority = priority
        self.category = category
        self.url = url
        self.notes = notes
        self.dateAdded = dateAdded
        self.targetDate = targetDate
        self.isPurchased = isPurchased
        self.purchasedDate = purchasedDate
    }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

// MARK: - Priority

enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent

    var label: String {
        rawValue.capitalized
    }

    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

// MARK: - Item Category

enum ItemCategory: String, Codable, CaseIterable {
    case electronics
    case clothing
    case home
    case entertainment
    case travel
    case health
    case education
    case automotive
    case gifts
    case other

    var label: String {
        switch self {
        case .electronics: return "Electronics"
        case .clothing: return "Clothing"
        case .home: return "Home & Garden"
        case .entertainment: return "Entertainment"
        case .travel: return "Travel"
        case .health: return "Health & Fitness"
        case .education: return "Education"
        case .automotive: return "Automotive"
        case .gifts: return "Gifts"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .electronics: return "iphone"
        case .clothing: return "tshirt"
        case .home: return "house"
        case .entertainment: return "gamecontroller"
        case .travel: return "airplane"
        case .health: return "heart"
        case .education: return "graduationcap"
        case .automotive: return "car"
        case .gifts: return "gift"
        case .other: return "shippingbox"
        }
    }
}

// MARK: - Financing Option

struct FinancingOption: Identifiable, Codable {
    let id: String
    let name: String
    let type: FinancingType
    let apr: Double
    let termMonths: Int
    let minPurchaseAmount: Double?
    let maxPurchaseAmount: Double?
    let promotionalPeriod: Int?
    let promotionalApr: Double?
    let fees: Double?

    init(
        id: String = UUID().uuidString,
        name: String,
        type: FinancingType,
        apr: Double,
        termMonths: Int,
        minPurchaseAmount: Double? = nil,
        maxPurchaseAmount: Double? = nil,
        promotionalPeriod: Int? = nil,
        promotionalApr: Double? = nil,
        fees: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.apr = apr
        self.termMonths = termMonths
        self.minPurchaseAmount = minPurchaseAmount
        self.maxPurchaseAmount = maxPurchaseAmount
        self.promotionalPeriod = promotionalPeriod
        self.promotionalApr = promotionalApr
        self.fees = fees
    }

    func isApplicable(forAmount amount: Double) -> Bool {
        if let min = minPurchaseAmount, amount < min { return false }
        if let max = maxPurchaseAmount, amount > max { return false }
        return true
    }
}

enum FinancingType: String, Codable, CaseIterable {
    case creditCard = "credit_card"
    case bnpl = "bnpl"
    case personalLoan = "personal_loan"
    case storeCredit = "store_credit"
    case layaway = "layaway"

    var label: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .bnpl: return "Buy Now Pay Later"
        case .personalLoan: return "Personal Loan"
        case .storeCredit: return "Store Credit"
        case .layaway: return "Layaway"
        }
    }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard"
        case .bnpl: return "cart"
        case .personalLoan: return "banknote"
        case .storeCredit: return "storefront"
        case .layaway: return "clock"
        }
    }
}

// MARK: - Financing Calculation

struct FinancingCalculation {
    let monthlyPayment: Double
    let totalPayment: Double
    let totalInterest: Double
    let payoffDate: Date

    var formattedMonthlyPayment: String {
        String(format: "$%.2f", monthlyPayment)
    }

    var formattedTotalPayment: String {
        String(format: "$%.2f", totalPayment)
    }

    var formattedTotalInterest: String {
        String(format: "$%.2f", totalInterest)
    }
}

// MARK: - Purchase Plan

struct PurchasePlan: Identifiable {
    let id: String
    let item: WishlistItem
    let estimatedPurchaseDate: Date
    let monthsToSave: Int
    let monthlySavingsRequired: Double
    let financingOption: FinancingOption?
    let financingCalculation: FinancingCalculation?

    var formattedMonthlySavings: String {
        String(format: "$%.2f", monthlySavingsRequired)
    }
}

// MARK: - Budget Settings (for purchase planning)

struct PurchaseBudget: Codable {
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var savingsGoalPercent: Double
    var currentSavings: Double

    init(
        monthlyIncome: Double = 0,
        monthlyExpenses: Double = 0,
        savingsGoalPercent: Double = 20,
        currentSavings: Double = 0
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyExpenses = monthlyExpenses
        self.savingsGoalPercent = savingsGoalPercent
        self.currentSavings = currentSavings
    }

    var disposableIncome: Double {
        max(0, monthlyIncome - monthlyExpenses)
    }

    var monthlySavings: Double {
        disposableIncome * (savingsGoalPercent / 100)
    }
}

// MARK: - Default Financing Options

extension FinancingOption {
    static let defaults: [FinancingOption] = [
        FinancingOption(
            id: "affirm-standard",
            name: "Affirm (Standard)",
            type: .bnpl,
            apr: 15,
            termMonths: 12,
            minPurchaseAmount: 50
        ),
        FinancingOption(
            id: "affirm-0-apr",
            name: "Affirm (0% APR Promo)",
            type: .bnpl,
            apr: 0,
            termMonths: 6,
            minPurchaseAmount: 50,
            maxPurchaseAmount: 1000
        ),
        FinancingOption(
            id: "klarna-4",
            name: "Klarna (Pay in 4)",
            type: .bnpl,
            apr: 0,
            termMonths: 2,
            minPurchaseAmount: 35,
            maxPurchaseAmount: 1500
        ),
        FinancingOption(
            id: "credit-card-standard",
            name: "Credit Card (Average)",
            type: .creditCard,
            apr: 24.99,
            termMonths: 12
        ),
        FinancingOption(
            id: "credit-card-promo",
            name: "Credit Card (0% Intro APR)",
            type: .creditCard,
            apr: 24.99,
            termMonths: 18,
            promotionalPeriod: 12,
            promotionalApr: 0
        ),
        FinancingOption(
            id: "personal-loan",
            name: "Personal Loan",
            type: .personalLoan,
            apr: 11.5,
            termMonths: 36,
            minPurchaseAmount: 1000,
            fees: 50
        ),
        FinancingOption(
            id: "store-credit",
            name: "Store Credit (Typical)",
            type: .storeCredit,
            apr: 29.99,
            termMonths: 24,
            minPurchaseAmount: 299
        ),
        FinancingOption(
            id: "layaway",
            name: "Layaway Plan",
            type: .layaway,
            apr: 0,
            termMonths: 3,
            minPurchaseAmount: 50,
            fees: 5
        )
    ]
}
