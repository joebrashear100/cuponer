//
//  CashFlowView.swift
//  Furg
//
//  Cash Flow analysis view inspired by Copilot Money
//  Shows income, spending, and net income with detailed charts
//

import SwiftUI
import Charts

// MARK: - Cash Flow Data Models

struct CashFlowPeriod: Identifiable {
    let id = UUID()
    let label: String
    let income: Double
    let spending: Double
    var netIncome: Double { income - spending }
    let date: Date
}

struct CategorySpend: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let color: Color
    let icon: String
    let percentage: Double
}

// MARK: - Cash Flow View

struct CashFlowView: View {
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedTab: CashFlowTab = .overview
    @State private var animate = false
    @State private var selectedBar: CashFlowPeriod?
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var showSpendingDashboard = false

    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    enum CashFlowTab: String, CaseIterable {
        case overview = "Overview"
        case income = "Income"
        case spending = "Spending"

        var shortLabel: String {
            switch self {
            case .overview: return "All"
            case .income: return "In"
            case .spending: return "Out"
            }
        }
    }

    // Demo data
    var cashFlowData: [CashFlowPeriod] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .week:
            return (0..<7).reversed().map { i in
                let date = calendar.date(byAdding: .day, value: -i, to: now)!
                return CashFlowPeriod(
                    label: date.formatted(.dateTime.weekday(.abbreviated)),
                    income: Double.random(in: 0...500),
                    spending: Double.random(in: 100...400),
                    date: date
                )
            }
        case .month:
            return (0..<4).reversed().map { i in
                let date = calendar.date(byAdding: .weekOfYear, value: -i, to: now)!
                return CashFlowPeriod(
                    label: "Week \(4-i)",
                    income: Double.random(in: 1500...3000),
                    spending: Double.random(in: 1000...2500),
                    date: date
                )
            }
        case .quarter:
            return (0..<3).reversed().map { i in
                let date = calendar.date(byAdding: .month, value: -i, to: now)!
                return CashFlowPeriod(
                    label: date.formatted(.dateTime.month(.abbreviated)),
                    income: Double.random(in: 5000...8000),
                    spending: Double.random(in: 4000...7000),
                    date: date
                )
            }
        case .year:
            return (0..<12).reversed().map { i in
                let date = calendar.date(byAdding: .month, value: -i, to: now)!
                return CashFlowPeriod(
                    label: date.formatted(.dateTime.month(.narrow)),
                    income: Double.random(in: 5000...8000),
                    spending: Double.random(in: 4000...7000),
                    date: date
                )
            }
        }
    }

    var categoryBreakdown: [CategorySpend] {
        let total = 4250.0
        return [
            CategorySpend(category: "Housing", amount: 1500, color: .blue, icon: "house.fill", percentage: 1500/total),
            CategorySpend(category: "Food & Dining", amount: 850, color: .orange, icon: "fork.knife", percentage: 850/total),
            CategorySpend(category: "Transportation", amount: 450, color: .purple, icon: "car.fill", percentage: 450/total),
            CategorySpend(category: "Shopping", amount: 620, color: .pink, icon: "bag.fill", percentage: 620/total),
            CategorySpend(category: "Entertainment", amount: 380, color: .green, icon: "tv.fill", percentage: 380/total),
            CategorySpend(category: "Subscriptions", amount: 250, color: .red, icon: "repeat", percentage: 250/total),
            CategorySpend(category: "Other", amount: 200, color: .gray, icon: "ellipsis.circle.fill", percentage: 200/total)
        ]
    }

    var totalIncome: Double { cashFlowData.reduce(0) { $0 + $1.income } }
    var totalSpending: Double { cashFlowData.reduce(0) { $0 + $1.spending } }
    var netIncome: Double { totalIncome - totalSpending }

    var body: some View {
        ZStack {
            // Solid dark background for better contrast
            Color.furgCharcoal
                .ignoresSafeArea()

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.furgMint.opacity(0.05),
                    Color.clear,
                    Color.furgSeafoam.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    header
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // Period selector
                    periodSelector
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Summary cards
                    summaryCards
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Main chart
                    mainChart
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Category breakdown
                    categorySection
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Key metrics
                    keyMetrics
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .navigationTitle("Cash Flow")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $showSpendingDashboard) {
            NavigationStack {
                SpendingDashboardView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showSpendingDashboard = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
    }

    // MARK: - Generate Report

    private func generateAndShareReport(asPDF: Bool) {
        let totalIncome = cashFlowData.reduce(0) { $0 + $1.income }
        let totalSpending = cashFlowData.reduce(0) { $0 + $1.spending }
        let netIncome = totalIncome - totalSpending

        let periodLabel = selectedPeriod.rawValue.lowercased()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var report = """
        FURG Cash Flow Report
        Period: \(selectedPeriod.rawValue)
        Generated: \(dateFormatter.string(from: Date()))

        ═══════════════════════════════

        SUMMARY
        ───────────────────────────────
        Total Income:   $\(String(format: "%.2f", totalIncome))
        Total Spending: $\(String(format: "%.2f", totalSpending))
        Net Income:     $\(String(format: "%.2f", netIncome))

        ═══════════════════════════════

        BREAKDOWN BY \(selectedPeriod.rawValue.uppercased())
        ───────────────────────────────
        """

        for period in cashFlowData {
            report += """

            \(period.label)
              Income:   $\(String(format: "%.2f", period.income))
              Spending: $\(String(format: "%.2f", period.spending))
              Net:      $\(String(format: "%.2f", period.netIncome))
            """
        }

        report += """


        ═══════════════════════════════
        Generated with FURG Finance App
        """

        shareText = report
        showShareSheet = true
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cash Flow")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Menu {
                Button {
                    generateAndShareReport(asPDF: true)
                } label: {
                    Label("Export PDF", systemImage: "doc.fill")
                }

                Button {
                    generateAndShareReport(asPDF: false)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPeriod == period ? Color.furgMint.opacity(0.3) : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Summary Cards

    var totalSavings: Double { max(0, netIncome) }

    private var summaryCards: some View {
        HStack(spacing: 8) {
            CashFlowSummaryCard(
                title: "In",
                amount: totalIncome,
                trend: "+12%",
                trendUp: true,
                color: .furgMint
            )

            CashFlowSummaryCard(
                title: "Out",
                amount: totalSpending,
                trend: "-5%",
                trendUp: false,
                color: .furgWarning
            )

            CashFlowSummaryCard(
                title: "Saved",
                amount: totalSavings,
                trend: "+18%",
                trendUp: totalSavings > 0,
                color: .furgSuccess
            )
        }
    }

    // MARK: - Main Chart

    private var mainChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Trend")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                // Tab selector - full width
                HStack(spacing: 4) {
                    ForEach(CashFlowTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab.shortLabel)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .furgCharcoal : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTab == tab ? Color.furgMint : Color.clear)
                                )
                        }
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
            }

            // Chart
            Chart {
                ForEach(cashFlowData) { period in
                    switch selectedTab {
                    case .overview:
                        BarMark(
                            x: .value("Period", period.label),
                            y: .value("Income", period.income)
                        )
                        .foregroundStyle(Color.furgMint.gradient)
                        .cornerRadius(4)

                        BarMark(
                            x: .value("Period", period.label),
                            y: .value("Spending", -period.spending)
                        )
                        .foregroundStyle(Color.furgWarning.gradient)
                        .cornerRadius(4)

                    case .income:
                        BarMark(
                            x: .value("Period", period.label),
                            y: .value("Income", period.income)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)

                    case .spending:
                        BarMark(
                            x: .value("Period", period.label),
                            y: .value("Spending", period.spending)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgWarning.opacity(0.7), .furgWarning],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatCurrency(abs(amount)))
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(height: 220)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Spending by Category")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button("View All") {
                    showSpendingDashboard = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.furgMint)
            }

            // Donut chart
            HStack(spacing: 20) {
                // Chart
                ZStack {
                    Chart(categoryBreakdown) { category in
                        SectorMark(
                            angle: .value("Amount", category.amount),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.5
                        )
                        .foregroundStyle(category.color.gradient)
                        .cornerRadius(4)
                    }
                    .frame(width: 140, height: 140)

                    VStack(spacing: 2) {
                        Text(formatCurrency(totalSpending))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("Total")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categoryBreakdown.prefix(5)) { category in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)

                            Text(category.category)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)

                            Spacer()

                            Text(formatCurrency(category.amount))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Key Metrics

    private var keyMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Savings Rate",
                    value: "\(Int((netIncome / totalIncome) * 100))%",
                    subtitle: "of income saved",
                    icon: "arrow.up.right",
                    color: .furgMint
                )

                MetricCard(
                    title: "Avg Daily Spend",
                    value: CurrencyFormatter.formatCompact(totalSpending / 30),
                    subtitle: "per day",
                    icon: "calendar",
                    color: .furgWarning
                )

                MetricCard(
                    title: "Largest Expense",
                    value: "Housing",
                    subtitle: CurrencyFormatter.formatCompact(1500),
                    icon: "house.fill",
                    color: .blue
                )

                MetricCard(
                    title: "vs Last Month",
                    value: "-8%",
                    subtitle: "less spending",
                    icon: "chart.line.downtrend.xyaxis",
                    color: .furgSuccess
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Views

private struct CashFlowSummaryCard: View {
    let title: String
    let amount: Double
    let trend: String
    let trendUp: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))

                    Text(trend)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(trendUp ? .furgSuccess : .furgDanger)
            }

            Text(CurrencyFormatter.formatCompact(amount))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            // Mini progress indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.3))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 40)
                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CashFlowView()
}
