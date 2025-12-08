//
//  InvestmentPortfolioView.swift
//  Furg
//
//  Created for radical life integration - investment portfolio display
//

import SwiftUI
import Charts

struct InvestmentPortfolioView: View {
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var selectedPeriod: PerformancePeriod = .month
    @State private var selectedTab = 0
    @State private var showingAddAccount = false
    @State private var showingHoldingDetail = false
    @State private var selectedHolding: Holding?
    @State private var selectedAccount: BrokerageAccount?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio Summary Card
                    if let summary = portfolioManager.portfolioSummary {
                        PortfolioSummaryCard(summary: summary)
                    }

                    // Performance Chart
                    PerformanceChartSection(
                        performanceData: portfolioManager.performanceData,
                        selectedPeriod: $selectedPeriod
                    )

                    // Insights
                    if !portfolioManager.insights.isEmpty {
                        InsightsSection(insights: portfolioManager.insights)
                    }

                    // Tab Picker
                    Picker("", selection: $selectedTab) {
                        Text("Holdings").tag(0)
                        Text("Allocation").tag(1)
                        Text("Dividends").tag(2)
                        Text("Goals").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Tab Content
                    switch selectedTab {
                    case 0:
                        HoldingsSection(
                            accounts: portfolioManager.accounts,
                            onHoldingTap: { holding, account in
                                selectedHolding = holding
                                selectedAccount = account
                                showingHoldingDetail = true
                            }
                        )
                    case 1:
                        AllocationSection(
                            assetAllocation: portfolioManager.assetAllocation,
                            sectorAllocation: portfolioManager.sectorAllocation
                        )
                    case 2:
                        DividendsSection(dividendSummary: portfolioManager.dividendSummary)
                    case 3:
                        GoalsSection(goals: portfolioManager.goals)
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAccount = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await portfolioManager.refreshAllAccounts()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddBrokerageAccountView()
            }
            .sheet(isPresented: $showingHoldingDetail) {
                if let holding = selectedHolding, let account = selectedAccount {
                    HoldingDetailView(holding: holding, account: account)
                }
            }
        }
    }
}

// MARK: - Portfolio Summary Card

struct PortfolioSummaryCard: View {
    let summary: PortfolioSummary

    var body: some View {
        VStack(spacing: 16) {
            // Total value
            VStack(spacing: 4) {
                Text("Total Portfolio Value")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(CurrencyFormatter.format(summary.totalValue))
                    .font(.system(size: 36, weight: .bold))
            }

            // Day change
            HStack(spacing: 4) {
                Image(systemName: summary.dayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(CurrencyFormatter.format(abs(summary.dayChange)))
                Text("(\(formatSignedPercent(summary.dayChangePercent)))")
            }
            .font(.subheadline)
            .foregroundColor(summary.dayChange >= 0 ? .green : .red)

            Divider()

            // Stats row
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(CurrencyFormatter.format(summary.totalGain))
                        .font(.headline)
                        .foregroundColor(summary.totalGain >= 0 ? .green : .red)
                    Text("Total Gain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(formatSignedPercent(summary.totalGainPercent))
                        .font(.headline)
                        .foregroundColor(summary.totalGain >= 0 ? .green : .red)
                    Text("Return")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(CurrencyFormatter.format(summary.cashTotal))
                        .font(.headline)
                    Text("Cash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Accounts and holdings count
            HStack {
                Text("\(summary.accountCount) accounts")
                Text("•")
                Text("\(summary.holdingCount) holdings")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func formatSignedPercent(_ percent: Double) -> String {
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percent))%"
    }
}

// MARK: - Performance Chart

struct PerformanceChartSection: View {
    let performanceData: [PerformancePeriod: PerformanceData]
    @Binding var selectedPeriod: PerformancePeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .padding(.horizontal)

            // Period selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([PerformancePeriod.day, .week, .month, .threeMonth, .ytd, .year], id: \.self) { period in
                        PeriodButton(
                            period: period,
                            isSelected: selectedPeriod == period,
                            action: { selectedPeriod = period }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Chart
            if let data = performanceData[selectedPeriod] {
                VStack(alignment: .leading, spacing: 8) {
                    // Change indicator
                    HStack {
                        Text(CurrencyFormatter.formatSigned(data.change))
                        Text("(\(PercentageFormatter.formatSigned(data.changePercent)))")
                    }
                    .font(.subheadline)
                    .foregroundColor(data.change >= 0 ? .green : .red)
                    .padding(.horizontal)

                    // Chart
                    if #available(iOS 16.0, *) {
                        PerformanceChart(dataPoints: data.dataPoints, isPositive: data.change >= 0)
                            .frame(height: 180)
                            .padding(.horizontal)
                    } else {
                        // Fallback for older iOS
                        SimplifiedPerformanceChart(dataPoints: data.dataPoints, isPositive: data.change >= 0)
                            .frame(height: 180)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct PeriodButton: View {
    let period: PerformancePeriod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(period.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

@available(iOS 16.0, *)
struct PerformanceChart: View {
    let dataPoints: [PerformancePoint]
    let isPositive: Bool

    var body: some View {
        Chart {
            ForEach(dataPoints, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(isPositive ? Color.green : Color.red)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [isPositive ? Color.green.opacity(0.3) : Color.red.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(CurrencyFormatter.formatAbbreviated(val))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis(.hidden)
    }
}

struct SimplifiedPerformanceChart: View {
    let dataPoints: [PerformancePoint]
    let isPositive: Bool

    var body: some View {
        GeometryReader { geometry in
            let minValue = dataPoints.map { $0.value }.min() ?? 0
            let maxValue = dataPoints.map { $0.value }.max() ?? 1
            let range = maxValue - minValue

            Path { path in
                guard dataPoints.count > 1 else { return }

                let stepX = geometry.size.width / CGFloat(dataPoints.count - 1)

                for (index, point) in dataPoints.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = (point.value - minValue) / range
                    let y = geometry.size.height * (1 - CGFloat(normalizedY))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(isPositive ? Color.green : Color.red, lineWidth: 2)
        }
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    let insights: [InvestmentInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insights.prefix(5)) { insight in
                        InvestmentInsightCard(insight: insight)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct InvestmentInsightCard: View {
    let insight: InvestmentInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insightIcon(for: insight.type))
                    .foregroundColor(insightColor(for: insight.type))
                if let symbol = insight.symbol {
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }

            Text(insight.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let action = insight.action {
                Text(action)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func insightIcon(for type: InvestmentInsightType) -> String {
        switch type {
        case .overweight, .underweight: return "scale.3d"
        case .taxLossHarvest: return "leaf.fill"
        case .dividendIncrease: return "arrow.up.circle.fill"
        case .priceAlert: return "bell.fill"
        case .rebalanceNeeded: return "arrow.triangle.2.circlepath"
        case .newHigh: return "chart.line.uptrend.xyaxis"
        case .newLow: return "chart.line.downtrend.xyaxis"
        case .largeLoss: return "arrow.down.circle.fill"
        case .largeGain: return "arrow.up.circle.fill"
        case .concentrationRisk: return "exclamationmark.triangle.fill"
        case .sectorImbalance: return "chart.pie.fill"
        case .upcomingDividend: return "calendar"
        case .costBasisOpportunity: return "dollarsign.circle.fill"
        }
    }

    private func insightColor(for type: InvestmentInsightType) -> Color {
        switch type {
        case .largeGain, .newHigh, .dividendIncrease: return .green
        case .largeLoss, .newLow, .taxLossHarvest: return .red
        case .concentrationRisk, .sectorImbalance: return .orange
        case .rebalanceNeeded, .overweight, .underweight: return .blue
        case .upcomingDividend, .costBasisOpportunity: return .purple
        case .priceAlert: return .yellow
        }
    }
}

// MARK: - Holdings Section

struct HoldingsSection: View {
    let accounts: [BrokerageAccount]
    let onHoldingTap: (Holding, BrokerageAccount) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(accounts) { account in
                VStack(alignment: .leading, spacing: 12) {
                    // Account header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.accountName)
                                .font(.headline)
                            HStack {
                                Text(account.brokerage.rawValue)
                                Text("•")
                                Text("••••\(account.accountNumber)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(CurrencyFormatter.format(account.totalValue))
                                .font(.headline)
                            Text("\(CurrencyFormatter.formatSigned(account.dayChange)) (\(PercentageFormatter.formatSigned(account.dayChangePercent)))")
                                .font(.caption)
                                .foregroundColor(account.dayChange >= 0 ? .green : .red)
                        }
                    }
                    .padding(.horizontal)

                    // Holdings
                    ForEach(account.holdings) { holding in
                        HoldingRow(holding: holding)
                            .onTapGesture {
                                onHoldingTap(holding, account)
                            }
                    }

                    // Cash balance
                    if account.cashBalance > 0 {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                            Text("Cash")
                            Spacer()
                            Text(CurrencyFormatter.format(account.cashBalance))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

struct HoldingRow: View {
    let holding: Holding

    var body: some View {
        HStack(spacing: 12) {
            // Symbol badge
            ZStack {
                Circle()
                    .fill(assetColor(holding.assetType).opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(String(holding.symbol.prefix(2)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(assetColor(holding.assetType))
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(holding.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Value and change
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(holding.marketValue))
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 2) {
                    Image(systemName: holding.totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(PercentageFormatter.formatSigned(holding.totalGainPercent))
                        .font(.caption)
                }
                .foregroundColor(holding.totalGain >= 0 ? .green : .red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func assetColor(_ type: AssetType) -> Color {
        switch type {
        case .stock: return .blue
        case .etf: return .purple
        case .mutualFund: return .indigo
        case .bond, .bondFund: return .orange
        case .reit: return .green
        case .crypto: return .yellow
        default: return .gray
        }
    }
}

// MARK: - Allocation Section

struct AllocationSection: View {
    let assetAllocation: [AssetAllocation]
    let sectorAllocation: [SectorAllocation]
    @State private var showingSector = false

    var body: some View {
        VStack(spacing: 16) {
            // Toggle
            Picker("", selection: $showingSector) {
                Text("Asset Class").tag(false)
                Text("Sector").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if showingSector {
                // Sector allocation
                VStack(spacing: 12) {
                    ForEach(sectorAllocation, id: \.sector) { allocation in
                        AllocationRow(
                            name: allocation.sector,
                            value: allocation.value,
                            percentage: allocation.percentage,
                            color: sectorColor(allocation.sector)
                        )
                    }
                }
                .padding(.horizontal)
            } else {
                // Asset class allocation
                VStack(spacing: 12) {
                    ForEach(assetAllocation, id: \.assetType) { allocation in
                        AllocationRow(
                            name: allocation.assetType.rawValue,
                            value: allocation.value,
                            percentage: allocation.percentage,
                            color: assetColor(allocation.assetType)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func assetColor(_ type: AssetType) -> Color {
        switch type {
        case .stock: return .blue
        case .etf: return .purple
        case .mutualFund: return .indigo
        case .bond, .bondFund: return .orange
        case .reit: return .green
        case .crypto: return .yellow
        case .cash, .moneyMarket: return .green
        default: return .gray
        }
    }

    private func sectorColor(_ sector: String) -> Color {
        switch sector.lowercased() {
        case "technology": return .blue
        case "broad market": return .purple
        case "bonds": return .orange
        case "dividend": return .green
        case "healthcare": return .red
        case "financial": return .indigo
        case "consumer": return .pink
        case "energy": return .yellow
        default: return .gray
        }
    }
}

struct AllocationRow: View {
    let name: String
    let value: Double
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text(CurrencyFormatter.formatCompact(value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(percentage, 100) / 100), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Dividends Section

struct DividendsSection: View {
    let dividendSummary: DividendSummary?

    var body: some View {
        VStack(spacing: 16) {
            if let summary = dividendSummary {
                // Summary card
                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        VStack {
                            Text(CurrencyFormatter.format(summary.totalAnnualDividends))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Annual Dividends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(String(format: "%.2f", summary.currentYield))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Current Yield")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        VStack {
                            Text(CurrencyFormatter.format(summary.monthlyAverage))
                                .fontWeight(.medium)
                            Text("Monthly Avg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(String(format: "%.2f", summary.yieldOnCost))%")
                                .fontWeight(.medium)
                            Text("Yield on Cost")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Upcoming dividends
                if !summary.upcomingDividends.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Dividends")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(summary.upcomingDividends) { dividend in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dividend.symbol)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Ex: \(DateFormatters.shortDate(dividend.exDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(CurrencyFormatter.format(dividend.expectedPayout))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                    Text("\(String(format: "%.0f", dividend.sharesOwned)) shares")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }

                // Dividend history
                if !summary.dividendHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Payments")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(summary.dividendHistory.prefix(5)) { payment in
                            HStack {
                                Text(payment.symbol)
                                    .fontWeight(.medium)
                                Text(DateFormatters.shortDate(payment.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(CurrencyFormatter.format(payment.amount))
                                    .foregroundColor(.green)
                                if payment.isReinvested {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Text("No dividend data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

// MARK: - Goals Section

struct GoalsSection: View {
    let goals: [InvestmentGoal]
    @State private var showingAddGoal = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(goals) { goal in
                GoalCard(goal: goal)
            }

            Button(action: { showingAddGoal = true }) {
                Label("Add Goal", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

struct GoalCard: View {
    let goal: InvestmentGoal
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                Spacer()
                if goal.onTrack {
                    Text("On Track")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                } else {
                    Text("Behind")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }

            // Progress bar
            let progress = portfolioManager.calculateGoalProgress(goal)
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(min(progress, 100) / 100), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(CurrencyFormatter.formatCompact(goal.currentAmount))
                        .font(.caption)
                    Spacer()
                    Text("\(String(format: "%.1f", progress))%")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text(CurrencyFormatter.formatCompact(goal.targetAmount))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            // Details
            HStack {
                if let targetDate = goal.targetDate {
                    VStack(alignment: .leading) {
                        Text("Target")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(DateFormatters.monthYear(targetDate))
                            .font(.caption)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Monthly")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.formatCompact(goal.monthlyContribution))
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Add Brokerage Account View

struct AddBrokerageAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var selectedBrokerage: BrokerageType?
    @State private var isConnecting = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Connect your brokerage account to track all your investments in one place.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()

                    // Brokerage list
                    ForEach(BrokerageType.allCases, id: \.self) { brokerage in
                        BrokerageRow(
                            brokerage: brokerage,
                            isSelected: selectedBrokerage == brokerage,
                            action: { selectedBrokerage = brokerage }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Connect") {
                        connectAccount()
                    }
                    .disabled(selectedBrokerage == nil || isConnecting)
                }
            }
        }
    }

    private func connectAccount() {
        guard let brokerage = selectedBrokerage else { return }

        isConnecting = true
        Task {
            let success = await portfolioManager.connectAccount(brokerage: brokerage, credentials: [:])
            isConnecting = false
            if success {
                dismiss()
            }
        }
    }
}

struct BrokerageRow: View {
    let brokerage: BrokerageType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: brokerage.iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                Text(brokerage.rawValue)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Holding Detail View

struct HoldingDetailView: View {
    let holding: Holding
    let account: BrokerageAccount
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Main info
                    VStack(spacing: 8) {
                        Text(holding.symbol)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(holding.name)
                            .foregroundColor(.secondary)

                        Text(CurrencyFormatter.format(holding.currentPrice))
                            .font(.title)

                        HStack {
                            Image(systemName: holding.dayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(CurrencyFormatter.formatSigned(holding.dayChange))
                            Text("(\(PercentageFormatter.formatSigned(holding.dayChangePercent)))")
                        }
                        .foregroundColor(holding.dayChange >= 0 ? .green : .red)
                    }
                    .padding()

                    // Position details
                    VStack(spacing: 12) {
                        DetailRow(label: "Shares", value: String(format: "%.4f", holding.shares))
                        DetailRow(label: "Market Value", value: CurrencyFormatter.format(holding.marketValue))
                        DetailRow(label: "Avg Cost", value: CurrencyFormatter.format(holding.averageCost))
                        DetailRow(label: "Total Cost", value: CurrencyFormatter.format(holding.averageCost * holding.shares))
                        DetailRow(label: "Total Gain/Loss", value: CurrencyFormatter.formatSigned(holding.totalGain), isHighlighted: true, isPositive: holding.totalGain >= 0)
                        DetailRow(label: "Return", value: PercentageFormatter.formatSigned(holding.totalGainPercent), isHighlighted: true, isPositive: holding.totalGain >= 0)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Fundamentals
                    if holding.peRatio != nil || holding.dividendYield != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fundamentals")
                                .font(.headline)

                            if let pe = holding.peRatio {
                                DetailRow(label: "P/E Ratio", value: String(format: "%.1f", pe))
                            }
                            if let yield = holding.dividendYield {
                                DetailRow(label: "Dividend Yield", value: "\(String(format: "%.2f", yield))%")
                            }
                            if let high = holding.fiftyTwoWeekHigh {
                                DetailRow(label: "52-Week High", value: CurrencyFormatter.format(high))
                            }
                            if let low = holding.fiftyTwoWeekLow {
                                DetailRow(label: "52-Week Low", value: CurrencyFormatter.format(low))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Account info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account")
                            .font(.headline)
                        HStack {
                            Text(account.accountName)
                            Spacer()
                            Text(account.brokerage.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Position Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    var isPositive: Bool = true

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(isHighlighted ? (isPositive ? .green : .red) : .primary)
        }
    }
}

#Preview {
    InvestmentPortfolioView()
}
