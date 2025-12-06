//
//  GoalsModels.swift
//  Furg
//
//  Models for savings goals, progress tracking, and automation
//

import Foundation
import SwiftUI

// MARK: - Savings Goal

struct FurgSavingsGoal: Identifiable, Codable {
    let id: String
    var name: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var deadline: Date?
    var priority: Int
    var category: GoalCategory
    var icon: String
    var color: String
    var linkedAccountIds: [String]
    var autoContribute: Bool
    var autoContributeAmount: Decimal?
    var autoContributeFrequency: RecurringFrequency?
    let createdAt: Date
    var achievedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case deadline, priority, category, icon, color
        case linkedAccountIds = "linked_account_ids"
        case autoContribute = "auto_contribute"
        case autoContributeAmount = "auto_contribute_amount"
        case autoContributeFrequency = "auto_contribute_frequency"
        case createdAt = "created_at"
        case achievedAt = "achieved_at"
    }

    var percentComplete: Float {
        guard targetAmount > 0 else { return 0 }
        let percent = Float(truncating: (currentAmount / targetAmount * 100) as NSNumber)
        return min(percent, 100)
    }

    var amountRemaining: Decimal {
        return max(0, targetAmount - currentAmount)
    }

    var isAchieved: Bool {
        return currentAmount >= targetAmount
    }

    var formattedTarget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: targetAmount as NSNumber) ?? "$\(targetAmount)"
    }

    var formattedCurrent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: currentAmount as NSNumber) ?? "$\(currentAmount)"
    }

    var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amountRemaining as NSNumber) ?? "$\(amountRemaining)"
    }

    var displayColor: Color {
        switch color.lowercased() {
        case "mint", "green": return .furgMint
        case "blue": return .furgInfo
        case "orange": return .furgWarning
        case "red": return .furgDanger
        case "purple": return .purple
        case "pink": return .pink
        default: return .furgMint
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case emergencyFund = "emergency_fund"
    case homeDownPayment = "home_down_payment"
    case vacation
    case car
    case wedding
    case retirement
    case education
    case debtPayoff = "debt_payoff"
    case investment
    case custom

    var label: String {
        switch self {
        case .emergencyFund: return "Emergency Fund"
        case .homeDownPayment: return "Home Down Payment"
        case .vacation: return "Vacation"
        case .car: return "Car"
        case .wedding: return "Wedding"
        case .retirement: return "Retirement"
        case .education: return "Education"
        case .debtPayoff: return "Debt Payoff"
        case .investment: return "Investment"
        case .custom: return "Custom Goal"
        }
    }

    var icon: String {
        switch self {
        case .emergencyFund: return "cross.case"
        case .homeDownPayment: return "house"
        case .vacation: return "airplane"
        case .car: return "car"
        case .wedding: return "heart"
        case .retirement: return "sun.horizon"
        case .education: return "graduationcap"
        case .debtPayoff: return "arrow.down.circle"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .custom: return "star"
        }
    }

    var suggestedColor: String {
        switch self {
        case .emergencyFund: return "red"
        case .homeDownPayment: return "blue"
        case .vacation: return "orange"
        case .car: return "purple"
        case .wedding: return "pink"
        case .retirement: return "green"
        case .education: return "blue"
        case .debtPayoff: return "green"
        case .investment: return "mint"
        case .custom: return "mint"
        }
    }
}

// MARK: - Goal Progress

struct GoalProgress: Codable {
    let goalId: String
    let percentComplete: Float
    let amountRemaining: Decimal
    let daysRemaining: Int?
    let onTrack: Bool
    let projectedCompletionDate: Date
    let requiredMonthlySavings: Decimal
    let currentMonthlySavings: Decimal
    let shortfall: Decimal?
    let status: GoalStatus

    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case percentComplete = "percent_complete"
        case amountRemaining = "amount_remaining"
        case daysRemaining = "days_remaining"
        case onTrack = "on_track"
        case projectedCompletionDate = "projected_completion_date"
        case requiredMonthlySavings = "required_monthly_savings"
        case currentMonthlySavings = "current_monthly_savings"
        case shortfall
        case status
    }

    var formattedRequired: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: requiredMonthlySavings as NSNumber) ?? "$\(requiredMonthlySavings)"
    }

    var formattedCurrent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: currentMonthlySavings as NSNumber) ?? "$\(currentMonthlySavings)"
    }
}

enum GoalStatus: String, Codable {
    case onTrack = "on_track"
    case behind
    case ahead
    case achieved
    case atRisk = "at_risk"
}

// MARK: - Goal Contribution

struct GoalContribution: Identifiable, Codable {
    let id: String
    let goalId: String
    let amount: Decimal
    let source: ContributionSource
    let date: Date
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case amount, source, date, note
    }
}

enum ContributionSource: String, Codable {
    case manual
    case roundUp = "round_up"
    case paydayTransfer = "payday_transfer"
    case shadowBanking = "shadow_banking"
    case recurring
}

// MARK: - Goal Milestone

struct GoalMilestone: Identifiable, Codable {
    let id: String
    let goalId: String
    let percentage: Int
    let amount: Decimal
    let reachedAt: Date?
    let message: String

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case percentage, amount
        case reachedAt = "reached_at"
        case message
    }

    var isReached: Bool {
        return reachedAt != nil
    }

    static func defaultMilestones(for goal: FurgSavingsGoal) -> [GoalMilestone] {
        let milestones = [10, 25, 50, 75, 90, 100]
        return milestones.enumerated().map { index, percentage in
            let amount = goal.targetAmount * Decimal(percentage) / 100
            let message = milestoneMessage(for: percentage)
            return GoalMilestone(
                id: "\(goal.id)-\(percentage)",
                goalId: goal.id,
                percentage: percentage,
                amount: amount,
                reachedAt: nil,
                message: message
            )
        }
    }

    static func milestoneMessage(for percentage: Int) -> String {
        switch percentage {
        case 10: return "You've started! The hardest part is over."
        case 25: return "Quarter way there! Keep that momentum."
        case 50: return "HALFWAY! You're killing it."
        case 75: return "Three quarters done. The finish line is in sight."
        case 90: return "Almost there! Don't stop now."
        case 100: return "GOAL ACHIEVED! You absolute legend."
        default: return "Great progress!"
        }
    }
}

// MARK: - Round-Up Configuration

struct RoundUpConfig: Codable {
    var enabled: Bool
    var linkedCardIds: [String]
    var roundUpTo: RoundUpAmount
    var multiplier: Int
    var dailyCap: Decimal?
    var weeklyCap: Decimal?
    var investmentAccountId: String?
    var goalId: String?
    var transferFrequency: TransferFrequency
    var minimumTransfer: Decimal

    enum CodingKeys: String, CodingKey {
        case enabled
        case linkedCardIds = "linked_card_ids"
        case roundUpTo = "round_up_to"
        case multiplier
        case dailyCap = "daily_cap"
        case weeklyCap = "weekly_cap"
        case investmentAccountId = "investment_account_id"
        case goalId = "goal_id"
        case transferFrequency = "transfer_frequency"
        case minimumTransfer = "minimum_transfer"
    }

    static var `default`: RoundUpConfig {
        RoundUpConfig(
            enabled: false,
            linkedCardIds: [],
            roundUpTo: .nearestDollar,
            multiplier: 1,
            dailyCap: nil,
            weeklyCap: nil,
            investmentAccountId: nil,
            goalId: nil,
            transferFrequency: .weekly,
            minimumTransfer: 5
        )
    }
}

enum RoundUpAmount: String, Codable, CaseIterable {
    case nearestDollar = "nearest_dollar"
    case nearestTwo = "nearest_two"
    case nearestFive = "nearest_five"

    var label: String {
        switch self {
        case .nearestDollar: return "Nearest $1"
        case .nearestTwo: return "Nearest $2"
        case .nearestFive: return "Nearest $5"
        }
    }

    func calculate(from amount: Decimal) -> Decimal {
        let roundTo: Decimal
        switch self {
        case .nearestDollar: roundTo = 1
        case .nearestTwo: roundTo = 2
        case .nearestFive: roundTo = 5
        }

        let remainder = amount.truncatingRemainder(dividingBy: roundTo)
        if remainder == 0 { return 0 }
        return roundTo - remainder
    }
}

enum TransferFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly

    var label: String {
        rawValue.capitalized
    }
}

// MARK: - Round-Up Transaction

struct RoundUpTransaction: Identifiable, Codable {
    let id: String
    let sourceTransactionId: String
    let originalAmount: Decimal
    let roundedAmount: Decimal
    let roundUpAmount: Decimal
    let multipliedAmount: Decimal
    let status: RoundUpStatus
    let transferId: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sourceTransactionId = "source_transaction_id"
        case originalAmount = "original_amount"
        case roundedAmount = "rounded_amount"
        case roundUpAmount = "round_up_amount"
        case multipliedAmount = "multiplied_amount"
        case status
        case transferId = "transfer_id"
        case createdAt = "created_at"
    }
}

enum RoundUpStatus: String, Codable {
    case pending
    case transferred
    case invested
    case failed
}

// MARK: - API Response Models

struct GoalsResponse: Codable {
    let goals: [FurgSavingsGoal]
}

struct GoalProgressResponse: Codable {
    let progress: GoalProgress
    let milestones: [GoalMilestone]
    let recentContributions: [GoalContribution]

    enum CodingKeys: String, CodingKey {
        case progress, milestones
        case recentContributions = "recent_contributions"
    }
}

struct CreateGoalRequest: Codable {
    let name: String
    let targetAmount: Decimal
    let deadline: Date?
    let category: GoalCategory
    let icon: String?
    let color: String?
    let autoContribute: Bool?
    let autoContributeAmount: Decimal?
    let autoContributeFrequency: RecurringFrequency?

    enum CodingKeys: String, CodingKey {
        case name
        case targetAmount = "target_amount"
        case deadline, category, icon, color
        case autoContribute = "auto_contribute"
        case autoContributeAmount = "auto_contribute_amount"
        case autoContributeFrequency = "auto_contribute_frequency"
    }
}

struct ContributeToGoalRequest: Codable {
    let amount: Decimal
    let source: ContributionSource
    let note: String?
}

struct RoundUpSummary: Codable {
    let totalRoundedUp: Decimal
    let totalTransferred: Decimal
    let pendingAmount: Decimal
    let transactionCount: Int
    let lastTransferDate: Date?

    enum CodingKeys: String, CodingKey {
        case totalRoundedUp = "total_rounded_up"
        case totalTransferred = "total_transferred"
        case pendingAmount = "pending_amount"
        case transactionCount = "transaction_count"
        case lastTransferDate = "last_transfer_date"
    }
}
