//
//  BudgetChartV2.swift
//  Furg
//
//  Copilot-style budget tracking chart with daily spending visualization
//

import SwiftUI
import Charts

// MARK: - Budget Line Chart (Copilot-style)

struct V2BudgetLineChart: View {
    let dailySpending: [DailySpendingPoint]
    let monthlyBudget: Double
    let daysInMonth: Int

    @State private var selectedPoint: DailySpendingPoint?
    @State private var animationProgress: CGFloat = 0

    var idealDailyBudget: Double { monthlyBudget / Double(daysInMonth) }
    var currentDay: Int { Calendar.current.component(.day, from: Date()) }

    // Generate ideal spending line (linear from 0 to budget)
    var idealLine: [DailySpendingPoint] {
        (1...daysInMonth).map { day in
            DailySpendingPoint(
                day: day,
                amount: idealDailyBudget * Double(day),
                cumulativeAmount: idealDailyBudget * Double(day)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Tracking")
                        .font(.v2Headline)
                        .foregroundColor(.v2TextPrimary)

                    if let lastPoint = dailySpending.last {
                        let remaining = monthlyBudget - lastPoint.cumulativeAmount
                        let idealAtThisPoint = idealDailyBudget * Double(lastPoint.day)
                        let difference = idealAtThisPoint - lastPoint.cumulativeAmount

                        HStack(spacing: 6) {
                            Text("$\(Int(remaining)) left")
                                .font(.v2Caption)
                                .foregroundColor(.v2TextSecondary)

                            if abs(difference) > 1 {
                                V2BudgetBadge(
                                    amount: abs(difference),
                                    isUnder: difference > 0
                                )
                            }
                        }
                    }
                }

                Spacer()

                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .v2Lime, label: "Actual")
                    LegendItem(color: .v2TextTertiary, label: "Budget")
                }
            }

            // Chart
            Chart {
                // Ideal/Budget line (dashed)
                ForEach(idealLine, id: \.day) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.cumulativeAmount)
                    )
                    .foregroundStyle(Color.v2TextTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }

                // Actual spending line
                ForEach(dailySpending, id: \.day) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.cumulativeAmount * animationProgress)
                    )
                    .foregroundStyle(
                        point.cumulativeAmount > idealDailyBudget * Double(point.day)
                        ? Color.v2Coral
                        : Color.v2Lime
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // Area under actual line
                ForEach(dailySpending, id: \.day) { point in
                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.cumulativeAmount * animationProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (point.cumulativeAmount > idealDailyBudget * Double(point.day)
                                 ? Color.v2Coral : Color.v2Lime).opacity(0.3),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Selected point indicator
                if let selected = selectedPoint {
                    PointMark(
                        x: .value("Day", selected.day),
                        y: .value("Amount", selected.cumulativeAmount)
                    )
                    .foregroundStyle(Color.v2Mint)
                    .symbolSize(100)

                    RuleMark(x: .value("Day", selected.day))
                        .foregroundStyle(Color.v2TextTertiary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .chartXScale(domain: 1...daysInMonth)
            .chartYScale(domain: 0...(monthlyBudget * 1.1))
            .chartXAxis {
                AxisMarks(values: [1, 7, 14, 21, daysInMonth]) { value in
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("\(day)")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    if let day: Int = proxy.value(atX: x) {
                                        selectedPoint = dailySpending.first { $0.day == day }
                                    }
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            }

            // Selected point details
            if let selected = selectedPoint {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day \(selected.day)")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)
                        Text("$\(Int(selected.cumulativeAmount)) spent")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)
                    }

                    Spacer()

                    let idealAtPoint = idealDailyBudget * Double(selected.day)
                    let diff = idealAtPoint - selected.cumulativeAmount

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("vs budget")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)
                        Text(diff >= 0 ? "$\(Int(diff)) under" : "$\(Int(abs(diff))) over")
                            .font(.v2BodyBold)
                            .foregroundColor(diff >= 0 ? .v2Lime : .v2Coral)
                    }
                }
                .padding()
                .background(Color.v2BackgroundSecondary)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Legend Item

struct ChartLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.v2CaptionSmall)
                .foregroundColor(.v2TextSecondary)
        }
    }
}

// MARK: - Daily Spending Data Point

struct DailySpendingPoint: Identifiable {
    let id = UUID()
    let day: Int
    let amount: Double          // Amount spent on this day
    let cumulativeAmount: Double // Total spent up to this day
}

// MARK: - Spending by Day Bar Chart

struct V2DailySpendingBars: View {
    let dailySpending: [DailySpendingPoint]
    let averageDaily: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Spending")
                .font(.v2Headline)
                .foregroundColor(.v2TextPrimary)

            Chart {
                ForEach(dailySpending, id: \.day) { point in
                    BarMark(
                        x: .value("Day", point.day),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(
                        point.amount > averageDaily * 1.5
                        ? Color.v2Coral
                        : (point.amount > averageDaily ? Color.v2Gold : Color.v2Mint)
                    )
                    .cornerRadius(4)
                }

                // Average line
                RuleMark(y: .value("Average", averageDaily))
                    .foregroundStyle(Color.v2TextTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("avg")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 7)) { value in
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("\(day)")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
    }
}

// MARK: - Category Donut Chart

struct V2CategoryDonut: View {
    let categories: [CategorySpendingV2]
    @State private var selectedCategory: CategorySpendingV2?

    var totalSpent: Double {
        categories.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Donut chart
                Chart(categories, id: \.name) { category in
                    SectorMark(
                        angle: .value("Amount", category.amount),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(category.color)
                    .opacity(selectedCategory == nil || selectedCategory?.name == category.name ? 1 : 0.4)
                }
                .chartLegend(.hidden)
                .frame(width: 180, height: 180)

                // Center text
                VStack(spacing: 2) {
                    if let selected = selectedCategory {
                        Text(selected.name)
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)
                        Text("$\(Int(selected.amount))")
                            .font(.v2DisplaySmall)
                            .foregroundColor(.v2TextPrimary)
                        Text("\(Int(selected.amount / totalSpent * 100))%")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    } else {
                        Text("Total")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)
                        Text("$\(Int(totalSpent))")
                            .font(.v2DisplaySmall)
                            .foregroundColor(.v2TextPrimary)
                    }
                }
            }

            // Category list
            VStack(spacing: 8) {
                ForEach(categories.sorted(by: { $0.amount > $1.amount }), id: \.name) { category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedCategory?.name == category.name {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 10, height: 10)

                            Text(category.name)
                                .font(.v2Caption)
                                .foregroundColor(.v2TextPrimary)

                            Spacer()

                            Text("$\(Int(category.amount))")
                                .font(.v2Caption)
                                .foregroundColor(.v2TextSecondary)

                            Text("\(Int(category.amount / totalSpent * 100))%")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                                .frame(width: 35, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            selectedCategory?.name == category.name
                            ? category.color.opacity(0.15)
                            : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Category Spending Data

struct CategorySpendingV2: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let amount: Double
    let budget: Double

    static func == (lhs: CategorySpendingV2, rhs: CategorySpendingV2) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.v2Background.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                V2Card {
                    V2BudgetLineChart(
                        dailySpending: (1...15).map { day in
                            DailySpendingPoint(
                                day: day,
                                amount: Double.random(in: 20...150),
                                cumulativeAmount: Double(day) * 65 + Double.random(in: -100...100)
                            )
                        },
                        monthlyBudget: 2000,
                        daysInMonth: 30
                    )
                }

                V2Card {
                    V2CategoryDonut(categories: [
                        CategorySpendingV2(name: "Food", icon: "fork.knife", color: .v2CategoryFood, amount: 450, budget: 500),
                        CategorySpendingV2(name: "Shopping", icon: "bag.fill", color: .v2CategoryShopping, amount: 320, budget: 300),
                        CategorySpendingV2(name: "Transport", icon: "car.fill", color: .v2CategoryTransport, amount: 180, budget: 200),
                        CategorySpendingV2(name: "Entertainment", icon: "tv.fill", color: .v2CategoryEntertainment, amount: 95, budget: 150)
                    ])
                }
            }
            .padding()
        }
    }
}
