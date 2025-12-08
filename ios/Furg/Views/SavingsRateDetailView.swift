//
//  SavingsRateDetailView.swift
//  Furg
//
//  Detailed savings rate analysis with historical data and projections
//

import SwiftUI
import Charts

struct SavingsRateDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedTimeframe: Timeframe = .year

    enum Timeframe: String, CaseIterable {
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    // Demo data
    let currentSavingsRate: Double = 22.5
    let income: Double = 6500
    let expenses: Double = 4235
    let savings: Double = 1465
    let invested: Double = 800
    let targetSavingsRate: Double = 25.0

    var savingsHistory: [SavingsDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { i in
            SavingsDataPoint(
                date: calendar.date(byAdding: .month, value: -i, to: now)!,
                rate: Double.random(in: 18...28),
                income: Double.random(in: 6000...7000),
                expenses: Double.random(in: 4000...4800)
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Current rate hero
                        savingsRateHero
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Breakdown
                        breakdownSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Historical chart
                        historicalChart
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Projections
                        projectionsSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        // Tips to improve
                        improvementTips
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.4), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Savings Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Savings Rate Hero

    private var savingsRateHero: some View {
        VStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 16)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: currentSavingsRate / 100)
                    .stroke(
                        AngularGradient(
                            colors: [.furgMint, .furgSeafoam, .furgSuccess],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Target indicator
                Circle()
                    .fill(Color.furgWarning)
                    .frame(width: 12, height: 12)
                    .offset(y: -90)
                    .rotationEffect(.degrees(targetSavingsRate / 100 * 360))

                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", currentSavingsRate))%")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text("of income saved")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 4) {
                        Image(systemName: currentSavingsRate >= 20 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text("+2.3% vs last month")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.furgSuccess)
                }
            }

            // Target comparison
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Your Rate")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(String(format: "%.1f", currentSavingsRate))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.furgMint)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("Target")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(String(format: "%.0f", targetSavingsRate))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.furgWarning)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("US Average")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("6%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Month's Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // Visual breakdown bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Expenses
                    Rectangle()
                        .fill(Color.furgDanger.opacity(0.8))
                        .frame(width: geo.size.width * (expenses / income))

                    // Savings
                    Rectangle()
                        .fill(Color.furgMint)
                        .frame(width: geo.size.width * (savings / income))

                    // Invested
                    Rectangle()
                        .fill(Color.furgSeafoam)
                        .frame(width: geo.size.width * (invested / income))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 12)

            // Legend
            VStack(spacing: 12) {
                BreakdownRow(
                    label: "Income",
                    amount: income,
                    color: .white,
                    percentage: 100
                )

                BreakdownRow(
                    label: "Expenses",
                    amount: expenses,
                    color: .furgDanger,
                    percentage: (expenses / income) * 100
                )

                BreakdownRow(
                    label: "Cash Savings",
                    amount: savings,
                    color: .furgMint,
                    percentage: (savings / income) * 100
                )

                BreakdownRow(
                    label: "Invested",
                    amount: invested,
                    color: .furgSeafoam,
                    percentage: (invested / income) * 100
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Historical Chart

    private var historicalChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Savings Rate History")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            Chart {
                // Target line
                RuleMark(y: .value("Target", targetSavingsRate))
                    .foregroundStyle(Color.furgWarning.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                ForEach(savingsHistory) { point in
                    LineMark(
                        x: .value("Month", point.date),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", point.date),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint.opacity(0.3), .furgMint.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...40)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let rate = value.as(Double.self) {
                            Text("\(Int(rate))%")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.furgMint)
                        .frame(width: 12, height: 3)
                    Text("Your rate")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.furgWarning)
                        .frame(width: 12, height: 3)
                    Text("Target (25%)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Projections Section

    private var projectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.furgMint)
                Text("Projections")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                ProjectionRow(
                    title: "If you maintain 22.5%",
                    oneYear: 17580,
                    fiveYear: 87900,
                    tenYear: 175800
                )

                Divider().background(Color.white.opacity(0.1))

                ProjectionRow(
                    title: "If you reach 25% target",
                    oneYear: 19500,
                    fiveYear: 97500,
                    tenYear: 195000,
                    isTarget: true
                )

                Divider().background(Color.white.opacity(0.1))

                ProjectionRow(
                    title: "If you hit 30%",
                    oneYear: 23400,
                    fiveYear: 117000,
                    tenYear: 234000
                )
            }

            Text("* Assumes 7% annual investment return")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Improvement Tips

    private var improvementTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.furgWarning)
                Text("Tips to Increase Your Rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                ImprovementTip(
                    icon: "dollarsign.arrow.circlepath",
                    title: "Automate savings",
                    description: "Set up automatic transfers on payday before you can spend it",
                    impact: "+3-5%"
                )

                ImprovementTip(
                    icon: "cart.badge.minus",
                    title: "Cut subscriptions",
                    description: "Cancel unused subscriptions - you have 3 you rarely use",
                    impact: "+1%"
                )

                ImprovementTip(
                    icon: "house.fill",
                    title: "Reduce housing costs",
                    description: "Consider roommates or refinancing if rates drop",
                    impact: "+5-10%"
                )

                ImprovementTip(
                    icon: "arrow.up.circle.fill",
                    title: "Boost income",
                    description: "A side hustle or raise goes directly to savings",
                    impact: "+5%+"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.furgWarning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgWarning.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Supporting Types

struct SavingsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
    let income: Double
    let expenses: Double
}

// MARK: - Supporting Views

private struct BreakdownRow: View {
    let label: String
    let amount: Double
    let color: Color
    let percentage: Double

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text("$\(Int(amount))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("(\(String(format: "%.0f", percentage))%)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 45, alignment: .trailing)
        }
    }
}

private struct ProjectionRow: View {
    let title: String
    let oneYear: Int
    let fiveYear: Int
    let tenYear: Int
    var isTarget: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isTarget ? .furgMint : .white.opacity(0.7))

                if isTarget {
                    Text("RECOMMENDED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.furgCharcoal)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.furgMint)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("1 Year")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("$\(oneYear.formatted())")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("5 Years")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("$\(fiveYear.formatted())")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("10 Years")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("$\(tenYear.formatted())")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isTarget ? .furgMint : .white)
                }
            }
        }
    }
}

private struct ImprovementTip: View {
    let icon: String
    let title: String
    let description: String
    let impact: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.furgMint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text(impact)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.furgSuccess)
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    SavingsRateDetailView()
}
