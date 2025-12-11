//
//  ForecastViewV2.swift
//  Furg
//
//  Cash flow forecasting with predictions
//

import SwiftUI
import Charts

struct ForecastViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedRange: ForecastRange = .month
    @State private var selectedDataPoint: ForecastPoint?

    enum ForecastRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Range selector
                    rangeSelector

                    // Summary card
                    summaryCard

                    // Forecast chart
                    forecastChart

                    // Upcoming bills
                    upcomingBillsSection

                    // Predictions
                    predictionsSection
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Range Selector

    var rangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(ForecastRange.allCases, id: \.self) { range in
                Button {
                    withAnimation { selectedRange = range }
                } label: {
                    Text(range.rawValue)
                        .font(.v2Caption)
                        .foregroundColor(selectedRange == range ? .v2TextInverse : .v2TextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedRange == range ? Color.v2Primary : Color.v2CardBackground)
                        .cornerRadius(20)
                }
            }
            Spacer()
        }
    }

    // MARK: - Summary Card

    var summaryCard: some View {
        V2Card(padding: 24) {
            VStack(spacing: 20) {
                // Projected balance
                VStack(spacing: 4) {
                    Text("Projected Balance")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.v2Primary)
                        Text("3,240")
                            .font(.v2DisplayMedium)
                            .foregroundColor(.v2TextPrimary)
                    }

                    Text("in 30 days")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }

                // Flow summary
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.v2Success)
                            Text("+$4,500")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2Success)
                        }
                        Text("Expected income")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.v2Danger)
                            Text("-$2,180")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2Danger)
                        }
                        Text("Expected expenses")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                // Confidence indicator
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.v2Success)
                    Text("High confidence forecast based on 6 months of data")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.v2Success.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Forecast Chart

    var forecastChart: some View {
        V2Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Balance Projection")
                    .font(.v2Headline)
                    .foregroundColor(.v2TextPrimary)

                Chart {
                    // Historical data (solid line)
                    ForEach(forecastData.filter { !$0.isProjected }, id: \.day) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Balance", point.balance)
                        )
                        .foregroundStyle(Color.v2Primary)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                        AreaMark(
                            x: .value("Day", point.day),
                            y: .value("Balance", point.balance)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.v2Primary.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Projected data (dashed line)
                    ForEach(forecastData.filter { $0.isProjected }, id: \.day) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Balance", point.balance)
                        )
                        .foregroundStyle(Color.v2Primary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
                    }

                    // Bill markers
                    ForEach(forecastData.filter { $0.hasBill }, id: \.day) { point in
                        PointMark(
                            x: .value("Day", point.day),
                            y: .value("Balance", point.balance)
                        )
                        .foregroundStyle(Color.v2Warning)
                        .symbolSize(60)
                    }

                    // Selected point
                    if let selected = selectedDataPoint {
                        RuleMark(x: .value("Day", selected.day))
                            .foregroundStyle(Color.v2TextTertiary.opacity(0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(Int(amount / 1000))k")
                                    .font(.v2CaptionSmall)
                                    .foregroundColor(.v2TextTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 7)) { value in
                        AxisValueLabel {
                            if let day = value.as(Int.self) {
                                Text("Day \(day)")
                                    .font(.v2CaptionSmall)
                                    .foregroundColor(.v2TextTertiary)
                            }
                        }
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
                                            selectedDataPoint = forecastData.first { $0.day == day }
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedDataPoint = nil
                                    }
                            )
                    }
                }
                .frame(height: 200)

                // Selected point detail
                if let selected = selectedDataPoint {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day \(selected.day)")
                                .font(.v2Caption)
                                .foregroundColor(.v2TextSecondary)
                            Text("$\(Int(selected.balance))")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2TextPrimary)
                        }

                        Spacer()

                        if selected.isProjected {
                            Text("Projected")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2Warning)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.v2Warning.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color.v2BackgroundSecondary)
                    .cornerRadius(12)
                }

                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .v2Primary, label: "Actual")
                    LegendItem(color: .v2Primary.opacity(0.5), label: "Projected")
                    LegendItem(color: .v2Warning, label: "Bill due")
                }
            }
        }
    }

    var forecastData: [ForecastPoint] {
        var points: [ForecastPoint] = []
        var balance: Double = 2920

        for day in 1...30 {
            let hasBill = [5, 15, 22].contains(day)
            let isProjected = day > 15

            if hasBill {
                balance -= Double.random(in: 100...300)
            } else {
                balance += Double.random(in: -80...60)
            }

            points.append(ForecastPoint(
                day: day,
                balance: max(balance, 500),
                isProjected: isProjected,
                hasBill: hasBill
            ))
        }
        return points
    }

    // MARK: - Upcoming Bills

    var upcomingBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Upcoming Bills")

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(upcomingBills, id: \.name) { bill in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(bill.color.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: bill.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(bill.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(bill.name)
                                    .font(.v2Body)
                                    .foregroundColor(.v2TextPrimary)

                                Text(bill.dueDate)
                                    .font(.v2CaptionSmall)
                                    .foregroundColor(bill.isUrgent ? .v2Warning : .v2TextTertiary)
                            }

                            Spacer()

                            Text("-$\(Int(bill.amount))")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2TextPrimary)
                        }
                        .padding(16)

                        if bill.name != upcomingBills.last?.name {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    var upcomingBills: [(name: String, icon: String, color: Color, amount: Double, dueDate: String, isUrgent: Bool)] {
        [
            ("Rent", "house.fill", .v2CategoryHome, 1500, "Due in 5 days", true),
            ("Electric Bill", "bolt.fill", .v2Warning, 85, "Due in 8 days", false),
            ("Internet", "wifi", .v2Info, 65, "Due in 12 days", false),
            ("Car Insurance", "car.fill", .v2CategoryTransport, 120, "Due in 15 days", false)
        ]
    }

    // MARK: - Predictions

    var predictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "AI Predictions")

            VStack(spacing: 12) {
                PredictionCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Low balance warning",
                    description: "Your balance may drop below $500 around day 22 if all bills are paid on time.",
                    color: .v2Warning
                )

                PredictionCard(
                    icon: "arrow.up.right",
                    title: "Spending trend",
                    description: "Based on patterns, you'll likely spend $180 more this month on dining out.",
                    color: .v2Info
                )

                PredictionCard(
                    icon: "dollarsign.circle.fill",
                    title: "Savings opportunity",
                    description: "If you reduce subscriptions, you could save an extra $50 this month.",
                    color: .v2Success
                )
            }
        }
    }
}

// MARK: - Forecast Point

struct ForecastPoint {
    let day: Int
    let balance: Double
    let isProjected: Bool
    let hasBill: Bool
}

// MARK: - Prediction Card

struct PredictionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)

                Text(description)
                    .font(.v2Caption)
                    .foregroundColor(.v2TextSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.v2CardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ForecastViewV2()
}
