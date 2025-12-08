//
//  FinancialHealthManager.swift
//  Furg
//
//  Comprehensive financial health scoring and analysis
//

import Foundation
import SwiftUI
import Combine

class FinancialHealthManager: ObservableObject {
    static let shared = FinancialHealthManager()

    @Published var healthScore: Int = 0
    @Published var healthGrade: HealthGrade = .c
    @Published var scoreBreakdown: [ScoreComponent] = []
    @Published var recommendations: [HealthRecommendation] = []
    @Published var scoreHistory: [ScoreHistoryPoint] = []

    private init() {
        calculateHealthScore()
        loadScoreHistory()
    }

    // MARK: - Score Calculation

    func calculateHealthScore() {
        var components: [ScoreComponent] = []

        // 1. Savings Rate (25 points max)
        let savingsRateScore = calculateSavingsRateScore()
        components.append(savingsRateScore)

        // 2. Debt-to-Income Ratio (20 points max)
        let dtiScore = calculateDTIScore()
        components.append(dtiScore)

        // 3. Emergency Fund (20 points max)
        let emergencyFundScore = calculateEmergencyFundScore()
        components.append(emergencyFundScore)

        // 4. Budget Adherence (15 points max)
        let budgetScore = calculateBudgetScore()
        components.append(budgetScore)

        // 5. Spending Patterns (10 points max)
        let spendingScore = calculateSpendingPatternScore()
        components.append(spendingScore)

        // 6. Goal Progress (10 points max)
        let goalScore = calculateGoalProgressScore()
        components.append(goalScore)

        scoreBreakdown = components
        healthScore = components.reduce(0) { $0 + $1.score }
        healthGrade = HealthGrade.fromScore(healthScore)

        generateRecommendations()
    }

    private func calculateSavingsRateScore() -> ScoreComponent {
        // Demo calculation - in production, use actual income/savings data
        let savingsRate = 0.18 // 18% savings rate
        let maxScore = 25

        let score: Int
        let status: ComponentStatus

        if savingsRate >= 0.20 {
            score = maxScore
            status = .excellent
        } else if savingsRate >= 0.15 {
            score = Int(Double(maxScore) * 0.85)
            status = .good
        } else if savingsRate >= 0.10 {
            score = Int(Double(maxScore) * 0.65)
            status = .fair
        } else if savingsRate >= 0.05 {
            score = Int(Double(maxScore) * 0.45)
            status = .needsWork
        } else {
            score = Int(Double(maxScore) * 0.2)
            status = .critical
        }

        return ScoreComponent(
            name: "Savings Rate",
            icon: "banknote.fill",
            score: score,
            maxScore: maxScore,
            status: status,
            detail: "\(Int(savingsRate * 100))% of income saved",
            recommendation: savingsRate < 0.20 ? "Aim for 20% savings rate" : nil
        )
    }

    private func calculateDTIScore() -> ScoreComponent {
        let dti = 0.28 // 28% debt-to-income
        let maxScore = 20

        let score: Int
        let status: ComponentStatus

        if dti <= 0.20 {
            score = maxScore
            status = .excellent
        } else if dti <= 0.30 {
            score = Int(Double(maxScore) * 0.8)
            status = .good
        } else if dti <= 0.40 {
            score = Int(Double(maxScore) * 0.6)
            status = .fair
        } else if dti <= 0.50 {
            score = Int(Double(maxScore) * 0.4)
            status = .needsWork
        } else {
            score = Int(Double(maxScore) * 0.2)
            status = .critical
        }

        return ScoreComponent(
            name: "Debt-to-Income",
            icon: "creditcard.fill",
            score: score,
            maxScore: maxScore,
            status: status,
            detail: "\(Int(dti * 100))% DTI ratio",
            recommendation: dti > 0.30 ? "Work on reducing debt payments" : nil
        )
    }

    private func calculateEmergencyFundScore() -> ScoreComponent {
        let monthsCovered = 2.5 // 2.5 months of expenses saved
        let maxScore = 20

        let score: Int
        let status: ComponentStatus

        if monthsCovered >= 6 {
            score = maxScore
            status = .excellent
        } else if monthsCovered >= 3 {
            score = Int(Double(maxScore) * 0.75)
            status = .good
        } else if monthsCovered >= 1 {
            score = Int(Double(maxScore) * 0.5)
            status = .fair
        } else if monthsCovered >= 0.5 {
            score = Int(Double(maxScore) * 0.3)
            status = .needsWork
        } else {
            score = Int(Double(maxScore) * 0.1)
            status = .critical
        }

        return ScoreComponent(
            name: "Emergency Fund",
            icon: "shield.fill",
            score: score,
            maxScore: maxScore,
            status: status,
            detail: String(format: "%.1f months covered", monthsCovered),
            recommendation: monthsCovered < 6 ? "Build up to 6 months of expenses" : nil
        )
    }

    private func calculateBudgetScore() -> ScoreComponent {
        let budgetAdherence = 0.92 // 92% within budget
        let maxScore = 15

        let score: Int
        let status: ComponentStatus

        if budgetAdherence >= 0.95 {
            score = maxScore
            status = .excellent
        } else if budgetAdherence >= 0.85 {
            score = Int(Double(maxScore) * 0.8)
            status = .good
        } else if budgetAdherence >= 0.75 {
            score = Int(Double(maxScore) * 0.6)
            status = .fair
        } else {
            score = Int(Double(maxScore) * 0.4)
            status = .needsWork
        }

        return ScoreComponent(
            name: "Budget Adherence",
            icon: "chart.pie.fill",
            score: score,
            maxScore: maxScore,
            status: status,
            detail: "\(Int(budgetAdherence * 100))% on track",
            recommendation: budgetAdherence < 0.90 ? "Track spending more closely" : nil
        )
    }

    private func calculateSpendingPatternScore() -> ScoreComponent {
        // Based on spending consistency and avoiding impulse purchases
        let patternScore = 7 // Out of 10
        let maxScore = 10

        let status: ComponentStatus = patternScore >= 8 ? .excellent : patternScore >= 6 ? .good : .fair

        return ScoreComponent(
            name: "Spending Patterns",
            icon: "waveform.path.ecg",
            score: patternScore,
            maxScore: maxScore,
            status: status,
            detail: "Mostly consistent",
            recommendation: patternScore < 8 ? "Reduce impulse purchases" : nil
        )
    }

    private func calculateGoalProgressScore() -> ScoreComponent {
        let goalProgress = 0.65 // 65% toward goals on average
        let maxScore = 10

        let score = Int(Double(maxScore) * goalProgress)
        let status: ComponentStatus = goalProgress >= 0.8 ? .excellent : goalProgress >= 0.5 ? .good : .fair

        return ScoreComponent(
            name: "Goal Progress",
            icon: "target",
            score: score,
            maxScore: maxScore,
            status: status,
            detail: "\(Int(goalProgress * 100))% toward goals",
            recommendation: goalProgress < 0.5 ? "Increase goal contributions" : nil
        )
    }

    // MARK: - Recommendations

    private func generateRecommendations() {
        recommendations = []

        for component in scoreBreakdown {
            if let rec = component.recommendation {
                let priority: RecommendationPriority
                switch component.status {
                case .critical: priority = .high
                case .needsWork: priority = .medium
                default: priority = .low
                }

                recommendations.append(HealthRecommendation(
                    title: component.name,
                    description: rec,
                    icon: component.icon,
                    priority: priority,
                    impact: "Could improve score by \(component.maxScore - component.score) points"
                ))
            }
        }

        recommendations.sort { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - History

    private func loadScoreHistory() {
        // Demo history data
        let calendar = Calendar.current
        let now = Date()

        scoreHistory = (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let baseScore = 72
            let variation = Int.random(in: -5...5)
            return ScoreHistoryPoint(date: date, score: baseScore + variation)
        }
    }

    func refreshScore() {
        calculateHealthScore()

        // Add current score to history
        scoreHistory.append(ScoreHistoryPoint(date: Date(), score: healthScore))

        // Keep only last 90 days
        if scoreHistory.count > 90 {
            scoreHistory.removeFirst()
        }
    }
}

// MARK: - Models

struct ScoreComponent: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let score: Int
    let maxScore: Int
    let status: ComponentStatus
    let detail: String
    let recommendation: String?

    var percentage: Double {
        Double(score) / Double(maxScore)
    }
}

enum ComponentStatus {
    case excellent, good, fair, needsWork, critical

    var color: Color {
        switch self {
        case .excellent: return .furgSuccess
        case .good: return .furgMint
        case .fair: return .furgWarning
        case .needsWork: return .orange
        case .critical: return .furgDanger
        }
    }

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .needsWork: return "Needs Work"
        case .critical: return "Critical"
        }
    }
}

enum HealthGrade: String, CaseIterable {
    case aPlus = "A+"
    case a = "A"
    case bPlus = "B+"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    static func fromScore(_ score: Int) -> HealthGrade {
        switch score {
        case 95...100: return .aPlus
        case 85..<95: return .a
        case 75..<85: return .bPlus
        case 65..<75: return .b
        case 50..<65: return .c
        case 35..<50: return .d
        default: return .f
        }
    }

    var color: Color {
        switch self {
        case .aPlus, .a: return .furgSuccess
        case .bPlus, .b: return .furgMint
        case .c: return .furgWarning
        case .d: return .orange
        case .f: return .furgDanger
        }
    }

    var description: String {
        switch self {
        case .aPlus: return "Outstanding"
        case .a: return "Excellent"
        case .bPlus: return "Very Good"
        case .b: return "Good"
        case .c: return "Fair"
        case .d: return "Needs Improvement"
        case .f: return "Critical"
        }
    }
}

struct HealthRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let priority: RecommendationPriority
    let impact: String
}

enum RecommendationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3

    var color: Color {
        switch self {
        case .low: return .furgInfo
        case .medium: return .furgWarning
        case .high: return .furgDanger
        }
    }
}

struct ScoreHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}
