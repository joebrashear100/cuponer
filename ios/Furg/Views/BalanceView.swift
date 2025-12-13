//
//  BalanceView.swift
//  Furg
//
//  Redesigned with Copilot Money aesthetic - clean, elegant, intuitive
//

import SwiftUI
import Charts
import WebKit

struct BalanceView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var animate = false
    @State private var selectedTimeRange: TimeRange = .month

    // Premium tool sheet states
    @State private var showDebtPayoff = false
    @State private var showCardRecommendations = false
    @State private var showInvestmentPortfolio = false
    @State private var showMerchantIntelligence = false
    @State private var showLifeIntegration = false

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 18 { return "Afternoon" }
        return "Evening"
    }

    var body: some View {
        ZStack {
            // Clean background - no mesh, just subtle gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    heroBalanceSection
                    balanceTrendSection
                    spendingBreakdownChart
                    weeklyComparisonChart
                    cashFlowSection
                    metricsSection
                    premiumToolsSection
                    categoriesSection
                    accountsSection
                    quickActionsSection
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            animate = true
            Task {
                await financeManager.refreshAll()
            }
        }
        .sheet(isPresented: $showDebtPayoff) {
            DebtPayoffView()
                .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showCardRecommendations) {
            CardRecommendationsView()
                .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showInvestmentPortfolio) {
            InvestmentPortfolioView()
                .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showMerchantIntelligence) {
            MerchantIntelligenceView()
                .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showLifeIntegration) {
            LifeIntegrationView()
                .presentationBackground(Color.furgCharcoal)
        }
    }

    // MARK: - View Sections
    private var headerSection: some View {
        HStack {
            Text(greeting)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Button {
                Task { await financeManager.refreshAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }

    private var heroBalanceSection: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            if let balance = financeManager.balance {
                Text(formatCurrency(balance.totalBalance))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)

                let monthChange = 450.0
                HStack(spacing: 6) {
                    Image(systemName: monthChange >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 14, weight: .bold))
                    Text("$\(Int(abs(monthChange))) this month")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(monthChange >= 0 ? .chartIncome : .chartSpending)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background((monthChange >= 0 ? Color.chartIncome : Color.chartSpending).opacity(0.15))
                .clipShape(Capsule())
            } else {
                Text("$0")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.vertical, 20)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : -10)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
    }

    private var balanceTrendSection: some View {
        PlotlyWaterfallView()
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animate)
    }

    private var spendingBreakdownChart: some View {
        Group {
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending Breakdown")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)

                SpendingBreakdownTechnicalChart(data: generateSpendingData())
                    .frame(height: 220)
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: animate)
        }
    }

    private var weeklyComparisonChart: some View {
        Group {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Spending Heatmap")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)

                Text("Color intensity shows how much you're spending each day")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)

                SpendingHeatmapCalendar(monthData: generateHeatmapData())
                    .padding(.horizontal, 20)
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animate)
        }
    }

    private var cashFlowSection: some View {
        HStack(spacing: 16) {
            CashFlowIndicator(
                title: "Income",
                amount: 4200,
                isPositive: true,
                icon: "arrow.down"
            )
            CashFlowIndicator(
                title: "Spending",
                amount: 3150,
                isPositive: false,
                icon: "arrow.up"
            )
        }
        .padding(.horizontal, 20)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: animate)
    }

    private var metricsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                DashboardMetricCard(
                    title: "Savings Rate",
                    value: "24%",
                    subtitle: "This month",
                    icon: "arrow.up.right.circle.fill",
                    color: .chartIncome
                )
                DashboardMetricCard(
                    title: "Avg Daily",
                    value: "$105",
                    subtitle: "Spending",
                    icon: "chart.bar.fill",
                    color: .chartSpending
                )
            }
            HStack(spacing: 12) {
                DashboardMetricCard(
                    title: "Net Worth",
                    value: "+$4,250",
                    subtitle: "This month",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(red: 0.45, green: 0.85, blue: 0.65)
                )
                DashboardMetricCard(
                    title: "Forecast",
                    value: "$3,240",
                    subtitle: "Month end",
                    icon: "calendar.badge.clock",
                    color: Color(red: 0.35, green: 0.75, blue: 0.95)
                )
            }
        }
        .padding(.horizontal, 20)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: animate)
    }

    // MARK: - Premium Tools Section
    private var premiumToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Premium Tools")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                NavigationLink(destination: EmptyView()) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.furgMint)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Debt Payoff
                    ToolQuickAccessCard(
                        icon: "chart.line.downtrend.xyaxis",
                        title: "Debt Payoff",
                        metric: "$38,500",
                        color: Color(red: 0.95, green: 0.4, blue: 0.4)
                    ) { showDebtPayoff = true }

                    // Card Optimizer
                    ToolQuickAccessCard(
                        icon: "creditcard.fill",
                        title: "Card Match",
                        metric: "95% match",
                        color: Color(red: 0.6, green: 0.4, blue: 0.9)
                    ) { showCardRecommendations = true }

                    // Investments
                    ToolQuickAccessCard(
                        icon: "chart.pie.fill",
                        title: "Portfolio",
                        metric: "+$2,450",
                        color: Color(red: 0.7, green: 0.4, blue: 0.9)
                    ) { showInvestmentPortfolio = true }

                    // Merchant Intel
                    ToolQuickAccessCard(
                        icon: "building.2.fill",
                        title: "Deals",
                        metric: "5 active",
                        color: Color(red: 0.4, green: 0.8, blue: 0.9)
                    ) { showMerchantIntelligence = true }

                    // Life Integration
                    ToolQuickAccessCard(
                        icon: "heart.text.square.fill",
                        title: "Life",
                        metric: "Risk: 45",
                        color: Color(red: 0.9, green: 0.4, blue: 0.7)
                    ) { showLifeIntegration = true }
                }
                .padding(.horizontal, 20)
            }
        }
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.38), value: animate)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Spending by Category")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("This Month")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                DashboardCategoryRow(name: "Groceries", amount: 523, percentage: 17, color: Color(red: 0.4, green: 0.8, blue: 0.4))
                DashboardCategoryRow(name: "Dining", amount: 387, percentage: 13, color: Color(red: 0.8, green: 0.6, blue: 0.2))
                DashboardCategoryRow(name: "Transport", amount: 245, percentage: 8, color: Color(red: 0.8, green: 0.4, blue: 0.4))
                DashboardCategoryRow(name: "Entertainment", amount: 156, percentage: 5, color: Color(red: 0.6, green: 0.4, blue: 0.8))
                DashboardCategoryRow(name: "Other", amount: 839, percentage: 28, color: Color(red: 0.5, green: 0.5, blue: 0.5))
            }
            .padding(.horizontal, 20)
        }
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animate)
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                BalanceAccountRow(name: "Chase Checking", balance: 2450, change: 120)
                BalanceAccountRow(name: "Discover Savings", balance: 8900, change: 250)
                BalanceAccountRow(name: "Amex Credit", balance: -1200, change: -80)
            }
        }
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.45), value: animate)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                QuickActionButton(
                    icon: "arrow.left.arrow.right",
                    label: "Transfer",
                    color: Color(red: 0.35, green: 0.75, blue: 0.95),
                    action: {}
                )
                QuickActionButton(
                    icon: "creditcard.fill",
                    label: "Pay Bill",
                    color: Color(red: 0.75, green: 0.55, blue: 0.95),
                    action: {}
                )
                QuickActionButton(
                    icon: "arrow.down.doc.fill",
                    label: "Request",
                    color: Color(red: 0.95, green: 0.65, blue: 0.35),
                    action: {}
                )
            }
        }
        .padding(.horizontal, 20)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animate)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func generateBalanceData() -> [BalanceDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [BalanceDataPoint] = []

        let days = selectedTimeRange == .week ? 7 : (selectedTimeRange == .month ? 30 : 365)

        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -days + i, to: today) {
                // Generate realistic trending data
                let baseBalance = 10000.0
                let trend = Double(i) * 15
                let variance = Double.random(in: -200...300)
                let balance = baseBalance + trend + variance
                data.append(BalanceDataPoint(date: date, balance: balance))
            }
        }

        return data
    }

    private func generateSpendingData() -> [TechnicalCategoryData] {
        let categories = [
            ("Groceries", Color(red: 0.4, green: 0.8, blue: 0.4)),
            ("Dining", Color(red: 0.8, green: 0.6, blue: 0.2)),
            ("Transport", Color(red: 0.8, green: 0.4, blue: 0.4)),
            ("Entertainment", Color(red: 0.6, green: 0.4, blue: 0.8)),
            ("Shopping", Color(red: 0.9, green: 0.6, blue: 0.3)),
            ("Other", Color(red: 0.5, green: 0.5, blue: 0.5))
        ]

        return categories.map { category, color in
            let minAmount = Double.random(in: 50...150)
            let openAmount = minAmount + Double.random(in: 50...200)
            let maxAmount = openAmount + Double.random(in: 100...300)
            let closeAmount = Double.random(in: openAmount...maxAmount)

            return TechnicalCategoryData(
                category: category,
                minAmount: minAmount,
                openAmount: openAmount,
                closeAmount: closeAmount,
                maxAmount: maxAmount,
                color: color
            )
        }
    }

    private func generateWeeklyData() -> [WeeklyPerformanceData] {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var baseBalance = 11500.0

        return days.map { day in
            let dailyChange = Double.random(in: -300...500)
            let openBalance = baseBalance
            let closeBalance = baseBalance + dailyChange
            let lowBalance = min(openBalance, closeBalance) - Double.random(in: 50...200)
            let highBalance = max(openBalance, closeBalance) + Double.random(in: 50...200)

            baseBalance = closeBalance

            return WeeklyPerformanceData(
                day: day,
                openBalance: openBalance,
                closeBalance: closeBalance,
                lowBalance: lowBalance,
                highBalance: highBalance
            )
        }
    }

    private func generateWaterfallData() -> [(category: String, amount: Double, color: Color)] {
        [
            (category: "Groceries", amount: 45, color: Color(red: 0.4, green: 0.85, blue: 0.6)),
            (category: "Dining", amount: 65, color: Color(red: 0.35, green: 0.75, blue: 0.95)),
            (category: "Transport", amount: 30, color: Color(red: 0.95, green: 0.65, blue: 0.35)),
            (category: "Entertainment", amount: 50, color: Color(red: 0.6, green: 0.4, blue: 0.9)),
            (category: "Shopping", amount: 75, color: Color(red: 0.9, green: 0.4, blue: 0.7)),
            (category: "Bills", amount: 35, color: Color(red: 0.95, green: 0.4, blue: 0.4))
        ]
    }

    private func generateHeatmapData() -> [Int: Double] {
        var data: [Int: Double] = [:]
        for day in 1...31 {
            // Simulate spending patterns: weekends higher, random variation
            let dayOfWeek = (day + 2) % 7 // Approximate day of week
            let isWeekend = dayOfWeek > 4
            let baseAmount = isWeekend ? Double.random(in: 200...500) : Double.random(in: 100...350)
            let adjustment = Double.random(in: -50...50)
            data[day] = max(0, baseAmount + adjustment)
        }
        return data
    }
}

// MARK: - Balance Data Model
struct BalanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
    var lineColor: Color {
        // Color based on spending category impact
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        let isWeekend = dayOfWeek == 1 || dayOfWeek == 7

        if balance > 12500 {
            return Color(red: 0.45, green: 0.85, blue: 0.65) // Green - good savings
        } else if balance > 10000 {
            return Color(red: 0.35, green: 0.75, blue: 0.95) // Blue - stable
        } else if balance > 7500 {
            return Color(red: 0.95, green: 0.75, blue: 0.3) // Yellow - moderate spending
        } else {
            return Color(red: 0.95, green: 0.4, blue: 0.4) // Red - high spending
        }
    }
}

// MARK: - Technical Category Data Model
struct TechnicalCategoryData: Identifiable {
    let id = UUID()
    let category: String
    let minAmount: Double
    let openAmount: Double
    let closeAmount: Double
    let maxAmount: Double
    let color: Color
}

// MARK: - Weekly Performance Data Model
struct WeeklyPerformanceData: Identifiable {
    let id = UUID()
    let day: String
    let openBalance: Double
    let closeBalance: Double
    let lowBalance: Double
    let highBalance: Double
    var isPositiveDay: Bool {
        closeBalance >= openBalance
    }
}

// MARK: - Balance Trend Chart with Category Coloring
struct BalanceTrendChart: View {
    let data: [BalanceDataPoint]
    let selectedRange: BalanceView.TimeRange

    var body: some View {
        Chart(data) { point in
            let lineColor = point.lineColor

            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(lineColor)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [lineColor.opacity(0.25), lineColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
    }
}

// MARK: - Spending Breakdown Technical Chart
struct SpendingBreakdownTechnicalChart: View {
    let data: [TechnicalCategoryData]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Category", item.category),
                yStart: .value("Min", item.minAmount),
                yEnd: .value("Max", item.maxAmount)
            )
            .foregroundStyle(item.color)
            .opacity(0.8)

            BarMark(
                x: .value("Category", item.category),
                y: .value("Open", item.openAmount)
            )
            .foregroundStyle(item.color)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("Category", item.category),
                y: .value("Close", item.closeAmount)
            )
            .foregroundStyle(item.closeAmount > item.openAmount ? Color.chartSpending : Color.chartIncome)
            .symbolSize(120)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
    }
}

// MARK: - Weekly Performance Technical Chart
struct WeeklyComparisonTechnicalChart: View {
    let data: [WeeklyPerformanceData]

    var body: some View {
        Chart(data) { item in
            RectangleMark(
                x: .value("Day", item.day),
                yStart: .value("Low", item.lowBalance),
                yEnd: .value("High", item.highBalance)
            )
            .foregroundStyle(item.isPositiveDay ? Color.chartIncome.opacity(0.3) : Color.chartSpending.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1))

            BarMark(
                x: .value("Day", item.day),
                y: .value("Open", item.openBalance)
            )
            .foregroundStyle(item.isPositiveDay ? Color.chartIncome : Color.chartSpending)
            .opacity(0.7)

            PointMark(
                x: .value("Day", item.day),
                y: .value("Close", item.closeBalance)
            )
            .foregroundStyle(item.isPositiveDay ? Color.chartIncome : Color.chartSpending)
            .symbolSize(100)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
    }
}

// MARK: - Cash Flow Indicator
struct CashFlowIndicator: View {
    let title: String
    let amount: Double
    let isPositive: Bool
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.6))

            Text("$\(Int(amount))")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(isPositive ? .chartIncome : .chartSpending)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Dashboard Metric Card (specific to dashboard view)
private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Dashboard Category Row (specific to dashboard view)
private struct DashboardCategoryRow: View {
    let name: String
    let amount: Double
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)

                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(amount))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(percentage)%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))

                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Balance Account Row (renamed to avoid conflict)
private struct BalanceAccountRow: View {
    let name: String
    let balance: Double
    let change: Double

    var body: some View {
        HStack {
            // Account icon
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: balance < 0 ? "creditcard.fill" : "banknote.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                // Change indicator - GREEN up, RED down
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text("$\(Int(abs(change)))")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(change >= 0 ? .chartIncome : .chartSpending)
            }

            Spacer()

            Text("$\(Int(abs(balance)))")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(balance >= 0 ? .white : .chartSpending)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - Tool Quick Access Card
private struct ToolQuickAccessCard: View {
    let icon: String
    let title: String
    let metric: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Text(metric)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(width: 110, height: 120)
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plotly Waterfall Chart
struct PlotlyWaterfallView: View {
    @State private var timeRange: String = "month"

    var body: some View {
        VStack(spacing: 0) {
            // Time range selector
            HStack(spacing: 12) {
                ForEach(["day", "week", "month"], id: \.self) { range in
                    Button(action: { timeRange = range }) {
                        Text(range.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(timeRange == range ? .furgMint : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(timeRange == range ? Color.furgMint.opacity(0.2) : Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)

            // Web view with Plotly
            WaterfallChartWebView(timeRange: timeRange)
                .frame(height: 300)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(16)
        .padding(16)
    }
}

struct WaterfallChartWebView: UIViewRepresentable {
    let timeRange: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
        webView.isOpaque = false

        let htmlString = generateWaterfallHTML(timeRange: timeRange)
        webView.loadHTMLString(htmlString, baseURL: nil)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = generateWaterfallHTML(timeRange: timeRange)
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    private func generateWaterfallHTML(timeRange: String) -> String {
        // Generate stacked bar chart data
        let stackedData = getStackedBarData(timeRange: timeRange)

        // Calculate totals per period for sorting
        var periodTotals: [(index: Int, name: String, total: Double)] = []
        for (idx, period) in stackedData.periods.enumerated() {
            let total = stackedData.data.reduce(0) { $0 + $1[idx] }
            periodTotals.append((idx, period, total))
        }
        // Sort by total (highest first)
        periodTotals.sort { $0.total > $1.total }

        // Create sorted labels and reorganized data
        let sortedLabels = periodTotals.map { $0.name }
        let periodLabels = sortedLabels.map { "\"\($0)\"" }.joined(separator: ",")

        // Reorganize data arrays to match sorted order
        var sortedData: [[Double]] = Array(repeating: [], count: stackedData.categories.count)
        for categoryIdx in 0..<stackedData.categories.count {
            for (sortedPos, periodInfo) in periodTotals.enumerated() {
                sortedData[categoryIdx].append(stackedData.data[categoryIdx][periodInfo.index])
            }
        }

        // Category colors - matching Furg's design system
        let colors = [
            "#4FBF85", // Groceries - mint green
            "#FFD93D", // Dining - yellow
            "#FF6B6B", // Transport - red
            "#A8E6CF", // Entertainment - light green
            "#FFB3BA", // Shopping - light red
            "#BAE1FF"  // Other - light blue
        ]

        // Build trace for each category
        var tracesCode = ""
        for (idx, category) in stackedData.categories.enumerated() {
            let values = sortedData[idx].map { String($0) }.joined(separator: ",")
            let color = idx < colors.count ? colors[idx] : "#999"
            tracesCode += """
            {
                name: "\(category)",
                x: [\(periodLabels)],
                y: [\(values)],
                type: "bar",
                marker: {color: "\(color)"},
                hovertemplate: '<b>\(category)</b><br>$%{y:,.0f}<extra></extra>'
            },
            """
        }
        // Remove trailing comma
        tracesCode = String(tracesCode.dropLast(1))

        // Calculate budget threshold (average spending)
        let avgSpending = periodTotals.reduce(0) { $0 + $1.total } / Double(periodTotals.count)
        let budgetThreshold = avgSpending * 1.1  // 10% above average

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
            <style>
                html, body { margin: 0; padding: 0; width: 100%; height: 100%; background-color: #13131f; }
                #chart { width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div id="chart"></div>
            <script>
                var data = [\(tracesCode)];

                var layout = {
                    barmode: "stack",
                    margin: {l: 50, r: 30, t: 30, b: 50},
                    paper_bgcolor: "#13131f",
                    plot_bgcolor: "#13131f",
                    font: {color: "#999", family: "system-ui, -apple-system, sans-serif", size: 11},
                    xaxis: {
                        showgrid: false,
                        zeroline: false,
                        color: "#666",
                        tickfont: {size: 10}
                    },
                    yaxis: {
                        showgrid: true,
                        gridcolor: "rgba(255,255,255,0.1)",
                        gridwidth: 1,
                        zeroline: false,
                        color: "#666",
                        tickformat: "$.0f",
                        tickfont: {size: 10}
                    },
                    hovermode: "x unified",
                    autosize: true,
                    legend: {
                        x: 1.02,
                        y: 1,
                        xanchor: "left",
                        yanchor: "top",
                        bgcolor: "rgba(0,0,0,0.5)",
                        bordercolor: "#666",
                        borderwidth: 1
                    },
                    shapes: [{
                        type: "line",
                        xref: "paper",
                        yref: "y",
                        x0: 0,
                        x1: 1,
                        y0: \(budgetThreshold),
                        y1: \(budgetThreshold),
                        line: {
                            color: "#FFA500",
                            width: 2,
                            dash: "dash"
                        }
                    }],
                    annotations: [{
                        x: 0.98,
                        y: \(budgetThreshold),
                        xref: "paper",
                        yref: "y",
                        text: "Budget Threshold",
                        showarrow: false,
                        xanchor: "right",
                        yanchor: "bottom",
                        font: {color: "#FFA500", size: 10},
                        bgcolor: "rgba(0,0,0,0.6)",
                        bordercolor: "#FFA500",
                        borderwidth: 1,
                        borderpad: 4
                    }]
                };

                var config = {
                    responsive: true,
                    displayModeBar: false,
                    staticPlot: false
                };

                Plotly.newPlot('chart', data, layout, config);
            </script>
        </body>
        </html>
        """
    }

    private struct StackedBarChartData {
        let periods: [String]
        let categories: [String]
        let data: [[Double]]
    }

    private func getStackedBarData(timeRange: String) -> StackedBarChartData {
        let categories = ["Groceries", "Dining", "Transport", "Entertainment", "Shopping", "Other"]

        var periods: [String] = []
        var data: [[Double]] = Array(repeating: [], count: categories.count)

        if timeRange == "day" {
            // Daily view - last 7 days
            periods = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let dailyData: [(Double, Double, Double, Double, Double, Double)] = [
                (45, 20, 15, 30, 40, 10), (50, 25, 18, 35, 45, 12), (40, 18, 12, 25, 35, 8),
                (55, 30, 20, 40, 50, 15), (48, 22, 16, 32, 42, 11), (60, 35, 25, 45, 55, 20),
                (52, 28, 18, 38, 48, 14)
            ]
            // Extract data by category
            for idx in 0..<categories.count {
                for day in 0..<7 {
                    switch idx {
                    case 0: data[idx].append(dailyData[day].0)  // Groceries
                    case 1: data[idx].append(dailyData[day].1)  // Dining
                    case 2: data[idx].append(dailyData[day].2)  // Transport
                    case 3: data[idx].append(dailyData[day].3)  // Entertainment
                    case 4: data[idx].append(dailyData[day].4)  // Shopping
                    case 5: data[idx].append(dailyData[day].5)  // Other
                    default: break
                    }
                }
            }
        } else if timeRange == "week" {
            // Weekly view - last 4 weeks
            periods = ["Week 1", "Week 2", "Week 3", "Week 4"]
            let weeklyData: [[Double]] = [
                [285, 320, 295, 310],  // Groceries
                [155, 175, 160, 180],  // Dining
                [105, 115, 110, 120],  // Transport
                [210, 240, 225, 250],  // Entertainment
                [270, 310, 290, 320],  // Shopping
                [85, 95, 80, 100]      // Other
            ]
            data = weeklyData
        } else {
            // Monthly view - last 6 months
            periods = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
            let monthlyData: [[Double]] = [
                [1200, 1350, 1280, 1400, 1320, 1450],  // Groceries
                [680, 750, 720, 800, 760, 850],        // Dining
                [450, 520, 480, 560, 500, 600],        // Transport
                [900, 1050, 980, 1100, 1020, 1150],    // Entertainment
                [1200, 1400, 1300, 1500, 1400, 1600],  // Shopping
                [380, 420, 400, 450, 420, 500]         // Other
            ]
            data = monthlyData
        }

        return StackedBarChartData(periods: periods, categories: categories, data: data)
    }

    private func getWaterfallData(timeRange: String) -> ([String], [Double], [String]) {
        // Kept for backward compatibility, but not used
        return ([], [], [])
    }
}
