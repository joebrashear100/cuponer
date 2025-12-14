//
//  LifeModels.swift
//  Furg
//
//  Models for life scenario simulation, financial projections, and life planning
//

import Foundation

// MARK: - User Financial Profile

struct UserFinancialProfile {
    // Basic demographics
    var currentAge: Int
    var retirementAgeGoal: Int

    // Income
    var annualIncome: Double
    var additionalMonthlyIncome: Double = 0

    // Expenses
    var monthlyExpenses: Double

    // Savings & Net Worth
    var currentSavingsBalance: Double = 0
    var currentNetWorth: Double = 0
    var investmentBalance: Double = 0

    // Computed properties
    var monthlyIncome: Double {
        annualIncome / 12
    }

    var annualExpenses: Double {
        monthlyExpenses * 12
    }

    var savingsRate: Double { // Between 0 and 1
        guard monthlyIncome > 0 else { return 0 }
        let monthlyAfterExpenses = (monthlyIncome + additionalMonthlyIncome) - monthlyExpenses
        return monthlyAfterExpenses / (monthlyIncome + additionalMonthlyIncome)
    }

    // Debt
    var totalDebt: Double = 0
    var studentDebt: Double = 0
    var creditCardDebt: Double = 0
    var mortgageBalance: Double = 0
    var otherDebt: Double = 0
    var debtInterestRate: Double = 0.05 // Default 5%

    // Housing
    var monthlyRent: Double = 0
    var homeValue: Double = 0
    var propertyTaxMonthly: Double = 0
    var homeInsuranceMonthly: Double = 0

    // Investment Details
    var investmentReturnRate: Double = 0.07 // Default 7% annual
    var investmentAllocation: InvestmentAllocation = InvestmentAllocation()

    // Family
    var numberOfDependents: Int = 0
    var childcareExpenseMonthly: Double = 0

    // Tax & Insurance
    var effectiveTaxRate: Double = 0.20 // Default 20%
    var healthInsuranceMonthly: Double = 0
    var lifeInsuranceMonthly: Double = 0
    var disabilityInsuranceMonthly: Double = 0

    // Location
    var currentCity: String = ""
    var currentState: String = ""
    var stateTaxRate: Double = 0

    // Goals
    var emergencyFundTarget: Double = 0
    var retirementSavingsTarget: Double = 0

    // Timestamps
    let createdAt: Date
    var lastUpdatedAt: Date

    init(
        currentAge: Int,
        retirementAgeGoal: Int,
        annualIncome: Double,
        monthlyExpenses: Double,
        currentNetWorth: Double = 0
    ) {
        self.currentAge = currentAge
        self.retirementAgeGoal = retirementAgeGoal
        self.annualIncome = annualIncome
        self.monthlyExpenses = monthlyExpenses
        self.currentNetWorth = currentNetWorth
        self.createdAt = Date()
        self.lastUpdatedAt = Date()

        // Calculate emergency fund target (3-6 months of expenses)
        self.emergencyFundTarget = monthlyExpenses * 5

        // Calculate retirement savings target (25x annual expenses, simplified)
        self.retirementSavingsTarget = annualIncome * 25
    }

    // Computed properties for financial health

    var monthlyNetIncome: Double {
        (monthlyIncome + additionalMonthlyIncome) * (1 - effectiveTaxRate)
    }

    var monthlyAfterTax: Double {
        monthlyNetIncome - monthlyExpenses
    }

    var yearsUntilRetirement: Int {
        max(0, retirementAgeGoal - currentAge)
    }

    var hasPositiveCashFlow: Bool {
        monthlyAfterTax > 0
    }

    var debtToIncomeRatio: Double {
        guard monthlyIncome > 0 else { return 0 }
        return totalDebt / annualIncome
    }

    var netWorthToIncomeRatio: Double {
        guard annualIncome > 0 else { return 0 }
        return currentNetWorth / annualIncome
    }

    var hasEmergencyFund: Bool {
        currentSavingsBalance >= emergencyFundTarget
    }

    var isDebtFree: Bool {
        totalDebt <= 0
    }

    static func placeholder() -> UserFinancialProfile {
        UserFinancialProfile(
            currentAge: 35,
            retirementAgeGoal: 65,
            annualIncome: 75000,
            monthlyExpenses: 4500,
            currentNetWorth: 150000
        )
    }
}

// MARK: - Investment Allocation

struct InvestmentAllocation: Codable {
    var stocks: Double = 0.60 // 60% default
    var bonds: Double = 0.30 // 30% default
    var cash: Double = 0.10 // 10% default
    var alternatives: Double = 0.0 // Real estate, commodities, etc.

    var total: Double {
        stocks + bonds + cash + alternatives
    }

    var isBalanced: Bool {
        abs(total - 1.0) < 0.01
    }

    enum CodingKeys: String, CodingKey {
        case stocks
        case bonds
        case cash
        case alternatives
    }
}

// MARK: - Life Event

struct LifeEvent: Identifiable, Codable {
    let id: String
    let type: LifeEventType
    let title: String
    let description: String?
    let targetDate: Date
    let estimatedCost: Double?
    let impactOnIncome: Double? // Percentage change
    let impactOnExpenses: Double? // Percentage change
    let priority: Int // 1-5, higher is more important
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case targetDate = "target_date"
        case estimatedCost = "estimated_cost"
        case impactOnIncome = "impact_on_income"
        case impactOnExpenses = "impact_on_expenses"
        case priority
        case notes
    }
}

enum LifeEventType: String, Codable, CaseIterable {
    case marriage
    case childBirth = "child_birth"
    case homeDownPayment = "home_down_payment"
    case jobChange = "job_change"
    case educationProgram = "education_program"
    case retirement
    case relocation
    case debtPayoff = "debt_payoff"
    case majorPurchase = "major_purchase"
    case inheritance
    case layoff
    case sabbatical
    case other

    var label: String {
        switch self {
        case .marriage: return "Marriage"
        case .childBirth: return "Child Birth"
        case .homeDownPayment: return "Home Down Payment"
        case .jobChange: return "Job Change"
        case .educationProgram: return "Education Program"
        case .retirement: return "Retirement"
        case .relocation: return "Relocation"
        case .debtPayoff: return "Debt Payoff"
        case .majorPurchase: return "Major Purchase"
        case .inheritance: return "Inheritance"
        case .layoff: return "Layoff"
        case .sabbatical: return "Sabbatical"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .marriage: return "heart.fill"
        case .childBirth: return "figure.and.child.holdinghands"
        case .homeDownPayment: return "house.fill"
        case .jobChange: return "briefcase.fill"
        case .educationProgram: return "graduationcap.fill"
        case .retirement: return "sun.horizon.fill"
        case .relocation: return "map.fill"
        case .debtPayoff: return "creditcard.fill"
        case .majorPurchase: return "cart.fill"
        case .inheritance: return "gift.fill"
        case .layoff: return "exclamationmark.circle.fill"
        case .sabbatical: return "tree.fill"
        case .other: return "star.fill"
        }
    }
}

// MARK: - Financial Milestone

struct FinancialMilestone: Identifiable, Codable {
    let id: String
    let type: MilestoneType
    let targetAmount: Double?
    let targetDate: Date?
    let isAchieved: Bool
    let achievedDate: Date?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case targetAmount = "target_amount"
        case targetDate = "target_date"
        case isAchieved = "is_achieved"
        case achievedDate = "achieved_date"
        case notes
    }
}

enum MilestoneType: String, Codable, CaseIterable {
    case debtFree = "debt_free"
    case emergencyFundComplete = "emergency_fund_complete"
    case firstHousePurchase = "first_house_purchase"
    case millionairStatus = "millionaire_status"
    case retirementReady = "retirement_ready"
    case collegeEdgeFundComplete = "college_fund_complete"
    case savingsRate50Percent = "savings_rate_50_percent"

    var label: String {
        switch self {
        case .debtFree: return "Debt Free"
        case .emergencyFundComplete: return "Emergency Fund Complete"
        case .firstHousePurchase: return "First House Purchase"
        case .millionairStatus: return "Millionaire Status"
        case .retirementReady: return "Retirement Ready"
        case .collegeEdgeFundComplete: return "College Fund Complete"
        case .savingsRate50Percent: return "50% Savings Rate"
        }
    }

    var icon: String {
        switch self {
        case .debtFree: return "checkmark.circle.fill"
        case .emergencyFundComplete: return "lock.shield.fill"
        case .firstHousePurchase: return "house.fill"
        case .millionairStatus: return "dollarsign.circle.fill"
        case .retirementReady: return "beach.umbrella.fill"
        case .collegeEdgeFundComplete: return "graduationcap.fill"
        case .savingsRate50Percent: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Historical Financial Data

struct HistoricalFinancialData: Codable {
    var date: Date
    var netWorth: Double
    var totalIncome: Double
    var totalExpenses: Double
    var investmentBalance: Double
    var savingsBalance: Double
    var totalDebt: Double

    enum CodingKeys: String, CodingKey {
        case date
        case netWorth = "net_worth"
        case totalIncome = "total_income"
        case totalExpenses = "total_expenses"
        case investmentBalance = "investment_balance"
        case savingsBalance = "savings_balance"
        case totalDebt = "total_debt"
    }
}
