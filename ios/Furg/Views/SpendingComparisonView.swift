//
//  SpendingComparisonView.swift
//  Furg
//
//  Compare spending across different time periods
//

import SwiftUI
import Charts

struct SpendingComparisonView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedComparison: ComparisonType = .monthOverMonth
    @State private var selectedCategory: String? = nil
    @State private var animate = false

    let categories = ["All", "Food & Dining", "Shopping", "Transportation", "Entertainment", "Utilities"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Comparison type selector
                        comparisonSelector
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Summary cards
                        summaryCards
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Comparison chart
                        comparisonChart
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Category filter
                        categoryFilter
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        // Category breakdown
                        categoryBreakdown
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        // Insights
                        insightsSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.35), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Compare Spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Comparison Selector

    private var comparisonSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ComparisonType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedComparison = type
                        }
                    } label: {
                        Text(type.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedComparison == type ? .furgCharcoal : .white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedComparison == type ? Color.furgMint : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            ComparisonSummaryCard(
                label: selectedComparison.currentLabel,
                amount: 3245.67,
                trend: -12.5,
                isPositive: true
            )

            ComparisonSummaryCard(
                label: selectedComparison.previousLabel,
                amount: 3710.45,
                trend: nil,
                isPositive: false
            )
        }
    }

    // MARK: - Comparison Chart

    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Chart {
                ForEach(currentPeriodData) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(Color.furgMint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                ForEach(previousPeriodData) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(Color.white.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("\(day)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .furgMint, label: selectedComparison.currentLabel, isDashed: false)
                LegendItem(color: .white.opacity(0.3), label: selectedComparison.previousLabel, isDashed: true)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category == "All" ? nil : category
                    } label: {
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor((selectedCategory == nil && category == "All") || selectedCategory == category ? .furgCharcoal : .white.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background((selectedCategory == nil && category == "All") || selectedCategory == category ? Color.furgMint : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 12) {
                CategoryComparisonRow(category: "Food & Dining", current: 687.45, previous: 820.30, icon: "fork.knife", color: .orange)
                CategoryComparisonRow(category: "Shopping", current: 423.20, previous: 567.80, icon: "bag.fill", color: .pink)
                CategoryComparisonRow(category: "Transportation", current: 234.50, previous: 198.70, icon: "car.fill", color: .blue)
                CategoryComparisonRow(category: "Entertainment", current: 156.80, previous: 210.45, icon: "film.fill", color: .purple)
                CategoryComparisonRow(category: "Utilities", current: 289.00, previous: 275.00, icon: "bolt.fill", color: .yellow)
            }
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.furgMint)
                Text("Insights")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 10) {
                InsightRow(
                    icon: "arrow.down.circle.fill",
                    color: .furgSuccess,
                    text: "Your dining spending decreased by $132.85 (16%) compared to last month."
                )

                InsightRow(
                    icon: "arrow.up.circle.fill",
                    color: .furgWarning,
                    text: "Transportation costs increased by $35.80 (18%). Consider carpooling?"
                )

                InsightRow(
                    icon: "star.fill",
                    color: .furgMint,
                    text: "Overall, you're spending 12.5% less this month. Great progress!"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Demo Data

    private var currentPeriodData: [SpendingDataPoint] {
        (1...30).map { day in
            SpendingDataPoint(day: day, amount: Double.random(in: 50...200) + Double(day) * 8)
        }
    }

    private var previousPeriodData: [SpendingDataPoint] {
        (1...30).map { day in
            SpendingDataPoint(day: day, amount: Double.random(in: 60...220) + Double(day) * 9)
        }
    }
}

// MARK: - Supporting Views

struct ComparisonSummaryCard: View {
    let label: String
    let amount: Double
    let trend: Double?
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text("$\(Int(amount))")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend < 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))

                    Text("\(abs(Int(trend)))%")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(isPositive ? .furgSuccess : .furgDanger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let isDashed: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isDashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .frame(width: 20, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct CategoryComparisonRow: View {
    let category: String
    let current: Double
    let previous: Double
    let icon: String
    let color: Color

    var change: Double {
        ((current - previous) / previous) * 100
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Text("$\(Int(current))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.furgMint)

                    Text("vs $\(Int(previous))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                    .font(.system(size: 10, weight: .bold))

                Text("\(abs(Int(change)))%")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(change < 0 ? .furgSuccess : .furgDanger)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
        }
    }
}

// MARK: - Models

enum ComparisonType: CaseIterable {
    case monthOverMonth
    case weekOverWeek
    case yearOverYear
    case customRange

    var label: String {
        switch self {
        case .monthOverMonth: return "Month vs Month"
        case .weekOverWeek: return "Week vs Week"
        case .yearOverYear: return "Year vs Year"
        case .customRange: return "Custom"
        }
    }

    var currentLabel: String {
        switch self {
        case .monthOverMonth: return "This Month"
        case .weekOverWeek: return "This Week"
        case .yearOverYear: return "This Year"
        case .customRange: return "Period 1"
        }
    }

    var previousLabel: String {
        switch self {
        case .monthOverMonth: return "Last Month"
        case .weekOverWeek: return "Last Week"
        case .yearOverYear: return "Last Year"
        case .customRange: return "Period 2"
        }
    }
}

struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let amount: Double
}

// MARK: - Preview

#Preview {
    SpendingComparisonView()
}
