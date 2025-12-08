//
//  SmartBudgetAlerts.swift
//  Furg
//
//  Intelligent budget alert system with predictive warnings
//

import Foundation
import SwiftUI
import Combine

class SmartBudgetAlertManager: ObservableObject {
    static let shared = SmartBudgetAlertManager()

    @Published var activeAlerts: [BudgetAlert] = []
    @Published var dismissedAlertIds: Set<String> = []
    @Published var alertSettings: AlertSettings = AlertSettings()

    private init() {
        generateSmartAlerts()
    }

    // MARK: - Alert Generation

    func generateSmartAlerts() {
        var alerts: [BudgetAlert] = []

        // Pace Alert - spending faster than usual
        alerts.append(BudgetAlert(
            id: "pace_warning",
            type: .paceWarning,
            title: "Spending Pace Alert",
            message: "You're spending 23% faster than your usual pace. At this rate, you'll exceed your budget by Dec 20.",
            severity: .warning,
            category: nil,
            actionLabel: "View Breakdown",
            actionType: .viewDetails,
            predictedOverage: 340.50,
            daysUntilOverage: 12
        ))

        // Category Spike
        alerts.append(BudgetAlert(
            id: "category_spike_dining",
            type: .categorySpike,
            title: "Dining Spending Spike",
            message: "You've spent $287 on dining this week - that's 65% more than your weekly average.",
            severity: .info,
            category: "Food & Dining",
            actionLabel: "Set Limit",
            actionType: .setLimit,
            predictedOverage: nil,
            daysUntilOverage: nil
        ))

        // Unusual Transaction
        alerts.append(BudgetAlert(
            id: "unusual_txn",
            type: .unusualTransaction,
            title: "Unusual Transaction",
            message: "A $450 charge at 'Electronics Plus' is higher than your typical purchases in Shopping.",
            severity: .info,
            category: "Shopping",
            actionLabel: "Review",
            actionType: .reviewTransaction,
            predictedOverage: nil,
            daysUntilOverage: nil
        ))

        // Bill Increase
        alerts.append(BudgetAlert(
            id: "bill_increase",
            type: .billIncrease,
            title: "Bill Increased",
            message: "Your electricity bill went up 18% from last month ($127 → $150).",
            severity: .info,
            category: "Utilities",
            actionLabel: "View History",
            actionType: .viewDetails,
            predictedOverage: nil,
            daysUntilOverage: nil
        ))

        // Savings Opportunity
        alerts.append(BudgetAlert(
            id: "savings_opportunity",
            type: .savingsOpportunity,
            title: "Savings Opportunity",
            message: "You have $340 unspent this month. Want to move it to savings before you spend it?",
            severity: .positive,
            category: nil,
            actionLabel: "Save Now",
            actionType: .transferToSavings,
            predictedOverage: nil,
            daysUntilOverage: nil
        ))

        // Subscription Warning
        alerts.append(BudgetAlert(
            id: "sub_renewal",
            type: .subscriptionRenewal,
            title: "Annual Renewal Coming",
            message: "Your Adobe Creative Cloud ($599.99/yr) renews in 5 days. Cancel or switch to monthly?",
            severity: .warning,
            category: "Subscriptions",
            actionLabel: "Manage",
            actionType: .manageSubscription,
            predictedOverage: nil,
            daysUntilOverage: 5
        ))

        activeAlerts = alerts.filter { !dismissedAlertIds.contains($0.id) }
    }

    func dismissAlert(_ alert: BudgetAlert) {
        dismissedAlertIds.insert(alert.id)
        activeAlerts.removeAll { $0.id == alert.id }
    }

    func snoozeAlert(_ alert: BudgetAlert, hours: Int) {
        // In production, would schedule reappearance
        dismissAlert(alert)
    }

    func handleAlertAction(_ alert: BudgetAlert) {
        switch alert.actionType {
        case .viewDetails:
            // Navigate to details
            break
        case .setLimit:
            // Open limit setter
            break
        case .reviewTransaction:
            // Open transaction
            break
        case .transferToSavings:
            // Initiate transfer
            break
        case .manageSubscription:
            // Open subscription management
            break
        }
    }
}

// MARK: - Models

struct BudgetAlert: Identifiable {
    let id: String
    let type: AlertType
    let title: String
    let message: String
    let severity: AlertSeverity
    let category: String?
    let actionLabel: String
    let actionType: AlertAction
    let predictedOverage: Double?
    let daysUntilOverage: Int?

    enum AlertType {
        case paceWarning
        case categorySpike
        case unusualTransaction
        case billIncrease
        case savingsOpportunity
        case subscriptionRenewal
        case goalAtRisk
    }
}

enum AlertSeverity {
    case critical, warning, info, positive

    var color: Color {
        switch self {
        case .critical: return .furgDanger
        case .warning: return .furgWarning
        case .info: return .furgInfo
        case .positive: return .furgSuccess
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        case .positive: return "checkmark.circle.fill"
        }
    }
}

enum AlertAction {
    case viewDetails
    case setLimit
    case reviewTransaction
    case transferToSavings
    case manageSubscription
}

struct AlertSettings {
    var paceAlertsEnabled = true
    var categorySpikesEnabled = true
    var unusualTransactionsEnabled = true
    var billChangesEnabled = true
    var savingsOpportunitiesEnabled = true
    var subscriptionRemindersEnabled = true
    var alertThreshold: Double = 0.15 // 15% variance triggers alert
}
