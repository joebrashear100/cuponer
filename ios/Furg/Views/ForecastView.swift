//
//  ForecastView.swift
//  Furg
//
//  Cash flow forecasting and projections view
//

import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var forecastingManager: ForecastingManager
    @State private var animate = false
    @State private var selectedTimeframe = 30
    @State private var showBalance = false
    @State private var showBills = false
    @State private var showGoals = false
    @State private var showCategories = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                ForecastHeader()
                    .offset(y: animate ? 0 : -20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animate)

                // Summary Card
                if let forecast = forecastingManager.forecast ?? forecastingManager.demoForecast as CashFlowForecast? {
                    ForecastSummaryCard(forecast: forecast)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)
                }

                // Safe to Spend Card
                SafeToSpendCard(
                    amount: forecastingManager.forecast?.safeToSpend ?? forecastingManager.demoForecast.safeToSpend,
                    daysUntilPayday: forecastingManager.forecast?.daysUntilPayday ?? forecastingManager.demoForecast.daysUntilPayday
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                // Timeframe Selector
                TimeframeSelector(selectedTimeframe: $selectedTimeframe)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)

                // Balance Projection Chart
                BalanceProjectionChart(
                    projections: forecastingManager.dailyProjections.isEmpty
                        ? forecastingManager.demoDailyProjections
                        : forecastingManager.dailyProjections,
                    days: selectedTimeframe
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                // Alerts Section
                if !forecastingManager.alerts.isEmpty || !forecastingManager.demoAlerts.isEmpty {
                    ForecastAlertsSection(
                        alerts: forecastingManager.alerts.isEmpty
                            ? forecastingManager.demoAlerts
                            : forecastingManager.alerts
                    ) { actionType in
                        handleAlertAction(actionType)
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)
                }

                // Upcoming Bills
                UpcomingBillsForecast(
                    projections: forecastingManager.dailyProjections.isEmpty
                        ? forecastingManager.demoDailyProjections
                        : forecastingManager.dailyProjections
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: animate)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .task {
            await forecastingManager.refreshAll()
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .sheet(isPresented: $showBalance) {
            NavigationStack {
                BalanceView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showBalance = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
        }
        .sheet(isPresented: $showGoals) {
            NavigationStack {
                GoalsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showGoals = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
        }
        .sheet(isPresented: $showCategories) {
            NavigationStack {
                CategoriesView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showCategories = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
        }
    }

    private func handleAlertAction(_ actionType: ForecastActionType) {
        switch actionType {
        case .showBalance:
            showBalance = true
        case .showBills:
            showBills = true
        case .showGoals:
            showGoals = true
        case .showCategories:
            showCategories = true
        case .none:
            break
        }
    }
}

// MARK: - Header

struct ForecastHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Forecast")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)

                Text("See where your money is going")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                // Refresh
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.furgMint)
                    .padding(12)
                    .glassCard(cornerRadius: 14, opacity: 0.1)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Summary Card

struct ForecastSummaryCard: View {
    let forecast: CashFlowForecast

    var body: some View {
        VStack(spacing: 20) {
            // Current vs Projected
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TODAY")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)

                    Text("$\(NSDecimalNumber(decimal: forecast.currentBalance).intValue)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.horizontal, 20)

                VStack(alignment: .trailing, spacing: 8) {
                    Text("IN 30 DAYS")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)

                    Text("$\(NSDecimalNumber(decimal: forecast.projectedBalance30Days).intValue)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(forecast.projectedBalance30Days < forecast.currentBalance ? .furgWarning : .furgMint)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Income vs Expenses
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.furgSuccess)
                        Text("Expected Income")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Text("+$\(NSDecimalNumber(decimal: forecast.expectedIncome).intValue)")
                        .font(.furgHeadline)
                        .foregroundColor(.furgSuccess)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Expected Expenses")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.furgError)
                    }

                    Text("-$\(NSDecimalNumber(decimal: forecast.expectedExpenses).intValue)")
                        .font(.furgHeadline)
                        .foregroundColor(.furgError)
                }
            }
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Safe to Spend Card

struct SafeToSpendCard: View {
    let amount: Decimal
    let daysUntilPayday: Int

    var dailyBudget: Decimal {
        guard daysUntilPayday > 0 else { return amount }
        return amount / Decimal(daysUntilPayday)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: "creditcard.fill")
                    .font(.title2)
                    .foregroundColor(.furgMint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("SAFE TO SPEND")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)

                Text("$\(NSDecimalNumber(decimal: amount).intValue)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.furgMint)

                Text("$\(NSDecimalNumber(decimal: dailyBudget).intValue)/day for \(daysUntilPayday) days")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Timeframe Selector

struct TimeframeSelector: View {
    @Binding var selectedTimeframe: Int

    let options = [7, 14, 30, 60, 90]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { days in
                Button {
                    selectedTimeframe = days
                } label: {
                    Text("\(days)d")
                        .font(.furgCaption.bold())
                        .foregroundColor(selectedTimeframe == days ? .furgCharcoal : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedTimeframe == days ? Color.furgMint : Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Balance Projection Chart

struct BalanceProjectionChart: View {
    let projections: [DailyProjection]
    let days: Int

    var filteredProjections: [DailyProjection] {
        Array(projections.prefix(days))
    }

    var maxBalance: Decimal {
        filteredProjections.map { $0.projectedBalance }.max() ?? 1
    }

    var minBalance: Decimal {
        filteredProjections.map { $0.projectedBalance }.min() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Balance Projection")
                .font(.furgHeadline)
                .foregroundColor(.white)

            // Chart
            GeometryReader { geo in
                let width = geo.size.width
                let height: CGFloat = 150
                let range = maxBalance - minBalance

                ZStack {
                    // Grid lines
                    ForEach(0..<4) { i in
                        let y = height * CGFloat(i) / 3
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }

                    // Line chart
                    Path { path in
                        for (index, projection) in filteredProjections.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(max(filteredProjections.count - 1, 1))
                            let normalizedBalance = range > 0 ? (projection.projectedBalance - minBalance) / range : 0.5
                            let y = height * (1 - CGFloat(truncating: normalizedBalance as NSNumber))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    // Fill under curve
                    Path { path in
                        for (index, projection) in filteredProjections.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(max(filteredProjections.count - 1, 1))
                            let normalizedBalance = range > 0 ? (projection.projectedBalance - minBalance) / range : 0.5
                            let y = height * (1 - CGFloat(truncating: normalizedBalance as NSNumber))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [.furgMint.opacity(0.3), .furgMint.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 150)

            // Labels
            HStack {
                Text("$\(NSDecimalNumber(decimal: minBalance).intValue)")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                Text("$\(NSDecimalNumber(decimal: maxBalance).intValue)")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Alerts Section

struct ForecastAlertsSection: View {
    let alerts: [ForecastAlert]
    var onAlertAction: ((ForecastActionType) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.furgWarning)
                Text("Alerts")
                    .font(.furgHeadline)
                    .foregroundColor(.white)
                Spacer()
            }

            ForEach(alerts) { alert in
                ForecastAlertRow(alert: alert) { actionType in
                    onAlertAction?(actionType)
                }
            }
        }
    }
}

struct ForecastAlertRow: View {
    let alert: ForecastAlert
    var onAction: ((ForecastActionType) -> Void)?

    var iconColor: Color {
        switch alert.severity {
        case .info: return .furgInfo
        case .warning: return .furgWarning
        case .critical: return .furgError
        case .positive: return .furgSuccess
        }
    }

    var icon: String {
        switch alert.type {
        case .lowBalance: return "exclamationmark.triangle.fill"
        case .billDue: return "calendar.badge.clock"
        case .payday: return "dollarsign.circle.fill"
        case .overdraft: return "xmark.circle.fill"
        case .goalMilestone: return "star.fill"
        case .unusualSpending: return "chart.line.uptrend.xyaxis"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.furgBody.bold())
                    .foregroundColor(.white)

                Text(alert.message)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()

            if let actionLabel = alert.actionLabel {
                Button {
                    onAction?(alert.actionType)
                } label: {
                    HStack(spacing: 4) {
                        Text(actionLabel)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.furgCaption.bold())
                    .foregroundColor(.furgMint)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14, opacity: 0.08)
    }
}

// MARK: - Upcoming Bills Forecast

struct UpcomingBillsForecast: View {
    let projections: [DailyProjection]

    var upcomingBills: [ProjectedBill] {
        projections.flatMap { $0.bills }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var totalBills: Decimal {
        upcomingBills.reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Bills")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                Text("$\(NSDecimalNumber(decimal: totalBills).intValue)")
                    .font(.furgHeadline)
                    .foregroundColor(.furgWarning)
            }

            if upcomingBills.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.title)
                            .foregroundColor(.furgSuccess)
                        Text("No bills due soon")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(upcomingBills.prefix(5)) { bill in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bill.name)
                                    .font(.furgBody)
                                    .foregroundColor(.white)

                                Text(bill.dueDate, style: .date)
                                    .font(.furgCaption)
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Text("$\(NSDecimalNumber(decimal: bill.amount).intValue)")
                                .font(.furgBody.bold())
                                .foregroundColor(.furgWarning)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground()
        ForecastView()
    }
    .environmentObject(ForecastingManager())
}
