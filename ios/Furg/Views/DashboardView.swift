//
//  DashboardView.swift
//  Furg
//
//  Main dashboard providing high-level financial overview
//  with drill-down capabilities to detailed metrics
//
//  FURG Design System - Cyber-Premium Dark Mode
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
            // True Black background for OLED
            Color.furgTrueBlack.ignoresSafeArea()

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
                        .font(.furgSubheadline)
                        .foregroundColor(.furgSecondaryLabel)

                    Text("Your Finances")
                        .font(.furgTitle)
                        .foregroundColor(.furgPrimaryLabel)
                }

                Spacer()

                // Profile avatar with Indigo/Violet gradient
                ZStack {
                    Circle()
                        .fill(FurgGradients.indigoVioletGradient)
                        .frame(width: 44, height: 44)

                    Text("JB")
                        .font(.furgHeadline)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 60)

            // Net Worth Card with Balance Hero styling
            Button {
                showAccounts = true
            } label: {
                ZStack {
                    // Subtle Indigo glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.furgIndigo.opacity(0.25), Color.furgIndigo.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .blur(radius: 50)
                        .offset(y: -30)

                    VStack(spacing: 12) {
                        HStack {
                            Text("NET WORTH")
                                .font(.furgCaption)
                                .foregroundColor(.furgTertiaryLabel)
                                .tracking(1.5)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                Text("+\(formatCurrency(netWorthChange))")
                                    .font(.furgCaption)
                            }
                            .foregroundColor(.furgNeonGreen)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.furgCurrencySymbol)
                                .foregroundColor(.furgIndigo)

                            Text(formatLargeNumber(netWorth))
                                .font(.furgBalanceHero)
                                .foregroundColor(.furgPrimaryLabel)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.furgTertiaryLabel)
                        }

                        // Mini sparkline with Indigo gradient
                        MiniSparklineView()
                            .frame(height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.furgOffBlack)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.furgIndigo.opacity(0.6), Color.furgIndigo.opacity(0.15), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
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
                // Credit Score Gauge with Indigo/Violet gradient
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: CGFloat(creditScore - 300) / 550)
                        .stroke(
                            LinearGradient(
                                colors: [.furgIndigo, .furgViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(creditScore)")
                            .font(.furgTitle2)
                            .foregroundColor(.furgPrimaryLabel)
                        Text("Score")
                            .font(.furgCaption2)
                            .foregroundColor(.furgTertiaryLabel)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Financial Health")
                        .font(.furgHeadline)
                        .foregroundColor(.furgPrimaryLabel)

                    Text("Very Good")
                        .font(.furgSubheadline)
                        .foregroundColor(.furgIndigo)

                    Text("Credit score up 12 pts this month")
                        .font(.furgCaption)
                        .foregroundColor(.furgTertiaryLabel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgTertiaryLabel)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.furgOffBlack)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.furgIndigo.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.furgSubheadline)
                .foregroundColor(.furgSecondaryLabel)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                DashboardQuickActionButton(icon: "dollarsign.circle.fill", label: "Cash Flow", color: .furgIndigo) {
                    showCashFlow = true
                }
                DashboardQuickActionButton(icon: "cart.fill", label: "Shop AI", color: .furgViolet) {
                    showShoppingAssistant = true
                }
                DashboardQuickActionButton(icon: "chart.bar.fill", label: "Analytics", color: .furgIndigo) {
                    showSpendingAnalytics = true
                }
                DashboardQuickActionButton(icon: "tag.fill", label: "Offers", color: .furgNeonAmber) {
                    showOffers = true
                }
            }
        }
    }

    // MARK: - AI Insights Section
    // Sarcastic personality: "The UI copy should reflect the AI's roast persona"

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(.furgIndigo)

                Text("FURG Says")
                    .font(.furgSubheadline)
                    .foregroundColor(.furgSecondaryLabel)

                Spacer()
            }

            VStack(spacing: 10) {
                AIInsightRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .furgNeonAmber,
                    message: "Survival? Dramatic much? You've blown 40% more on food this week.",
                    actionText: "See Details"
                ) {
                    showCategories = true
                }

                AIInsightRow(
                    icon: "sparkles",
                    iconColor: .furgNeonGreen,
                    message: "Wow, you're actually saving money. $500 extra this month. Don't spend it all in one place.",
                    actionText: nil
                ) { }

                AIInsightRow(
                    icon: "lightbulb.fill",
                    iconColor: .furgNeonAmber,
                    message: "Found 3 subscriptions you forgot about. Shocking.",
                    actionText: "Review"
                ) {
                    showTransactions = true
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.furgOffBlack)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color.furgIndigo.opacity(0.4), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.furgSubheadline)
                    .foregroundColor(.furgSecondaryLabel)

                Spacer()

                Button {
                    showTransactions = true
                } label: {
                    Text("See All")
                        .font(.furgCaption)
                        .foregroundColor(.furgIndigo)
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
                    .font(.furgCaption2)
                    .foregroundColor(.furgTertiaryLabel)

                Text(value)
                    .font(.furgTitle2)
                    .foregroundColor(.furgPrimaryLabel)

                // Progress bar with gradient
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
                    .font(.furgCaption2)
                    .foregroundColor(.furgTertiaryLabel)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.furgOffBlack)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
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
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.furgCaption)
                    .foregroundColor(.furgSecondaryLabel)
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
                    .font(.furgCaption)
                    .foregroundColor(.furgSecondaryLabel)
                    .lineLimit(2)

                if let actionText = actionText {
                    Button(action: action) {
                        Text(actionText)
                            .font(.furgCaption)
                            .foregroundColor(.furgIndigo)
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
                    .fill(amount > 0 ? Color.furgNeonGreen.opacity(0.2) : Color.furgOffBlack)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(amount > 0 ? Color.furgNeonGreen.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )

                Image(systemName: amount > 0 ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(amount > 0 ? .furgNeonGreen : .furgSecondaryLabel)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(merchant)
                    .font(.furgSubheadline)
                    .foregroundColor(.furgPrimaryLabel)

                Text(category)
                    .font(.furgCaption)
                    .foregroundColor(.furgTertiaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(amount))
                    .font(.furgSubheadline)
                    .foregroundColor(amount > 0 ? .furgNeonGreen : .furgPrimaryLabel)

                Text(time)
                    .font(.furgCaption2)
                    .foregroundColor(.furgTertiaryLabel)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.furgOffBlack)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
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
                        colors: [.furgIndigo, .furgViolet],
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
                        colors: [.furgIndigo.opacity(0.3), .clear],
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
