//
//  SpendingAnalyticsView.swift
//  Furg
//
//  Spending analytics with charts and insights
//

import SwiftUI
import Charts

struct SpendingAnalyticsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedCategory: String? = nil
    @State private var animate = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                AnalyticsHeader(selectedPeriod: $selectedPeriod)
                    .offset(y: animate ? 0 : -20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animate)

                // Spending Overview Card
                SpendingOverviewCard(
                    summary: financeManager.spendingSummary,
                    period: selectedPeriod
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Category Breakdown Chart
                CategoryBreakdownChart(
                    summary: financeManager.spendingSummary,
                    selectedCategory: $selectedCategory
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                // Daily Spending Trend
                DailySpendingTrendChart(transactions: financeManager.transactions)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)

                // Top Merchants
                TopMerchantsCard(transactions: financeManager.transactions)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                // Spending Insights
                SpendingInsightsCard(
                    summary: financeManager.spendingSummary,
                    transactions: financeManager.transactions
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .task {
            await financeManager.loadTransactions(days: selectedPeriod.days)
            await financeManager.loadSpendingSummary(days: selectedPeriod.days)
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .onChange(of: selectedPeriod) {
            Task {
                await financeManager.loadTransactions(days: selectedPeriod.days)
                await financeManager.loadSpendingSummary(days: selectedPeriod.days)
            }
        }
    }
}

// MARK: - Analytics Period

enum AnalyticsPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

// MARK: - Analytics Header

struct AnalyticsHeader: View {
    @Binding var selectedPeriod: AnalyticsPeriod

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analytics")
                        .font(.furgLargeTitle)
                        .foregroundColor(.white)

                    Text("Track your spending habits")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(.top, 60)

            // Period selector
            HStack(spacing: 8) {
                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation { selectedPeriod = period }
                    } label: {
                        Text(period.rawValue)
                            .font(.furgCaption.bold())
                            .foregroundColor(selectedPeriod == period ? .furgCharcoal : .white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedPeriod == period ? Color.furgMint : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Spending Overview Card

struct SpendingOverviewCard: View {
    let summary: SpendingSummaryResponse?
    let period: AnalyticsPeriod

    var totalSpent: Double {
        summary?.totalSpent ?? 0
    }

    var avgDaily: Double {
        period.days > 0 ? totalSpent / Double(period.days) : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Spending Overview")
                    .font(.furgHeadline)
                    .foregroundColor(.white)
                Spacer()
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOTAL SPENT")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)

                    Text("$\(Int(totalSpent))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.furgError)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Daily Avg")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))

                        Text("$\(Int(avgDaily))")
                            .font(.furgHeadline)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Categories")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))

                        Text("\(summary?.byCategory.count ?? 0)")
                            .font(.furgHeadline)
                            .foregroundColor(.furgMint)
                    }
                }
            }
        }
        .padding(20)
        .copilotCard()
    }
}

// MARK: - Category Breakdown Chart

struct CategoryBreakdownChart: View {
    let summary: SpendingSummaryResponse?
    @Binding var selectedCategory: String?

    var categoryData: [(category: String, amount: Double, color: Color)] {
        guard let summary = summary else { return demoData }

        return summary.byCategory.map { (key, value) in
            (category: key, amount: value, color: categoryColor(for: key))
        }.sorted { $0.amount > $1.amount }
    }

    var demoData: [(category: String, amount: Double, color: Color)] {
        [
            ("Food", 450, .orange),
            ("Shopping", 320, .pink),
            ("Entertainment", 180, .purple),
            ("Transportation", 150, .blue),
            ("Utilities", 200, .yellow)
        ]
    }

    var totalAmount: Double {
        categoryData.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Category Breakdown")
                .font(.furgHeadline)
                .foregroundColor(.white)

            // Pie Chart
            HStack(spacing: 24) {
                // Chart
                ZStack {
                    ForEach(Array(categoryData.enumerated()), id: \.element.category) { index, item in
                        let startAngle = angleForIndex(index)
                        let endAngle = angleForIndex(index + 1)

                        PieSlice(
                            startAngle: startAngle,
                            endAngle: endAngle,
                            isSelected: selectedCategory == item.category
                        )
                        .fill(item.color)
                        .onTapGesture {
                            withAnimation {
                                selectedCategory = selectedCategory == item.category ? nil : item.category
                            }
                        }
                    }

                    // Center label
                    VStack(spacing: 4) {
                        Text("$\(Int(totalAmount))")
                            .font(.furgTitle2)
                            .foregroundColor(.white)

                        Text("Total")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(width: 140, height: 140)

                // Legend
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(categoryData.prefix(5), id: \.category) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)

                            Text(item.category)
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)

                            Spacer()

                            Text("$\(Int(item.amount))")
                                .font(.furgCaption.bold())
                                .foregroundColor(.white)
                        }
                        .opacity(selectedCategory == nil || selectedCategory == item.category ? 1 : 0.4)
                    }
                }
            }
        }
        .padding(20)
        .copilotCard()
    }

    func angleForIndex(_ index: Int) -> Angle {
        let amounts = categoryData.prefix(index).map { $0.amount }
        let sum = amounts.reduce(0, +)
        return .degrees(sum / totalAmount * 360 - 90)
    }

    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food", "dining", "restaurants": return .orange
        case "shopping": return .pink
        case "transportation", "travel": return .blue
        case "entertainment": return .purple
        case "utilities": return .yellow
        case "health": return .red
        case "groceries": return .green
        default: return .furgMint
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let isSelected: Bool

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * (isSelected ? 1.05 : 0.95)
        let innerRadius = radius * 0.6

        var path = Path()

        path.move(to: CGPoint(
            x: center.x + innerRadius * CGFloat(cos(startAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(startAngle.radians))
        ))

        path.addArc(center: center, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        path.addLine(to: CGPoint(
            x: center.x + radius * CGFloat(cos(endAngle.radians)),
            y: center.y + radius * CGFloat(sin(endAngle.radians))
        ))

        path.addArc(center: center, radius: radius, startAngle: endAngle, endAngle: startAngle, clockwise: true)

        path.closeSubpath()

        return path
    }
}

// MARK: - Daily Spending Trend Chart

struct DailySpendingTrendChart: View {
    let transactions: [Transaction]

    var dailyData: [DailySpending] {
        // Group transactions by day
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions.filter { $0.amount < 0 }) { transaction -> Date in
            // Parse the date string and get start of day
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            if let date = formatter.date(from: transaction.date) {
                return calendar.startOfDay(for: date)
            }
            return Date()
        }

        // If no real data, return demo data
        if grouped.isEmpty {
            return generateDemoData()
        }

        return grouped.map { (date, txns) in
            DailySpending(
                date: date,
                amount: txns.reduce(0) { $0 + abs($1.amount) }
            )
        }.sorted { $0.date < $1.date }
    }

    func generateDemoData() -> [DailySpending] {
        let calendar = Calendar.current
        return (0..<14).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let amount = Double.random(in: 20...150)
            return DailySpending(date: date, amount: amount)
        }.reversed()
    }

    var maxAmount: Double {
        dailyData.map { $0.amount }.max() ?? 100
    }

    var avgAmount: Double {
        let total = dailyData.reduce(0) { $0 + $1.amount }
        return dailyData.isEmpty ? 0 : total / Double(dailyData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Daily Spending")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Avg: $\(Int(avgAmount))/day")
                        .font(.furgCaption)
                        .foregroundColor(.furgMint)
                }
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(dailyData.suffix(14), id: \.date) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: CGFloat(day.amount / maxAmount) * 100)

                        Text(dayLabel(day.date))
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)

            // Average line indicator
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.furgWarning)
                    .frame(width: 20, height: 2)

                Text("Average spending line")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .copilotCard()
    }

    func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Top Merchants Card

struct TopMerchantsCard: View {
    let transactions: [Transaction]

    var topMerchants: [(merchant: String, total: Double, count: Int)] {
        let grouped = Dictionary(grouping: transactions.filter { $0.amount < 0 }) { $0.merchant }

        var merchants = grouped.map { (merchant, txns) in
            (
                merchant: merchant,
                total: txns.reduce(0) { $0 + abs($1.amount) },
                count: txns.count
            )
        }

        // If empty, return demo data
        if merchants.isEmpty {
            merchants = [
                ("Amazon", 234.50, 8),
                ("Starbucks", 89.25, 15),
                ("Uber Eats", 156.00, 6),
                ("Target", 178.90, 4),
                ("Netflix", 15.99, 1)
            ]
        }

        return merchants.sorted { $0.total > $1.total }.prefix(5).map { $0 }
    }

    var maxTotal: Double {
        topMerchants.first?.total ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Top Merchants")
                .font(.furgHeadline)
                .foregroundColor(.white)

            VStack(spacing: 16) {
                ForEach(topMerchants, id: \.merchant) { merchant in
                    HStack(spacing: 14) {
                        // Merchant icon
                        ZStack {
                            Circle()
                                .fill(Color.furgMint.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Text(String(merchant.merchant.prefix(1)))
                                .font(.furgBody.bold())
                                .foregroundColor(.furgMint)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(merchant.merchant)
                                    .font(.furgBody)
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Spacer()

                                Text("$\(Int(merchant.total))")
                                    .font(.furgBody.bold())
                                    .foregroundColor(.white)
                            }

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.furgMint, .furgSeafoam],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(merchant.total / maxTotal), height: 6)
                                }
                            }
                            .frame(height: 6)

                            Text("\(merchant.count) transactions")
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }
        }
        .padding(20)
        .copilotCard()
    }
}

// MARK: - Spending Insights Card

struct SpendingInsightsCard: View {
    let summary: SpendingSummaryResponse?
    let transactions: [Transaction]

    var insights: [SpendingInsight] {
        var results: [SpendingInsight] = []

        // Top category insight
        if let summary = summary, let topCategory = summary.byCategory.max(by: { $0.value < $1.value }) {
            let percentage = Int((topCategory.value / summary.totalSpent) * 100)
            results.append(SpendingInsight(
                icon: "chart.pie.fill",
                title: "Biggest Category",
                message: "\(topCategory.key) takes \(percentage)% of your spending. Watch it!",
                color: .orange
            ))
        }

        // Frequency insight
        let foodTransactions = transactions.filter {
            $0.category.lowercased().contains("food") ||
            $0.category.lowercased().contains("dining")
        }
        if foodTransactions.count > 10 {
            results.append(SpendingInsight(
                icon: "fork.knife",
                title: "Food Habit",
                message: "You've eaten out \(foodTransactions.count) times. Your kitchen misses you.",
                color: .red
            ))
        }

        // Weekend warrior
        results.append(SpendingInsight(
            icon: "calendar.badge.exclamationmark",
            title: "Weekend Warrior",
            message: "You spend 40% more on weekends. Friday you is sabotaging Monday you.",
            color: .purple
        ))

        // Small purchases add up
        let smallPurchases = transactions.filter { abs($0.amount) < 20 && $0.amount < 0 }
        let smallTotal = smallPurchases.reduce(0) { $0 + abs($1.amount) }
        if smallTotal > 100 {
            results.append(SpendingInsight(
                icon: "dollarsign.circle",
                title: "Death by Coffee",
                message: "\(smallPurchases.count) small purchases totaling $\(Int(smallTotal)). The latte factor is real.",
                color: .brown
            ))
        }

        return results
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.furgWarning)
                Text("Spending Insights")
                    .font(.furgHeadline)
                    .foregroundColor(.white)
                Spacer()
            }

            ForEach(insights, id: \.title) { insight in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(insight.color.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: insight.icon)
                            .font(.body)
                            .foregroundColor(insight.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.furgBody.bold())
                            .foregroundColor(.white)

                        Text(insight.message)
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .copilotCard()
    }
}

struct SpendingInsight {
    let icon: String
    let title: String
    let message: String
    let color: Color
}

#Preview {
    ZStack {
        CopilotBackground()
        SpendingAnalyticsView()
    }
    .environmentObject(FinanceManager())
}
