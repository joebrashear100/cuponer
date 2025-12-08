//
//  IncomeManager.swift
//  Furg
//
//  Track multiple income sources, predict paydays, and manage irregular income
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct IncomeSource: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: IncomeType
    var amount: Double
    var frequency: PayFrequency
    var nextPayday: Date
    var employer: String?
    var accountDepositId: String? // Which account it deposits to
    var isActive: Bool
    var taxWithholdingPercent: Double
    var notes: String?
    var color: String

    var monthlyAmount: Double {
        switch frequency {
        case .weekly: return amount * 52 / 12
        case .biweekly: return amount * 26 / 12
        case .semimonthly: return amount * 2
        case .monthly: return amount
        case .quarterly: return amount / 3
        case .annual: return amount / 12
        case .irregular: return amount // Best estimate
        }
    }

    var annualAmount: Double {
        monthlyAmount * 12
    }

    var netAmount: Double {
        amount * (1 - taxWithholdingPercent)
    }

    func getNextPaydays(count: Int) -> [Date] {
        var dates: [Date] = []
        var currentDate = nextPayday

        for _ in 0..<count {
            dates.append(currentDate)
            currentDate = frequency.nextDate(from: currentDate)
        }

        return dates
    }
}

enum IncomeType: String, Codable, CaseIterable {
    case salary = "Salary"
    case hourly = "Hourly Wages"
    case freelance = "Freelance"
    case sideGig = "Side Gig"
    case rental = "Rental Income"
    case investment = "Investment Income"
    case dividends = "Dividends"
    case pension = "Pension"
    case socialSecurity = "Social Security"
    case childSupport = "Child Support"
    case alimony = "Alimony"
    case bonus = "Bonus"
    case commission = "Commission"
    case tips = "Tips"
    case other = "Other"

    var icon: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .hourly: return "clock.fill"
        case .freelance: return "laptopcomputer"
        case .sideGig: return "car.fill"
        case .rental: return "house.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .dividends: return "chart.pie.fill"
        case .pension: return "person.crop.circle.badge.checkmark"
        case .socialSecurity: return "building.columns.fill"
        case .childSupport: return "figure.2.and.child.holdinghands"
        case .alimony: return "person.2.fill"
        case .bonus: return "gift.fill"
        case .commission: return "percent"
        case .tips: return "dollarsign.circle.fill"
        case .other: return "banknote.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .salary: return "blue"
        case .hourly: return "green"
        case .freelance: return "purple"
        case .sideGig: return "orange"
        case .rental: return "brown"
        case .investment: return "mint"
        case .dividends: return "teal"
        case .pension: return "gray"
        case .socialSecurity: return "indigo"
        case .childSupport, .alimony: return "pink"
        case .bonus: return "yellow"
        case .commission: return "cyan"
        case .tips: return "green"
        case .other: return "gray"
        }
    }
}

enum PayFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case semimonthly = "Twice a Month"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annual = "Annually"
    case irregular = "Irregular"

    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current

        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .semimonthly:
            // 1st and 15th, or 15th and last day
            let day = calendar.component(.day, from: date)
            if day < 15 {
                return calendar.date(bySetting: .day, value: 15, of: date) ?? date
            } else {
                var nextMonth = calendar.date(byAdding: .month, value: 1, to: date) ?? date
                nextMonth = calendar.date(bySetting: .day, value: 1, of: nextMonth) ?? nextMonth
                return nextMonth
            }
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .irregular:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date // Estimate
        }
    }

    var paychecksPerYear: Double {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .semimonthly: return 24
        case .monthly: return 12
        case .quarterly: return 4
        case .annual: return 1
        case .irregular: return 12 // Estimate
        }
    }
}

struct IncomeRecord: Identifiable, Codable {
    let id: UUID
    let sourceId: UUID
    let amount: Double
    let date: Date
    let netAmount: Double
    let taxWithheld: Double
    let notes: String?
    var isVerified: Bool
}

struct PaydayPrediction: Identifiable {
    let id = UUID()
    let sourceId: UUID
    let sourceName: String
    let predictedDate: Date
    let expectedAmount: Double
    let confidence: Double
    let isUpcoming: Bool // Within 7 days
}

struct IncomeSummary {
    let totalMonthlyGross: Double
    let totalMonthlyNet: Double
    let totalAnnualGross: Double
    let totalAnnualNet: Double
    let incomeByType: [IncomeType: Double]
    let diversificationScore: Double // 0-100
    let stabilityScore: Double // 0-100
}

// MARK: - Income Manager

class IncomeManager: ObservableObject {
    static let shared = IncomeManager()

    @Published var incomeSources: [IncomeSource] = []
    @Published var incomeHistory: [IncomeRecord] = []
    @Published var upcomingPaydays: [PaydayPrediction] = []
    @Published var summary: IncomeSummary?

    private let userDefaults = UserDefaults.standard
    private let sourcesKey = "furg_income_sources"
    private let historyKey = "furg_income_history"
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadIncomeSources()
        loadIncomeHistory()
        calculateSummary()
        updateUpcomingPaydays()

        // Update predictions daily
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.updateUpcomingPaydays()
        }
    }

    // MARK: - Computed Properties

    var totalMonthlyIncome: Double {
        incomeSources.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyAmount }
    }

    var totalAnnualIncome: Double {
        totalMonthlyIncome * 12
    }

    var primaryIncomeSource: IncomeSource? {
        incomeSources.filter { $0.isActive }.max(by: { $0.monthlyAmount < $1.monthlyAmount })
    }

    var activeSourceCount: Int {
        incomeSources.filter { $0.isActive }.count
    }

    // MARK: - Income Source Management

    func addIncomeSource(_ source: IncomeSource) {
        incomeSources.append(source)
        saveIncomeSources()
        calculateSummary()
        updateUpcomingPaydays()
    }

    func updateIncomeSource(_ source: IncomeSource) {
        if let index = incomeSources.firstIndex(where: { $0.id == source.id }) {
            incomeSources[index] = source
            saveIncomeSources()
            calculateSummary()
            updateUpcomingPaydays()
        }
    }

    func deleteIncomeSource(_ source: IncomeSource) {
        incomeSources.removeAll { $0.id == source.id }
        incomeHistory.removeAll { $0.sourceId == source.id }
        saveIncomeSources()
        saveIncomeHistory()
        calculateSummary()
        updateUpcomingPaydays()
    }

    func recordIncome(sourceId: UUID, amount: Double, date: Date = Date(), notes: String? = nil) {
        guard let source = incomeSources.first(where: { $0.id == sourceId }) else { return }

        let taxWithheld = amount * source.taxWithholdingPercent
        let netAmount = amount - taxWithheld

        let record = IncomeRecord(
            id: UUID(),
            sourceId: sourceId,
            amount: amount,
            date: date,
            netAmount: netAmount,
            taxWithheld: taxWithheld,
            notes: notes,
            isVerified: true
        )

        incomeHistory.append(record)
        saveIncomeHistory()

        // Update next payday for this source
        if let index = incomeSources.firstIndex(where: { $0.id == sourceId }) {
            incomeSources[index].nextPayday = source.frequency.nextDate(from: date)
            saveIncomeSources()
        }

        updateUpcomingPaydays()
    }

    // MARK: - Payday Predictions

    func updateUpcomingPaydays() {
        var predictions: [PaydayPrediction] = []
        let today = Date()
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: today)!

        for source in incomeSources where source.isActive {
            let nextPaydays = source.getNextPaydays(count: 3)

            for payday in nextPaydays where payday <= thirtyDaysFromNow {
                let confidence = calculatePredictionConfidence(for: source)
                let isUpcoming = payday <= sevenDaysFromNow && payday >= today

                predictions.append(PaydayPrediction(
                    sourceId: source.id,
                    sourceName: source.name,
                    predictedDate: payday,
                    expectedAmount: source.netAmount,
                    confidence: confidence,
                    isUpcoming: isUpcoming
                ))
            }
        }

        upcomingPaydays = predictions.sorted { $0.predictedDate < $1.predictedDate }

        // Schedule notifications for upcoming paydays
        schedulePaydayNotifications()
    }

    private func calculatePredictionConfidence(for source: IncomeSource) -> Double {
        // Base confidence on income type stability
        var confidence: Double

        switch source.type {
        case .salary, .pension, .socialSecurity:
            confidence = 0.95
        case .hourly, .rental:
            confidence = 0.85
        case .commission, .tips:
            confidence = 0.7
        case .freelance, .sideGig:
            confidence = 0.6
        case .bonus:
            confidence = 0.5
        case .investment, .dividends:
            confidence = 0.75
        default:
            confidence = 0.7
        }

        // Adjust based on history consistency
        let recentRecords = incomeHistory.filter { $0.sourceId == source.id }.suffix(6)
        if recentRecords.count >= 3 {
            let amounts = recentRecords.map { $0.amount }
            let avg = amounts.reduce(0, +) / Double(amounts.count)
            let variance = amounts.map { pow($0 - avg, 2) }.reduce(0, +) / Double(amounts.count)
            let stdDev = sqrt(variance)
            let coefficientOfVariation = avg > 0 ? stdDev / avg : 1

            // Lower CV = more consistent = higher confidence
            if coefficientOfVariation < 0.05 {
                confidence = min(0.98, confidence + 0.1)
            } else if coefficientOfVariation > 0.2 {
                confidence = max(0.4, confidence - 0.15)
            }
        }

        return confidence
    }

    private func schedulePaydayNotifications() {
        // Clear existing payday notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:
            upcomingPaydays.map { "payday_\($0.id.uuidString)" }
        )

        for prediction in upcomingPaydays where prediction.isUpcoming {
            let content = UNMutableNotificationContent()
            content.title = "💰 Payday Coming!"
            content.body = "\(prediction.sourceName): $\(String(format: "%.2f", prediction.expectedAmount)) expected \(formatRelativeDate(prediction.predictedDate))"
            content.sound = .default
            content.categoryIdentifier = "PAYDAY_REMINDER"

            // Schedule for 9 AM day before
            var triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: prediction.predictedDate)!
            var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            components.hour = 9
            components.minute = 0

            if let scheduledDate = Calendar.current.date(from: components), scheduledDate > Date() {
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "payday_\(prediction.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }

    // MARK: - Summary & Analytics

    func calculateSummary() {
        let activeSources = incomeSources.filter { $0.isActive }

        let totalMonthlyGross = activeSources.reduce(0) { $0 + $1.monthlyAmount }
        let totalMonthlyNet = activeSources.reduce(0) { $0 + $1.monthlyAmount * (1 - $1.taxWithholdingPercent) }

        // Income by type
        var incomeByType: [IncomeType: Double] = [:]
        for source in activeSources {
            incomeByType[source.type, default: 0] += source.monthlyAmount
        }

        // Diversification score (0-100)
        // Higher = more diversified
        let diversificationScore: Double
        if activeSources.count <= 1 {
            diversificationScore = 0
        } else {
            let total = totalMonthlyGross
            let shares = activeSources.map { $0.monthlyAmount / total }
            let herfindahl = shares.reduce(0) { $0 + pow($1, 2) }
            diversificationScore = (1 - herfindahl) * 100
        }

        // Stability score (0-100)
        // Based on income types
        let stabilityWeights: [IncomeType: Double] = [
            .salary: 1.0, .pension: 1.0, .socialSecurity: 1.0,
            .rental: 0.8, .hourly: 0.7,
            .dividends: 0.7, .investment: 0.6,
            .freelance: 0.5, .commission: 0.5,
            .sideGig: 0.4, .tips: 0.4,
            .bonus: 0.3,
            .childSupport: 0.7, .alimony: 0.7,
            .other: 0.5
        ]

        let weightedStability = activeSources.reduce(0.0) { result, source in
            let weight = stabilityWeights[source.type] ?? 0.5
            return result + (source.monthlyAmount / totalMonthlyGross) * weight
        }
        let stabilityScore = weightedStability * 100

        summary = IncomeSummary(
            totalMonthlyGross: totalMonthlyGross,
            totalMonthlyNet: totalMonthlyNet,
            totalAnnualGross: totalMonthlyGross * 12,
            totalAnnualNet: totalMonthlyNet * 12,
            incomeByType: incomeByType,
            diversificationScore: diversificationScore,
            stabilityScore: stabilityScore
        )
    }

    func getIncomeHistory(for sourceId: UUID, limit: Int = 12) -> [IncomeRecord] {
        incomeHistory
            .filter { $0.sourceId == sourceId }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func getMonthlyIncomeHistory(months: Int = 6) -> [(Date, Double)] {
        let calendar = Calendar.current
        var result: [(Date, Double)] = []

        for i in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let components = calendar.dateComponents([.year, .month], from: monthStart)
            guard let startOfMonth = calendar.date(from: components) else { continue }
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { continue }

            let monthlyTotal = incomeHistory
                .filter { $0.date >= startOfMonth && $0.date < endOfMonth }
                .reduce(0) { $0 + $1.amount }

            result.append((startOfMonth, monthlyTotal))
        }

        return result.reversed()
    }

    func getIncomeByDayOfWeek() -> [Int: Double] {
        var byDay: [Int: [Double]] = [:]

        for record in incomeHistory {
            let weekday = Calendar.current.component(.weekday, from: record.date)
            byDay[weekday, default: []].append(record.amount)
        }

        return byDay.mapValues { values in
            values.reduce(0, +) / Double(max(1, values.count))
        }
    }

    // MARK: - Cash Flow Integration

    func getExpectedIncomeForMonth(_ date: Date = Date()) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return totalMonthlyIncome
        }

        var expectedIncome = 0.0

        for source in incomeSources where source.isActive {
            let paydays = source.getNextPaydays(count: 10)
            for payday in paydays where payday >= startOfMonth && payday < endOfMonth {
                expectedIncome += source.netAmount
            }
        }

        return expectedIncome
    }

    func getDaysUntilNextPayday() -> Int? {
        guard let nextPayday = upcomingPaydays.first?.predictedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextPayday).day
    }

    // MARK: - Recommendations

    func getIncomeRecommendations() -> [String] {
        var recommendations: [String] = []
        guard let summary = summary else { return recommendations }

        // Diversification recommendation
        if summary.diversificationScore < 30 && activeSourceCount == 1 {
            recommendations.append("💡 Consider diversifying your income. Relying on a single source can be risky.")
        }

        // Side income opportunity
        if summary.totalMonthlyNet < 5000 {
            recommendations.append("🚀 A side gig could boost your monthly income. Even $500/month adds up to $6,000/year!")
        }

        // Tax optimization
        let avgTaxRate = incomeSources.filter { $0.isActive }.reduce(0.0) { $0 + $1.taxWithholdingPercent } / Double(max(1, activeSourceCount))
        if avgTaxRate > 0.25 {
            recommendations.append("💰 High tax withholding detected. Consider reviewing your W-4 or tax-advantaged accounts.")
        }

        // Irregular income warning
        let irregularSources = incomeSources.filter { $0.isActive && $0.frequency == .irregular }
        if !irregularSources.isEmpty {
            recommendations.append("📊 You have irregular income. Build a 3-6 month emergency fund to smooth out cash flow.")
        }

        return recommendations
    }

    // MARK: - Persistence

    private func saveIncomeSources() {
        if let data = try? JSONEncoder().encode(incomeSources) {
            userDefaults.set(data, forKey: sourcesKey)
        }
    }

    private func loadIncomeSources() {
        guard let data = userDefaults.data(forKey: sourcesKey),
              let loaded = try? JSONDecoder().decode([IncomeSource].self, from: data) else {
            addDemoIncomeSources()
            return
        }
        incomeSources = loaded
    }

    private func saveIncomeHistory() {
        if let data = try? JSONEncoder().encode(incomeHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }

    private func loadIncomeHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let loaded = try? JSONDecoder().decode([IncomeRecord].self, from: data) else {
            return
        }
        incomeHistory = loaded
    }

    private func addDemoIncomeSources() {
        let nextFriday = getNextWeekday(5) // Friday
        let firstOfMonth = getFirstOfNextMonth()

        incomeSources = [
            IncomeSource(
                id: UUID(),
                name: "Tech Corp Salary",
                type: .salary,
                amount: 4500,
                frequency: .biweekly,
                nextPayday: nextFriday,
                employer: "Tech Corp Inc.",
                accountDepositId: "checking_001",
                isActive: true,
                taxWithholdingPercent: 0.25,
                notes: nil,
                color: "blue"
            ),
            IncomeSource(
                id: UUID(),
                name: "Freelance Design",
                type: .freelance,
                amount: 1200,
                frequency: .monthly,
                nextPayday: firstOfMonth,
                employer: nil,
                accountDepositId: "checking_001",
                isActive: true,
                taxWithholdingPercent: 0.15,
                notes: "Various clients",
                color: "purple"
            ),
            IncomeSource(
                id: UUID(),
                name: "Dividend Income",
                type: .dividends,
                amount: 150,
                frequency: .quarterly,
                nextPayday: getNextQuarter(),
                employer: nil,
                accountDepositId: "savings_001",
                isActive: true,
                taxWithholdingPercent: 0.15,
                notes: "VTSAX dividends",
                color: "green"
            )
        ]
        saveIncomeSources()
    }

    private func getNextWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        var date = Date()

        while calendar.component(.weekday, from: date) != weekday {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return date
    }

    private func getFirstOfNextMonth() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month! += 1
        components.day = 1
        return calendar.date(from: components)!
    }

    private func getNextQuarter() -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let quarterMonth = ((month - 1) / 3 + 1) * 3 + 1
        var components = calendar.dateComponents([.year], from: Date())
        components.month = quarterMonth > 12 ? quarterMonth - 12 : quarterMonth
        if quarterMonth > 12 { components.year! += 1 }
        components.day = 1
        return calendar.date(from: components)!
    }
}
