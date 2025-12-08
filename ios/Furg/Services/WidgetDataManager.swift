//
//  WidgetDataManager.swift
//  Furg
//
//  Manages data sharing between the main app and iOS widgets
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let sharedDefaults = UserDefaults(suiteName: "group.com.furg.app")

    private init() {}

    // MARK: - Balance Widget Data

    func updateBalanceData(
        totalBalance: Double,
        change: Double,
        changePercent: Double,
        accountCount: Int
    ) {
        sharedDefaults?.set(totalBalance, forKey: "widget_total_balance")
        sharedDefaults?.set(change, forKey: "widget_balance_change")
        sharedDefaults?.set(changePercent, forKey: "widget_balance_change_percent")
        sharedDefaults?.set(accountCount, forKey: "widget_account_count")
        sharedDefaults?.set(Date(), forKey: "widget_last_updated")

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "BalanceWidget")
    }

    // MARK: - Spending Widget Data

    func updateSpendingData(
        monthlySpent: Double,
        monthlyBudget: Double
    ) {
        sharedDefaults?.set(monthlySpent, forKey: "widget_monthly_spent")
        sharedDefaults?.set(monthlyBudget, forKey: "widget_monthly_budget")

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "SpendingWidget")
    }

    // MARK: - Goals Widget Data

    struct WidgetGoalData: Codable {
        let name: String
        let current: Double
        let target: Double
        let icon: String
        let color: String
        let daysRemaining: Int?
    }

    func updateGoalsData(goals: [WidgetGoalData]) {
        if let encoded = try? JSONEncoder().encode(goals) {
            sharedDefaults?.set(encoded, forKey: "widget_goals")
        }

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "GoalsWidget")
    }

    // MARK: - Refresh All Widgets

    func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Clear Widget Data

    func clearAllData() {
        let keys = [
            "widget_total_balance",
            "widget_balance_change",
            "widget_balance_change_percent",
            "widget_account_count",
            "widget_last_updated",
            "widget_monthly_spent",
            "widget_monthly_budget",
            "widget_goals"
        ]

        keys.forEach { sharedDefaults?.removeObject(forKey: $0) }
        refreshAllWidgets()
    }
}

// MARK: - FinanceManager Extension

extension FinanceManager {
    func syncToWidgets() {
        let widgetManager = WidgetDataManager.shared

        // Sync balance data
        let totalBalance = accounts.reduce(0.0) { $0 + $1.currentBalance }
        let change = monthlyChange
        let changePercent = totalBalance > 0 ? (change / totalBalance) * 100 : 0

        widgetManager.updateBalanceData(
            totalBalance: totalBalance,
            change: change,
            changePercent: changePercent,
            accountCount: accounts.count
        )

        // Sync spending data
        widgetManager.updateSpendingData(
            monthlySpent: monthlySpending,
            monthlyBudget: monthlyBudget ?? 4000
        )
    }
}

// MARK: - GoalsManager Extension

extension GoalsManager {
    func syncToWidgets() {
        let widgetManager = WidgetDataManager.shared

        let widgetGoals = goals.map { goal -> WidgetDataManager.WidgetGoalData in
            let daysRemaining: Int?
            if let deadline = goal.deadline {
                daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
            } else {
                daysRemaining = nil
            }

            return WidgetDataManager.WidgetGoalData(
                name: goal.name,
                current: Double(truncating: goal.currentAmount as NSNumber),
                target: Double(truncating: goal.targetAmount as NSNumber),
                icon: goal.icon,
                color: goal.color,
                daysRemaining: daysRemaining
            )
        }

        widgetManager.updateGoalsData(goals: widgetGoals)
    }
}
