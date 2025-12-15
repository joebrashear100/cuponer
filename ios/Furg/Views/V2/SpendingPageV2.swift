//
//  SpendingPageV2.swift
//  Furg
//
//  Spending analysis page for V2 gesture navigation
//  Shows spending breakdown, trends, and top merchants
//

import SwiftUI

struct SpendingPageV2: View {
    // MARK: - Actions
    var onShowInsights: () -> Void = {}
    var onShowSpendingLimits: () -> Void = {}

    // MARK: - Environment
    @EnvironmentObject var financeManager: FinanceManager

    // MARK: - State
    @State private var selectedTimeframe: Timeframe = .month

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Total Spending Card
                totalSpendingCard

                // Timeframe Selector
                timeframeSelector

                // Category Breakdown
                categoryBreakdownSection

                // Top Merchants
                topMerchantsSection

                // Actions
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spending")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)

                Text("Track where your money goes")
                    .font(.v2Caption)
                    .foregroundColor(.v2TextTertiary)
            }
            Spacer()
        }
    }

    // MARK: - Total Spending Card
    private var totalSpendingCard: some View {
        V2Card {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Spent")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextTertiary)

                        V2AmountDisplay(amount: totalSpent, size: .large)
                    }

                    Spacer()

                    // vs Budget indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(budgetStatus)
                            .font(.v2CaptionMedium)
                            .foregroundColor(budgetStatusColor)

                        Text("of $\(Int(monthlyBudget)) budget")
                            .font(.v2Footnote)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                // Mini trend chart placeholder
                HStack(spacing: 4) {
                    ForEach(weeklySpending, id: \.self) { amount in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.v2Primary.opacity(0.6))
                            .frame(width: 30, height: CGFloat(amount / 100) * 40 + 10)
                    }
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        HStack(spacing: 8) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    V2Pill(
                        text: timeframe.rawValue,
                        isSelected: selectedTimeframe == timeframe
                    )
                }
            }
            Spacer()
        }
    }

    // MARK: - Category Breakdown
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(
                title: "By Category",
                action: "See All",
                onAction: onShowInsights
            )

            VStack(spacing: 10) {
                ForEach(categorySpending, id: \.name) { category in
                    categoryRow(
                        name: category.name,
                        amount: category.amount,
                        percentage: category.percentage,
                        color: categoryColor(for: category.name)
                    )
                }
            }
        }
    }

    private func categoryRow(name: String, amount: Double, percentage: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            // Name
            Text(name)
                .font(.v2Body)
                .foregroundColor(.v2TextPrimary)

            Spacer()

            // Amount
            Text(String(format: "$%.0f", amount))
                .font(.v2BodyMedium)
                .foregroundColor(.v2TextPrimary)

            // Percentage
            Text(String(format: "%.0f%%", percentage))
                .font(.v2Caption)
                .foregroundColor(.v2TextTertiary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(12)
        .background(Color.v2CardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Top Merchants
    private var topMerchantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Top Merchants")

            VStack(spacing: 8) {
                ForEach(topMerchants.prefix(5), id: \.name) { merchant in
                    merchantRow(
                        name: merchant.name,
                        amount: merchant.amount,
                        visits: merchant.visits
                    )
                }
            }
        }
    }

    private func merchantRow(name: String, amount: Double, visits: Int) -> some View {
        HStack(spacing: 12) {
            // Merchant icon placeholder
            Image(systemName: "building.2.fill")
                .font(.system(size: 16))
                .foregroundColor(.v2Primary)
                .frame(width: 36, height: 36)
                .background(Color.v2Primary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.v2BodyMedium)
                    .foregroundColor(.v2TextPrimary)

                Text("\(visits) visits")
                    .font(.v2Footnote)
                    .foregroundColor(.v2TextTertiary)
            }

            Spacer()

            Text(String(format: "$%.0f", amount))
                .font(.v2BodyMedium)
                .foregroundColor(.v2TextPrimary)
        }
        .padding(12)
        .background(Color.v2CardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onShowInsights) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                    Text("Insights")
                }
                .v2SecondaryButton()
            }

            Button(action: onShowSpendingLimits) {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    Text("Limits")
                }
                .v2SecondaryButton()
            }

            Spacer()
        }
    }

    // MARK: - Computed Properties
    private var totalSpent: Double {
        // Use actual transactions if available, otherwise demo
        if !financeManager.transactions.isEmpty {
            return financeManager.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
        }
        return 2450
    }

    private var monthlyBudget: Double {
        // Demo value - FinanceManager doesn't have monthlyBudget
        5000
    }

    private var budgetStatus: String {
        let remaining = monthlyBudget - totalSpent
        if remaining < 0 {
            return "Over budget"
        } else if remaining < monthlyBudget * 0.1 {
            return "Almost at limit"
        }
        return "\(Int((totalSpent / monthlyBudget) * 100))% used"
    }

    private var budgetStatusColor: Color {
        let ratio = totalSpent / monthlyBudget
        if ratio > 1.0 { return .v2Danger }
        if ratio > 0.9 { return .v2Warning }
        return .v2Success
    }

    private var weeklySpending: [Double] {
        [85, 120, 45, 200, 90, 150, 75]
    }

    private var categorySpending: [(name: String, amount: Double, percentage: Double)] {
        [
            ("Food & Dining", 650, 26.5),
            ("Shopping", 420, 17.1),
            ("Transportation", 280, 11.4),
            ("Bills", 520, 21.2),
            ("Entertainment", 180, 7.3),
            ("Other", 400, 16.5)
        ]
    }

    private var topMerchants: [(name: String, amount: Double, visits: Int)] {
        [
            ("Whole Foods", 350, 8),
            ("Amazon", 280, 5),
            ("Target", 220, 4),
            ("Uber", 180, 12),
            ("Starbucks", 95, 15)
        ]
    }

    // MARK: - Helpers
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Food & Dining": return .v2CategoryFood
        case "Shopping": return .v2CategoryShopping
        case "Transportation": return .v2CategoryTransport
        case "Bills": return .v2CategoryBills
        case "Entertainment": return .v2CategoryEntertainment
        default: return .v2CategoryOther
        }
    }
}

#Preview {
    SpendingPageV2()
        .environmentObject(FinanceManager())
        .v2Background()
}
