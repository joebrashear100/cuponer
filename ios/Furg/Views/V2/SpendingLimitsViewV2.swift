//
//  SpendingLimitsViewV2.swift
//  Furg
//
//  Category budget limits and alerts
//

import SwiftUI

struct SpendingLimitsViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAddLimit = false
    @State private var selectedLimit: SpendingLimitV2?

    var totalBudget: Double {
        sampleLimits.reduce(0) { $0 + $1.limit }
    }

    var totalSpent: Double {
        sampleLimits.reduce(0) { $0 + $1.spent }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview card
                    overviewCard

                    // Quick actions
                    quickActions

                    // Active limits
                    limitsSection

                    // Tips
                    tipsSection
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Spending Limits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddLimit = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.v2Primary)
                    }
                }
            }
            .sheet(isPresented: $showAddLimit) {
                AddSpendingLimitV2()
                    .presentationBackground(Color.v2Background)
            }
            .sheet(item: $selectedLimit) { limit in
                SpendingLimitDetailV2(limit: limit)
                    .presentationBackground(Color.v2Background)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Overview Card

    var overviewCard: some View {
        V2Card(padding: 24) {
            VStack(spacing: 20) {
                // Progress ring
                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.v2CardBackgroundElevated, lineWidth: 12)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: min(totalSpent / totalBudget, 1.0))
                            .stroke(
                                totalSpent / totalBudget > 0.9 ? Color.v2Danger :
                                    (totalSpent / totalBudget > 0.7 ? Color.v2Warning : Color.v2Primary),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(Int((totalSpent / totalBudget) * 100))%")
                                .font(.v2MetricMedium)
                                .foregroundColor(.v2TextPrimary)
                            Text("used")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Spent")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                            Text("$\(Int(totalSpent))")
                                .font(.v2Headline)
                                .foregroundColor(.v2TextPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Budget")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                            Text("$\(Int(totalBudget))")
                                .font(.v2Headline)
                                .foregroundColor(.v2Primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remaining")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                            Text("$\(Int(totalBudget - totalSpent))")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2Success)
                        }
                    }
                }

                // Month indicator
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.v2TextTertiary)
                    Text("December 2024 • 24 days remaining")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)
                }
            }
        }
    }

    // MARK: - Quick Actions

    var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButtonSpendingV2(
                icon: "arrow.clockwise",
                title: "Reset All",
                color: .v2Warning
            ) {
                // Reset limits
            }

            QuickActionButtonSpendingV2(
                icon: "bell.fill",
                title: "Alerts",
                color: .v2Primary
            ) {
                // Alert settings
            }

            QuickActionButtonSpendingV2(
                icon: "chart.bar.fill",
                title: "History",
                color: .v2Info
            ) {
                // View history
            }
        }
    }

    // MARK: - Limits Section

    var limitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Active Limits")

            VStack(spacing: 12) {
                ForEach(sampleLimits) { limit in
                    Button {
                        selectedLimit = limit
                    } label: {
                        SpendingLimitCardV2(limit: limit)
                    }
                }
            }
        }
    }

    // MARK: - Tips Section

    var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Smart Tips")

            V2Card {
                VStack(spacing: 16) {
                    TipRowV2(
                        icon: "lightbulb.fill",
                        text: "You're on track to save $120 more this month if you stay within limits",
                        color: .v2Success
                    )

                    Divider().background(Color.white.opacity(0.06))

                    TipRowV2(
                        icon: "exclamationmark.triangle.fill",
                        text: "Dining out is 85% of limit with 24 days left. Consider cooking at home",
                        color: .v2Warning
                    )

                    Divider().background(Color.white.opacity(0.06))

                    TipRowV2(
                        icon: "arrow.down.circle.fill",
                        text: "Entertainment spending is 40% lower than last month. Great job!",
                        color: .v2Primary
                    )
                }
            }
        }
    }

    // MARK: - Sample Data

    var sampleLimits: [SpendingLimitV2] {
        [
            SpendingLimitV2(
                category: "Dining Out",
                icon: "fork.knife",
                color: .v2CategoryFood,
                limit: 400,
                spent: 342,
                alertThreshold: 0.8,
                isActive: true
            ),
            SpendingLimitV2(
                category: "Shopping",
                icon: "bag.fill",
                color: .v2CategoryShopping,
                limit: 300,
                spent: 156,
                alertThreshold: 0.75,
                isActive: true
            ),
            SpendingLimitV2(
                category: "Entertainment",
                icon: "film.fill",
                color: .v2CategoryEntertainment,
                limit: 200,
                spent: 89,
                alertThreshold: 0.8,
                isActive: true
            ),
            SpendingLimitV2(
                category: "Transportation",
                icon: "car.fill",
                color: .v2CategoryTransport,
                limit: 250,
                spent: 198,
                alertThreshold: 0.9,
                isActive: true
            ),
            SpendingLimitV2(
                category: "Groceries",
                icon: "cart.fill",
                color: .v2Success,
                limit: 500,
                spent: 312,
                alertThreshold: 0.85,
                isActive: true
            )
        ]
    }
}

// MARK: - Spending Limit Model

struct SpendingLimitV2: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let color: Color
    let limit: Double
    let spent: Double
    let alertThreshold: Double
    let isActive: Bool

    var percentUsed: Double {
        spent / limit
    }

    var remaining: Double {
        max(limit - spent, 0)
    }

    var status: LimitStatus {
        if percentUsed >= 1.0 {
            return .exceeded
        } else if percentUsed >= alertThreshold {
            return .warning
        } else {
            return .onTrack
        }
    }

    enum LimitStatus {
        case onTrack
        case warning
        case exceeded

        var color: Color {
            switch self {
            case .onTrack: return .v2Primary
            case .warning: return .v2Warning
            case .exceeded: return .v2Danger
            }
        }
    }
}

// MARK: - Spending Limit Card

struct SpendingLimitCardV2: View {
    let limit: SpendingLimitV2

    var body: some View {
        V2Card {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(limit.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: limit.icon)
                            .font(.system(size: 18))
                            .foregroundColor(limit.color)
                    }

                    // Category and status
                    VStack(alignment: .leading, spacing: 4) {
                        Text(limit.category)
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(limit.status.color)
                                .frame(width: 6, height: 6)

                            Text(statusText)
                                .font(.v2CaptionSmall)
                                .foregroundColor(limit.status.color)
                        }
                    }

                    Spacer()

                    // Amount
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(Int(limit.spent))")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)

                        Text("of $\(Int(limit.limit))")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.v2BackgroundSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(limit.status.color)
                            .frame(width: min(CGFloat(limit.percentUsed) * geometry.size.width, geometry.size.width), height: 8)
                    }
                }
                .frame(height: 8)

                // Remaining
                HStack {
                    Text("$\(Int(limit.remaining)) remaining")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)

                    Spacer()

                    Text("\(Int(limit.percentUsed * 100))%")
                        .font(.v2Caption)
                        .foregroundColor(limit.status.color)
                }
            }
        }
    }

    var statusText: String {
        switch limit.status {
        case .onTrack: return "On track"
        case .warning: return "Approaching limit"
        case .exceeded: return "Limit exceeded"
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButtonSpendingV2: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(title)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.v2CardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Tip Row

struct TipRowV2: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .lineSpacing(2)
        }
    }
}

// MARK: - Add Spending Limit Sheet

struct AddSpendingLimitV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory = "Dining Out"
    @State private var limitAmount = ""
    @State private var alertThreshold = 80.0

    let categories = [
        ("Dining Out", "fork.knife", Color.v2CategoryFood),
        ("Shopping", "bag.fill", Color.v2CategoryShopping),
        ("Entertainment", "film.fill", Color.v2CategoryEntertainment),
        ("Transportation", "car.fill", Color.v2CategoryTransport),
        ("Groceries", "cart.fill", Color.v2Success),
        ("Health", "heart.fill", Color.v2CategoryHealth),
        ("Travel", "airplane", Color.v2Info),
        ("Other", "ellipsis.circle.fill", Color.v2TextTertiary)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.v2Headline)
                            .foregroundColor(.v2TextPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(categories, id: \.0) { category in
                                Button {
                                    selectedCategory = category.0
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: category.1)
                                            .font(.system(size: 16))
                                            .foregroundColor(category.2)

                                        Text(category.0)
                                            .font(.v2Caption)
                                            .foregroundColor(.v2TextPrimary)

                                        Spacer()

                                        if selectedCategory == category.0 {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.v2Primary)
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedCategory == category.0 ? Color.v2Primary.opacity(0.15) : Color.v2CardBackground)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedCategory == category.0 ? Color.v2Primary : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Limit amount
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Limit")
                            .font(.v2Headline)
                            .foregroundColor(.v2TextPrimary)

                        FormFieldV2(label: "", placeholder: "$0", text: $limitAmount, keyboardType: .decimalPad)
                    }

                    // Alert threshold
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Alert Threshold")
                                .font(.v2Headline)
                                .foregroundColor(.v2TextPrimary)

                            Spacer()

                            Text("\(Int(alertThreshold))%")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2Primary)
                        }

                        Slider(value: $alertThreshold, in: 50...100, step: 5)
                            .tint(.v2Primary)

                        Text("You'll be notified when spending reaches \(Int(alertThreshold))% of the limit")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }

                    Spacer(minLength: 40)

                    Button {
                        dismiss()
                    } label: {
                        Text("Create Limit")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(limitAmount.isEmpty ? Color.v2TextTertiary : Color.v2Primary)
                            .cornerRadius(14)
                    }
                    .disabled(limitAmount.isEmpty)
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("New Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.v2TextSecondary)
                }
            }
        }
    }
}

// MARK: - Spending Limit Detail

struct SpendingLimitDetailV2: View {
    let limit: SpendingLimitV2
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(limit.color.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: limit.icon)
                            .font(.system(size: 32))
                            .foregroundColor(limit.color)
                    }

                    Text(limit.category)
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("$\(Int(limit.spent)) of $\(Int(limit.limit))")
                        .font(.v2Headline)
                        .foregroundColor(.v2TextSecondary)
                }
                .padding(.top, 20)

                // Progress
                V2Card {
                    VStack(spacing: 16) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.v2BackgroundSecondary)
                                    .frame(height: 12)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(limit.status.color)
                                    .frame(width: min(CGFloat(limit.percentUsed) * geometry.size.width, geometry.size.width), height: 12)
                            }
                        }
                        .frame(height: 12)

                        HStack {
                            Text("\(Int(limit.percentUsed * 100))% used")
                                .font(.v2Caption)
                                .foregroundColor(limit.status.color)

                            Spacer()

                            Text("$\(Int(limit.remaining)) left")
                                .font(.v2Caption)
                                .foregroundColor(.v2TextSecondary)
                        }
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        // Edit limit
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Limit")
                        }
                        .font(.v2BodyBold)
                        .foregroundColor(.v2Primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.v2Primary.opacity(0.12))
                        .cornerRadius(14)
                    }

                    Button {
                        // Delete
                    } label: {
                        Text("Delete Limit")
                            .font(.v2Body)
                            .foregroundColor(.v2Danger)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(Color.v2Background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SpendingLimitsViewV2()
}
