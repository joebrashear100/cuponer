//
//  DebtPayoffManager.swift
//  Furg
//
//  Comprehensive debt tracking with snowball/avalanche payoff strategies
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct Debt: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: DebtType
    var originalBalance: Double
    var currentBalance: Double
    var interestRate: Double // APR as decimal (e.g., 0.18 for 18%)
    var minimumPayment: Double
    var dueDay: Int // Day of month (1-31)
    var lender: String
    var accountNumber: String?
    var startDate: Date
    var notes: String?
    var isActive: Bool
    var color: String

    var monthlyInterest: Double {
        currentBalance * (interestRate / 12)
    }

    var principalPayment: Double {
        max(0, minimumPayment - monthlyInterest)
    }

    var percentPaid: Double {
        guard originalBalance > 0 else { return 1.0 }
        return (originalBalance - currentBalance) / originalBalance
    }

    var monthsToPayoff: Int {
        guard minimumPayment > monthlyInterest else { return Int.max }
        let monthlyRate = interestRate / 12
        if monthlyRate == 0 {
            return Int(ceil(currentBalance / minimumPayment))
        }
        let months = -log(1 - (monthlyRate * currentBalance / minimumPayment)) / log(1 + monthlyRate)
        return Int(ceil(months))
    }

    var payoffDate: Date {
        Calendar.current.date(byAdding: .month, value: monthsToPayoff, to: Date()) ?? Date()
    }

    var totalInterestRemaining: Double {
        let months = Double(monthsToPayoff)
        let totalPayments = minimumPayment * months
        return max(0, totalPayments - currentBalance)
    }
}

enum DebtType: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case studentLoan = "Student Loan"
    case autoLoan = "Auto Loan"
    case mortgage = "Mortgage"
    case personalLoan = "Personal Loan"
    case medicalDebt = "Medical Debt"
    case other = "Other"

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .studentLoan: return "graduationcap.fill"
        case .autoLoan: return "car.fill"
        case .mortgage: return "house.fill"
        case .personalLoan: return "person.fill"
        case .medicalDebt: return "cross.case.fill"
        case .other: return "dollarsign.circle.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .creditCard: return "red"
        case .studentLoan: return "blue"
        case .autoLoan: return "green"
        case .mortgage: return "purple"
        case .personalLoan: return "orange"
        case .medicalDebt: return "pink"
        case .other: return "gray"
        }
    }
}

enum PayoffStrategy: String, Codable, CaseIterable {
    case snowball = "Snowball"
    case avalanche = "Avalanche"
    case custom = "Custom"

    var description: String {
        switch self {
        case .snowball: return "Pay smallest balances first for quick wins"
        case .avalanche: return "Pay highest interest rates first to save money"
        case .custom: return "Set your own priority order"
        }
    }

    var detailedDescription: String {
        switch self {
        case .snowball:
            return "The debt snowball method focuses on paying off your smallest debts first while making minimum payments on larger ones. Each time you pay off a debt, you roll that payment into the next smallest debt, creating momentum."
        case .avalanche:
            return "The debt avalanche method targets debts with the highest interest rates first. This approach saves the most money on interest over time, but may take longer to see debts fully paid off."
        case .custom:
            return "Set your own priority order for paying off debts based on your personal preferences and circumstances."
        }
    }
}

struct PayoffPlan: Identifiable, Codable {
    let id: UUID
    var strategy: PayoffStrategy
    var extraMonthlyPayment: Double
    var debtOrder: [UUID] // Order of debt IDs
    var projectedPayoffDate: Date
    var totalInterestSaved: Double
    var monthsToDebtFree: Int
    let createdAt: Date
}

struct PaymentRecord: Identifiable, Codable {
    let id: UUID
    let debtId: UUID
    let amount: Double
    let date: Date
    let principalPaid: Double
    let interestPaid: Double
    let remainingBalance: Double
    let notes: String?
}

struct DebtMilestone: Identifiable, Codable {
    let id: UUID
    let debtId: UUID?
    let type: MilestoneType
    let targetDate: Date
    var isAchieved: Bool
    var achievedDate: Date?
    let description: String

    enum MilestoneType: String, Codable {
        case debtPaidOff = "Debt Paid Off"
        case halfwayPoint = "Halfway There"
        case firstDebtFree = "First Debt Free"
        case debtFree = "Completely Debt Free"
        case interestSaved = "Interest Saved Milestone"
        case streakMaintained = "Payment Streak"
    }
}

struct PayoffProjection: Identifiable {
    let id = UUID()
    let month: Int
    let date: Date
    let remainingBalance: Double
    let debtId: UUID
    let debtName: String
    let interestPaid: Double
    let principalPaid: Double
}

// MARK: - Debt Payoff Manager

class DebtPayoffManager: ObservableObject {
    static let shared = DebtPayoffManager()

    @Published var debts: [Debt] = []
    @Published var paymentHistory: [PaymentRecord] = []
    @Published var currentPlan: PayoffPlan?
    @Published var milestones: [DebtMilestone] = []
    @Published var projections: [PayoffProjection] = []

    private let userDefaults = UserDefaults.standard
    private let debtsKey = "furg_debts"
    private let paymentsKey = "furg_debt_payments"
    private let planKey = "furg_debt_plan"
    private let milestonesKey = "furg_debt_milestones"

    // MARK: - Computed Properties

    var totalDebt: Double {
        debts.filter { $0.isActive }.reduce(0) { $0 + $1.currentBalance }
    }

    var totalMinimumPayments: Double {
        debts.filter { $0.isActive }.reduce(0) { $0 + $1.minimumPayment }
    }

    var totalMonthlyInterest: Double {
        debts.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyInterest }
    }

    var averageInterestRate: Double {
        let activeDebts = debts.filter { $0.isActive }
        guard !activeDebts.isEmpty else { return 0 }

        let weightedSum = activeDebts.reduce(0) { $0 + $1.interestRate * $1.currentBalance }
        return weightedSum / totalDebt
    }

    var debtFreeDate: Date {
        currentPlan?.projectedPayoffDate ?? debts.map { $0.payoffDate }.max() ?? Date()
    }

    var totalOriginalDebt: Double {
        debts.reduce(0) { $0 + $1.originalBalance }
    }

    var totalPaidOff: Double {
        totalOriginalDebt - totalDebt
    }

    var overallProgress: Double {
        guard totalOriginalDebt > 0 else { return 1.0 }
        return totalPaidOff / totalOriginalDebt
    }

    init() {
        loadDebts()
        loadPayments()
        loadPlan()
        loadMilestones()
    }

    // MARK: - Debt Management

    func addDebt(_ debt: Debt) {
        debts.append(debt)
        saveDebts()
        recalculatePlan()
        checkMilestones()
    }

    func updateDebt(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index] = debt
            saveDebts()
            recalculatePlan()
            checkMilestones()
        }
    }

    func deleteDebt(_ debt: Debt) {
        debts.removeAll { $0.id == debt.id }
        paymentHistory.removeAll { $0.debtId == debt.id }
        saveDebts()
        savePayments()
        recalculatePlan()
    }

    func recordPayment(debtId: UUID, amount: Double, notes: String? = nil) {
        guard let index = debts.firstIndex(where: { $0.id == debtId }) else { return }

        let debt = debts[index]
        let interestPortion = min(amount, debt.monthlyInterest)
        let principalPortion = amount - interestPortion
        let newBalance = max(0, debt.currentBalance - principalPortion)

        // Update debt balance
        debts[index].currentBalance = newBalance

        // Record payment
        let payment = PaymentRecord(
            id: UUID(),
            debtId: debtId,
            amount: amount,
            date: Date(),
            principalPaid: principalPortion,
            interestPaid: interestPortion,
            remainingBalance: newBalance,
            notes: notes
        )
        paymentHistory.append(payment)

        // Check if debt is paid off
        if newBalance == 0 {
            debts[index].isActive = false
            celebrateDebtPayoff(debt)
        }

        saveDebts()
        savePayments()
        recalculatePlan()
        checkMilestones()
    }

    // MARK: - Payoff Strategies

    func createPayoffPlan(strategy: PayoffStrategy, extraMonthlyPayment: Double = 0) {
        let sortedDebts = sortDebtsForStrategy(strategy)
        let (payoffDate, interestSaved, months) = calculateProjectedPayoff(
            debts: sortedDebts,
            extraPayment: extraMonthlyPayment
        )

        currentPlan = PayoffPlan(
            id: UUID(),
            strategy: strategy,
            extraMonthlyPayment: extraMonthlyPayment,
            debtOrder: sortedDebts.map { $0.id },
            projectedPayoffDate: payoffDate,
            totalInterestSaved: interestSaved,
            monthsToDebtFree: months,
            createdAt: Date()
        )

        generateProjections(strategy: strategy, extraPayment: extraMonthlyPayment)
        savePlan()
    }

    private func sortDebtsForStrategy(_ strategy: PayoffStrategy) -> [Debt] {
        let activeDebts = debts.filter { $0.isActive }

        switch strategy {
        case .snowball:
            return activeDebts.sorted { $0.currentBalance < $1.currentBalance }
        case .avalanche:
            return activeDebts.sorted { $0.interestRate > $1.interestRate }
        case .custom:
            if let plan = currentPlan {
                return plan.debtOrder.compactMap { orderId in
                    activeDebts.first { $0.id == orderId }
                }
            }
            return activeDebts
        }
    }

    private func calculateProjectedPayoff(debts: [Debt], extraPayment: Double) -> (Date, Double, Int) {
        var remainingDebts = debts.map { ($0.id, $0.currentBalance, $0.interestRate, $0.minimumPayment) }
        var totalInterestPaid = 0.0
        var months = 0
        var extraAvailable = extraPayment

        // Calculate baseline interest (minimum payments only)
        var baselineInterest = 0.0
        for debt in debts {
            baselineInterest += debt.totalInterestRemaining
        }

        while !remainingDebts.isEmpty && months < 600 { // Max 50 years
            months += 1

            // Apply payments to each debt
            var i = 0
            while i < remainingDebts.count {
                var (id, balance, rate, minPayment) = remainingDebts[i]
                let monthlyRate = rate / 12
                let interest = balance * monthlyRate
                totalInterestPaid += interest

                // Calculate payment (minimum + extra for priority debt)
                var payment = minPayment
                if i == 0 { // Priority debt gets extra payment
                    payment += extraAvailable
                }

                balance = max(0, balance + interest - payment)

                if balance <= 0.01 {
                    // Debt paid off, roll payment to next debt
                    extraAvailable += minPayment
                    remainingDebts.remove(at: i)
                } else {
                    remainingDebts[i] = (id, balance, rate, minPayment)
                    i += 1
                }
            }
        }

        let payoffDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        let interestSaved = max(0, baselineInterest - totalInterestPaid)

        return (payoffDate, interestSaved, months)
    }

    private func generateProjections(strategy: PayoffStrategy, extraPayment: Double) {
        var newProjections: [PayoffProjection] = []
        var remainingDebts = sortDebtsForStrategy(strategy).map {
            (id: $0.id, name: $0.name, balance: $0.currentBalance, rate: $0.interestRate, minPayment: $0.minimumPayment)
        }
        var extraAvailable = extraPayment
        var month = 0

        while !remainingDebts.isEmpty && month < 360 {
            month += 1
            let date = Calendar.current.date(byAdding: .month, value: month, to: Date()) ?? Date()

            var i = 0
            while i < remainingDebts.count {
                var debt = remainingDebts[i]
                let monthlyRate = debt.rate / 12
                let interest = debt.balance * monthlyRate

                var payment = debt.minPayment
                if i == 0 {
                    payment += extraAvailable
                }

                let principalPaid = min(debt.balance, payment - interest)
                debt.balance = max(0, debt.balance + interest - payment)

                newProjections.append(PayoffProjection(
                    month: month,
                    date: date,
                    remainingBalance: debt.balance,
                    debtId: debt.id,
                    debtName: debt.name,
                    interestPaid: interest,
                    principalPaid: principalPaid
                ))

                if debt.balance <= 0.01 {
                    extraAvailable += debt.minPayment
                    remainingDebts.remove(at: i)
                } else {
                    remainingDebts[i] = debt
                    i += 1
                }
            }
        }

        projections = newProjections
    }

    // MARK: - Comparisons

    func compareStrategies(extraPayment: Double = 0) -> [(PayoffStrategy, Date, Double, Int)] {
        var results: [(PayoffStrategy, Date, Double, Int)] = []

        for strategy in [PayoffStrategy.snowball, .avalanche] {
            let sortedDebts = sortDebtsForStrategy(strategy)
            let (date, savings, months) = calculateProjectedPayoff(debts: sortedDebts, extraPayment: extraPayment)
            results.append((strategy, date, savings, months))
        }

        return results
    }

    func calculateExtraPaymentImpact(amounts: [Double]) -> [(Double, Date, Double)] {
        let strategy = currentPlan?.strategy ?? .avalanche
        var results: [(Double, Date, Double)] = []

        for amount in amounts {
            let sortedDebts = sortDebtsForStrategy(strategy)
            let (date, savings, _) = calculateProjectedPayoff(debts: sortedDebts, extraPayment: amount)
            results.append((amount, date, savings))
        }

        return results
    }

    // MARK: - Milestones

    private func checkMilestones() {
        // First debt paid off
        let paidOffDebts = debts.filter { !$0.isActive }
        if !paidOffDebts.isEmpty && !milestones.contains(where: { $0.type == .firstDebtFree }) {
            addMilestone(.firstDebtFree, description: "Paid off your first debt!")
        }

        // Completely debt free
        if totalDebt == 0 && !debts.isEmpty && !milestones.contains(where: { $0.type == .debtFree }) {
            addMilestone(.debtFree, description: "You're completely debt free!")
        }

        // Halfway point per debt
        for debt in debts where debt.percentPaid >= 0.5 {
            if !milestones.contains(where: { $0.debtId == debt.id && $0.type == .halfwayPoint }) {
                addMilestone(.halfwayPoint, debtId: debt.id, description: "Halfway done paying off \(debt.name)!")
            }
        }

        saveMilestones()
    }

    private func addMilestone(_ type: DebtMilestone.MilestoneType, debtId: UUID? = nil, description: String) {
        let milestone = DebtMilestone(
            id: UUID(),
            debtId: debtId,
            type: type,
            targetDate: Date(),
            isAchieved: true,
            achievedDate: Date(),
            description: description
        )
        milestones.append(milestone)

        // Send notification
        NotificationManager.shared.scheduleDebtMilestoneNotification(milestone: milestone)
    }

    private func celebrateDebtPayoff(_ debt: Debt) {
        let milestone = DebtMilestone(
            id: UUID(),
            debtId: debt.id,
            type: .debtPaidOff,
            targetDate: Date(),
            isAchieved: true,
            achievedDate: Date(),
            description: "Congratulations! You paid off \(debt.name)!"
        )
        milestones.append(milestone)
        saveMilestones()

        NotificationManager.shared.scheduleDebtMilestoneNotification(milestone: milestone)
    }

    // MARK: - Analytics

    func getMonthlyPaymentBreakdown() -> [(String, Double, Double)] {
        // Returns (debt name, principal, interest) for current month
        debts.filter { $0.isActive }.map { debt in
            (debt.name, debt.principalPayment, debt.monthlyInterest)
        }
    }

    func getPaymentHistory(for debtId: UUID, limit: Int = 12) -> [PaymentRecord] {
        paymentHistory
            .filter { $0.debtId == debtId }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func getTotalPaidThisMonth() -> Double {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return paymentHistory
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }

    func getTotalInterestPaid() -> Double {
        paymentHistory.reduce(0) { $0 + $1.interestPaid }
    }

    // MARK: - Recommendations

    func getRecommendations() -> [String] {
        var recommendations: [String] = []

        // High interest warning
        if let highInterestDebt = debts.filter({ $0.isActive }).max(by: { $0.interestRate < $1.interestRate }),
           highInterestDebt.interestRate > 0.20 {
            recommendations.append("🚨 \(highInterestDebt.name) has a \(Int(highInterestDebt.interestRate * 100))% APR. Consider balance transfer or consolidation.")
        }

        // Small balance quick win
        if let smallDebt = debts.filter({ $0.isActive && $0.currentBalance < 500 }).min(by: { $0.currentBalance < $1.currentBalance }) {
            recommendations.append("💪 Quick win: \(smallDebt.name) only has $\(Int(smallDebt.currentBalance)) left. A little extra could wipe it out!")
        }

        // Extra payment impact
        if let plan = currentPlan, plan.extraMonthlyPayment == 0 {
            let impactResults = calculateExtraPaymentImpact(amounts: [50, 100])
            if let result = impactResults.first {
                let monthsSaved = plan.monthsToDebtFree - Int(result.1.timeIntervalSince(Date()) / (30 * 24 * 3600))
                if monthsSaved > 0 {
                    recommendations.append("💰 Adding just $50/month could make you debt-free \(monthsSaved) months sooner!")
                }
            }
        }

        // Strategy suggestion
        let comparison = compareStrategies()
        if let snowball = comparison.first(where: { $0.0 == .snowball }),
           let avalanche = comparison.first(where: { $0.0 == .avalanche }) {
            if avalanche.2 > snowball.2 + 500 {
                recommendations.append("📊 Avalanche method could save you $\(Int(avalanche.2 - snowball.2)) more in interest.")
            }
        }

        return recommendations
    }

    // MARK: - Recalculation

    private func recalculatePlan() {
        if let plan = currentPlan {
            createPayoffPlan(strategy: plan.strategy, extraMonthlyPayment: plan.extraMonthlyPayment)
        }
    }

    // MARK: - Persistence

    private func saveDebts() {
        if let data = try? JSONEncoder().encode(debts) {
            userDefaults.set(data, forKey: debtsKey)
        }
    }

    private func loadDebts() {
        guard let data = userDefaults.data(forKey: debtsKey),
              let loaded = try? JSONDecoder().decode([Debt].self, from: data) else {
            addDemoDebts()
            return
        }
        debts = loaded
    }

    private func savePayments() {
        if let data = try? JSONEncoder().encode(paymentHistory) {
            userDefaults.set(data, forKey: paymentsKey)
        }
    }

    private func loadPayments() {
        guard let data = userDefaults.data(forKey: paymentsKey),
              let loaded = try? JSONDecoder().decode([PaymentRecord].self, from: data) else {
            return
        }
        paymentHistory = loaded
    }

    private func savePlan() {
        if let plan = currentPlan, let data = try? JSONEncoder().encode(plan) {
            userDefaults.set(data, forKey: planKey)
        }
    }

    private func loadPlan() {
        guard let data = userDefaults.data(forKey: planKey),
              let loaded = try? JSONDecoder().decode(PayoffPlan.self, from: data) else {
            return
        }
        currentPlan = loaded
        generateProjections(strategy: loaded.strategy, extraPayment: loaded.extraMonthlyPayment)
    }

    private func saveMilestones() {
        if let data = try? JSONEncoder().encode(milestones) {
            userDefaults.set(data, forKey: milestonesKey)
        }
    }

    private func loadMilestones() {
        guard let data = userDefaults.data(forKey: milestonesKey),
              let loaded = try? JSONDecoder().decode([DebtMilestone].self, from: data) else {
            return
        }
        milestones = loaded
    }

    private func addDemoDebts() {
        debts = [
            Debt(
                id: UUID(),
                name: "Chase Sapphire",
                type: .creditCard,
                originalBalance: 5200,
                currentBalance: 3850,
                interestRate: 0.2199,
                minimumPayment: 95,
                dueDay: 15,
                lender: "Chase",
                accountNumber: "****4521",
                startDate: Calendar.current.date(byAdding: .month, value: -18, to: Date())!,
                notes: nil,
                isActive: true,
                color: "blue"
            ),
            Debt(
                id: UUID(),
                name: "Student Loan",
                type: .studentLoan,
                originalBalance: 28000,
                currentBalance: 22450,
                interestRate: 0.0625,
                minimumPayment: 285,
                dueDay: 1,
                lender: "Nelnet",
                accountNumber: "****7890",
                startDate: Calendar.current.date(byAdding: .year, value: -4, to: Date())!,
                notes: "Federal loan",
                isActive: true,
                color: "purple"
            ),
            Debt(
                id: UUID(),
                name: "Car Loan",
                type: .autoLoan,
                originalBalance: 18500,
                currentBalance: 12200,
                interestRate: 0.049,
                minimumPayment: 345,
                dueDay: 20,
                lender: "Capital One Auto",
                accountNumber: "****3456",
                startDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
                notes: nil,
                isActive: true,
                color: "green"
            )
        ]
        saveDebts()

        // Create initial plan
        createPayoffPlan(strategy: .avalanche, extraMonthlyPayment: 0)
    }
}

// MARK: - Notification Extension

extension NotificationManager {
    func scheduleDebtMilestoneNotification(milestone: DebtMilestone) {
        let content = UNMutableNotificationContent()

        switch milestone.type {
        case .debtPaidOff:
            content.title = "🎉 Debt Paid Off!"
            content.body = milestone.description
            content.sound = UNNotificationSound.defaultCritical
        case .debtFree:
            content.title = "🏆 YOU'RE DEBT FREE!"
            content.body = "Congratulations! You've paid off all your debts!"
            content.sound = UNNotificationSound.defaultCritical
        case .halfwayPoint:
            content.title = "💪 Halfway There!"
            content.body = milestone.description
            content.sound = .default
        case .firstDebtFree:
            content.title = "🎊 First Debt Gone!"
            content.body = milestone.description
            content.sound = .default
        case .interestSaved:
            content.title = "💰 Interest Saved!"
            content.body = milestone.description
            content.sound = .default
        case .streakMaintained:
            content.title = "🔥 Payment Streak!"
            content.body = milestone.description
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "debt_milestone_\(milestone.id.uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
