//
//  DashboardView.swift
//  Furg
//
//  Main dashboard providing high-level financial overview
//  with drill-down capabilities to detailed metrics
//

import SwiftUI
import Charts

// MARK: - Dashboard View

struct DashboardView: View {
    @State private var animate = false
    @State private var selectedQuickAction: QuickAction?
    @State private var showBudgetCreator = false
    @State private var showCashFlow = false
    @State private var showAccounts = false
    @State private var showTransactions = false
    @State private var showCategories = false
    @State private var showOffers = false
    @State private var showSpendingAnalytics = false
    @State private var showFinancialHealth = false
    @State private var showShoppingAssistant = false

    // Demo data
    let netWorth: Double = 298264.74
    let netWorthChange: Double = 3420.50
    let monthlySpending: Double = 4235.67
    let spendingBudget: Double = 5000.00
    let savingsRate: Double = 22.5
    let creditScore: Int = 752

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Greeting & Net Worth Hero
                    heroSection
                        .offset(y: animate ? 0 : -30)
                        .opacity(animate ? 1 : 0)

                    // Quick Insights Row
                    quickInsightsRow
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.1), value: animate)

                    // Financial Health Score
                    financialHealthCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.2), value: animate)

                    // Quick Actions Grid
                    quickActionsGrid
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.3), value: animate)

                    // AI Insights Section
                    aiInsightsSection
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.4), value: animate)

                    // Recent Activity Preview
                    recentActivitySection
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.5), value: animate)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .sheet(isPresented: $showBudgetCreator) {
            AIBudgetCreatorView()
        }
        .sheet(isPresented: $showCashFlow) {
            NavigationStack {
                CashFlowView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showCashFlow = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showAccounts) {
            NavigationStack {
                AccountsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showAccounts = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showTransactions) {
            NavigationStack {
                TransactionsListView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showTransactions = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showCategories) {
            NavigationStack {
                CategoriesView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showCategories = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showOffers) {
            NavigationStack {
                OffersView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showOffers = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showSpendingAnalytics) {
            NavigationStack {
                SpendingAnalyticsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showSpendingAnalytics = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        // TODO: Add FinancialHealthView to Xcode project
        .sheet(isPresented: $showFinancialHealth) {
            NavigationStack {
                Text("Financial Health - Coming Soon")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.furgCharcoal)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showFinancialHealth = false }
                                .foregroundColor(.furgMint)
                        }
                    }
            }
            .presentationBackground(Color.furgCharcoal)
        }
        .sheet(isPresented: $showShoppingAssistant) {
            ShoppingChatView()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Greeting
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("Your Finances")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Profile avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Text("JB")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 60)

            // Net Worth Card
            Button {
                showAccounts = true
            } label: {
                VStack(spacing: 12) {
                    HStack {
                        Text("NET WORTH")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("+\(formatCurrency(netWorthChange))")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.furgSuccess)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.furgMint)

                        Text(formatLargeNumber(netWorth))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // Mini sparkline
                    MiniSparklineView()
                        .frame(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(20)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Quick Insights Row

    private var quickInsightsRow: some View {
        HStack(spacing: 12) {
            // Monthly Spending
            QuickInsightCard(
                title: "This Month",
                value: formatCurrency(monthlySpending),
                subtitle: "\(Int((monthlySpending/spendingBudget) * 100))% of budget",
                icon: "arrow.down.circle.fill",
                color: monthlySpending > spendingBudget ? .furgDanger : .furgMint,
                progress: min(monthlySpending/spendingBudget, 1.0)
            ) {
                showCashFlow = true
            }

            // Savings Rate
            QuickInsightCard(
                title: "Savings Rate",
                value: "\(Int(savingsRate))%",
                subtitle: "Great progress!",
                icon: "chart.line.uptrend.xyaxis",
                color: .furgSuccess,
                progress: savingsRate / 100
            ) {
                showCashFlow = true
            }
        }
    }

    // MARK: - Financial Health Card

    private var financialHealthCard: some View {
        Button {
            showFinancialHealth = true
        } label: {
            HStack(spacing: 16) {
                // Credit Score Gauge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: CGFloat(creditScore - 300) / 550)
                        .stroke(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(creditScore)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Score")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Financial Health")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Very Good")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.furgMint)

                    Text("Credit score up 12 pts this month")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                DashboardQuickActionButton(icon: "dollarsign.circle.fill", label: "Cash Flow", color: .furgMint) {
                    showCashFlow = true
                }
                DashboardQuickActionButton(icon: "cart.fill", label: "Shop AI", color: .pink) {
                    showShoppingAssistant = true
                }
                DashboardQuickActionButton(icon: "chart.bar.fill", label: "Analytics", color: .cyan) {
                    showSpendingAnalytics = true
                }
                DashboardQuickActionButton(icon: "tag.fill", label: "Offers", color: .orange) {
                    showOffers = true
                }
            }
        }
    }

    // MARK: - AI Insights Section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(.furgMint)

                Text("FURG Says")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()
            }

            VStack(spacing: 10) {
                AIInsightRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .furgWarning,
                    message: "You've spent 40% more on dining this week than usual.",
                    actionText: "See Details"
                ) {
                    showCategories = true
                }

                AIInsightRow(
                    icon: "sparkles",
                    iconColor: .furgMint,
                    message: "Great job! You're on track to save $500 more this month.",
                    actionText: nil
                ) { }

                AIInsightRow(
                    icon: "lightbulb.fill",
                    iconColor: .yellow,
                    message: "I found 3 subscriptions you might not need. Want to review?",
                    actionText: "Review"
                ) {
                    showTransactions = true
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Button {
                    showTransactions = true
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.furgMint)
                }
            }

            VStack(spacing: 8) {
                RecentTransactionRow(merchant: "Whole Foods", amount: -87.43, category: "Groceries", time: "2h ago")
                RecentTransactionRow(merchant: "Netflix", amount: -15.99, category: "Subscription", time: "Yesterday")
                RecentTransactionRow(merchant: "Paycheck", amount: 3250.00, category: "Income", time: "Dec 1")
            }
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatLargeNumber(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Supporting Views

private struct QuickInsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)

                    Spacer()
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardQuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AIInsightRow: View {
    let icon: String
    let iconColor: Color
    let message: String
    let actionText: String?
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)

                if let actionText = actionText {
                    Button(action: action) {
                        Text(actionText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.furgMint)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

private struct RecentTransactionRow: View {
    let merchant: String
    let amount: Double
    let category: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(amount > 0 ? Color.furgSuccess.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: amount > 0 ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(amount > 0 ? .furgSuccess : .white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(merchant)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(category)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(amount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(amount > 0 ? .furgSuccess : .white)

                Text(time)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        let prefix = amount > 0 ? "+" : ""
        return prefix + (formatter.string(from: NSNumber(value: amount)) ?? "$0")
    }
}

private struct MiniSparklineView: View {
    var body: some View {
        let data: [Double] = [280000, 282500, 285000, 283000, 290000, 288000, 292000, 295000, 293000, 296000, 294000, 298264]

        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Month", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Month", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.furgMint.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 275000...305000)
    }
}

#Preview {
    DashboardView()
}
