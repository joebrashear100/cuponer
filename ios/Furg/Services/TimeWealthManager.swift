import Foundation
import Combine

// MARK: - Time Wealth Models

struct TimeWealthProfile: Codable {
    var hourlyRate: Double
    var workHoursPerWeek: Double
    var annualIncome: Double
    var effectiveHourlyRate: Double // After taxes, commute, etc.
    var incomeSource: IncomeSource
    var taxRate: Double
    var commuteHoursPerWeek: Double
    var workRelatedExpensesPerMonth: Double

    enum IncomeSource: String, Codable, CaseIterable {
        case salary
        case hourly
        case freelance
        case business
        case mixed

        var description: String {
            switch self {
            case .salary: return "Salaried Employee"
            case .hourly: return "Hourly Worker"
            case .freelance: return "Freelancer"
            case .business: return "Business Owner"
            case .mixed: return "Multiple Sources"
            }
        }
    }

    var trueHourlyRate: Double {
        // Calculate true hourly rate accounting for:
        // 1. Taxes
        // 2. Commute time
        // 3. Work-related expenses (clothes, lunch, equipment)
        let afterTaxRate = hourlyRate * (1 - taxRate)
        let totalWorkHours = workHoursPerWeek + commuteHoursPerWeek
        let weeklyIncome = hourlyRate * workHoursPerWeek * (1 - taxRate) - (workRelatedExpensesPerMonth / 4.33)
        return max(1, weeklyIncome / totalWorkHours)
    }

    static var `default`: TimeWealthProfile {
        TimeWealthProfile(
            hourlyRate: 35,
            workHoursPerWeek: 40,
            annualIncome: 72800,
            effectiveHourlyRate: 25,
            incomeSource: .salary,
            taxRate: 0.25,
            commuteHoursPerWeek: 5,
            workRelatedExpensesPerMonth: 200
        )
    }
}

struct TimeWealthTransaction: Identifiable, Codable {
    let id: String
    let originalTransactionId: String
    let merchantName: String
    let category: String
    let amount: Double
    let hoursOfLife: Double
    let minutesOfLife: Int
    let date: Date
    let isEssential: Bool
    let alternativeSavings: Double? // If there's a cheaper alternative

    var formattedTime: String {
        if hoursOfLife >= 1 {
            let hours = Int(hoursOfLife)
            let minutes = Int((hoursOfLife - Double(hours)) * 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutesOfLife) minute\(minutesOfLife == 1 ? "" : "s")"
        }
    }
}

struct TimeWealthSummary: Codable {
    let period: TimePeriod
    let totalSpent: Double
    let totalHoursWorked: Double
    let essentialHours: Double
    let discretionaryHours: Double
    let topTimeConsumers: [CategoryTimeConsumption]
    let insights: [TimeWealthInsight]
    let comparisonToPrevious: Double? // Percentage change

    enum TimePeriod: String, Codable {
        case day, week, month, year
    }

    struct CategoryTimeConsumption: Identifiable, Codable {
        var id: String { category }
        let category: String
        let totalAmount: Double
        let hoursOfLife: Double
        let percentageOfTotal: Double
        let transactionCount: Int
    }

    struct TimeWealthInsight: Identifiable, Codable {
        let id: String
        let type: InsightType
        let title: String
        let message: String
        let hoursImpacted: Double
        let suggestion: String?

        enum InsightType: String, Codable {
            case warning, opportunity, achievement, comparison
        }
    }
}

struct LifeTimeAllocation: Codable {
    let totalWakingHoursPerYear: Double // ~5840 hours (16 hrs/day * 365)
    let workHoursPerYear: Double
    let commuteHoursPerYear: Double
    let sleepHoursPerYear: Double
    let freeHoursPerYear: Double

    let hoursSpentEarningForEssentials: Double
    let hoursSpentEarningForDiscretionary: Double
    let hoursWorkedToPayTaxes: Double

    var workLifeBalance: Double {
        freeHoursPerYear / (workHoursPerYear + commuteHoursPerYear)
    }

    var essentialsRatio: Double {
        hoursSpentEarningForEssentials / workHoursPerYear
    }
}

// MARK: - Time Wealth Manager

class TimeWealthManager: ObservableObject {
    static let shared = TimeWealthManager()

    // MARK: - Published Properties
    @Published var profile: TimeWealthProfile
    @Published var recentTransactions: [TimeWealthTransaction] = []
    @Published var dailySummary: TimeWealthSummary?
    @Published var weeklySummary: TimeWealthSummary?
    @Published var monthlySummary: TimeWealthSummary?
    @Published var lifeTimeAllocation: LifeTimeAllocation?

    @Published var todayHoursSpent: Double = 0
    @Published var weekHoursSpent: Double = 0
    @Published var monthHoursSpent: Double = 0

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let profileKey = "timeWealth_profile"
    private let transactionsKey = "timeWealth_transactions"

    private let essentialCategories = [
        "Groceries", "Utilities", "Rent", "Mortgage", "Insurance",
        "Healthcare", "Medical", "Gas", "Transportation", "Childcare"
    ]

    // MARK: - Initialization

    init() {
        if let data = userDefaults.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(TimeWealthProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = .default
        }

        loadTransactions()
        calculateSummaries()
    }

    // MARK: - Profile Management

    func updateProfile(_ newProfile: TimeWealthProfile) {
        var updatedProfile = newProfile

        // Calculate derived values
        if newProfile.incomeSource == .salary {
            updatedProfile.hourlyRate = newProfile.annualIncome / (newProfile.workHoursPerWeek * 52)
        } else {
            updatedProfile.annualIncome = newProfile.hourlyRate * newProfile.workHoursPerWeek * 52
        }

        updatedProfile.effectiveHourlyRate = updatedProfile.trueHourlyRate

        profile = updatedProfile
        saveProfile()

        // Recalculate all transactions with new rate
        recalculateAllTransactions()
        calculateSummaries()
    }

    func setupFromIncome(annualIncome: Double, workHoursPerWeek: Double = 40, taxRate: Double = 0.25) {
        let hourlyRate = annualIncome / (workHoursPerWeek * 52)

        var newProfile = TimeWealthProfile(
            hourlyRate: hourlyRate,
            workHoursPerWeek: workHoursPerWeek,
            annualIncome: annualIncome,
            effectiveHourlyRate: hourlyRate * (1 - taxRate),
            incomeSource: .salary,
            taxRate: taxRate,
            commuteHoursPerWeek: 5,
            workRelatedExpensesPerMonth: 200
        )

        newProfile.effectiveHourlyRate = newProfile.trueHourlyRate
        profile = newProfile
        saveProfile()

        recalculateAllTransactions()
        calculateSummaries()
    }

    // MARK: - Transaction Conversion

    func convertToTimeWealth(amount: Double, merchantName: String, category: String, transactionId: String, date: Date) -> TimeWealthTransaction {
        let hoursOfLife = amount / profile.trueHourlyRate
        let minutesOfLife = Int(hoursOfLife * 60)
        let isEssential = essentialCategories.contains { category.lowercased().contains($0.lowercased()) }

        let transaction = TimeWealthTransaction(
            id: UUID().uuidString,
            originalTransactionId: transactionId,
            merchantName: merchantName,
            category: category,
            amount: amount,
            hoursOfLife: hoursOfLife,
            minutesOfLife: minutesOfLife,
            date: date,
            isEssential: isEssential,
            alternativeSavings: nil
        )

        return transaction
    }

    func addTransaction(_ transaction: TimeWealthTransaction) {
        recentTransactions.insert(transaction, at: 0)

        // Keep only last 500 transactions in memory
        if recentTransactions.count > 500 {
            recentTransactions = Array(recentTransactions.prefix(500))
        }

        saveTransactions()
        updateTodayStats()
        calculateSummaries()
    }

    func processTransactions(_ transactions: [(amount: Double, merchant: String, category: String, id: String, date: Date)]) {
        for t in transactions {
            let timeTransaction = convertToTimeWealth(
                amount: t.amount,
                merchantName: t.merchant,
                category: t.category,
                transactionId: t.id,
                date: t.date
            )
            addTransaction(timeTransaction)
        }
    }

    // MARK: - Quick Calculations

    func hoursForAmount(_ amount: Double) -> Double {
        return amount / profile.trueHourlyRate
    }

    func minutesForAmount(_ amount: Double) -> Int {
        return Int((amount / profile.trueHourlyRate) * 60)
    }

    func amountForHours(_ hours: Double) -> Double {
        return hours * profile.trueHourlyRate
    }

    func formatTimeForAmount(_ amount: Double) -> String {
        let hours = hoursForAmount(amount)
        if hours >= 1 {
            let wholeHours = Int(hours)
            let minutes = Int((hours - Double(wholeHours)) * 60)
            if minutes > 0 {
                return "\(wholeHours)h \(minutes)m"
            }
            return "\(wholeHours) hour\(wholeHours == 1 ? "" : "s")"
        } else {
            let minutes = Int(hours * 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }

    func workDaysForAmount(_ amount: Double) -> Double {
        let hours = hoursForAmount(amount)
        return hours / 8.0
    }

    // MARK: - Perspective Calculations

    func getLifePerspective(for amount: Double) -> String {
        let hours = hoursForAmount(amount)

        if hours < 0.25 {
            return "About \(Int(hours * 60)) minutes of work"
        } else if hours < 1 {
            return "About \(Int(hours * 60)) minutes of your life"
        } else if hours < 8 {
            return String(format: "%.1f hours of work", hours)
        } else if hours < 40 {
            let days = hours / 8
            return String(format: "%.1f work days", days)
        } else if hours < 160 {
            let weeks = hours / 40
            return String(format: "%.1f work weeks", weeks)
        } else {
            let months = hours / 160
            return String(format: "%.1f work months", months)
        }
    }

    func getAlternativePerspective(for amount: Double) -> [String] {
        let hours = hoursForAmount(amount)
        var alternatives: [String] = []

        // Time-based alternatives
        if hours >= 2 {
            alternatives.append("Could watch \(Int(hours / 2)) movies instead")
        }
        if hours >= 1 {
            alternatives.append("Could read for \(Int(hours)) hour\(hours >= 2 ? "s" : "")")
        }
        if hours >= 0.5 {
            alternatives.append("Could take a \(Int(hours * 60))-minute nap")
        }

        // Money-based alternatives
        if amount >= 50 {
            alternatives.append("Could invest and have $\(Int(amount * 1.07 * 10)) in 10 years")
        }
        if amount >= 20 {
            alternatives.append("Could buy \(Int(amount / 5)) nice coffees")
        }
        if amount >= 100 {
            alternatives.append("Could add \(Int(amount / profile.trueHourlyRate)) hours to your freedom fund")
        }

        return alternatives
    }

    // MARK: - Summary Calculations

    private func calculateSummaries() {
        calculateDailySummary()
        calculateWeeklySummary()
        calculateMonthlySummary()
        calculateLifeTimeAllocation()
    }

    private func calculateDailySummary() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayTransactions = recentTransactions.filter { calendar.isDate($0.date, inSameDayAs: today) }

        dailySummary = createSummary(for: todayTransactions, period: .day)
        todayHoursSpent = todayTransactions.reduce(0) { $0 + $1.hoursOfLife }
    }

    private func calculateWeeklySummary() {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekTransactions = recentTransactions.filter { $0.date >= startOfWeek }

        weeklySummary = createSummary(for: weekTransactions, period: .week)
        weekHoursSpent = weekTransactions.reduce(0) { $0 + $1.hoursOfLife }
    }

    private func calculateMonthlySummary() {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let monthTransactions = recentTransactions.filter { $0.date >= startOfMonth }

        monthlySummary = createSummary(for: monthTransactions, period: .month)
        monthHoursSpent = monthTransactions.reduce(0) { $0 + $1.hoursOfLife }
    }

    private func createSummary(for transactions: [TimeWealthTransaction], period: TimeWealthSummary.TimePeriod) -> TimeWealthSummary {
        let totalSpent = transactions.reduce(0) { $0 + $1.amount }
        let totalHours = transactions.reduce(0) { $0 + $1.hoursOfLife }
        let essentialHours = transactions.filter { $0.isEssential }.reduce(0) { $0 + $1.hoursOfLife }
        let discretionaryHours = totalHours - essentialHours

        // Group by category
        var categoryTotals: [String: (amount: Double, hours: Double, count: Int)] = [:]
        for transaction in transactions {
            let current = categoryTotals[transaction.category] ?? (0, 0, 0)
            categoryTotals[transaction.category] = (
                current.amount + transaction.amount,
                current.hours + transaction.hoursOfLife,
                current.count + 1
            )
        }

        let topCategories = categoryTotals.map { category, data in
            TimeWealthSummary.CategoryTimeConsumption(
                category: category,
                totalAmount: data.amount,
                hoursOfLife: data.hours,
                percentageOfTotal: totalHours > 0 ? (data.hours / totalHours) * 100 : 0,
                transactionCount: data.count
            )
        }.sorted { $0.hoursOfLife > $1.hoursOfLife }

        // Generate insights
        var insights: [TimeWealthSummary.TimeWealthInsight] = []

        // High discretionary spending
        if discretionaryHours > essentialHours * 2 {
            insights.append(TimeWealthSummary.TimeWealthInsight(
                id: "high_discretionary",
                type: .warning,
                title: "High Discretionary Spending",
                message: "You're spending \(String(format: "%.1f", discretionaryHours)) hours on non-essentials vs \(String(format: "%.1f", essentialHours)) hours on essentials.",
                hoursImpacted: discretionaryHours - essentialHours,
                suggestion: "Consider if these purchases align with your values"
            ))
        }

        // Top time consumer
        if let topCategory = topCategories.first, topCategory.percentageOfTotal > 40 {
            insights.append(TimeWealthSummary.TimeWealthInsight(
                id: "top_consumer",
                type: .opportunity,
                title: "\(topCategory.category) is Your Top Time Consumer",
                message: "\(Int(topCategory.percentageOfTotal))% of your work time (\(String(format: "%.1f", topCategory.hoursOfLife)) hours) goes to \(topCategory.category).",
                hoursImpacted: topCategory.hoursOfLife,
                suggestion: "Look for ways to optimize this category"
            ))
        }

        // Achievement for low spending
        if totalHours < profile.workHoursPerWeek * 0.3 && period == .week {
            insights.append(TimeWealthSummary.TimeWealthInsight(
                id: "low_spending",
                type: .achievement,
                title: "Time Wealthy Week!",
                message: "You only spent \(String(format: "%.1f", totalHours)) hours worth this week - keeping over 70% of your earnings!",
                hoursImpacted: profile.workHoursPerWeek - totalHours,
                suggestion: nil
            ))
        }

        return TimeWealthSummary(
            period: period,
            totalSpent: totalSpent,
            totalHoursWorked: totalHours,
            essentialHours: essentialHours,
            discretionaryHours: discretionaryHours,
            topTimeConsumers: Array(topCategories.prefix(5)),
            insights: insights,
            comparisonToPrevious: nil
        )
    }

    private func calculateLifeTimeAllocation() {
        let workHoursPerYear = profile.workHoursPerWeek * 52
        let commuteHoursPerYear = profile.commuteHoursPerWeek * 52
        let sleepHoursPerYear = 8.0 * 365 // Assuming 8 hours sleep
        let totalWakingHours = 16.0 * 365 // 16 waking hours per day

        let freeHours = totalWakingHours - workHoursPerYear - commuteHoursPerYear

        // Calculate hours worked to pay for things
        let monthlyEssentials = 2500.0 // Estimate - could be calculated from actual spending
        let monthlyDiscretionary = 1000.0 // Estimate
        let annualTaxes = profile.annualIncome * profile.taxRate

        let hoursForEssentials = (monthlyEssentials * 12) / profile.trueHourlyRate
        let hoursForDiscretionary = (monthlyDiscretionary * 12) / profile.trueHourlyRate
        let hoursForTaxes = annualTaxes / profile.hourlyRate

        lifeTimeAllocation = LifeTimeAllocation(
            totalWakingHoursPerYear: totalWakingHours,
            workHoursPerYear: workHoursPerYear,
            commuteHoursPerYear: commuteHoursPerYear,
            sleepHoursPerYear: sleepHoursPerYear,
            freeHoursPerYear: freeHours,
            hoursSpentEarningForEssentials: hoursForEssentials,
            hoursSpentEarningForDiscretionary: hoursForDiscretionary,
            hoursWorkedToPayTaxes: hoursForTaxes
        )
    }

    private func updateTodayStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayTransactions = recentTransactions.filter { calendar.isDate($0.date, inSameDayAs: today) }
        todayHoursSpent = todayTransactions.reduce(0) { $0 + $1.hoursOfLife }
    }

    private func recalculateAllTransactions() {
        recentTransactions = recentTransactions.map { transaction in
            let newHours = transaction.amount / profile.trueHourlyRate
            return TimeWealthTransaction(
                id: transaction.id,
                originalTransactionId: transaction.originalTransactionId,
                merchantName: transaction.merchantName,
                category: transaction.category,
                amount: transaction.amount,
                hoursOfLife: newHours,
                minutesOfLife: Int(newHours * 60),
                date: transaction.date,
                isEssential: transaction.isEssential,
                alternativeSavings: transaction.alternativeSavings
            )
        }
        saveTransactions()
    }

    // MARK: - Financial Independence Calculations

    func yearsToFinancialIndependence(currentSavings: Double, monthlyInvestment: Double, targetAnnualSpending: Double, expectedReturn: Double = 0.07) -> Double {
        // Using the 4% rule (need 25x annual spending)
        let targetAmount = targetAnnualSpending * 25
        let monthlyReturn = expectedReturn / 12

        // Compound interest formula solving for time
        // FV = PV(1+r)^n + PMT[((1+r)^n - 1)/r]
        // This is a numerical approximation
        var years = 0.0
        var currentAmount = currentSavings

        while currentAmount < targetAmount && years < 100 {
            currentAmount = currentAmount * (1 + expectedReturn) + (monthlyInvestment * 12)
            years += 1
        }

        return years
    }

    func hoursUntilFreedom(currentSavings: Double, monthlySavingsRate: Double, targetAnnualSpending: Double) -> Double {
        let years = yearsToFinancialIndependence(
            currentSavings: currentSavings,
            monthlyInvestment: monthlySavingsRate,
            targetAnnualSpending: targetAnnualSpending
        )
        return years * profile.workHoursPerWeek * 52
    }

    // MARK: - Persistence

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }

    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(recentTransactions) {
            userDefaults.set(data, forKey: transactionsKey)
        }
    }

    private func loadTransactions() {
        if let data = userDefaults.data(forKey: transactionsKey),
           let transactions = try? JSONDecoder().decode([TimeWealthTransaction].self, from: data) {
            recentTransactions = transactions
        }
    }
}
