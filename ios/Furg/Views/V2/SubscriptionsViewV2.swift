//
//  SubscriptionsViewV2.swift
//  Furg
//
//  Subscription tracking and management
//

import SwiftUI

struct SubscriptionsViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSubscription: SubscriptionV2?
    @State private var showAddSubscription = false
    @State private var filterActive = true

    var activeSubscriptions: [SubscriptionV2] {
        sampleSubscriptions.filter { $0.isActive }
    }

    var canceledSubscriptions: [SubscriptionV2] {
        sampleSubscriptions.filter { !$0.isActive }
    }

    var monthlyTotal: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    var yearlyTotal: Double {
        monthlyTotal * 12
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    summaryCard

                    // Category breakdown
                    categoryBreakdown

                    // Active Subscriptions
                    if !activeSubscriptions.isEmpty {
                        activeSection
                    }

                    // Canceled
                    if !canceledSubscriptions.isEmpty {
                        canceledSection
                    }
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSubscription = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.v2Primary)
                    }
                }
            }
            .sheet(item: $selectedSubscription) { sub in
                SubscriptionDetailV2(subscription: sub)
                    .presentationBackground(Color.v2Background)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Summary Card

    var summaryCard: some View {
        V2Card(padding: 24) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Cost")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.v2Primary)
                            Text(String(format: "%.2f", monthlyTotal))
                                .font(.v2DisplayMedium)
                                .foregroundColor(.v2TextPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Yearly")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        Text("$\(Int(yearlyTotal))")
                            .font(.v2MetricMedium)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                // Quick stats
                HStack(spacing: 16) {
                    QuickStatPill(value: "\(activeSubscriptions.count)", label: "Active", color: .v2Primary)
                    QuickStatPill(value: "2", label: "Renew soon", color: .v2Warning)
                    QuickStatPill(value: "$24", label: "Can save", color: .v2Success)
                }
            }
        }
    }

    // MARK: - Category Breakdown

    var categoryBreakdown: some View {
        V2Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("By Category")
                    .font(.v2Headline)
                    .foregroundColor(.v2TextPrimary)

                HStack(spacing: 0) {
                    ForEach(subscriptionCategories, id: \.name) { cat in
                        Rectangle()
                            .fill(cat.color)
                            .frame(width: CGFloat(cat.percentage) * 2.8)
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(subscriptionCategories, id: \.name) { cat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cat.color)
                                .frame(width: 8, height: 8)
                            Text(cat.name)
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextSecondary)
                            Spacer()
                            Text("$\(Int(cat.amount))")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextPrimary)
                        }
                    }
                }
            }
        }
    }

    var subscriptionCategories: [(name: String, amount: Double, percentage: Double, color: Color)] {
        [
            ("Streaming", 49.96, 39, .v2CategoryEntertainment),
            ("Productivity", 32.99, 26, .v2Info),
            ("Health", 45.00, 35, .v2CategoryHealth)
        ]
    }

    // MARK: - Active Section

    var activeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Active (\(activeSubscriptions.count))")

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(activeSubscriptions) { sub in
                        Button {
                            selectedSubscription = sub
                        } label: {
                            SubscriptionRowV2(subscription: sub)
                        }

                        if sub.id != activeSubscriptions.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Canceled Section

    var canceledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Canceled")

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(canceledSubscriptions) { sub in
                        SubscriptionRowV2(subscription: sub, isCanceled: true)

                        if sub.id != canceledSubscriptions.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sample Data

    var sampleSubscriptions: [SubscriptionV2] {
        [
            SubscriptionV2(name: "Netflix", icon: "tv.fill", color: .red, amount: 15.99, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 12), category: "Streaming", isActive: true),
            SubscriptionV2(name: "Spotify", icon: "music.note", color: .green, amount: 10.99, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 5), category: "Streaming", isActive: true),
            SubscriptionV2(name: "iCloud+", icon: "icloud.fill", color: .v2Info, amount: 2.99, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 18), category: "Productivity", isActive: true),
            SubscriptionV2(name: "Gym Membership", icon: "figure.walk", color: .v2CategoryHealth, amount: 45.00, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 8), category: "Health", isActive: true),
            SubscriptionV2(name: "HBO Max", icon: "play.tv.fill", color: .purple, amount: 15.99, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 22), category: "Streaming", isActive: true),
            SubscriptionV2(name: "NYT Digital", icon: "newspaper.fill", color: .v2TextPrimary, amount: 17.00, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 3), category: "Productivity", isActive: true),
            SubscriptionV2(name: "Hulu", icon: "play.rectangle.fill", color: .green, amount: 7.99, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 15), category: "Streaming", isActive: true),
            SubscriptionV2(name: "YouTube Premium", icon: "play.rectangle.fill", color: .red, amount: 11.99, billingCycle: .monthly, nextBilling: Date().addingTimeInterval(86400 * 9), category: "Streaming", isActive: true),
            SubscriptionV2(name: "Adobe CC", icon: "paintbrush.fill", color: .red, amount: 54.99, billingCycle: .monthly, nextBilling: nil, category: "Productivity", isActive: false),
            SubscriptionV2(name: "Audible", icon: "headphones", color: .orange, amount: 14.95, billingCycle: .monthly, nextBilling: nil, category: "Entertainment", isActive: false)
        ]
    }
}

// MARK: - Subscription Model

struct SubscriptionV2: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let amount: Double
    let billingCycle: BillingCycle
    let nextBilling: Date?
    let category: String
    let isActive: Bool

    var monthlyAmount: Double {
        switch billingCycle {
        case .monthly: return amount
        case .yearly: return amount / 12
        case .weekly: return amount * 4.33
        }
    }

    enum BillingCycle: String {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
}

// MARK: - Subscription Row

struct SubscriptionRowV2: View {
    let subscription: SubscriptionV2
    var isCanceled: Bool = false

    var daysUntilBilling: Int? {
        guard let next = subscription.nextBilling else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: next).day
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(subscription.color.opacity(isCanceled ? 0.1 : 0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: subscription.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isCanceled ? .v2TextTertiary : subscription.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.v2BodyBold)
                    .foregroundColor(isCanceled ? .v2TextTertiary : .v2TextPrimary)

                if let days = daysUntilBilling {
                    Text(days <= 3 ? "Renews in \(days) days" : subscription.billingCycle.rawValue)
                        .font(.v2CaptionSmall)
                        .foregroundColor(days <= 3 ? .v2Warning : .v2TextTertiary)
                } else if isCanceled {
                    Text("Canceled")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }
            }

            Spacer()

            Text("$\(String(format: "%.2f", subscription.amount))")
                .font(.v2BodyBold)
                .foregroundColor(isCanceled ? .v2TextTertiary : .v2TextPrimary)

            if !isCanceled {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.v2TextTertiary)
            }
        }
        .padding(16)
        .opacity(isCanceled ? 0.6 : 1)
    }
}

// MARK: - Quick Stat Pill

struct QuickStatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.v2BodyBold)
                .foregroundColor(color)
            Text(label)
                .font(.v2CaptionSmall)
                .foregroundColor(.v2TextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(16)
    }
}

// MARK: - Subscription Detail

struct SubscriptionDetailV2: View {
    let subscription: SubscriptionV2
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(subscription.color.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: subscription.icon)
                            .font(.system(size: 32))
                            .foregroundColor(subscription.color)
                    }

                    Text(subscription.name)
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("$\(String(format: "%.2f", subscription.amount))/\(subscription.billingCycle.rawValue.lowercased())")
                        .font(.v2Headline)
                        .foregroundColor(.v2TextSecondary)
                }
                .padding(.top, 20)

                // Details
                V2Card(padding: 16) {
                    VStack(spacing: 0) {
                        DetailRowV2(label: "Category", value: subscription.category)
                        Divider().background(Color.white.opacity(0.06))
                        if let next = subscription.nextBilling {
                            DetailRowV2(label: "Next billing", value: next.formatted(date: .abbreviated, time: .omitted))
                            Divider().background(Color.white.opacity(0.06))
                        }
                        DetailRowV2(label: "Yearly cost", value: "$\(Int(subscription.monthlyAmount * 12))")
                    }
                }

                Spacer()

                // Actions
                Button {
                    // Cancel subscription
                } label: {
                    Text("Cancel Subscription")
                        .font(.v2BodyBold)
                        .foregroundColor(.v2Danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.v2Danger.opacity(0.12))
                        .cornerRadius(14)
                }
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
    SubscriptionsViewV2()
}
