//
//  SpendingDashboardView.swift
//  Furg
//
//  Detailed spending analytics dashboard with advanced metrics
//

import SwiftUI
import Charts

struct SpendingDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedTimeframe: Timeframe = .month
    @State private var selectedCategory: SpendingCategoryData?

    // Currency formatter since Formatters.swift isn't in project
    private func formatCurrency(_ value: Double) -> String {
        return String(format: "$%.0f", value)
    }

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    // Demo data
    let totalSpending: Double = 4235.67
    let budgetLimit: Double = 5000.00
    let avgDailySpend: Double = 141.19
    let topMerchant: String = "Amazon"
    let topMerchantAmount: Double = 523.45

    var categories: [SpendingCategoryData] {
        [
            SpendingCategoryData(name: "Housing", amount: 1500, budget: 1600, icon: "house.fill", color: .blue, transactions: 2),
            SpendingCategoryData(name: "Food & Dining", amount: 850, budget: 800, icon: "fork.knife", color: .orange, transactions: 24),
            SpendingCategoryData(name: "Transportation", amount: 450, budget: 500, icon: "car.fill", color: .purple, transactions: 12),
            SpendingCategoryData(name: "Shopping", amount: 620, budget: 400, icon: "bag.fill", color: .pink, transactions: 18),
            SpendingCategoryData(name: "Entertainment", amount: 380, budget: 300, icon: "tv.fill", color: .green, transactions: 8),
            SpendingCategoryData(name: "Subscriptions", amount: 250, budget: 250, icon: "repeat", color: .red, transactions: 6),
            SpendingCategoryData(name: "Utilities", amount: 185, budget: 200, icon: "bolt.fill", color: .yellow, transactions: 4)
        ]
    }

    var dailySpending: [DailySpend] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<14).reversed().map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            return DailySpend(date: date, amount: Double.random(in: 50...250))
        }
    }

    var body: some View {
        ZStack {
            Color.furgCharcoal.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // Time selector
                    timeframeSelector
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Overview cards
                    overviewCards
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Spending trend chart
                    spendingTrendCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Budget progress
                    budgetProgressCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Category breakdown
                    categoryBreakdownCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Insights
                    insightsCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending Dashboard")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Track where your money goes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
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
                    Text(timeframe.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedTimeframe == timeframe ? .furgCharcoal : .white.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeframe == timeframe ? Color.furgMint : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - Overview Cards

    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            OverviewMetricCard(
                title: "Total Spent",
                value: formatCurrency(totalSpending),
                subtitle: "\(Int((totalSpending/budgetLimit) * 100))% of budget",
                icon: "creditcard.fill",
                color: .furgWarning
            )

            OverviewMetricCard(
                title: "Daily Avg",
                value: formatCurrency(avgDailySpend),
                subtitle: "per day",
                icon: "calendar",
                color: .furgMint
            )

            OverviewMetricCard(
                title: "Top Category",
                value: "Housing",
                subtitle: formatCurrency(1500),
                icon: "house.fill",
                color: .blue
            )

            OverviewMetricCard(
                title: "Top Merchant",
                value: topMerchant,
                subtitle: formatCurrency(topMerchantAmount),
                icon: "storefront.fill",
                color: .purple
            )
        }
    }

    // MARK: - Spending Trend

    private var spendingTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Chart(dailySpending) { day in
                AreaMark(
                    x: .value("Date", day.date),
                    y: .value("Amount", day.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.furgWarning.opacity(0.4), Color.furgWarning.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", day.date),
                    y: .value("Amount", day.amount)
                )
                .foregroundStyle(Color.furgWarning)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.day())
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .frame(height: 150)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Budget Progress

    private var budgetProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Budget Status")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int((totalSpending/budgetLimit) * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(totalSpending > budgetLimit ? .furgDanger : .furgMint)
            }

            // Main progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 16)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: totalSpending > budgetLimit
                                    ? [.furgWarning, .furgDanger]
                                    : [.furgMint, .furgSeafoam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(totalSpending/budgetLimit, 1.0), height: 16)
                }
            }
            .frame(height: 16)

            HStack {
                Text(formatCurrency(totalSpending))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text("of \(formatCurrency(budgetLimit))")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Remaining
            HStack(spacing: 8) {
                Image(systemName: budgetLimit > totalSpending ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(budgetLimit > totalSpending ? .furgSuccess : .furgDanger)

                Text(budgetLimit > totalSpending
                     ? "\(formatCurrency(budgetLimit - totalSpending)) remaining"
                     : "\(formatCurrency(totalSpending - budgetLimit)) over budget")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            ForEach(categories) { category in
                CategorySpendRow(category: category)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Insights

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                InsightRow(
                    icon: "exclamationmark.triangle.fill",
                    color: .furgWarning,
                    text: "Food & Dining is 6% over budget this month"
                )

                InsightRow(
                    icon: "arrow.up.right",
                    color: .furgDanger,
                    text: "Shopping spending up 23% vs last month"
                )

                InsightRow(
                    icon: "checkmark.circle.fill",
                    color: .furgSuccess,
                    text: "Utilities spending down 12% - great job!"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Supporting Types

struct SpendingCategoryData: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let budget: Double
    let icon: String
    let color: Color
    let transactions: Int

    var percentOfBudget: Double { amount / budget }
    var isOverBudget: Bool { amount > budget }
}

struct DailySpend: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Supporting Views

private struct OverviewMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct CategorySpendRow: View {
    let category: SpendingCategoryData

    private func formatCurrency(_ value: Double) -> String {
        return String(format: "$%.0f", value)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(category.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Text("\(category.transactions) transactions")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(category.amount))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(category.isOverBudget ? "Over budget" : "\(Int((1 - category.percentOfBudget) * 100))% left")
                        .font(.system(size: 11))
                        .foregroundColor(category.isOverBudget ? .furgDanger : .white.opacity(0.4))
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(category.isOverBudget ? Color.furgDanger : category.color)
                        .frame(width: geo.size.width * min(category.percentOfBudget, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}

private struct InsightRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }
}

#Preview {
    NavigationStack {
        SpendingDashboardView()
    }
}
