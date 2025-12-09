//
//  BalanceView.swift
//  Furg
//
//  Redesigned with Copilot Money aesthetic - clean, elegant, intuitive
//

import SwiftUI
import Charts

struct BalanceView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var animate = false
    @State private var selectedTimeRange: TimeRange = .month

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
                    // Minimal header
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

                    // Hero Balance - Big, bold, clear
                    VStack(spacing: 8) {
                        Text("Total Balance")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        if let balance = financeManager.balance {
                            Text(formatCurrency(balance.totalBalance))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)

                            // Change indicator - GREEN up (demo data)
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

                    // Balance trend chart - SIMPLE & BEAUTIFUL
                    if let balance = financeManager.balance {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Balance Trend")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)

                            // Time range picker
                            HStack(spacing: 12) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedTimeRange = range
                                        }
                                    } label: {
                                        Text(range.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedTimeRange == range ? .white : .white.opacity(0.4))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedTimeRange == range
                                                ? Color.white.opacity(0.15)
                                                : Color.clear
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                                Spacer()
                            }

                            // Beautiful line chart
                            BalanceTrendChart(data: generateBalanceData(), selectedRange: selectedTimeRange)
                                .frame(height: 200)
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
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animate)
                    }

                    // Cash flow summary - CLEAN INDICATORS
                    HStack(spacing: 16) {
                        // Income - GREEN
                        CashFlowIndicator(
                            title: "Income",
                            amount: 4200,
                            isPositive: true,
                            icon: "arrow.down"
                        )

                        // Spending - RED
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
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animate)

                    // Accounts - MINIMAL CARDS
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
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animate)

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
}

// MARK: - Balance Data Model
struct BalanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

// MARK: - Balance Trend Chart
struct BalanceTrendChart: View {
    let data: [BalanceDataPoint]
    let selectedRange: BalanceView.TimeRange

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.chartIncome.opacity(0.8), Color.chartIncome.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.chartIncome.opacity(0.3), Color.chartIncome.opacity(0.05)],
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
