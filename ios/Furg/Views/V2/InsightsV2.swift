//
//  InsightsV2.swift
//  Furg
//
//  AI-powered financial insights and spending analysis
//

import SwiftUI
import Charts

// MARK: - Insights Dashboard

struct InsightsV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedInsight: InsightCardV2?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // AI Summary Card
                    aiSummaryCard

                    // Spending Trends
                    spendingTrendsSection

                    // Insights Cards
                    insightsSection

                    // Money-saving tips
                    savingsTipsSection
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Mint)
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailSheetV2(insight: insight)
                    .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - AI Summary

    var aiSummaryCard: some View {
        V2Card(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(V2Gradients.budgetLine)
                            .frame(width: 40, height: 40)

                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.v2Background)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Summary")
                            .font(.v2Headline)
                            .foregroundColor(.v2TextPrimary)
                        Text("Updated just now")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }

                    Spacer()
                }

                Text("You're doing great this month! Your spending is 12% lower than last month, and you're on track to save $340. Your biggest savings came from reducing dining out. Keep it up!")
                    .font(.v2Body)
                    .foregroundColor(.v2TextSecondary)
                    .lineSpacing(4)

                // Quick stats
                HStack(spacing: 20) {
                    InsightStat(value: "12%", label: "Less spending", trend: .positive)
                    InsightStat(value: "$340", label: "Projected savings", trend: .positive)
                    InsightStat(value: "4", label: "Days ahead", trend: .positive)
                }
            }
        }
    }

    // MARK: - Spending Trends

    var spendingTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Spending Trends")

            V2Card {
                VStack(alignment: .leading, spacing: 16) {
                    // Month comparison chart
                    Chart {
                        ForEach(monthlyComparisonData, id: \.month) { data in
                            BarMark(
                                x: .value("Month", data.month),
                                y: .value("Amount", data.amount)
                            )
                            .foregroundStyle(data.isCurrent ? Color.v2Mint : Color.v2TextTertiary.opacity(0.5))
                            .cornerRadius(6)
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
                        AxisMarks { value in
                            AxisValueLabel {
                                if let month = value.as(String.self) {
                                    Text(month)
                                        .font(.v2CaptionSmall)
                                        .foregroundColor(.v2TextTertiary)
                                }
                            }
                        }
                    }
                    .frame(height: 160)

                    // Trend indicator
                    HStack {
                        Image(systemName: "arrow.down.right")
                            .foregroundColor(.v2Lime)
                        Text("Spending down 12% vs last month")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)
                        Spacer()
                    }
                }
            }
        }
    }

    var monthlyComparisonData: [MonthlyData] {
        [
            MonthlyData(month: "Sep", amount: 2100, isCurrent: false),
            MonthlyData(month: "Oct", amount: 2350, isCurrent: false),
            MonthlyData(month: "Nov", amount: 1980, isCurrent: false),
            MonthlyData(month: "Dec", amount: 1350, isCurrent: true)
        ]
    }

    // MARK: - Insights Cards

    var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Personalized Insights")

            ForEach(sampleInsights) { insight in
                Button {
                    selectedInsight = insight
                } label: {
                    InsightCardViewV2(insight: insight)
                }
            }
        }
    }

    var sampleInsights: [InsightCardV2] {
        [
            InsightCardV2(
                icon: "fork.knife",
                iconColor: .v2CategoryFood,
                title: "Restaurant spending up",
                subtitle: "You've spent $120 more on restaurants this month",
                type: .warning,
                actionText: "See restaurants"
            ),
            InsightCardV2(
                icon: "arrow.triangle.2.circlepath",
                iconColor: .v2Blue,
                title: "Recurring charges detected",
                subtitle: "We found 3 subscriptions you might want to review",
                type: .info,
                actionText: "Review subscriptions"
            ),
            InsightCardV2(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .v2Lime,
                title: "Savings opportunity",
                subtitle: "Switch to annual billing on Spotify to save $24/year",
                type: .positive,
                actionText: "Learn more"
            )
        ]
    }

    // MARK: - Savings Tips

    var savingsTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Money-Saving Tips")

            V2Card(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(savingsTips, id: \.title) { tip in
                        SavingsTipRow(tip: tip)

                        if tip.title != savingsTips.last?.title {
                            Divider()
                                .background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    var savingsTips: [SavingsTip] {
        [
            SavingsTip(
                icon: "creditcard.fill",
                title: "Use your Chase card at gas stations",
                subtitle: "Earn 5% cash back this quarter",
                potentialSavings: 15
            ),
            SavingsTip(
                icon: "bag.fill",
                title: "Shop on Wednesdays",
                subtitle: "Target offers 10% off for Circle members",
                potentialSavings: 25
            ),
            SavingsTip(
                icon: "cup.and.saucer.fill",
                title: "Bring coffee from home",
                subtitle: "You'd save ~$90/month based on your Starbucks visits",
                potentialSavings: 90
            )
        ]
    }
}

// MARK: - Supporting Views

struct InsightStat: View {
    let value: String
    let label: String
    let trend: TrendDirection

    enum TrendDirection {
        case positive, negative, neutral
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.v2MetricMedium)
                .foregroundColor(trend == .positive ? .v2Lime : (trend == .negative ? .v2Coral : .v2TextPrimary))

            Text(label)
                .font(.v2CaptionSmall)
                .foregroundColor(.v2TextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightCardV2: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let type: InsightType
    let actionText: String

    enum InsightType {
        case positive, warning, info
    }
}

struct InsightCardViewV2: View {
    let insight: InsightCardV2

    var borderColor: Color {
        switch insight.type {
        case .positive: return .v2Lime
        case .warning: return .v2Gold
        case .info: return .v2Blue
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(insight.iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: insight.icon)
                    .font(.system(size: 18))
                    .foregroundColor(insight.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)

                Text(insight.subtitle)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.v2TextTertiary)
        }
        .padding(16)
        .background(Color.v2CardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct SavingsTip: Equatable {
    let icon: String
    let title: String
    let subtitle: String
    let potentialSavings: Double
}

struct SavingsTipRow: View {
    let tip: SavingsTip

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: tip.icon)
                .font(.system(size: 18))
                .foregroundColor(.v2Mint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)

                Text(tip.subtitle)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }

            Spacer()

            Text("+$\(Int(tip.potentialSavings))")
                .font(.v2CaptionSmall)
                .foregroundColor(.v2Lime)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.v2Lime.opacity(0.15))
                .cornerRadius(8)
        }
        .padding(.vertical, 12)
    }
}

struct InsightDetailSheetV2: View {
    let insight: InsightCardV2
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        Circle()
                            .fill(insight.iconColor.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: insight.icon)
                            .font(.system(size: 32))
                            .foregroundColor(insight.iconColor)
                    }

                    Text(insight.title)
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text(insight.subtitle)
                        .font(.v2Body)
                        .foregroundColor(.v2TextSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button {
                        // Action
                    } label: {
                        Text(insight.actionText)
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.v2Mint)
                            .cornerRadius(14)
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Mint)
                }
            }
        }
    }
}

struct MonthlyData {
    let month: String
    let amount: Double
    let isCurrent: Bool
}

// MARK: - Preview

#Preview {
    InsightsV2()
}
