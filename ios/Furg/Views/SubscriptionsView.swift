//
//  SubscriptionsView.swift
//  Furg
//
//  Subscription tracking and management view with cancellation support
//

import SwiftUI

struct SubscriptionsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var selectedFilter = 0
    @State private var selectedSubscription: Subscription?
    @State private var showCancellationSheet = false
    @State private var animate = false

    let filters = ["All", "Active", "Unused"]

    var filteredSubscriptions: [Subscription] {
        switch selectedFilter {
        case 1: return subscriptionManager.activeSubscriptions.filter { !$0.isUnused }
        case 2: return subscriptionManager.unusedSubscriptions
        default: return subscriptionManager.subscriptions
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Subscriptions")
                            .font(.furgLargeTitle)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        Task { await subscriptionManager.detectSubscriptions() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.furgMint)
                            .padding(12)
                            .glassCard(cornerRadius: 14, opacity: 0.1)
                    }
                }
                .padding(.top, 60)
                .offset(y: animate ? 0 : -20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: animate)

                // Summary Cards
                HStack(spacing: 12) {
                    SubscriptionStatCard(
                        title: "Monthly",
                        value: formatCurrency(subscriptionManager.totalMonthly),
                        icon: "calendar",
                        color: .furgMint
                    )

                    SubscriptionStatCard(
                        title: "Annual",
                        value: formatCurrency(subscriptionManager.totalAnnual),
                        icon: "chart.bar",
                        color: .furgSeafoam
                    )

                    SubscriptionStatCard(
                        title: "Savings",
                        value: formatCurrency(subscriptionManager.potentialSavings),
                        icon: "arrow.down.circle",
                        color: subscriptionManager.potentialSavings > 0 ? .furgWarning : .furgSuccess
                    )
                }
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Unused Alert
                if !subscriptionManager.unusedSubscriptions.isEmpty {
                    UnusedSubscriptionsAlert(
                        count: subscriptionManager.unusedSubscriptions.count,
                        savings: subscriptionManager.potentialSavings
                    )
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: animate)
                }

                // Filter Tabs
                PillTabBar(selectedIndex: $selectedFilter, tabs: filters)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                // Subscriptions List
                if subscriptionManager.isLoading {
                    ProgressView()
                        .tint(.furgMint)
                        .padding(40)
                } else if filteredSubscriptions.isEmpty {
                    EmptySubscriptionsState(filter: selectedFilter)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.25), value: animate)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(filteredSubscriptions.enumerated()), id: \.element.id) { index, subscription in
                            SubscriptionCard(
                                subscription: subscription,
                                onCancel: {
                                    selectedSubscription = subscription
                                    showCancellationSheet = true
                                }
                            )
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.25 + Double(index) * 0.05), value: animate)
                        }
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .task {
            await subscriptionManager.loadSubscriptions()
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .sheet(isPresented: $showCancellationSheet) {
            if let subscription = selectedSubscription {
                CancellationGuideSheet(
                    subscription: subscription,
                    subscriptionManager: subscriptionManager
                )
            }
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}

// MARK: - Stat Card

struct SubscriptionStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.furgTitle2)
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20, opacity: 0.08)
    }
}

// MARK: - Unused Alert

struct UnusedSubscriptionsAlert: View {
    let count: Int
    let savings: Decimal

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.furgWarning.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.furgWarning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(count) unused subscription\(count > 1 ? "s" : "") detected")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Text("You could save \(formatCurrency(savings))/month")
                    .font(.furgCaption)
                    .foregroundColor(.furgWarning)
            }

            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 16, opacity: 0.1)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.furgWarning.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}

// MARK: - Empty State

struct EmptySubscriptionsState: View {
    let filter: Int

    var message: String {
        switch filter {
        case 1: return "All your subscriptions are in use"
        case 2: return "Great! No unused subscriptions found"
        default: return "Connect your bank to detect subscriptions"
        }
    }

    var icon: String {
        switch filter {
        case 2: return "checkmark.circle"
        default: return "creditcard"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.furgMint.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text(filter == 2 ? "All Clear!" : "No Subscriptions")
                    .font(.furgHeadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(message)
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let subscription: Subscription
    let onCancel: () -> Void

    var statusColor: Color {
        if subscription.isUnused {
            return .furgWarning
        }
        switch subscription.status {
        case .active: return .furgSuccess
        case .trialEnding: return .furgWarning
        case .priceIncrease: return .furgDanger
        case .paused: return .furgInfo
        case .cancelled: return .white.opacity(0.4)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: subscription.category.icon)
                        .font(.title2)
                        .foregroundColor(.furgMint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(subscription.merchantName)
                            .font(.furgHeadline)
                            .foregroundColor(.white)

                        if subscription.isUnused {
                            Text("UNUSED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.furgCharcoal)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.furgWarning)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subscription.category.label)
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(subscription.formattedAmount)
                        .font(.furgTitle2)
                        .foregroundColor(.furgMint)

                    Text(subscription.frequency.label)
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Usage Info
            if let usage = subscription.usageMetrics {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Used")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))

                        if let lastUsed = subscription.lastUsedDate {
                            Text(lastUsed, style: .relative)
                                .font(.furgBody)
                                .foregroundColor(subscription.isUnused ? .furgWarning : .white)
                        } else {
                            Text("Never")
                                .font(.furgBody)
                                .foregroundColor(.furgWarning)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Value Score")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))

                        HStack(spacing: 4) {
                            ValueScoreBar(score: usage.valueScore)

                            Text("\(Int(usage.valueScore * 100))%")
                                .font(.furgBody)
                                .foregroundColor(usage.valueScore < 0.3 ? .furgWarning : .white)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Next Billing
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    Text("Next billing: \(subscription.nextBillingDate, style: .date)")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Difficulty indicator
                HStack(spacing: 4) {
                    Image(systemName: subscription.cancellationDifficulty.icon)
                        .font(.caption)
                    Text(subscription.cancellationDifficulty.label)
                        .font(.furgCaption)
                }
                .foregroundColor(difficultyColor)
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("Cancel")
                    }
                    .font(.furgCaption)
                    .foregroundColor(.furgDanger)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.furgDanger.opacity(0.15))
                    .clipShape(Capsule())
                }

                Spacer()

                Text("$\(Int(truncating: subscription.annualCost as NSNumber))/year")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24, opacity: subscription.isUnused ? 0.15 : 0.1)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(subscription.isUnused ? Color.furgWarning.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    var difficultyColor: Color {
        switch subscription.cancellationDifficulty {
        case .easy: return .furgSuccess
        case .moderate: return .furgInfo
        case .hard: return .furgWarning
        case .veryHard: return .furgDanger
        }
    }
}

// MARK: - Value Score Bar

struct ValueScoreBar: View {
    let score: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(scoreColor)
                    .frame(width: geometry.size.width * CGFloat(score), height: 4)
            }
        }
        .frame(width: 50, height: 4)
    }

    var scoreColor: Color {
        if score < 0.3 { return .furgWarning }
        if score < 0.6 { return .furgInfo }
        return .furgSuccess
    }
}

// MARK: - Cancellation Guide Sheet

struct CancellationGuideSheet: View {
    @Environment(\.dismiss) var dismiss
    let subscription: Subscription
    let subscriptionManager: SubscriptionManager

    @State private var guide: CancellationGuide?
    @State private var isLoading = true
    @State private var showConfirmation = false
    @State private var isCancelling = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(12)
                                .glassCard(cornerRadius: 12, opacity: 0.1)
                        }
                        Spacer()
                        Text("Cancel Subscription")
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.top, 20)

                    // Subscription Info
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.furgDanger.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: subscription.category.icon)
                                .font(.system(size: 32))
                                .foregroundColor(.furgDanger)
                        }

                        Text(subscription.merchantName)
                            .font(.furgTitle)
                            .foregroundColor(.white)

                        Text("\(subscription.formattedAmount)/\(subscription.frequency.label.lowercased())")
                            .font(.furgHeadline)
                            .foregroundColor(.furgMint)

                        Text("You'll save \(formatCurrency(subscription.annualCost)) per year")
                            .font(.furgBody)
                            .foregroundColor(.furgSuccess)
                    }
                    .padding(24)
                    .glassCard()

                    if isLoading {
                        ProgressView()
                            .tint(.furgMint)
                            .padding(40)
                    } else if let guide = guide {
                        // Method Badge
                        HStack(spacing: 8) {
                            Image(systemName: methodIcon(guide.method))
                                .foregroundColor(.furgMint)
                            Text(guide.method.label)
                                .font(.furgHeadline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassCard(cornerRadius: 30, opacity: 0.15)

                        // Steps
                        VStack(alignment: .leading, spacing: 16) {
                            Text("HOW TO CANCEL")
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(2)

                            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.furgMint.opacity(0.2))
                                            .frame(width: 28, height: 28)

                                        Text("\(index + 1)")
                                            .font(.furgCaption.bold())
                                            .foregroundColor(.furgMint)
                                    }

                                    Text(step)
                                        .font(.furgBody)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(20)
                        .glassCard()

                        // Script (if available)
                        if let script = guide.script {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("WHAT TO SAY")
                                    .font(.furgCaption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(2)

                                Text(script)
                                    .font(.furgBody)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(16)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(20)
                            .glassCard()
                        }

                        // URL Button
                        if let urlString = guide.url, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("Open \(subscription.merchantName)")
                                }
                                .font(.furgHeadline)
                                .foregroundColor(.furgMint)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .glassCard(cornerRadius: 16, opacity: 0.15)
                            }
                        }

                        // Tips
                        if !guide.tips.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("TIPS")
                                    .font(.furgCaption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(2)

                                ForEach(guide.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "lightbulb")
                                            .font(.caption)
                                            .foregroundColor(.furgMint)
                                        Text(tip)
                                            .font(.furgCaption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .padding(20)
                            .glassCard()
                        }

                        // Warnings
                        if !guide.warnings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(guide.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.caption)
                                            .foregroundColor(.furgWarning)
                                        Text(warning)
                                            .font(.furgCaption)
                                            .foregroundColor(.furgWarning.opacity(0.8))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.furgWarning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Mark as Cancelled Button
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            if isCancelling {
                                ProgressView()
                                    .tint(.furgCharcoal)
                            } else {
                                Image(systemName: "checkmark.circle")
                                Text("I've Cancelled This")
                            }
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(FurgGradients.mintGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isCancelling)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            guide = await subscriptionManager.getCancellationGuide(for: subscription.id)
            isLoading = false
        }
        .alert("Confirm Cancellation", isPresented: $showConfirmation) {
            Button("Yes, I've Cancelled", role: .destructive) {
                Task {
                    isCancelling = true
                    let success = await subscriptionManager.markAsCancelled(subscriptionId: subscription.id)
                    isCancelling = false
                    if success {
                        dismiss()
                    }
                }
            }
            Button("Not Yet", role: .cancel) { }
        } message: {
            Text("Confirm that you've cancelled your \(subscription.merchantName) subscription?")
        }
    }

    private func methodIcon(_ method: CancellationMethod) -> String {
        switch method {
        case .onlineOneClick: return "hand.tap"
        case .onlineMultiStep: return "list.bullet"
        case .phoneCancellation: return "phone"
        case .emailCancellation: return "envelope"
        case .inPersonRequired: return "person"
        case .chatSupport: return "message"
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground()
        SubscriptionsView()
    }
}
