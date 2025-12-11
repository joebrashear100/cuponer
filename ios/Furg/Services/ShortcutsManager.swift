//
//  ShortcutsManager.swift
//  Furg
//
//  App Intents for Siri and Shortcuts integration
//

import Foundation
import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct FurgShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckBalanceIntent(),
            phrases: [
                "Check my balance in \(.applicationName)",
                "What's my spending power in \(.applicationName)",
                "How much money do I have in \(.applicationName)"
            ],
            shortTitle: "Check Balance",
            systemImageName: "dollarsign.circle.fill"
        )

        AppShortcut(
            intent: CheckSpendingIntent(),
            phrases: [
                "How much have I spent in \(.applicationName)",
                "Show my spending in \(.applicationName)",
                "What did I spend today in \(.applicationName)"
            ],
            shortTitle: "Check Spending",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: HideMoneyIntent(),
            phrases: [
                "Hide money in \(.applicationName)",
                "Save money in \(.applicationName)",
                "Hide \(\.$amount) dollars in \(.applicationName)"
            ],
            shortTitle: "Hide Money",
            systemImageName: "eye.slash.fill"
        )

        AppShortcut(
            intent: GetFinancialTipIntent(),
            phrases: [
                "Give me a financial tip from \(.applicationName)",
                "Financial advice from \(.applicationName)",
                "Money tip from \(.applicationName)"
            ],
            shortTitle: "Financial Tip",
            systemImageName: "lightbulb.fill"
        )

        AppShortcut(
            intent: CheckGoalProgressIntent(),
            phrases: [
                "How are my savings goals in \(.applicationName)",
                "Check goal progress in \(.applicationName)",
                "Show my goals in \(.applicationName)"
            ],
            shortTitle: "Goal Progress",
            systemImageName: "target"
        )
    }
}

// MARK: - Check Balance Intent

struct CheckBalanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Balance"
    static var description = IntentDescription("Check your current balance and spending power")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // In production, fetch from FinanceManager
        let availableBalance = 3847.50
        let hiddenBalance = 1200.00
        let spendingPower = 2847.50

        return .result(
            dialog: "You have $\(Int(spendingPower)) spending power. I'm protecting $\(Int(hiddenBalance)) in savings for you.",
            view: BalanceSnippetView(available: availableBalance, hidden: hiddenBalance, spendingPower: spendingPower)
        )
    }
}

struct BalanceSnippetView: View {
    let available: Double
    let hidden: Double
    let spendingPower: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                Text("Spending Power")
                    .font(.headline)
                Spacer()
                Text("$\(Int(spendingPower))")
                    .font(.title2.bold())
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Int(available))")
                        .font(.subheadline.bold())
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Hidden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Int(hidden))")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }
}

// MARK: - Check Spending Intent

struct CheckSpendingIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Spending"
    static var description = IntentDescription("See how much you've spent today or this week")

    @Parameter(title: "Time Period", default: .today)
    var period: SpendingPeriod

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, fetch from FinanceManager
        let spending: Double
        let periodText: String

        switch period {
        case .today:
            spending = 127.45
            periodText = "today"
        case .thisWeek:
            spending = 543.20
            periodText = "this week"
        case .thisMonth:
            spending = 2150.00
            periodText = "this month"
        }

        return .result(
            dialog: "You've spent $\(Int(spending)) \(periodText). \(spending > 100 ? "Maybe slow down a bit?" : "Looking good!")"
        )
    }
}

enum SpendingPeriod: String, AppEnum {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Period")
    static var caseDisplayRepresentations: [SpendingPeriod: DisplayRepresentation] = [
        .today: "Today",
        .thisWeek: "This Week",
        .thisMonth: "This Month"
    ]
}

// MARK: - Hide Money Intent

struct HideMoneyIntent: AppIntent {
    static var title: LocalizedStringResource = "Hide Money"
    static var description = IntentDescription("Hide money from yourself for savings")

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Purpose", default: "General Savings")
    var purpose: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            return .result(dialog: "Please specify an amount greater than zero.")
        }

        // In production, call FinanceManager to hide money
        return .result(
            dialog: "Done! I've hidden $\(Int(amount)) for \(purpose). Out of sight, out of mind. Smart move!"
        )
    }
}

// MARK: - Financial Tip Intent

struct GetFinancialTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Financial Tip"
    static var description = IntentDescription("Get a personalized financial tip")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let tips = [
            "The 50/30/20 rule: 50% needs, 30% wants, 20% savings. How are you doing?",
            "Small daily expenses add up. That $5 coffee is $1,825 a year!",
            "Pay yourself first - automate your savings before you see the money.",
            "Review your subscriptions monthly. Zombie subscriptions are budget killers.",
            "Emergency fund goal: 3-6 months of expenses. Start with $1,000.",
            "The best investment is paying off high-interest debt first.",
            "Wait 24 hours before any purchase over $100. Still want it? Then buy it.",
            "Track every expense for a month. You'll be surprised where money goes."
        ]

        let tip = tips.randomElement() ?? tips[0]
        return .result(dialog: tip)
    }
}

// MARK: - Check Goal Progress Intent

struct CheckGoalProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Goal Progress"
    static var description = IntentDescription("See your savings goal progress")

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Demo data - in production, fetch from GoalsManager
        let goals = [
            GoalProgress(name: "Emergency Fund", current: 3500, target: 5000),
            GoalProgress(name: "Vacation", current: 800, target: 2000),
            GoalProgress(name: "New Laptop", current: 450, target: 1500)
        ]

        let summary = goals.map { goal in
            "\(goal.name): \(Int(goal.percentComplete))%"
        }.joined(separator: ", ")

        return .result(
            dialog: "Here's your goal progress: \(summary). Keep going!",
            view: GoalProgressSnippetView(goals: goals)
        )
    }
}

struct ShortcutGoalProgress: Identifiable {
    let id = UUID()
    let name: String
    let current: Double
    let target: Double

    var percentComplete: Double {
        (current / target) * 100
    }
}

struct GoalProgressSnippetView: View {
    let goals: [ShortcutGoalProgress]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(goals) { goal in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.name)
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(Int(goal.percentComplete))%")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }

                    ProgressView(value: goal.current, total: goal.target)
                        .tint(.green)

                    Text("$\(Int(goal.current)) of $\(Int(goal.target))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Quick Actions Intent

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Quickly log an expense")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Merchant")
    var merchant: String

    @Parameter(title: "Category", default: "Shopping")
    var category: ExpenseCategory

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, add to FinanceManager
        return .result(
            dialog: "Added $\(Int(amount)) expense at \(merchant) in \(category.rawValue)."
        )
    }
}

enum ExpenseCategory: String, AppEnum {
    case food = "Food & Dining"
    case shopping = "Shopping"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case other = "Other"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    static var caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] = [
        .food: "Food & Dining",
        .shopping: "Shopping",
        .transportation: "Transportation",
        .entertainment: "Entertainment",
        .utilities: "Utilities",
        .other: "Other"
    ]
}
