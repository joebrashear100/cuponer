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

struct UserFinancialProfile: Codable {
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var currentSavings: Double
    var currentInvestments: Double
    var currentDebt: Double
    var debtInterestRate: Double
    var currentRent: Double
    var currentCity: String
    var age: Int
    var targetRetirementAge: Int
    var savingsRate: Double
    var investmentReturnRate: Double

    static var `default`: UserFinancialProfile {
        UserFinancialProfile(
            monthlyIncome: 6000,
            monthlyExpenses: 4000,
            currentSavings: 20000,
            currentInvestments: 50000,
            currentDebt: 10000,
            debtInterestRate: 0.07,
            currentRent: 1500,
            currentCity: "Current City",
            age: 30,
            targetRetirementAge: 65,
            savingsRate: 0.15,
            investmentReturnRate: 0.07
        )
    }
}

// MARK: - Cost of Living Data

struct CityData: Codable {
    let name: String
    let costOfLivingIndex: Double // 100 = national average
    let averageRent: Double
    let averageSalaryMultiplier: Double
    let stateTaxRate: Double
}

// MARK: - Life Simulator

class LifeSimulator: ObservableObject {
    static let shared = LifeSimulator()

    // MARK: - Published Properties
    @Published var userProfile: UserFinancialProfile
    @Published var savedScenarios: [LifeScenario] = []
    @Published var currentScenario: LifeScenario?

    @Published var isSimulating = false
    @Published var simulationProgress: Double = 0

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let profileKey = "lifeSimulator_profile"
    private let scenariosKey = "lifeSimulator_scenarios"

    // City cost of living data (simplified)
    private let cityData: [String: CityData] = [
        "New York": CityData(name: "New York", costOfLivingIndex: 187, averageRent: 3500, averageSalaryMultiplier: 1.25, stateTaxRate: 0.0685),
        "San Francisco": CityData(name: "San Francisco", costOfLivingIndex: 179, averageRent: 3200, averageSalaryMultiplier: 1.30, stateTaxRate: 0.093),
        "Los Angeles": CityData(name: "Los Angeles", costOfLivingIndex: 166, averageRent: 2500, averageSalaryMultiplier: 1.15, stateTaxRate: 0.093),
        "Seattle": CityData(name: "Seattle", costOfLivingIndex: 158, averageRent: 2200, averageSalaryMultiplier: 1.20, stateTaxRate: 0),
        "Denver": CityData(name: "Denver", costOfLivingIndex: 128, averageRent: 1800, averageSalaryMultiplier: 1.05, stateTaxRate: 0.0455),
        "Austin": CityData(name: "Austin", costOfLivingIndex: 115, averageRent: 1600, averageSalaryMultiplier: 1.00, stateTaxRate: 0),
        "Chicago": CityData(name: "Chicago", costOfLivingIndex: 107, averageRent: 1700, averageSalaryMultiplier: 1.05, stateTaxRate: 0.0495),
        "Miami": CityData(name: "Miami", costOfLivingIndex: 123, averageRent: 2000, averageSalaryMultiplier: 0.95, stateTaxRate: 0),
        "Phoenix": CityData(name: "Phoenix", costOfLivingIndex: 103, averageRent: 1400, averageSalaryMultiplier: 0.90, stateTaxRate: 0.025),
        "Nashville": CityData(name: "Nashville", costOfLivingIndex: 104, averageRent: 1500, averageSalaryMultiplier: 0.95, stateTaxRate: 0),
        "Portland": CityData(name: "Portland", costOfLivingIndex: 130, averageRent: 1700, averageSalaryMultiplier: 1.00, stateTaxRate: 0.099),
        "Atlanta": CityData(name: "Atlanta", costOfLivingIndex: 102, averageRent: 1500, averageSalaryMultiplier: 0.95, stateTaxRate: 0.055),
        "National Average": CityData(name: "National Average", costOfLivingIndex: 100, averageRent: 1400, averageSalaryMultiplier: 1.0, stateTaxRate: 0.05)
    ]

    // MARK: - Initialization

    init() {
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserFinancialProfile.self, from: data) {
            self.userProfile = profile
        } else {
            self.userProfile = .default
        }

        loadScenarios()
    }

    // MARK: - Profile Management

    func updateProfile(_ profile: UserFinancialProfile) {
        userProfile = profile
        saveProfile()
    }

    // MARK: - Scenario Simulation

    func simulateMoveToCity(_ cityName: String, timeHorizonYears: Int = 10) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        guard let newCityData = cityData[cityName] else {
            return simulateGenericScenario(type: .moveToCity, description: "Move to \(cityName)")
        }

        let currentCityData = cityData["National Average"]!
        let costOfLivingChange = (newCityData.costOfLivingIndex - currentCityData.costOfLivingIndex) / 100.0

        let parameters = ScenarioParameters(
            newCity: cityName,
            costOfLivingChange: costOfLivingChange,
            newSalary: userProfile.monthlyIncome * 12 * newCityData.averageSalaryMultiplier,
            oneTimeCost: 5000, // Moving costs
            newRent: newCityData.averageRent,
            timeHorizonYears: timeHorizonYears
        )

        let baseline = projectBaseline(years: timeHorizonYears)
        let scenario = projectScenario(parameters: parameters, years: timeHorizonYears)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .moveToCity,
            title: "Move to \(cityName)",
            description: "What if you moved from \(userProfile.currentCity) to \(cityName)?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    func simulateCareerChange(newSalary: Double, transitionCostMonths: Int = 3, timeHorizonYears: Int = 10) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        let parameters = ScenarioParameters(
            newSalary: newSalary,
            incomeStartDate: Calendar.current.date(byAdding: .month, value: transitionCostMonths, to: Date()),
            additionalMonthlyExpenses: 0,
            oneTimeCost: userProfile.monthlyExpenses * Double(transitionCostMonths), // Transition period
            timeHorizonYears: timeHorizonYears
        )

        let baseline = projectBaseline(years: timeHorizonYears)
        let scenario = projectScenario(parameters: parameters, years: timeHorizonYears)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let salaryChange = ((newSalary / 12) - userProfile.monthlyIncome) / userProfile.monthlyIncome * 100

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .careerChange,
            title: "Career Change to $\(Int(newSalary / 1000))k/year",
            description: "What if you changed careers to earn \(salaryChange > 0 ? "\(Int(salaryChange))% more" : "\(Int(abs(salaryChange)))% less")?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    func simulateHavingChild(timeHorizonYears: Int = 18) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        // Average cost of raising a child: ~$300k over 18 years, ~$1400/month
        let parameters = ScenarioParameters(
            additionalMonthlyExpenses: 1400,
            oneTimeCost: 15000, // Initial baby costs
            timeHorizonYears: timeHorizonYears
        )

        let baseline = projectBaseline(years: timeHorizonYears)
        let scenario = projectScenario(parameters: parameters, years: timeHorizonYears)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .havingChild,
            title: "Having a Child",
            description: "What would be the financial impact of having a child?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    func simulateBuyingHome(homePrice: Double, downPaymentPercent: Double = 0.20, mortgageRate: Double = 0.07, timeHorizonYears: Int = 30) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        let downPayment = homePrice * downPaymentPercent
        let loanAmount = homePrice - downPayment
        let monthlyMortgage = calculateMortgagePayment(principal: loanAmount, rate: mortgageRate, years: 30)
        let propertyTax = homePrice * 0.012 / 12 // 1.2% annual
        let insurance = homePrice * 0.005 / 12 // 0.5% annual
        let maintenance = homePrice * 0.01 / 12 // 1% annual

        let totalMonthlyHousing = monthlyMortgage + propertyTax + insurance + maintenance
        let housingDifference = totalMonthlyHousing - userProfile.currentRent

        let parameters = ScenarioParameters(
            additionalMonthlyExpenses: housingDifference,
            oneTimeCost: downPayment + (homePrice * 0.03), // Down payment + closing costs
            homePrice: homePrice,
            downPaymentPercent: downPaymentPercent,
            mortgageRate: mortgageRate,
            propertyTax: propertyTax,
            timeHorizonYears: timeHorizonYears
        )

        let baseline = projectBaseline(years: timeHorizonYears)
        let scenario = projectScenario(parameters: parameters, years: timeHorizonYears)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .buyingHome,
            title: "Buy a $\(Int(homePrice / 1000))k Home",
            description: "What if you bought a home for $\(Int(homePrice / 1000))k?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    func simulateEarlyRetirement(targetAge: Int, timeHorizonYears: Int? = nil) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        let yearsToRetirement = targetAge - userProfile.age
        let horizon = timeHorizonYears ?? max(yearsToRetirement + 30, 40)

        // Calculate required savings rate for early retirement
        let requiredSavingsRate = calculateRequiredSavingsRate(
            currentAge: userProfile.age,
            retirementAge: targetAge,
            currentSavings: userProfile.currentSavings + userProfile.currentInvestments,
            monthlyIncome: userProfile.monthlyIncome,
            monthlyExpenses: userProfile.monthlyExpenses
        )

        let parameters = ScenarioParameters(
            newSavingsRate: requiredSavingsRate,
            retirementAge: targetAge,
            timeHorizonYears: horizon
        )

        let baseline = projectBaseline(years: horizon)
        let scenario = projectScenario(parameters: parameters, years: horizon)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .earlyRetirement,
            title: "Retire at \(targetAge)",
            description: "What if you retired at \(targetAge) instead of \(userProfile.targetRetirementAge)?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    func simulateIncreasedSavings(newSavingsRate: Double, timeHorizonYears: Int = 20) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        let additionalMonthlySavings = userProfile.monthlyIncome * (newSavingsRate - userProfile.savingsRate)

        let parameters = ScenarioParameters(
            reducedMonthlyExpenses: additionalMonthlySavings,
            newSavingsRate: newSavingsRate,
            timeHorizonYears: timeHorizonYears
        )

        let baseline = projectBaseline(years: timeHorizonYears)
        let scenario = projectScenario(parameters: parameters, years: timeHorizonYears)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .increaseSavings,
            title: "Save \(Int(newSavingsRate * 100))% of Income",
            description: "What if you saved \(Int(newSavingsRate * 100))% instead of \(Int(userProfile.savingsRate * 100))%?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    func simulatePayingOffDebt(extraMonthlyPayment: Double, timeHorizonYears: Int = 10) -> LifeScenario {
        isSimulating = true
        defer { isSimulating = false }

        let parameters = ScenarioParameters(
            debtAmount: userProfile.currentDebt,
            monthlyPayment: extraMonthlyPayment,
            interestRate: userProfile.debtInterestRate,
            timeHorizonYears: timeHorizonYears
        )

        let baseline = projectBaseline(years: timeHorizonYears)
        let scenario = projectScenario(parameters: parameters, years: timeHorizonYears)
        let comparison = compareProjections(baseline: baseline, scenario: scenario, parameters: parameters)

        let lifeScenario = LifeScenario(
            id: UUID().uuidString,
            type: .payingOffDebt,
            title: "Pay Extra $\(Int(extraMonthlyPayment))/mo on Debt",
            description: "What if you paid an extra $\(Int(extraMonthlyPayment)) per month toward debt?",
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: scenario,
            comparison: comparison,
            createdAt: Date()
        )

        savedScenarios.insert(lifeScenario, at: 0)
        currentScenario = lifeScenario
        saveScenarios()

        return lifeScenario
    }

    // MARK: - Projection Calculations

    private func projectBaseline(years: Int) -> FinancialProjection {
        var months: [FinancialProjection.MonthlyProjection] = []
        var currentSavings = userProfile.currentSavings
        var currentInvestments = userProfile.currentInvestments
        var currentDebt = userProfile.currentDebt
        let monthlyReturn = userProfile.investmentReturnRate / 12

        for month in 0..<(years * 12) {
            let date = Calendar.current.date(byAdding: .month, value: month, to: Date())!
            let monthlySavings = userProfile.monthlyIncome - userProfile.monthlyExpenses

            // Update balances
            currentSavings += monthlySavings * (1 - userProfile.savingsRate)
            currentInvestments = currentInvestments * (1 + monthlyReturn) + monthlySavings * userProfile.savingsRate

            // Minimum debt payment
            let debtPayment = min(userProfile.currentDebt * 0.02, currentDebt)
            currentDebt = max(0, currentDebt * (1 + userProfile.debtInterestRate / 12) - debtPayment)

            let netWorth = currentSavings + currentInvestments - currentDebt

            months.append(FinancialProjection.MonthlyProjection(
                month: month,
                date: date,
                income: userProfile.monthlyIncome,
                expenses: userProfile.monthlyExpenses,
                savings: monthlySavings,
                netWorth: netWorth,
                debtRemaining: currentDebt,
                investmentBalance: currentInvestments
            ))
        }

        let totalMonths = Double(years * 12)
        let summary = FinancialProjection.ProjectionSummary(
            totalIncome: userProfile.monthlyIncome * totalMonths,
            totalExpenses: userProfile.monthlyExpenses * totalMonths,
            totalSaved: months.reduce(0) { $0 + $1.savings },
            finalNetWorth: months.last?.netWorth ?? 0,
            averageMonthlySavings: userProfile.monthlyIncome - userProfile.monthlyExpenses,
            yearsToRetirement: calculateYearsToRetirement(targetNetWorth: userProfile.monthlyExpenses * 12 * 25),
            debtFreeDate: calculateDebtFreeDate(debt: userProfile.currentDebt, rate: userProfile.debtInterestRate, payment: userProfile.currentDebt * 0.02)
        )

        return FinancialProjection(months: months, summary: summary)
    }

    private func projectScenario(parameters: ScenarioParameters, years: Int) -> FinancialProjection {
        var months: [FinancialProjection.MonthlyProjection] = []
        var currentSavings = userProfile.currentSavings - (parameters.oneTimeCost ?? 0)
        var currentInvestments = userProfile.currentInvestments
        var currentDebt = userProfile.currentDebt
        let monthlyReturn = (parameters.investmentReturn ?? userProfile.investmentReturnRate) / 12
        let savingsRate = parameters.newSavingsRate ?? userProfile.savingsRate

        let newMonthlyIncome = parameters.newSalary.map { $0 / 12 } ?? userProfile.monthlyIncome
        let expenseChange = (parameters.additionalMonthlyExpenses ?? 0) - (parameters.reducedMonthlyExpenses ?? 0)
        let newMonthlyExpenses = userProfile.monthlyExpenses + expenseChange

        // Adjust for cost of living if moving
        let adjustedExpenses: Double
        if let colChange = parameters.costOfLivingChange {
            adjustedExpenses = newMonthlyExpenses * (1 + colChange)
        } else {
            adjustedExpenses = newMonthlyExpenses
        }

        for month in 0..<(years * 12) {
            let date = Calendar.current.date(byAdding: .month, value: month, to: Date())!

            // Check if income has started (for career transition scenarios)
            let effectiveIncome: Double
            if let startDate = parameters.incomeStartDate, date < startDate {
                effectiveIncome = 0 // No income during transition
            } else {
                effectiveIncome = newMonthlyIncome
            }

            let monthlySavings = effectiveIncome - adjustedExpenses

            // Update balances
            currentSavings += monthlySavings * (1 - savingsRate)
            currentInvestments = currentInvestments * (1 + monthlyReturn) + max(0, monthlySavings * savingsRate)

            // Debt payment (with extra payment if specified)
            let extraPayment = parameters.monthlyPayment ?? 0
            let totalDebtPayment = min(userProfile.currentDebt * 0.02 + extraPayment, currentDebt)
            currentDebt = max(0, currentDebt * (1 + userProfile.debtInterestRate / 12) - totalDebtPayment)

            let netWorth = currentSavings + currentInvestments - currentDebt

            months.append(FinancialProjection.MonthlyProjection(
                month: month,
                date: date,
                income: effectiveIncome,
                expenses: adjustedExpenses,
                savings: monthlySavings,
                netWorth: netWorth,
                debtRemaining: currentDebt,
                investmentBalance: currentInvestments
            ))
        }

        let totalMonths = Double(years * 12)
        let avgSavings = months.reduce(0) { $0 + $1.savings } / totalMonths

        let summary = FinancialProjection.ProjectionSummary(
            totalIncome: months.reduce(0) { $0 + $1.income },
            totalExpenses: months.reduce(0) { $0 + $1.expenses },
            totalSaved: months.reduce(0) { $0 + $1.savings },
            finalNetWorth: months.last?.netWorth ?? 0,
            averageMonthlySavings: avgSavings,
            yearsToRetirement: calculateYearsToRetirement(targetNetWorth: adjustedExpenses * 12 * 25),
            debtFreeDate: months.first { $0.debtRemaining <= 0 }?.date
        )

        return FinancialProjection(months: months, summary: summary)
    }

    private func compareProjections(baseline: FinancialProjection, scenario: FinancialProjection, parameters: ScenarioParameters) -> ProjectionComparison {
        let netWorthDiff = scenario.summary.finalNetWorth - baseline.summary.finalNetWorth
        let savingsDiff = scenario.summary.totalSaved - baseline.summary.totalSaved
        let expenseDiff = (scenario.summary.totalExpenses / Double(scenario.months.count)) -
                          (baseline.summary.totalExpenses / Double(baseline.months.count))

        // Calculate break-even
        var breakEvenMonth: Int? = nil
        for i in 0..<min(baseline.months.count, scenario.months.count) {
            if scenario.months[i].netWorth >= baseline.months[i].netWorth && i > 0 {
                breakEvenMonth = i
                break
            }
        }

        // Generate pros and cons
        var pros: [String] = []
        var cons: [String] = []

        if netWorthDiff > 0 {
            pros.append("Increases net worth by $\(formatCurrency(netWorthDiff))")
        } else if netWorthDiff < 0 {
            cons.append("Decreases net worth by $\(formatCurrency(abs(netWorthDiff)))")
        }

        if savingsDiff > 0 {
            pros.append("Saves $\(formatCurrency(savingsDiff)) more over the period")
        } else if savingsDiff < 0 {
            cons.append("Saves $\(formatCurrency(abs(savingsDiff))) less over the period")
        }

        if let oneTimeCost = parameters.oneTimeCost, oneTimeCost > 0 {
            cons.append("Requires upfront cost of $\(formatCurrency(oneTimeCost))")
        }

        if let breakEven = breakEvenMonth {
            pros.append("Breaks even in \(breakEven) months")
        }

        // Generate recommendation
        let recommendation: String
        if netWorthDiff > 0 && (breakEvenMonth ?? Int.max) < 24 {
            recommendation = "This scenario appears financially favorable with a reasonable break-even period."
        } else if netWorthDiff > 0 {
            recommendation = "Long-term financial gains, but consider if you can handle the initial impact."
        } else if netWorthDiff < 0 && abs(netWorthDiff) < baseline.summary.finalNetWorth * 0.1 {
            recommendation = "Minor financial impact. Consider non-financial benefits when deciding."
        } else {
            recommendation = "Significant financial impact. Carefully weigh the trade-offs."
        }

        return ProjectionComparison(
            netWorthDifference: netWorthDiff,
            totalSavingsDifference: savingsDiff,
            monthlyExpenseDifference: expenseDiff,
            retirementDateDifference: nil,
            debtFreeDateDifference: nil,
            opportunityCost: max(0, -savingsDiff),
            breakEvenMonths: breakEvenMonth,
            recommendation: recommendation,
            prosAndCons: ProjectionComparison.ProsAndCons(pros: pros, cons: cons)
        )
    }

    // MARK: - Helper Calculations

    private func calculateMortgagePayment(principal: Double, rate: Double, years: Int) -> Double {
        let monthlyRate = rate / 12
        let numPayments = Double(years * 12)
        let payment = principal * (monthlyRate * pow(1 + monthlyRate, numPayments)) / (pow(1 + monthlyRate, numPayments) - 1)
        return payment
    }

    private func calculateYearsToRetirement(targetNetWorth: Double) -> Double {
        let monthlySavings = userProfile.monthlyIncome - userProfile.monthlyExpenses
        let currentNetWorth = userProfile.currentSavings + userProfile.currentInvestments - userProfile.currentDebt
        let monthlyReturn = userProfile.investmentReturnRate / 12

        var netWorth = currentNetWorth
        var months = 0

        while netWorth < targetNetWorth && months < 600 {
            netWorth = netWorth * (1 + monthlyReturn) + monthlySavings * userProfile.savingsRate
            months += 1
        }

        return Double(months) / 12.0
    }

    private func calculateDebtFreeDate(debt: Double, rate: Double, payment: Double) -> Date? {
        guard debt > 0 && payment > 0 else { return nil }

        var remaining = debt
        var months = 0

        while remaining > 0 && months < 600 {
            remaining = remaining * (1 + rate / 12) - payment
            months += 1
        }

        return Calendar.current.date(byAdding: .month, value: months, to: Date())
    }

    private func calculateRequiredSavingsRate(currentAge: Int, retirementAge: Int, currentSavings: Double, monthlyIncome: Double, monthlyExpenses: Double) -> Double {
        let yearsToRetirement = retirementAge - currentAge
        let targetNetWorth = monthlyExpenses * 12 * 25 // 4% rule

        // Simple approximation - in production would use more sophisticated calculation
        let futureValue = currentSavings * pow(1 + userProfile.investmentReturnRate, Double(yearsToRetirement))
        let needed = targetNetWorth - futureValue

        let monthlyContributionNeeded = needed / (((pow(1 + userProfile.investmentReturnRate / 12, Double(yearsToRetirement * 12)) - 1) / (userProfile.investmentReturnRate / 12)))

        return min(monthlyContributionNeeded / monthlyIncome, 0.8)
    }

    private func simulateGenericScenario(type: LifeScenario.ScenarioType, description: String) -> LifeScenario {
        let parameters = ScenarioParameters(timeHorizonYears: 10)
        let baseline = projectBaseline(years: 10)

        return LifeScenario(
            id: UUID().uuidString,
            type: type,
            title: type.rawValue,
            description: description,
            parameters: parameters,
            baselineProjection: baseline,
            scenarioProjection: baseline,
            comparison: ProjectionComparison(
                netWorthDifference: 0,
                totalSavingsDifference: 0,
                monthlyExpenseDifference: 0,
                retirementDateDifference: nil,
                debtFreeDateDifference: nil,
                opportunityCost: 0,
                breakEvenMonths: nil,
                recommendation: "Unable to simulate. Please provide more details.",
                prosAndCons: ProjectionComparison.ProsAndCons(pros: [], cons: [])
            ),
            createdAt: Date()
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "\(Int(abs(amount)))"
    }

    // MARK: - Persistence

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }

    private func loadScenarios() {
        if let data = userDefaults.data(forKey: scenariosKey),
           let scenarios = try? JSONDecoder().decode([LifeScenario].self, from: data) {
            savedScenarios = scenarios
        }
    }

    private func saveScenarios() {
        if let data = try? JSONEncoder().encode(savedScenarios) {
            userDefaults.set(data, forKey: scenariosKey)
        }
    }

    func deleteScenario(_ id: String) {
        savedScenarios.removeAll { $0.id == id }
        saveScenarios()
    }

    func getAvailableCities() -> [String] {
        return Array(cityData.keys).sorted()
    }
}
