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

// MARK: - Life Simulator Stub

class LifeSimulator: ObservableObject {
    static let shared = LifeSimulator()

    @Published var currentScenario: LifeScenario?
    @Published var savedScenarios: [LifeScenario] = []
    @Published var isSimulating = false

    init() {
        // TODO: Implement LifeSimulator initialization with proper UserFinancialProfile
    }

    func updateProfile(_ profile: UserFinancialProfile) {
        // TODO: Implement profile update
    }

    func simulateMoveToCity(_ cityName: String, timeHorizonYears: Int = 10) -> LifeScenario {
        // TODO: Implement city move simulation
        return .stub()
    }

    func simulateCareerChange(newSalary: Double, transitionCostMonths: Int = 3, timeHorizonYears: Int = 10) -> LifeScenario {
        // TODO: Implement career change simulation
        return .stub()
    }

    func simulateHavingChild(childcareCostMonthly: Double, timeHorizonYears: Int = 10) -> LifeScenario {
        // TODO: Implement having child simulation
        return .stub()
    }

    func simulateBuyingHome(homePrice: Double, downPaymentPercent: Double = 20, mortgageYears: Int = 30, timeHorizonYears: Int = 10) -> LifeScenario {
        // TODO: Implement home buying simulation
        return .stub()
    }

    func simulatePayingOffDebt(targetDebtAmount: Double, monthlyPaymentGoal: Double, timeHorizonYears: Int = 5) -> LifeScenario {
        // TODO: Implement debt payoff simulation
        return .stub()
    }

    func simulateGenericScenario(type: LifeScenario.ScenarioType, description: String) -> LifeScenario {
        // TODO: Implement generic scenario simulation
        return .stub()
    }

    func loadScenarios() {
        // TODO: Implement scenario loading
    }

    func saveScenarios() {
        // TODO: Implement scenario saving
    }

    func deleteScenario(_ scenario: LifeScenario) {
        savedScenarios.removeAll { $0.id == scenario.id }
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
