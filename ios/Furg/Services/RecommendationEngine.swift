//
//  RecommendationEngine.swift
//  Furg
//
//  Comprehensive AI-powered recommendation engine for financial products and lifestyle optimizations
//

import Foundation
import SwiftUI
import Combine

// MARK: - Core Models

struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let category: RecommendationCategory
    let title: String
    let subtitle: String
    let description: String
    let potentialSavings: Double?
    let potentialEarnings: Double?
    let confidence: Double
    let urgency: RecommendationUrgency
    let actionItems: [ActionItem]
    let pros: [String]
    let cons: [String]
    let externalLink: String?
    let expiresAt: Date?
    let metadata: [String: Any]

    var icon: String {
        type.icon
    }

    var color: Color {
        category.color
    }
}

enum RecommendationType: String, CaseIterable {
    // Accounts
    case savingsAccount = "Savings Account"
    case checkingAccount = "Checking Account"
    case creditCard = "Credit Card"
    case brokerageAccount = "Brokerage Account"
    case cdAccount = "CD Account"
    case hsa = "HSA Account"
    case retirement401k = "401(k) Optimization"
    case iraAccount = "IRA Account"

    // Cards & Rewards
    case cardOptimization = "Card Optimization"
    case signupBonus = "Sign-up Bonus"
    case rewardsMaximization = "Rewards Maximization"
    case balanceTransfer = "Balance Transfer"

    // Insurance
    case autoInsurance = "Auto Insurance"
    case homeInsurance = "Home Insurance"
    case rentersInsurance = "Renters Insurance"
    case lifeInsurance = "Life Insurance"
    case healthInsurance = "Health Insurance"
    case petInsurance = "Pet Insurance"

    // Loans & Debt
    case studentLoanRefi = "Student Loan Refinance"
    case mortgageRefi = "Mortgage Refinance"
    case autoLoanRefi = "Auto Loan Refinance"
    case debtConsolidation = "Debt Consolidation"
    case personalLoan = "Personal Loan"

    // Subscriptions
    case subscriptionBundle = "Subscription Bundle"
    case subscriptionAlternative = "Subscription Alternative"
    case subscriptionCancel = "Cancel Subscription"

    // Bills & Services
    case billNegotiation = "Bill Negotiation"
    case phonePlan = "Phone Plan"
    case internetPlan = "Internet Plan"
    case utilitySwitch = "Utility Switch"

    // Investments
    case investmentOpportunity = "Investment Opportunity"
    case taxLossHarvest = "Tax-Loss Harvesting"
    case portfolioRebalance = "Portfolio Rebalance"
    case roboAdvisor = "Robo-Advisor"

    // Lifestyle
    case mealDelivery = "Meal Delivery"
    case groceryOptimization = "Grocery Optimization"
    case transportationSavings = "Transportation"
    case fitnessAlternative = "Fitness Alternative"
    case entertainmentBundle = "Entertainment Bundle"

    // Tax
    case taxDeduction = "Tax Deduction"
    case taxCredit = "Tax Credit"
    case estimatedTaxPayment = "Estimated Tax"

    var icon: String {
        switch self {
        case .savingsAccount: return "banknote"
        case .checkingAccount: return "building.columns"
        case .creditCard: return "creditcard.fill"
        case .brokerageAccount: return "chart.line.uptrend.xyaxis"
        case .cdAccount: return "clock.badge.checkmark"
        case .hsa: return "cross.case.fill"
        case .retirement401k: return "chart.pie.fill"
        case .iraAccount: return "building.columns.fill"
        case .cardOptimization: return "creditcard.and.123"
        case .signupBonus: return "gift.fill"
        case .rewardsMaximization: return "star.fill"
        case .balanceTransfer: return "arrow.left.arrow.right"
        case .autoInsurance: return "car.fill"
        case .homeInsurance: return "house.fill"
        case .rentersInsurance: return "building.2.fill"
        case .lifeInsurance: return "heart.fill"
        case .healthInsurance: return "cross.circle.fill"
        case .petInsurance: return "pawprint.fill"
        case .studentLoanRefi: return "graduationcap.fill"
        case .mortgageRefi: return "house.circle.fill"
        case .autoLoanRefi: return "car.circle.fill"
        case .debtConsolidation: return "arrow.triangle.merge"
        case .personalLoan: return "dollarsign.circle.fill"
        case .subscriptionBundle: return "square.stack.3d.up.fill"
        case .subscriptionAlternative: return "arrow.triangle.swap"
        case .subscriptionCancel: return "xmark.circle.fill"
        case .billNegotiation: return "phone.fill"
        case .phonePlan: return "iphone"
        case .internetPlan: return "wifi"
        case .utilitySwitch: return "bolt.fill"
        case .investmentOpportunity: return "chart.bar.fill"
        case .taxLossHarvest: return "leaf.fill"
        case .portfolioRebalance: return "scale.3d"
        case .roboAdvisor: return "cpu"
        case .mealDelivery: return "takeoutbag.and.cup.and.straw.fill"
        case .groceryOptimization: return "cart.fill"
        case .transportationSavings: return "figure.walk"
        case .fitnessAlternative: return "dumbbell.fill"
        case .entertainmentBundle: return "tv.fill"
        case .taxDeduction: return "doc.text.fill"
        case .taxCredit: return "checkmark.seal.fill"
        case .estimatedTaxPayment: return "calendar.badge.exclamationmark"
        }
    }
}

enum RecommendationCategory: String, CaseIterable {
    case accounts = "Accounts"
    case creditCards = "Credit Cards"
    case insurance = "Insurance"
    case loans = "Loans & Debt"
    case subscriptions = "Subscriptions"
    case bills = "Bills & Services"
    case investments = "Investments"
    case lifestyle = "Lifestyle"
    case taxes = "Taxes"

    var color: Color {
        switch self {
        case .accounts: return .blue
        case .creditCards: return .purple
        case .insurance: return .green
        case .loans: return .red
        case .subscriptions: return .orange
        case .bills: return .yellow
        case .investments: return .mint
        case .lifestyle: return .pink
        case .taxes: return .indigo
        }
    }

    var icon: String {
        switch self {
        case .accounts: return "building.columns.fill"
        case .creditCards: return "creditcard.fill"
        case .insurance: return "shield.fill"
        case .loans: return "dollarsign.arrow.circlepath"
        case .subscriptions: return "repeat.circle.fill"
        case .bills: return "doc.text.fill"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .lifestyle: return "heart.fill"
        case .taxes: return "percent"
        }
    }
}

enum RecommendationUrgency: String, Codable {
    case critical = "Act Now"
    case high = "Time Sensitive"
    case medium = "Worth Considering"
    case low = "Nice to Have"

    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct ActionItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let actionType: ActionType
    let link: String?

    enum ActionType {
        case apply
        case compare
        case learn
        case call
        case negotiate
        case cancel
        case switch_
    }
}

// MARK: - Financial Product Models

struct SavingsAccountOffer: Identifiable, Codable {
    let id: UUID
    let bankName: String
    let accountName: String
    let apy: Double
    let minimumBalance: Double
    let monthlyFee: Double
    let signupBonus: Double?
    let bonusRequirements: String?
    let fdic: Bool
    let features: [String]
    let link: String
}

struct CreditCardOffer: Identifiable, Codable {
    let id: UUID
    let issuer: String
    let cardName: String
    let annualFee: Double
    let signupBonus: String
    let signupBonusValue: Double
    let signupRequirement: String
    let rewardsStructure: [String: Double] // category -> multiplier
    let baseRewardsRate: Double
    let apr: String
    let introApr: String?
    let foreignTransactionFee: Double
    let creditScoreRequired: String
    let perks: [String]
    let bestFor: [String]
    let link: String
}

struct InsuranceQuote: Identifiable {
    let id = UUID()
    let provider: String
    let type: RecommendationType
    let monthlyPremium: Double
    let coverage: String
    let deductible: Double
    let features: [String]
    let rating: Double
    let link: String
}

struct LoanOffer: Identifiable {
    let id = UUID()
    let lender: String
    let type: RecommendationType
    let apr: Double
    let term: Int // months
    let monthlyPayment: Double
    let totalInterest: Double
    let features: [String]
    let requirements: [String]
    let link: String
}

// MARK: - User Profile for Recommendations

struct UserFinancialProfile {
    var monthlyIncome: Double
    var totalSavings: Double
    var checkingBalance: Double
    var creditScore: Int
    var monthlySpendingByCategory: [String: Double]
    var currentCreditCards: [String]
    var currentInsurance: [String: Double] // type -> monthly cost
    var currentSubscriptions: [String: Double]
    var debts: [(type: String, balance: Double, rate: Double)]
    var age: Int
    var hasHome: Bool
    var hasCar: Bool
    var hasPets: Bool
    var employmentType: String
    var state: String
}

// MARK: - Recommendation Engine

class RecommendationEngine: ObservableObject {
    static let shared = RecommendationEngine()

    @Published var recommendations: [Recommendation] = []
    @Published var featuredRecommendations: [Recommendation] = []
    @Published var totalPotentialSavings: Double = 0
    @Published var totalPotentialEarnings: Double = 0
    @Published var isAnalyzing = false
    @Published var lastAnalyzed: Date?

    @Published var savingsAccounts: [SavingsAccountOffer] = []
    @Published var creditCards: [CreditCardOffer] = []

    private var userProfile: UserFinancialProfile?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadProductData()
    }

    // MARK: - Analysis

    func analyzeAndGenerateRecommendations() {
        isAnalyzing = true
        recommendations.removeAll()

        // Build user profile from app data
        userProfile = buildUserProfile()

        guard let profile = userProfile else {
            isAnalyzing = false
            return
        }

        // Generate all recommendation types
        var allRecommendations: [Recommendation] = []

        // Account Recommendations
        allRecommendations.append(contentsOf: generateSavingsAccountRecommendations(profile: profile))
        allRecommendations.append(contentsOf: generateCheckingAccountRecommendations(profile: profile))
        allRecommendations.append(contentsOf: generateCreditCardRecommendations(profile: profile))

        // Card Optimization
        allRecommendations.append(contentsOf: generateCardOptimizationRecommendations(profile: profile))
        allRecommendations.append(contentsOf: generateSignupBonusRecommendations(profile: profile))

        // Insurance
        allRecommendations.append(contentsOf: generateInsuranceRecommendations(profile: profile))

        // Loans & Refinancing
        allRecommendations.append(contentsOf: generateLoanRecommendations(profile: profile))

        // Subscriptions
        allRecommendations.append(contentsOf: generateSubscriptionRecommendations(profile: profile))

        // Bills & Services
        allRecommendations.append(contentsOf: generateBillRecommendations(profile: profile))

        // Investments
        allRecommendations.append(contentsOf: generateInvestmentRecommendations(profile: profile))

        // Lifestyle
        allRecommendations.append(contentsOf: generateLifestyleRecommendations(profile: profile))

        // Tax
        allRecommendations.append(contentsOf: generateTaxRecommendations(profile: profile))

        // Sort by urgency and potential value
        recommendations = allRecommendations.sorted { rec1, rec2 in
            let value1 = (rec1.potentialSavings ?? 0) + (rec1.potentialEarnings ?? 0)
            let value2 = (rec2.potentialSavings ?? 0) + (rec2.potentialEarnings ?? 0)
            return value1 > value2
        }

        // Set featured (top 5 by value)
        featuredRecommendations = Array(recommendations.prefix(5))

        // Calculate totals
        totalPotentialSavings = recommendations.compactMap { $0.potentialSavings }.reduce(0, +)
        totalPotentialEarnings = recommendations.compactMap { $0.potentialEarnings }.reduce(0, +)

        lastAnalyzed = Date()
        isAnalyzing = false
    }

    // MARK: - Profile Building

    private func buildUserProfile() -> UserFinancialProfile {
        let incomeManager = IncomeManager.shared
        let debtManager = DebtPayoffManager.shared

        // Get spending by category from transactions
        var spendingByCategory: [String: Double] = [:]
        let transactions = RealTimeTransactionManager.shared.recentTransactions
        for transaction in transactions where transaction.amount < 0 {
            spendingByCategory[transaction.category, default: 0] += abs(transaction.amount)
        }

        // Get debts
        let debts = debtManager.debts.map { ($0.type.rawValue, $0.currentBalance, $0.interestRate) }

        return UserFinancialProfile(
            monthlyIncome: incomeManager.totalMonthlyIncome,
            totalSavings: 15000, // Demo value
            checkingBalance: 5000, // Demo value
            creditScore: 720, // Demo value
            monthlySpendingByCategory: spendingByCategory,
            currentCreditCards: ["Chase Sapphire", "Apple Card"],
            currentInsurance: ["Auto": 150, "Renters": 25],
            currentSubscriptions: ["Netflix": 15.99, "Spotify": 9.99, "Gym": 49.99],
            debts: debts,
            age: 32,
            hasHome: false,
            hasCar: true,
            hasPets: false,
            employmentType: "Full-time",
            state: "CA"
        )
    }

    // MARK: - Savings Account Recommendations

    private func generateSavingsAccountRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Find best high-yield savings based on balance
        let bestAccounts = savingsAccounts
            .filter { profile.totalSavings >= $0.minimumBalance }
            .sorted { $0.apy > $1.apy }

        if let bestAccount = bestAccounts.first {
            // Calculate potential earnings vs typical 0.5% savings
            let currentYearlyEarnings = profile.totalSavings * 0.005
            let newYearlyEarnings = profile.totalSavings * (bestAccount.apy / 100)
            let additionalEarnings = newYearlyEarnings - currentYearlyEarnings

            if additionalEarnings > 50 {
                var pros = [
                    "\(String(format: "%.2f", bestAccount.apy))% APY - among the highest available",
                    "FDIC insured up to $250,000"
                ]
                pros.append(contentsOf: bestAccount.features.prefix(2))

                var cons: [String] = []
                if bestAccount.minimumBalance > 0 {
                    cons.append("Requires $\(Int(bestAccount.minimumBalance)) minimum balance")
                }
                if bestAccount.monthlyFee > 0 {
                    cons.append("$\(Int(bestAccount.monthlyFee)) monthly fee")
                }

                recommendations.append(Recommendation(
                    type: .savingsAccount,
                    category: .accounts,
                    title: "Switch to \(bestAccount.bankName)",
                    subtitle: "\(String(format: "%.2f", bestAccount.apy))% APY High-Yield Savings",
                    description: "Your savings could earn \(String(format: "$%.0f", additionalEarnings)) more per year with a high-yield savings account. \(bestAccount.accountName) offers one of the best rates available.",
                    potentialSavings: nil,
                    potentialEarnings: additionalEarnings,
                    confidence: 0.9,
                    urgency: additionalEarnings > 200 ? .high : .medium,
                    actionItems: [
                        ActionItem(title: "Open Account", description: "Takes about 10 minutes", actionType: .apply, link: bestAccount.link),
                        ActionItem(title: "Compare Rates", description: "See all high-yield options", actionType: .compare, link: nil)
                    ],
                    pros: pros,
                    cons: cons.isEmpty ? ["May need to transfer funds from current bank"] : cons,
                    externalLink: bestAccount.link,
                    expiresAt: nil,
                    metadata: ["apy": bestAccount.apy, "bank": bestAccount.bankName]
                ))
            }
        }

        // Sign-up bonus opportunities
        for account in savingsAccounts where account.signupBonus ?? 0 > 100 {
            recommendations.append(Recommendation(
                type: .savingsAccount,
                category: .accounts,
                title: "$\(Int(account.signupBonus!)) Bonus - \(account.bankName)",
                subtitle: account.bonusRequirements ?? "Limited time offer",
                description: "Earn a $\(Int(account.signupBonus!)) bonus when you open a new \(account.accountName) and meet the requirements.",
                potentialSavings: nil,
                potentialEarnings: account.signupBonus!,
                confidence: 0.85,
                urgency: .high,
                actionItems: [
                    ActionItem(title: "Claim Bonus", description: nil, actionType: .apply, link: account.link)
                ],
                pros: ["Easy bonus money", "\(String(format: "%.2f", account.apy))% APY after bonus"],
                cons: [account.bonusRequirements ?? "Requirements apply"],
                externalLink: account.link,
                expiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                metadata: ["bonus": account.signupBonus!]
            ))
        }

        return recommendations
    }

    // MARK: - Checking Account Recommendations

    private func generateCheckingAccountRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Recommend checking with no fees and good perks
        if profile.checkingBalance > 1000 {
            recommendations.append(Recommendation(
                type: .checkingAccount,
                category: .accounts,
                title: "Switch to Fee-Free Checking",
                subtitle: "No monthly fees, ATM rebates",
                description: "Many online banks offer checking accounts with no monthly fees, unlimited ATM rebates, and early direct deposit.",
                potentialSavings: 144, // $12/month avg fee
                potentialEarnings: nil,
                confidence: 0.8,
                urgency: .medium,
                actionItems: [
                    ActionItem(title: "Compare Options", description: nil, actionType: .compare, link: nil),
                    ActionItem(title: "Learn More", description: nil, actionType: .learn, link: nil)
                ],
                pros: ["No monthly fees", "ATM fee rebates", "Early direct deposit", "Mobile check deposit"],
                cons: ["May need to change direct deposit", "No physical branches"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        return recommendations
    }

    // MARK: - Credit Card Recommendations

    private func generateCreditCardRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Analyze spending to recommend best cards
        let topCategories = profile.monthlySpendingByCategory.sorted { $0.value > $1.value }.prefix(3)

        for card in creditCards {
            var matchScore = 0.0
            var matchReasons: [String] = []

            // Check if card rewards match spending
            for (category, spending) in topCategories {
                if let multiplier = card.rewardsStructure[category], multiplier >= 3 {
                    matchScore += spending * multiplier * 0.01 // Estimate yearly value
                    matchReasons.append("\(Int(multiplier))x on \(category)")
                }
            }

            // Add signup bonus value
            let signupValue = card.signupBonusValue

            if matchScore > 100 || signupValue > 200 {
                let yearlyValue = matchScore * 12 + signupValue

                recommendations.append(Recommendation(
                    type: .creditCard,
                    category: .creditCards,
                    title: card.cardName,
                    subtitle: card.issuer + (card.annualFee > 0 ? " • $\(Int(card.annualFee))/yr" : " • No Annual Fee"),
                    description: "Based on your spending, this card could earn you \(String(format: "$%.0f", yearlyValue)) in the first year. \(card.signupBonus)",
                    potentialSavings: nil,
                    potentialEarnings: yearlyValue,
                    confidence: 0.85,
                    urgency: signupValue > 500 ? .high : .medium,
                    actionItems: [
                        ActionItem(title: "Apply Now", description: "Check if you pre-qualify", actionType: .apply, link: card.link),
                        ActionItem(title: "Compare Cards", description: nil, actionType: .compare, link: nil)
                    ],
                    pros: card.perks.prefix(4).map { $0 },
                    cons: card.annualFee > 0 ? ["$\(Int(card.annualFee)) annual fee"] : [],
                    externalLink: card.link,
                    expiresAt: nil,
                    metadata: ["issuer": card.issuer, "bonus": signupValue]
                ))
            }
        }

        return recommendations
    }

    // MARK: - Card Optimization Recommendations

    private func generateCardOptimizationRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Recommend which card to use for each category
        let topCategories = profile.monthlySpendingByCategory.sorted { $0.value > $1.value }.prefix(5)

        var cardOptimizations: [(category: String, card: String, multiplier: Double, monthlyValue: Double)] = []

        for (category, spending) in topCategories {
            var bestCard = "Cash"
            var bestMultiplier = 1.0

            for card in creditCards {
                if let multiplier = card.rewardsStructure[category], multiplier > bestMultiplier {
                    bestMultiplier = multiplier
                    bestCard = card.cardName
                }
            }

            if bestMultiplier > 1.5 {
                let monthlyValue = spending * bestMultiplier * 0.01
                cardOptimizations.append((category, bestCard, bestMultiplier, monthlyValue))
            }
        }

        if !cardOptimizations.isEmpty {
            let totalMonthlyValue = cardOptimizations.reduce(0) { $0 + $1.monthlyValue }

            recommendations.append(Recommendation(
                type: .cardOptimization,
                category: .creditCards,
                title: "Optimize Your Card Usage",
                subtitle: "Earn \(String(format: "$%.0f", totalMonthlyValue))/month more in rewards",
                description: "You could maximize rewards by using the right card for each category. We'll show you which card to use where.",
                potentialSavings: nil,
                potentialEarnings: totalMonthlyValue * 12,
                confidence: 0.9,
                urgency: .medium,
                actionItems: [
                    ActionItem(title: "See Card Guide", description: "Which card for which purchase", actionType: .learn, link: nil)
                ],
                pros: cardOptimizations.map { "\($0.card) for \($0.category) (\(Int($0.multiplier))x)" },
                cons: ["Requires remembering which card to use"],
                externalLink: nil,
                expiresAt: nil,
                metadata: ["optimizations": cardOptimizations.count]
            ))
        }

        return recommendations
    }

    // MARK: - Sign-up Bonus Recommendations

    private func generateSignupBonusRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Find cards with valuable sign-up bonuses user doesn't have
        let cardsNotOwned = creditCards.filter { !profile.currentCreditCards.contains($0.cardName) }
        let bonusCards = cardsNotOwned.filter { $0.signupBonusValue >= 200 }.sorted { $0.signupBonusValue > $1.signupBonusValue }

        for card in bonusCards.prefix(3) {
            recommendations.append(Recommendation(
                type: .signupBonus,
                category: .creditCards,
                title: "Earn \(card.signupBonus)",
                subtitle: "\(card.cardName) by \(card.issuer)",
                description: "New cardholders can earn \(card.signupBonus) when they spend \(card.signupRequirement). That's worth approximately $\(Int(card.signupBonusValue))!",
                potentialSavings: nil,
                potentialEarnings: card.signupBonusValue,
                confidence: 0.85,
                urgency: .high,
                actionItems: [
                    ActionItem(title: "Check Eligibility", description: nil, actionType: .apply, link: card.link)
                ],
                pros: ["Valuable welcome bonus", "Great ongoing rewards"] + card.perks.prefix(2),
                cons: card.annualFee > 0 ? ["$\(Int(card.annualFee)) annual fee applies"] : [],
                externalLink: card.link,
                expiresAt: nil,
                metadata: ["bonusValue": card.signupBonusValue]
            ))
        }

        return recommendations
    }

    // MARK: - Insurance Recommendations

    private func generateInsuranceRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Auto insurance savings
        if profile.hasCar, let currentAutoInsurance = profile.currentInsurance["Auto"] {
            let potentialSavings = currentAutoInsurance * 0.20 * 12 // 20% avg savings

            recommendations.append(Recommendation(
                type: .autoInsurance,
                category: .insurance,
                title: "Compare Auto Insurance Rates",
                subtitle: "Could save $\(Int(potentialSavings))/year",
                description: "Drivers who compare rates save an average of 20% on auto insurance. Your current premium of $\(Int(currentAutoInsurance))/month might be higher than necessary.",
                potentialSavings: potentialSavings,
                potentialEarnings: nil,
                confidence: 0.75,
                urgency: .medium,
                actionItems: [
                    ActionItem(title: "Get Free Quotes", description: "Compare in minutes", actionType: .compare, link: nil),
                    ActionItem(title: "Call Current Insurer", description: "Ask about discounts", actionType: .call, link: nil)
                ],
                pros: ["Free to compare", "Could save hundreds", "Same or better coverage"],
                cons: ["Takes time to compare", "May need to switch providers"],
                externalLink: nil,
                expiresAt: nil,
                metadata: ["currentPremium": currentAutoInsurance]
            ))
        }

        // Renters insurance if applicable
        if !profile.hasHome && profile.currentInsurance["Renters"] == nil {
            recommendations.append(Recommendation(
                type: .rentersInsurance,
                category: .insurance,
                title: "Get Renters Insurance",
                subtitle: "From ~$15/month",
                description: "Protect your belongings from theft, fire, and water damage. Most policies also include liability coverage.",
                potentialSavings: nil,
                potentialEarnings: nil,
                confidence: 0.9,
                urgency: .medium,
                actionItems: [
                    ActionItem(title: "Get Quotes", description: nil, actionType: .compare, link: nil)
                ],
                pros: ["Protects belongings", "Liability coverage", "Very affordable"],
                cons: ["Additional monthly expense"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        // Pet insurance
        if profile.hasPets && profile.currentInsurance["Pet"] == nil {
            recommendations.append(Recommendation(
                type: .petInsurance,
                category: .insurance,
                title: "Consider Pet Insurance",
                subtitle: "From ~$30/month",
                description: "Pet insurance can save thousands on unexpected vet bills. Costs increase with pet age, so earlier is better.",
                potentialSavings: nil,
                potentialEarnings: nil,
                confidence: 0.7,
                urgency: .low,
                actionItems: [
                    ActionItem(title: "Compare Plans", description: nil, actionType: .compare, link: nil)
                ],
                pros: ["Peace of mind", "Covers accidents & illness", "Cheaper when pet is young"],
                cons: ["Monthly premium", "Deductibles apply", "Pre-existing conditions excluded"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        return recommendations
    }

    // MARK: - Loan Recommendations

    private func generateLoanRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        for debt in profile.debts {
            // Student loan refinancing
            if debt.type == "Student Loan" && debt.rate > 0.05 && profile.creditScore >= 680 {
                let currentMonthlyInterest = debt.balance * debt.rate / 12
                let refinancedRate = 0.045 // Estimated lower rate
                let newMonthlyInterest = debt.balance * refinancedRate / 12
                let monthlySavings = currentMonthlyInterest - newMonthlyInterest
                let yearlySavings = monthlySavings * 12

                if yearlySavings > 200 {
                    recommendations.append(Recommendation(
                        type: .studentLoanRefi,
                        category: .loans,
                        title: "Refinance Student Loans",
                        subtitle: "Save ~$\(Int(yearlySavings))/year in interest",
                        description: "With your credit score of \(profile.creditScore), you may qualify for rates as low as 4.5% APR, down from your current \(String(format: "%.1f", debt.rate * 100))%.",
                        potentialSavings: yearlySavings,
                        potentialEarnings: nil,
                        confidence: 0.8,
                        urgency: yearlySavings > 500 ? .high : .medium,
                        actionItems: [
                            ActionItem(title: "Check Rates", description: "No impact to credit score", actionType: .compare, link: nil)
                        ],
                        pros: ["Lower interest rate", "Lower monthly payment", "Pay off faster"],
                        cons: ["May lose federal benefits", "Requires credit check"],
                        externalLink: nil,
                        expiresAt: nil,
                        metadata: ["currentRate": debt.rate, "balance": debt.balance]
                    ))
                }
            }

            // Auto loan refinancing
            if debt.type == "Auto Loan" && debt.rate > 0.06 && profile.creditScore >= 670 {
                let potentialSavings = debt.balance * (debt.rate - 0.045) // Estimated savings

                recommendations.append(Recommendation(
                    type: .autoLoanRefi,
                    category: .loans,
                    title: "Refinance Auto Loan",
                    subtitle: "Potentially lower rate available",
                    description: "Your auto loan at \(String(format: "%.1f", debt.rate * 100))% APR could potentially be refinanced to a lower rate based on current market conditions.",
                    potentialSavings: potentialSavings,
                    potentialEarnings: nil,
                    confidence: 0.75,
                    urgency: .medium,
                    actionItems: [
                        ActionItem(title: "Check Rates", description: nil, actionType: .compare, link: nil)
                    ],
                    pros: ["Lower monthly payment", "Save on interest"],
                    cons: ["May extend loan term", "Fees may apply"],
                    externalLink: nil,
                    expiresAt: nil,
                    metadata: [:]
                ))
            }

            // Credit card balance transfer
            if debt.type == "Credit Card" && debt.rate > 0.15 && debt.balance > 1000 {
                let interestSavings = debt.balance * debt.rate * 0.75 // 15-month 0% transfer

                recommendations.append(Recommendation(
                    type: .balanceTransfer,
                    category: .creditCards,
                    title: "Balance Transfer Opportunity",
                    subtitle: "Save $\(Int(interestSavings)) in interest",
                    description: "Transfer your \(String(format: "$%.0f", debt.balance)) balance to a 0% APR card and save on interest for 15-21 months.",
                    potentialSavings: interestSavings,
                    potentialEarnings: nil,
                    confidence: 0.85,
                    urgency: .high,
                    actionItems: [
                        ActionItem(title: "See 0% APR Cards", description: nil, actionType: .compare, link: nil)
                    ],
                    pros: ["0% APR for 15-21 months", "Pay down principal faster"],
                    cons: ["3-5% transfer fee", "Rate increases after intro period"],
                    externalLink: nil,
                    expiresAt: nil,
                    metadata: ["balance": debt.balance, "currentRate": debt.rate]
                ))
            }
        }

        // Debt consolidation if multiple debts
        if profile.debts.count >= 3 {
            let totalDebt = profile.debts.reduce(0) { $0 + $1.balance }
            let avgRate = profile.debts.reduce(0) { $0 + $1.rate } / Double(profile.debts.count)

            if totalDebt > 5000 && avgRate > 0.12 {
                recommendations.append(Recommendation(
                    type: .debtConsolidation,
                    category: .loans,
                    title: "Consolidate Your Debts",
                    subtitle: "Simplify \(profile.debts.count) debts into one payment",
                    description: "Combine your debts into a single loan with potentially lower interest rate. You have \(String(format: "$%.0f", totalDebt)) across \(profile.debts.count) accounts.",
                    potentialSavings: totalDebt * 0.05, // Estimated savings
                    potentialEarnings: nil,
                    confidence: 0.7,
                    urgency: .medium,
                    actionItems: [
                        ActionItem(title: "Check Options", description: nil, actionType: .compare, link: nil)
                    ],
                    pros: ["One monthly payment", "Potentially lower rate", "Easier to manage"],
                    cons: ["May extend payoff time", "Origination fees"],
                    externalLink: nil,
                    expiresAt: nil,
                    metadata: ["totalDebt": totalDebt, "debtCount": profile.debts.count]
                ))
            }
        }

        return recommendations
    }

    // MARK: - Subscription Recommendations

    private func generateSubscriptionRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        let totalSubCost = profile.currentSubscriptions.values.reduce(0, +)

        // Streaming bundle opportunities
        let streamingServices = ["Netflix", "Hulu", "Disney+", "HBO Max", "Paramount+"]
        let currentStreaming = profile.currentSubscriptions.filter { streamingServices.contains($0.key) }

        if currentStreaming.count >= 2 {
            let currentStreamingCost = currentStreaming.values.reduce(0, +)
            let bundlePrice = 14.99 // Example bundle price

            if currentStreamingCost > bundlePrice {
                recommendations.append(Recommendation(
                    type: .subscriptionBundle,
                    category: .subscriptions,
                    title: "Bundle Your Streaming",
                    subtitle: "Save $\(Int((currentStreamingCost - bundlePrice) * 12))/year",
                    description: "You're paying $\(String(format: "%.2f", currentStreamingCost))/month for separate streaming services. Consider bundles like Disney Bundle or Hulu + Max.",
                    potentialSavings: (currentStreamingCost - bundlePrice) * 12,
                    potentialEarnings: nil,
                    confidence: 0.8,
                    urgency: .medium,
                    actionItems: [
                        ActionItem(title: "Compare Bundles", description: nil, actionType: .compare, link: nil)
                    ],
                    pros: ["Same content, less money", "One bill to manage"],
                    cons: ["May include services you don't want"],
                    externalLink: nil,
                    expiresAt: nil,
                    metadata: ["currentCost": currentStreamingCost]
                ))
            }
        }

        // Gym alternative
        if let gymCost = profile.currentSubscriptions["Gym"], gymCost > 30 {
            recommendations.append(Recommendation(
                type: .fitnessAlternative,
                category: .subscriptions,
                title: "Fitness Subscription Alternatives",
                subtitle: "From $12.99/month",
                description: "Consider alternatives like Planet Fitness ($10-25/mo), Apple Fitness+ ($10/mo), or YouTube workout videos (free).",
                potentialSavings: (gymCost - 15) * 12,
                potentialEarnings: nil,
                confidence: 0.6,
                urgency: .low,
                actionItems: [
                    ActionItem(title: "Compare Options", description: nil, actionType: .compare, link: nil)
                ],
                pros: ["Lower cost", "Workout from home options"],
                cons: ["May miss gym equipment", "Requires self-motivation"],
                externalLink: nil,
                expiresAt: nil,
                metadata: ["currentCost": gymCost]
            ))
        }

        return recommendations
    }

    // MARK: - Bill Recommendations

    private func generateBillRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Phone plan optimization
        recommendations.append(Recommendation(
            type: .phonePlan,
            category: .bills,
            title: "Review Your Phone Plan",
            subtitle: "MVNOs save 50%+ vs major carriers",
            description: "Carriers like Mint Mobile, Visible, and US Mobile use the same networks as major carriers at half the price.",
            potentialSavings: 400, // Estimated yearly
            potentialEarnings: nil,
            confidence: 0.75,
            urgency: .low,
            actionItems: [
                ActionItem(title: "Compare Plans", description: nil, actionType: .compare, link: nil)
            ],
            pros: ["Same network coverage", "No contracts", "Much cheaper"],
            cons: ["May need to switch numbers", "Customer service varies"],
            externalLink: nil,
            expiresAt: nil,
            metadata: [:]
        ))

        // Internet negotiation
        recommendations.append(Recommendation(
            type: .billNegotiation,
            category: .bills,
            title: "Negotiate Your Internet Bill",
            subtitle: "Most succeed in getting 20-30% off",
            description: "Call your internet provider and ask about promotions or threaten to switch. Most people who try get a discount.",
            potentialSavings: 180, // Estimated yearly
            potentialEarnings: nil,
            confidence: 0.7,
            urgency: .low,
            actionItems: [
                ActionItem(title: "Call Provider", description: "Use our script", actionType: .negotiate, link: nil),
                ActionItem(title: "Compare Competitors", description: "Know your options first", actionType: .compare, link: nil)
            ],
            pros: ["Takes 15 minutes", "Usually works", "No switching required"],
            cons: ["Requires phone call", "Not guaranteed"],
            externalLink: nil,
            expiresAt: nil,
            metadata: [:]
        ))

        return recommendations
    }

    // MARK: - Investment Recommendations

    private func generateInvestmentRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Emergency fund check
        let monthsOfExpenses = profile.totalSavings / (profile.monthlySpendingByCategory.values.reduce(0, +) + 500)
        if monthsOfExpenses < 3 {
            recommendations.append(Recommendation(
                type: .savingsAccount,
                category: .accounts,
                title: "Build Emergency Fund",
                subtitle: "Currently \(String(format: "%.1f", monthsOfExpenses)) months of expenses",
                description: "Financial experts recommend 3-6 months of expenses in savings. Focus on building this before investing.",
                potentialSavings: nil,
                potentialEarnings: nil,
                confidence: 0.95,
                urgency: monthsOfExpenses < 1 ? .critical : .high,
                actionItems: [
                    ActionItem(title: "Set Savings Goal", description: nil, actionType: .learn, link: nil)
                ],
                pros: ["Financial security", "Peace of mind", "Avoid debt in emergencies"],
                cons: ["Requires discipline"],
                externalLink: nil,
                expiresAt: nil,
                metadata: ["monthsOfExpenses": monthsOfExpenses]
            ))
        }

        // 401(k) contribution
        if profile.employmentType == "Full-time" {
            recommendations.append(Recommendation(
                type: .retirement401k,
                category: .investments,
                title: "Maximize 401(k) Match",
                subtitle: "Don't leave free money on the table",
                description: "If your employer offers a 401(k) match, contribute at least enough to get the full match. It's essentially free money.",
                potentialSavings: nil,
                potentialEarnings: 2000, // Estimated match value
                confidence: 0.9,
                urgency: .high,
                actionItems: [
                    ActionItem(title: "Check Match Policy", description: nil, actionType: .learn, link: nil),
                    ActionItem(title: "Increase Contribution", description: nil, actionType: .apply, link: nil)
                ],
                pros: ["Free employer money", "Tax advantages", "Compound growth"],
                cons: ["Reduces take-home pay"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        // Robo-advisor for beginners
        if profile.totalSavings > 5000 && monthsOfExpenses >= 3 {
            recommendations.append(Recommendation(
                type: .roboAdvisor,
                category: .investments,
                title: "Start Investing with a Robo-Advisor",
                subtitle: "Automated investing from $1",
                description: "Robo-advisors like Betterment, Wealthfront, or M1 Finance make investing easy with automatic diversification and rebalancing.",
                potentialSavings: nil,
                potentialEarnings: profile.totalSavings * 0.07, // Estimated yearly return
                confidence: 0.75,
                urgency: .medium,
                actionItems: [
                    ActionItem(title: "Compare Robo-Advisors", description: nil, actionType: .compare, link: nil)
                ],
                pros: ["Set it and forget it", "Low fees", "Diversified portfolio"],
                cons: ["Investment risk", "Less control"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        return recommendations
    }

    // MARK: - Lifestyle Recommendations

    private func generateLifestyleRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Food spending optimization
        if let foodSpending = profile.monthlySpendingByCategory["Food & Dining"], foodSpending > 500 {
            let potentialSavings = foodSpending * 0.25 * 12

            recommendations.append(Recommendation(
                type: .groceryOptimization,
                category: .lifestyle,
                title: "Reduce Food Spending",
                subtitle: "You spend $\(Int(foodSpending))/month on food",
                description: "With meal planning and cooking at home more, you could save 20-30% on food. Consider meal prep services like EveryPlate ($5/serving) or cooking more at home.",
                potentialSavings: potentialSavings,
                potentialEarnings: nil,
                confidence: 0.7,
                urgency: .low,
                actionItems: [
                    ActionItem(title: "Compare Meal Kits", description: nil, actionType: .compare, link: nil),
                    ActionItem(title: "See Tips", description: nil, actionType: .learn, link: nil)
                ],
                pros: ["Significant savings", "Healthier eating", "Less food waste"],
                cons: ["Requires time for cooking/prep"],
                externalLink: nil,
                expiresAt: nil,
                metadata: ["monthlySpending": foodSpending]
            ))
        }

        // Transportation
        if let transportSpending = profile.monthlySpendingByCategory["Transportation"], transportSpending > 300 {
            recommendations.append(Recommendation(
                type: .transportationSavings,
                category: .lifestyle,
                title: "Transportation Alternatives",
                subtitle: "Save on your $\(Int(transportSpending))/month spending",
                description: "Consider carpooling, public transit, biking, or working from home when possible to reduce transportation costs.",
                potentialSavings: transportSpending * 0.3 * 12,
                potentialEarnings: nil,
                confidence: 0.6,
                urgency: .low,
                actionItems: [
                    ActionItem(title: "Explore Options", description: nil, actionType: .learn, link: nil)
                ],
                pros: ["Environmental benefits", "Less stress", "Health benefits (biking/walking)"],
                cons: ["May take longer", "Weather dependent"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        return recommendations
    }

    // MARK: - Tax Recommendations

    private func generateTaxRecommendations(profile: UserFinancialProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // HSA recommendation
        recommendations.append(Recommendation(
            type: .hsa,
            category: .taxes,
            title: "Consider an HSA Account",
            subtitle: "Triple tax advantage",
            description: "If you have a high-deductible health plan, an HSA offers tax-free contributions, growth, and withdrawals for medical expenses.",
            potentialSavings: 500, // Estimated tax savings
            potentialEarnings: nil,
            confidence: 0.8,
            urgency: .medium,
            actionItems: [
                ActionItem(title: "Check Eligibility", description: nil, actionType: .learn, link: nil)
            ],
            pros: ["Tax-deductible contributions", "Tax-free growth", "Tax-free withdrawals"],
            cons: ["Requires HDHP", "Contribution limits"],
            externalLink: nil,
            expiresAt: nil,
            metadata: [:]
        ))

        // Tax deductions reminder
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        if month >= 10 || month <= 4 {
            recommendations.append(Recommendation(
                type: .taxDeduction,
                category: .taxes,
                title: "Track Tax Deductions",
                subtitle: "Don't miss money-saving deductions",
                description: "Make sure you're tracking all potential deductions: charitable donations, business expenses, student loan interest, and more.",
                potentialSavings: 500,
                potentialEarnings: nil,
                confidence: 0.85,
                urgency: month >= 1 && month <= 4 ? .high : .medium,
                actionItems: [
                    ActionItem(title: "See Deductions List", description: nil, actionType: .learn, link: nil)
                ],
                pros: ["Reduce tax bill", "Get bigger refund"],
                cons: ["Requires record keeping"],
                externalLink: nil,
                expiresAt: nil,
                metadata: [:]
            ))
        }

        return recommendations
    }

    // MARK: - Filtering

    func getRecommendations(for category: RecommendationCategory) -> [Recommendation] {
        recommendations.filter { $0.category == category }
    }

    func getRecommendations(byUrgency urgency: RecommendationUrgency) -> [Recommendation] {
        recommendations.filter { $0.urgency == urgency }
    }

    func getTopRecommendations(count: Int = 5) -> [Recommendation] {
        Array(recommendations.prefix(count))
    }

    // MARK: - Product Data

    private func loadProductData() {
        // Load savings accounts
        savingsAccounts = [
            SavingsAccountOffer(id: UUID(), bankName: "Marcus by Goldman Sachs", accountName: "High-Yield Savings", apy: 4.50, minimumBalance: 0, monthlyFee: 0, signupBonus: nil, bonusRequirements: nil, fdic: true, features: ["No minimum deposit", "No fees", "Easy transfers"], link: "https://marcus.com"),
            SavingsAccountOffer(id: UUID(), bankName: "Ally Bank", accountName: "Online Savings", apy: 4.25, minimumBalance: 0, monthlyFee: 0, signupBonus: nil, bonusRequirements: nil, fdic: true, features: ["Buckets for goals", "No minimum", "24/7 support"], link: "https://ally.com"),
            SavingsAccountOffer(id: UUID(), bankName: "Wealthfront", accountName: "Cash Account", apy: 5.00, minimumBalance: 0, monthlyFee: 0, signupBonus: nil, bonusRequirements: nil, fdic: true, features: ["$8M FDIC insurance", "No fees", "Automated savings"], link: "https://wealthfront.com"),
            SavingsAccountOffer(id: UUID(), bankName: "SoFi", accountName: "Checking & Savings", apy: 4.60, minimumBalance: 0, monthlyFee: 0, signupBonus: 300, bonusRequirements: "Direct deposit of $5,000+", fdic: true, features: ["2-day early paycheck", "No fees", "Vaults"], link: "https://sofi.com"),
            SavingsAccountOffer(id: UUID(), bankName: "Discover", accountName: "Online Savings", apy: 4.25, minimumBalance: 0, monthlyFee: 0, signupBonus: 200, bonusRequirements: "Deposit $15,000+", fdic: true, features: ["No fees", "24/7 US support"], link: "https://discover.com")
        ]

        // Load credit cards
        creditCards = [
            CreditCardOffer(id: UUID(), issuer: "Chase", cardName: "Sapphire Preferred", annualFee: 95, signupBonus: "60,000 points", signupBonusValue: 750, signupRequirement: "$4,000 in 3 months", rewardsStructure: ["Travel": 5, "Food & Dining": 3, "Streaming": 3], baseRewardsRate: 1, apr: "21.49%-28.49%", introApr: nil, foreignTransactionFee: 0, creditScoreRequired: "Good-Excellent (700+)", perks: ["3x on dining", "2x on travel", "Trip cancellation insurance", "No foreign transaction fees"], bestFor: ["Travel rewards", "Dining out"], link: "https://chase.com"),
            CreditCardOffer(id: UUID(), issuer: "American Express", cardName: "Blue Cash Preferred", annualFee: 95, signupBonus: "$350 back", signupBonusValue: 350, signupRequirement: "$3,000 in 6 months", rewardsStructure: ["Groceries": 6, "Streaming": 6, "Transportation": 3], baseRewardsRate: 1, apr: "19.24%-29.99%", introApr: "0% for 12 months", foreignTransactionFee: 2.7, creditScoreRequired: "Good-Excellent (670+)", perks: ["6% at supermarkets", "6% on streaming", "3% at gas stations"], bestFor: ["Groceries", "Families"], link: "https://americanexpress.com"),
            CreditCardOffer(id: UUID(), issuer: "Citi", cardName: "Double Cash", annualFee: 0, signupBonus: "$200 back", signupBonusValue: 200, signupRequirement: "$1,500 in 6 months", rewardsStructure: [:], baseRewardsRate: 2, apr: "18.24%-28.24%", introApr: "0% for 18 months on BT", foreignTransactionFee: 3, creditScoreRequired: "Good-Excellent (670+)", perks: ["2% on everything", "No annual fee", "0% BT intro APR"], bestFor: ["Simplicity", "Flat rate rewards"], link: "https://citi.com"),
            CreditCardOffer(id: UUID(), issuer: "Capital One", cardName: "Venture X", annualFee: 395, signupBonus: "75,000 miles", signupBonusValue: 750, signupRequirement: "$4,000 in 3 months", rewardsStructure: ["Travel": 10, "Entertainment": 5], baseRewardsRate: 2, apr: "19.99%-29.99%", introApr: nil, foreignTransactionFee: 0, creditScoreRequired: "Excellent (740+)", perks: ["$300 travel credit", "10x on hotels", "Airport lounge access", "Global Entry credit"], bestFor: ["Premium travel", "Lounge access"], link: "https://capitalone.com"),
            CreditCardOffer(id: UUID(), issuer: "Discover", cardName: "it Cash Back", annualFee: 0, signupBonus: "Cashback Match", signupBonusValue: 150, signupRequirement: "Automatic first year", rewardsStructure: ["Rotating": 5], baseRewardsRate: 1, apr: "17.24%-28.24%", introApr: "0% for 15 months", foreignTransactionFee: 0, creditScoreRequired: "Good (670+)", perks: ["5% rotating categories", "Cashback match first year", "No foreign fees"], bestFor: ["Building credit", "Rotating bonuses"], link: "https://discover.com"),
            CreditCardOffer(id: UUID(), issuer: "Wells Fargo", cardName: "Active Cash", annualFee: 0, signupBonus: "$200 back", signupBonusValue: 200, signupRequirement: "$500 in 3 months", rewardsStructure: [:], baseRewardsRate: 2, apr: "20.24%-29.24%", introApr: "0% for 15 months", foreignTransactionFee: 3, creditScoreRequired: "Good (670+)", perks: ["2% on everything", "Cell phone protection", "0% intro APR"], bestFor: ["Flat rate cash back", "Simple rewards"], link: "https://wellsfargo.com")
        ]
    }
}
