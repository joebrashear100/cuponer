import Foundation
import Combine

// MARK: - Life Simulator Models

struct LifeScenario: Identifiable, Codable {
    let id: String
    let type: ScenarioType
    let title: String
    let description: String
    let parameters: ScenarioParameters
    let baselineProjection: FinancialProjection
    let scenarioProjection: FinancialProjection
    let comparison: ProjectionComparison
    let createdAt: Date

    enum ScenarioType: String, Codable, CaseIterable {
        case moveToCity = "Move to a Different City"
        case careerChange = "Career Change"
        case havingChild = "Having a Child"
        case buyingHome = "Buying a Home"
        case earlyRetirement = "Early Retirement"
        case startingBusiness = "Starting a Business"
        case goingBackToSchool = "Going Back to School"
        case payingOffDebt = "Paying Off Debt"
        case increaseSavings = "Increasing Savings Rate"
        case sidehustle = "Starting a Side Hustle"
        case freelancing = "Going Freelance"
        case downsizing = "Downsizing Lifestyle"
        case majorPurchase = "Major Purchase"
        case investmentStrategy = "Investment Strategy Change"

        var icon: String {
            switch self {
            case .moveToCity: return "map.fill"
            case .careerChange: return "briefcase.fill"
            case .havingChild: return "figure.and.child.holdinghands"
            case .buyingHome: return "house.fill"
            case .earlyRetirement: return "beach.umbrella.fill"
            case .startingBusiness: return "building.2.fill"
            case .goingBackToSchool: return "graduationcap.fill"
            case .payingOffDebt: return "creditcard.fill"
            case .increaseSavings: return "banknote.fill"
            case .sidehustle: return "moon.stars.fill"
            case .freelancing: return "laptopcomputer"
            case .downsizing: return "arrow.down.right.and.arrow.up.left"
            case .majorPurchase: return "cart.fill"
            case .investmentStrategy: return "chart.line.uptrend.xyaxis"
            }
        }
    }
}

struct ScenarioParameters: Codable {
    // Location
    var newCity: String?
    var costOfLivingChange: Double? // Percentage

    // Income
    var newSalary: Double?
    var salaryChangePercentage: Double?
    var additionalIncomeMonthly: Double?
    var incomeStartDate: Date?

    // Expenses
    var additionalMonthlyExpenses: Double?
    var reducedMonthlyExpenses: Double?
    var oneTimeCost: Double?

    // Housing
    var newRent: Double?
    var homePrice: Double?
    var downPaymentPercent: Double?
    var mortgageRate: Double?
    var propertyTax: Double?

    // Debt
    var debtAmount: Double?
    var monthlyPayment: Double?
    var interestRate: Double?

    // Savings/Investment
    var newSavingsRate: Double?
    var investmentReturn: Double?
    var retirementAge: Int?

    // Time
    var timeHorizonYears: Int?
    var startDate: Date?
}

struct FinancialProjection: Codable {
    let months: [MonthlyProjection]
    let summary: ProjectionSummary

    struct MonthlyProjection: Codable {
        let month: Int
        let date: Date
        let income: Double
        let expenses: Double
        let savings: Double
        let netWorth: Double
        let debtRemaining: Double
        let investmentBalance: Double
    }

    struct ProjectionSummary: Codable {
        let totalIncome: Double
        let totalExpenses: Double
        let totalSaved: Double
        let finalNetWorth: Double
        let averageMonthlySavings: Double
        let yearsToRetirement: Double?
        let debtFreeDate: Date?
    }
}

struct ProjectionComparison: Codable {
    let netWorthDifference: Double
    let totalSavingsDifference: Double
    let monthlyExpenseDifference: Double
    let retirementDateDifference: Int? // In months
    let debtFreeDateDifference: Int? // In months
    let opportunityCost: Double
    let breakEvenMonths: Int?
    let recommendation: String
    let prosAndCons: ProsAndCons

    struct ProsAndCons: Codable {
        let pros: [String]
        let cons: [String]
    }
}

struct CityData: Codable {
    let name: String
    let costOfLivingIndex: Double // 100 = national average
    let averageRent: Double
    let averageSalaryMultiplier: Double
    let stateTaxRate: Double
}

// MARK: - User Profile Stub
struct UserFinancialProfile: Codable {
    var annualIncome: Double = 78000
    var monthlyIncome: Double = 6500
    var monthlyExpenses: Double = 3500
    var numberOfDependents: Int = 0
    var homeValue: Double = 0
    var mortgageBalance: Double = 0
    var totalDebt: Double = 0
    var currentNetWorth: Double = 50000
    var investmentBalance: Double = 25000
    var currentSavingsBalance: Double = 15000
    var investmentReturnRate: Double = 0.07
    var effectiveTaxRate: Double = 0.22
    var currentAge: Int = 35
    var retirementAgeGoal: Int = 65
}

// MARK: - Life Simulator

class LifeSimulator: ObservableObject {
    static let shared = LifeSimulator()

    @Published var currentScenario: LifeScenario?
    @Published var savedScenarios: [LifeScenario] = []
    @Published var isSimulating = false

    private var userProfile: UserFinancialProfile
    private let defaults = UserDefaults.standard

    init() {
        // Initialize with default profile
        self.userProfile = UserFinancialProfile()
        loadScenarios()
    }

    func updateProfile(_ profile: UserFinancialProfile) {
        self.userProfile = profile
        // Profile is updated in memory; persistence would be handled separately
    }

    // MARK: - Simulation Methods

    func simulateMoveToCity(_ cityName: String, costOfLivingMultiplier: Double, newSalaryMultiplier: Double? = nil, timeHorizonYears: Int = 10) -> LifeScenario {
        var parameters = ScenarioParameters()
        parameters.newCity = cityName
        parameters.costOfLivingChange = (costOfLivingMultiplier - 1.0) * 100
        parameters.timeHorizonYears = timeHorizonYears
        if let multiplier = newSalaryMultiplier {
            parameters.salaryChangePercentage = (multiplier - 1.0) * 100
        }

        let baselineProjection = projectCashFlow(months: timeHorizonYears * 12, profile: userProfile, parameters: ScenarioParameters())
        var scenarioProfile = userProfile
        scenarioProfile.monthlyExpenses *= costOfLivingMultiplier
        if let multiplier = newSalaryMultiplier {
            scenarioProfile.annualIncome *= multiplier
        }
        let scenarioProjection = projectCashFlow(months: timeHorizonYears * 12, profile: scenarioProfile, parameters: parameters)
        let comparison = compareProjections(baseline: baselineProjection, scenario: scenarioProjection, scenarioType: .moveToCity)

        return LifeScenario(
            id: UUID().uuidString,
            type: .moveToCity,
            title: "Move to \(cityName)",
            description: "Analyze the financial impact of relocating to \(cityName)",
            parameters: parameters,
            baselineProjection: baselineProjection,
            scenarioProjection: scenarioProjection,
            comparison: comparison,
            createdAt: Date()
        )
    }

    func simulateCareerChange(newSalary: Double, transitionCostMonths: Int = 3, timeHorizonYears: Int = 10) -> LifeScenario {
        var parameters = ScenarioParameters()
        parameters.newSalary = newSalary
        parameters.salaryChangePercentage = ((newSalary - userProfile.annualIncome) / userProfile.annualIncome) * 100
        parameters.additionalMonthlyExpenses = Double(transitionCostMonths) > 0 ? (5000 / Double(transitionCostMonths)) : 0
        parameters.timeHorizonYears = timeHorizonYears

        let baselineProjection = projectCashFlow(months: timeHorizonYears * 12, profile: userProfile, parameters: ScenarioParameters())
        var scenarioProfile = userProfile
        scenarioProfile.annualIncome = newSalary

        // Add transition costs for the first few months
        var transitionExpenses = 0.0
        if transitionCostMonths > 0 {
            transitionExpenses = 5000 / Double(transitionCostMonths)
        }

        let scenarioProjection = projectCashFlow(months: timeHorizonYears * 12, profile: scenarioProfile, parameters: parameters, transitionMonths: transitionCostMonths, transitionCostPerMonth: transitionExpenses)
        let comparison = compareProjections(baseline: baselineProjection, scenario: scenarioProjection, scenarioType: .careerChange)

        return LifeScenario(
            id: UUID().uuidString,
            type: .careerChange,
            title: "Career Change",
            description: "Transition to a new role with salary of $\(Int(newSalary))",
            parameters: parameters,
            baselineProjection: baselineProjection,
            scenarioProjection: scenarioProjection,
            comparison: comparison,
            createdAt: Date()
        )
    }

    func simulateHavingChild(childcareCostMonthly: Double, timeHorizonYears: Int = 10) -> LifeScenario {
        var parameters = ScenarioParameters()
        parameters.additionalMonthlyExpenses = childcareCostMonthly
        parameters.timeHorizonYears = timeHorizonYears

        let baselineProjection = projectCashFlow(months: timeHorizonYears * 12, profile: userProfile, parameters: ScenarioParameters())
        var scenarioProfile = userProfile
        scenarioProfile.monthlyExpenses += childcareCostMonthly
        scenarioProfile.numberOfDependents = userProfile.numberOfDependents + 1

        let scenarioProjection = projectCashFlow(months: timeHorizonYears * 12, profile: scenarioProfile, parameters: parameters)
        let comparison = compareProjections(baseline: baselineProjection, scenario: scenarioProjection, scenarioType: .havingChild)

        return LifeScenario(
            id: UUID().uuidString,
            type: .havingChild,
            title: "Having a Child",
            description: "Plan for a child with estimated childcare cost of $\(Int(childcareCostMonthly))/month",
            parameters: parameters,
            baselineProjection: baselineProjection,
            scenarioProjection: scenarioProjection,
            comparison: comparison,
            createdAt: Date()
        )
    }

    func simulateBuyingHome(homePrice: Double, downPaymentPercent: Double = 20, mortgageYears: Int = 30, timeHorizonYears: Int = 10) -> LifeScenario {
        var parameters = ScenarioParameters()
        parameters.homePrice = homePrice
        parameters.downPaymentPercent = downPaymentPercent
        parameters.mortgageRate = 0.065 // 6.5% current market rate
        parameters.timeHorizonYears = timeHorizonYears

        let downPayment = homePrice * (downPaymentPercent / 100)
        let loanAmount = homePrice - downPayment
        let monthlyRate = 0.065 / 12
        let numPayments = mortgageYears * 12
        let monthlyPayment = loanAmount * (monthlyRate * pow(1 + monthlyRate, Double(numPayments))) / (pow(1 + monthlyRate, Double(numPayments)) - 1)

        let baselineProjection = projectCashFlow(months: timeHorizonYears * 12, profile: userProfile, parameters: ScenarioParameters())
        var scenarioProfile = userProfile
        scenarioProfile.homeValue = homePrice
        scenarioProfile.mortgageBalance = loanAmount
        scenarioProfile.monthlyExpenses += monthlyPayment + (homePrice * 0.003 / 12) // Add mortgage + property tax/insurance

        let scenarioProjection = projectCashFlow(months: timeHorizonYears * 12, profile: scenarioProfile, parameters: parameters)
        let comparison = compareProjections(baseline: baselineProjection, scenario: scenarioProjection, scenarioType: .buyingHome)

        return LifeScenario(
            id: UUID().uuidString,
            type: .buyingHome,
            title: "Buy Home",
            description: "Purchase a $\(Int(homePrice)) home with \(Int(downPaymentPercent))% down payment",
            parameters: parameters,
            baselineProjection: baselineProjection,
            scenarioProjection: scenarioProjection,
            comparison: comparison,
            createdAt: Date()
        )
    }

    func simulatePayingOffDebt(targetDebtAmount: Double, monthlyPaymentGoal: Double, timeHorizonYears: Int = 5) -> LifeScenario {
        var parameters = ScenarioParameters()
        parameters.debtAmount = targetDebtAmount
        parameters.monthlyPayment = monthlyPaymentGoal
        parameters.timeHorizonYears = timeHorizonYears

        let baselineProjection = projectCashFlow(months: timeHorizonYears * 12, profile: userProfile, parameters: ScenarioParameters())
        var scenarioProfile = userProfile
        scenarioProfile.totalDebt = max(0, targetDebtAmount)

        let scenarioProjection = projectCashFlow(months: timeHorizonYears * 12, profile: scenarioProfile, parameters: parameters, extraPayment: monthlyPaymentGoal)
        let comparison = compareProjections(baseline: baselineProjection, scenario: scenarioProjection, scenarioType: .payingOffDebt)

        return LifeScenario(
            id: UUID().uuidString,
            type: .payingOffDebt,
            title: "Pay Off Debt",
            description: "Aggressively pay off $\(Int(targetDebtAmount)) debt at $\(Int(monthlyPaymentGoal))/month",
            parameters: parameters,
            baselineProjection: baselineProjection,
            scenarioProjection: scenarioProjection,
            comparison: comparison,
            createdAt: Date()
        )
    }

    func simulateGenericScenario(type: LifeScenario.ScenarioType, description: String, parameters: ScenarioParameters, timeHorizonYears: Int = 10) -> LifeScenario {
        var params = parameters
        params.timeHorizonYears = timeHorizonYears

        let baselineProjection = projectCashFlow(months: timeHorizonYears * 12, profile: userProfile, parameters: ScenarioParameters())
        var scenarioProfile = userProfile

        // Apply parameter changes to profile
        if let salaryChange = params.salaryChangePercentage {
            scenarioProfile.annualIncome *= (1 + salaryChange / 100)
        }
        if let expenseChange = params.additionalMonthlyExpenses {
            scenarioProfile.monthlyExpenses += expenseChange
        }
        if let expenseReduction = params.reducedMonthlyExpenses {
            scenarioProfile.monthlyExpenses = max(0, scenarioProfile.monthlyExpenses - expenseReduction)
        }
        if let investmentReturn = params.investmentReturn {
            scenarioProfile.investmentReturnRate = investmentReturn / 100
        }

        let scenarioProjection = projectCashFlow(months: timeHorizonYears * 12, profile: scenarioProfile, parameters: params)
        let comparison = compareProjections(baseline: baselineProjection, scenario: scenarioProjection, scenarioType: type)

        return LifeScenario(
            id: UUID().uuidString,
            type: type,
            title: type.rawValue,
            description: description,
            parameters: params,
            baselineProjection: baselineProjection,
            scenarioProjection: scenarioProjection,
            comparison: comparison,
            createdAt: Date()
        )
    }

    // MARK: - Core Calculation Engine

    private func projectCashFlow(months: Int, profile: UserFinancialProfile, parameters: ScenarioParameters?, transitionMonths: Int = 0, transitionCostPerMonth: Double = 0, extraPayment: Double = 0) -> FinancialProjection {
        var monthlyProjections: [FinancialProjection.MonthlyProjection] = []
        var currentNetWorth = profile.currentNetWorth
        var currentDebt = profile.totalDebt
        var currentInvestmentBalance = profile.investmentBalance
        var totalIncome = 0.0
        var totalExpenses = 0.0
        var totalSaved = 0.0
        var debtFreeDate: Date?

        let monthlyIncome = profile.monthlyIncome * (1 - profile.effectiveTaxRate)
        let baseMonthlyExpenses = profile.monthlyExpenses

        for month in 1...months {
            let date = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()

            // Income calculation
            var income = monthlyIncome
            if let params = parameters, let additionalIncome = params.additionalIncomeMonthly {
                income += additionalIncome
            }
            totalIncome += income

            // Expenses calculation
            var expenses = baseMonthlyExpenses
            if month <= transitionMonths {
                expenses += transitionCostPerMonth
            }
            if let params = parameters, let additionalExpenses = params.additionalMonthlyExpenses {
                expenses += additionalExpenses
            }
            totalExpenses += expenses

            // Savings and investment growth
            let monthlySavings = max(0, income - expenses)
            totalSaved += monthlySavings

            // Apply investment returns
            let monthlyReturn = profile.investmentReturnRate / 12
            currentInvestmentBalance *= (1 + monthlyReturn)
            currentInvestmentBalance += monthlySavings

            // Debt payoff
            if currentDebt > 0 {
                let debtPayment = min(extraPayment + (monthlySavings * 0.2), currentDebt) // Allocate 20% of savings to debt
                currentDebt = max(0, currentDebt - debtPayment)
                if currentDebt == 0 && debtFreeDate == nil {
                    debtFreeDate = date
                }
            }

            // Net worth update
            currentNetWorth = currentInvestmentBalance + profile.currentSavingsBalance - currentDebt

            monthlyProjections.append(
                FinancialProjection.MonthlyProjection(
                    month: month,
                    date: date,
                    income: income,
                    expenses: expenses,
                    savings: monthlySavings,
                    netWorth: currentNetWorth,
                    debtRemaining: currentDebt,
                    investmentBalance: currentInvestmentBalance
                )
            )
        }

        let yearsToRetirement: Double? = profile.retirementAgeGoal > profile.currentAge ? Double(profile.retirementAgeGoal - profile.currentAge) : nil

        let summary = FinancialProjection.ProjectionSummary(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            totalSaved: totalSaved,
            finalNetWorth: currentNetWorth,
            averageMonthlySavings: totalSaved / Double(months),
            yearsToRetirement: yearsToRetirement,
            debtFreeDate: debtFreeDate
        )

        return FinancialProjection(months: monthlyProjections, summary: summary)
    }

    private func compareProjections(baseline: FinancialProjection, scenario: FinancialProjection, scenarioType: LifeScenario.ScenarioType) -> ProjectionComparison {
        let netWorthDifference = scenario.summary.finalNetWorth - baseline.summary.finalNetWorth
        let totalSavingsDifference = scenario.summary.totalSaved - baseline.summary.totalSaved
        let monthlyExpenseDifference = (scenario.summary.totalExpenses - baseline.summary.totalExpenses) / Double(scenario.months.count)

        // Calculate retirement date difference if available
        var retirementDateDifference: Int?
        if let baselineRetirement = baseline.summary.yearsToRetirement,
           let scenarioRetirement = scenario.summary.yearsToRetirement {
            retirementDateDifference = Int((baselineRetirement - scenarioRetirement) * 12)
        }

        // Generate pros and cons based on scenario type
        let (pros, cons) = generateProsAndCons(for: scenarioType, netWorthDifference: netWorthDifference, expenseDifference: monthlyExpenseDifference)

        // Generate recommendation
        let recommendation = generateRecommendation(for: scenarioType, netWorthDifference: netWorthDifference, savingsDifference: totalSavingsDifference)

        return ProjectionComparison(
            netWorthDifference: netWorthDifference,
            totalSavingsDifference: totalSavingsDifference,
            monthlyExpenseDifference: monthlyExpenseDifference,
            retirementDateDifference: retirementDateDifference,
            debtFreeDateDifference: scenario.summary.debtFreeDate != nil && baseline.summary.debtFreeDate == nil ? 1 : nil,
            opportunityCost: netWorthDifference < 0 ? abs(netWorthDifference) : 0,
            breakEvenMonths: netWorthDifference < 0 ? calculateBreakEvenMonths(baseline: baseline, scenario: scenario) : nil,
            recommendation: recommendation,
            prosAndCons: ProjectionComparison.ProsAndCons(pros: pros, cons: cons)
        )
    }

    private func generateProsAndCons(for type: LifeScenario.ScenarioType, netWorthDifference: Double, expenseDifference: Double) -> ([String], [String]) {
        var pros: [String] = []
        var cons: [String] = []

        switch type {
        case .moveToCity:
            if netWorthDifference > 0 {
                pros.append("Higher income potential in new location")
            } else {
                cons.append("Higher cost of living may reduce savings")
            }
            if expenseDifference > 0 {
                cons.append("Monthly expenses increase by $\(Int(abs(expenseDifference)))")
            } else {
                pros.append("More affordable cost of living")
            }

        case .careerChange:
            if netWorthDifference > 0 {
                pros.append("Significantly higher future earnings")
                pros.append("Better career growth potential")
            } else {
                cons.append("Short-term financial impact during transition")
            }

        case .havingChild:
            cons.append("Increased monthly expenses for childcare")
            cons.append("Reduced savings capacity")
            pros.append("Long-term family wealth building benefits")

        case .buyingHome:
            if netWorthDifference > 0 {
                pros.append("Building equity through homeownership")
                pros.append("Potential property appreciation")
            } else {
                cons.append("High initial costs and monthly payments")
            }

        case .payingOffDebt:
            if netWorthDifference > 0 {
                pros.append("Debt-free status improves financial health")
                pros.append("Saves money on interest payments")
            }
            cons.append("Requires aggressive savings discipline")

        default:
            if netWorthDifference > 0 {
                pros.append("Positive long-term financial impact")
            } else {
                cons.append("May temporarily reduce net worth")
            }
        }

        return (pros, cons)
    }

    private func generateRecommendation(for type: LifeScenario.ScenarioType, netWorthDifference: Double, savingsDifference: Double) -> String {
        if netWorthDifference > 100000 {
            return "This scenario looks very promising financially. Consider moving forward with detailed planning."
        } else if netWorthDifference > 0 {
            return "This scenario shows positive financial outcomes. It's worth serious consideration."
        } else if netWorthDifference > -50000 {
            return "While this scenario reduces net worth in the short term, the non-financial benefits may justify it."
        } else {
            return "This scenario has significant financial costs. Explore alternatives or ways to offset the impact."
        }
    }

    private func calculateBreakEvenMonths(baseline: FinancialProjection, scenario: FinancialProjection) -> Int? {
        for (index, month) in scenario.months.enumerated() {
            if index < baseline.months.count {
                let baselineMonth = baseline.months[index]
                if month.netWorth >= baselineMonth.netWorth {
                    return index
                }
            }
        }
        return nil
    }

    // MARK: - Persistence

    func loadScenarios() {
        if let data = defaults.data(forKey: "SavedLifeScenarios"),
           let scenarios = try? JSONDecoder().decode([LifeScenario].self, from: data) {
            DispatchQueue.main.async {
                self.savedScenarios = scenarios
            }
        }
    }

    func saveScenarios() {
        if let encoded = try? JSONEncoder().encode(savedScenarios) {
            defaults.set(encoded, forKey: "SavedLifeScenarios")
        }
    }

    func deleteScenario(_ scenario: LifeScenario) {
        savedScenarios.removeAll { $0.id == scenario.id }
        saveScenarios()
    }

    func addScenario(_ scenario: LifeScenario) {
        savedScenarios.append(scenario)
        saveScenarios()
    }
}

// MARK: - Stub Extensions

extension LifeScenario {
    static func stub() -> LifeScenario {
        LifeScenario(
            id: UUID().uuidString,
            type: .moveToCity,
            title: "Scenario",
            description: "A life scenario",
            parameters: ScenarioParameters(),
            baselineProjection: .stub(),
            scenarioProjection: .stub(),
            comparison: .stub(),
            createdAt: Date()
        )
    }
}

extension FinancialProjection {
    static func stub() -> FinancialProjection {
        FinancialProjection(
            months: [],
            summary: FinancialProjection.ProjectionSummary(
                totalIncome: 0,
                totalExpenses: 0,
                totalSaved: 0,
                finalNetWorth: 0,
                averageMonthlySavings: 0,
                yearsToRetirement: nil,
                debtFreeDate: nil
            )
        )
    }
}

extension ProjectionComparison {
    static func stub() -> ProjectionComparison {
        ProjectionComparison(
            netWorthDifference: 0,
            totalSavingsDifference: 0,
            monthlyExpenseDifference: 0,
            retirementDateDifference: nil,
            debtFreeDateDifference: nil,
            opportunityCost: 0,
            breakEvenMonths: nil,
            recommendation: "Analyze your scenarios",
            prosAndCons: ProjectionComparison.ProsAndCons(pros: [], cons: [])
        )
    }
}
