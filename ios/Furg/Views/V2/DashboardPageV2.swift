//
//  DashboardPageV2.swift
//  Furg
//
//  Dashboard page for V2 gesture navigation
//  Shows budget overview, quick stats, and recent transactions
//

import SwiftUI

struct DashboardPageV2: View {
    // MARK: - Actions
    var onShowChat: () -> Void = {}
    var onShowGoals: () -> Void = {}
    var onShowTransactions: () -> Void = {}

    // MARK: - Environment
    @EnvironmentObject var financeManager: FinanceManager

    // MARK: - State
    @State private var selectedTimeframe: Timeframe = .month

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Hero Section - Budget Overview
                heroSection

                // Quick Stats
                quickStatsSection

                // Timeframe Selector
                timeframeSelector

                // Category Breakdown
                categoryBreakdown

                // Recent Transactions
                recentTransactions
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        V2Card {
            VStack(spacing: 16) {
                // Greeting
                HStack {
                    Text("Good \(greeting)")
                        .font(.v2Headline)
                        .foregroundColor(.v2TextSecondary)
                    Spacer()
                }

                // Budget Remaining
                VStack(spacing: 8) {
                    Text("Budget Remaining")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextTertiary)

                    V2AmountDisplay(amount: budgetRemaining, size: .large)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(budgetProgress > 0.9 ? Color.v2Danger : Color.v2Primary)
                                .frame(width: geometry.size.width * min(budgetProgress, 1.0), height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Budget status
                    HStack {
                        Text("$\(Int(totalSpent)) spent")
                            .font(.v2Footnote)
                            .foregroundColor(.v2TextTertiary)

                        Spacer()

                        Text("$\(Int(monthlyBudget)) budget")
                            .font(.v2Footnote)
                            .foregroundColor(.v2TextTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            quickStatCard(
                icon: "arrow.down.circle.fill",
                value: "$\(Int(monthlyIncome))",
                label: "Income",
                color: .v2Success
            )

            quickStatCard(
                icon: "arrow.up.circle.fill",
                value: "$\(Int(totalSpent))",
                label: "Spent",
                color: .v2Accent
            )

            quickStatCard(
                icon: "banknote.fill",
                value: "$\(Int(savedThisMonth))",
                label: "Saved",
                color: .v2Primary
            )
        }
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        V2Card(padding: 12) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(.v2BodyMedium)
                    .foregroundColor(.v2TextPrimary)

                Text(label)
                    .font(.v2Footnote)
                    .foregroundColor(.v2TextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        HStack(spacing: 8) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    V2Pill(
                        text: timeframe.rawValue,
                        isSelected: selectedTimeframe == timeframe
                    )
                }
            }
            Spacer()
        }
    }

    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Spending by Category")

            VStack(spacing: 8) {
                ForEach(topCategories, id: \.name) { category in
                    V2CategoryRow(
                        name: category.name,
                        amount: category.spent,
                        budget: category.budget,
                        color: categoryColor(for: category.name)
                    )
                }
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(
                title: "Recent Transactions",
                action: "See All",
                onAction: onShowTransactions
            )

            VStack(spacing: 8) {
                ForEach(recentTransactionList.prefix(5), id: \.id) { transaction in
                    V2TransactionRow(
                        merchant: transaction.merchant,
                        category: transaction.category,
                        amount: transaction.amount,
                        date: transaction.date,
                        icon: categoryIcon(for: transaction.category),
                        iconColor: categoryColor(for: transaction.category)
                    )
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    private var monthlyBudget: Double {
        // Demo value - FinanceManager doesn't have monthlyBudget
        5000
    }

    private var totalSpent: Double {
        // Use actual transactions if available, otherwise demo
        if !financeManager.transactions.isEmpty {
            return financeManager.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
        }
        return 2450
    }

    private var monthlyIncome: Double {
        // Demo value - FinanceManager doesn't have monthlyIncome
        6500
    }

    private var savedThisMonth: Double {
        max(0, monthlyIncome - totalSpent)
    }

    private var budgetRemaining: Double {
        max(0, monthlyBudget - totalSpent)
    }

    private var budgetProgress: Double {
        guard monthlyBudget > 0 else { return 0 }
        return totalSpent / monthlyBudget
    }

    private var topCategories: [(name: String, spent: Double, budget: Double)] {
        // Sample data - will be from financeManager
        [
            ("Food & Dining", 650, 800),
            ("Shopping", 420, 500),
            ("Transportation", 280, 350),
            ("Entertainment", 180, 200),
            ("Bills", 520, 600)
        ]
    }

    private var recentTransactionList: [(id: String, merchant: String, category: String, amount: Double, date: Date)] {
        // Use actual transactions if available
        if !financeManager.transactions.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            return financeManager.transactions.prefix(5).map { transaction in
                let date = dateFormatter.date(from: transaction.date) ?? Date()
                return (transaction.id, transaction.merchant, transaction.category, transaction.amount, date)
            }
        }
        // Sample data fallback
        return [
            (UUID().uuidString, "Whole Foods", "Food & Dining", -87.50, Date().addingTimeInterval(-86400)),
            (UUID().uuidString, "Amazon", "Shopping", -156.99, Date().addingTimeInterval(-172800)),
            (UUID().uuidString, "Uber", "Transportation", -24.50, Date().addingTimeInterval(-259200)),
            (UUID().uuidString, "Netflix", "Entertainment", -15.99, Date().addingTimeInterval(-345600)),
            (UUID().uuidString, "Electric Company", "Bills", -145.00, Date().addingTimeInterval(-432000))
        ]
    }

    // MARK: - Helpers
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Food & Dining": return "fork.knife"
        case "Shopping": return "cart.fill"
        case "Transportation": return "car.fill"
        case "Entertainment": return "tv.fill"
        case "Bills": return "doc.text.fill"
        case "Health": return "heart.fill"
        case "Travel": return "airplane"
        default: return "creditcard.fill"
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Food & Dining": return .v2CategoryFood
        case "Shopping": return .v2CategoryShopping
        case "Transportation": return .v2CategoryTransport
        case "Entertainment": return .v2CategoryEntertainment
        case "Bills": return .v2CategoryBills
        case "Health": return .v2CategoryHealth
        case "Travel": return .v2CategoryTravel
        default: return .v2CategoryOther
        }
    }
}

#Preview {
    DashboardPageV2()
        .environmentObject(FinanceManager())
        .v2Background()
}
