//
//  MainDashboardV2.swift
//  Furg
//
//  Complete redesign - Single scrolling dashboard with all key information
//  No bottom tab bar - uses sheets and navigation for drill-downs
//

import SwiftUI

struct MainDashboardV2: View {
    @State private var showSettings = false
    @State private var showAllTransactions = false
    @State private var showCategoryDetail: CategorySpendingV2?
    @State private var selectedTimeframe: Timeframe = .month
    @State private var scrollOffset: CGFloat = 0

    // Sample data - would come from FinanceManager in real app
    @State private var monthlyBudget: Double = 2000
    @State private var totalSpent: Double = 1350
    @State private var monthlyIncome: Double = 4500

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    var remainingBudget: Double { monthlyBudget - totalSpent }
    var budgetProgress: Double { totalSpent / monthlyBudget }
    var daysLeft: Int {
        let calendar = Calendar.current
        let today = Date()
        guard let range = calendar.range(of: .day, in: .month, for: today) else { return 0 }
        let currentDay = calendar.component(.day, from: today)
        return range.count - currentDay
    }

    var body: some View {
        ZStack {
            // Background
            Color.v2Background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Main content
                    VStack(spacing: 20) {
                        // Hero: Budget remaining
                        heroSection

                        // Quick stats row
                        quickStatsSection

                        // Timeframe selector
                        timeframeSelector

                        // Budget tracking chart
                        budgetChartSection

                        // Spending by category
                        categorySection

                        // Recent transactions
                        recentTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showAllTransactions) {
            TransactionsListV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(item: $showCategoryDetail) { category in
            CategoryDetailV2(category: category)
                .presentationBackground(Color.v2Background)
        }
    }

    // MARK: - Header

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.v2Caption)
                    .foregroundColor(.v2TextSecondary)
                Text("December 2025")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.v2TextSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.v2CardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    // MARK: - Hero Section

    var heroSection: some View {
        V2Card(padding: 24) {
            VStack(spacing: 16) {
                // Main amount
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(.v2Mint)
                        Text(formatNumber(remainingBudget))
                            .font(.v2DisplayLarge)
                            .foregroundColor(.v2TextPrimary)
                    }

                    Text("left to spend this month")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)
                }

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))

                            // Progress
                            if budgetProgress > 1 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.v2Coral)
                                    .frame(width: geo.size.width * min(budgetProgress, 1))
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(V2Gradients.budgetLine)
                                    .frame(width: geo.size.width * min(budgetProgress, 1))
                            }
                        }
                    }
                    .frame(height: 10)

                    // Labels
                    HStack {
                        Text("$\(Int(totalSpent)) spent")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)

                        Spacer()

                        Text("$\(Int(monthlyBudget)) budget")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                // Status badge
                HStack(spacing: 8) {
                    let dailyBudget = remainingBudget / Double(max(daysLeft, 1))
                    let isOnTrack = budgetProgress < (Double(Calendar.current.component(.day, from: Date())) / 30.0)

                    Image(systemName: isOnTrack ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isOnTrack ? .v2Lime : .v2Gold)

                    Text(isOnTrack ? "On track" : "Spending faster than planned")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)

                    Spacer()

                    Text("$\(Int(dailyBudget))/day")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2Mint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.v2Mint.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Quick Stats

    var quickStatsSection: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                icon: "arrow.down.circle.fill",
                iconColor: .v2Lime,
                label: "Income",
                value: "$\(formatNumber(monthlyIncome))"
            )

            QuickStatCard(
                icon: "arrow.up.circle.fill",
                iconColor: .v2Coral,
                label: "Spent",
                value: "$\(formatNumber(totalSpent))"
            )

            QuickStatCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .v2Blue,
                label: "Saved",
                value: "$\(formatNumber(monthlyIncome - totalSpent))"
            )
        }
    }

    // MARK: - Timeframe Selector

    var timeframeSelector: some View {
        HStack(spacing: 8) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(.v2Caption)
                        .foregroundColor(selectedTimeframe == timeframe ? .v2Background : .v2TextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedTimeframe == timeframe
                            ? Color.v2Mint
                            : Color.v2CardBackground
                        )
                        .cornerRadius(20)
                }
            }
            Spacer()
        }
    }

    // MARK: - Budget Chart Section

    var budgetChartSection: some View {
        V2Card {
            V2BudgetLineChart(
                dailySpending: generateSampleDailySpending(),
                monthlyBudget: monthlyBudget,
                daysInMonth: 31
            )
        }
    }

    // MARK: - Category Section

    var categorySection: some View {
        VStack(spacing: 12) {
            V2SectionHeader(title: "Spending by Category", action: "See all") {
                // Navigate to full categories view
            }

            V2Card(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(sampleCategories.prefix(4), id: \.name) { category in
                        Button {
                            showCategoryDetail = category
                        } label: {
                            V2CategoryRow(
                                name: category.name,
                                icon: category.icon,
                                color: category.color,
                                spent: category.amount,
                                budget: category.budget
                            )
                        }

                        if category.name != sampleCategories.prefix(4).last?.name {
                            Divider()
                                .background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Transactions

    var recentTransactionsSection: some View {
        VStack(spacing: 12) {
            V2SectionHeader(title: "Recent Activity", action: "See all") {
                showAllTransactions = true
            }

            V2Card(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(sampleTransactions.prefix(5)) { transaction in
                        V2TransactionRow(
                            icon: transaction.icon,
                            iconColor: transaction.color,
                            merchant: transaction.merchant,
                            category: transaction.category,
                            amount: transaction.amount,
                            date: transaction.dateString
                        )

                        if transaction.id != sampleTransactions.prefix(5).last?.id {
                            Divider()
                                .background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    func generateSampleDailySpending() -> [DailySpendingPoint] {
        var cumulative: Double = 0
        return (1...15).map { day in
            let daily = Double.random(in: 30...120)
            cumulative += daily
            return DailySpendingPoint(
                day: day,
                amount: daily,
                cumulativeAmount: cumulative
            )
        }
    }

    var sampleCategories: [CategorySpendingV2] {
        [
            CategorySpendingV2(name: "Food & Dining", icon: "fork.knife", color: .v2CategoryFood, amount: 387, budget: 500),
            CategorySpendingV2(name: "Shopping", icon: "bag.fill", color: .v2CategoryShopping, amount: 264, budget: 300),
            CategorySpendingV2(name: "Transportation", icon: "car.fill", color: .v2CategoryTransport, amount: 156, budget: 200),
            CategorySpendingV2(name: "Entertainment", icon: "tv.fill", color: .v2CategoryEntertainment, amount: 89, budget: 150),
            CategorySpendingV2(name: "Health", icon: "heart.fill", color: .v2CategoryHealth, amount: 45, budget: 100),
            CategorySpendingV2(name: "Travel", icon: "airplane", color: .v2CategoryTravel, amount: 320, budget: 400)
        ]
    }

    var sampleTransactions: [SampleTransaction] {
        [
            SampleTransaction(merchant: "Whole Foods", category: "Food & Dining", amount: -67.42, icon: "cart.fill", color: .v2CategoryFood, dateString: "Today"),
            SampleTransaction(merchant: "Uber", category: "Transportation", amount: -24.50, icon: "car.fill", color: .v2CategoryTransport, dateString: "Today"),
            SampleTransaction(merchant: "Netflix", category: "Entertainment", amount: -15.99, icon: "tv.fill", color: .v2CategoryEntertainment, dateString: "Yesterday"),
            SampleTransaction(merchant: "Amazon", category: "Shopping", amount: -89.00, icon: "bag.fill", color: .v2CategoryShopping, dateString: "Yesterday"),
            SampleTransaction(merchant: "Paycheck", category: "Income", amount: 2250.00, icon: "dollarsign.circle.fill", color: .v2Lime, dateString: "Dec 1")
        ]
    }
}

// MARK: - Quick Stat Card

struct DashboardQuickStatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        V2Card(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.v2BodyBold)
                        .foregroundColor(.v2TextPrimary)
                    Text(label)
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Sample Transaction Model

struct SampleTransaction: Identifiable {
    let id = UUID()
    let merchant: String
    let category: String
    let amount: Double
    let icon: String
    let color: Color
    let dateString: String
}

// MARK: - Placeholder Views

struct SettingsSheetV2: View {
    var body: some View {
        SettingsViewV2()
    }
}

struct TransactionsListV2: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()
                Text("All Transactions")
                    .foregroundColor(.v2TextPrimary)
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Mint)
                }
            }
        }
    }
}

struct CategoryDetailV2: View {
    let category: CategorySpendingV2
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Category header
                        V2Card {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(0.15))
                                        .frame(width: 64, height: 64)

                                    Image(systemName: category.icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(category.color)
                                }

                                Text(category.name)
                                    .font(.v2Title)
                                    .foregroundColor(.v2TextPrimary)

                                V2AmountDisplay(
                                    amount: category.amount,
                                    label: "of $\(Int(category.budget)) budget",
                                    size: .medium
                                )

                                // Progress
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(category.amount > category.budget ? Color.v2Coral : category.color)
                                            .frame(width: geo.size.width * min(category.amount / category.budget, 1))
                                    }
                                }
                                .frame(height: 8)
                            }
                        }

                        // Transactions in this category would go here
                        V2SectionHeader(title: "Transactions")

                        V2Card(padding: 16) {
                            Text("Transaction list for \(category.name)")
                                .foregroundColor(.v2TextSecondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Mint)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainDashboardV2()
}
