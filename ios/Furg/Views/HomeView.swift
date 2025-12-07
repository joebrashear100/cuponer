//
//  HomeView.swift
//  Furg
//
//  Main dashboard with spending power, goals, insights, and quick actions
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var goalsManager: GoalsManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showHideSheet = false
    @State private var showAddTransactionSheet = false
    @State private var showNotifications = false
    @State private var animate = false
    @State private var selectedTab = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header with greeting
                HomeHeader(greeting: greeting) {
                    showNotifications = true
                }
                    .offset(y: animate ? 0 : -20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animate)

                // Spending Power Card
                SpendingPowerCard(
                    balance: financeManager.balance ?? financeManager.demoBalance,
                    upcomingBills: financeManager.upcomingBills,
                    hasBankConnected: financeManager.hasBankConnected
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Quick Actions Row
                QuickActionsRow(
                    onHide: { showHideSheet = true },
                    onAskAI: { selectedTab = 1 },
                    onViewBills: { selectedTab = 3 },
                    onAddTransaction: { showAddTransactionSheet = true }
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                // Goal Progress Cards (horizontal scroll)
                if !goalsManager.goals.isEmpty {
                    GoalProgressSection(goals: goalsManager.goals)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)
                }

                // AI Insights Feed
                AIInsightsFeed(
                    balance: financeManager.balance ?? financeManager.demoBalance,
                    subscriptions: subscriptionManager.subscriptions,
                    goals: goalsManager.goals
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                // Recent Activity
                RecentActivitySection(transactions: financeManager.transactions)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)

                // Subscription Alert (if unused subscriptions)
                if !subscriptionManager.unusedSubscriptions.isEmpty {
                    SubscriptionAlertCard(unusedCount: subscriptionManager.unusedSubscriptions.count, monthlyCost: subscriptionManager.potentialSavings)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: animate)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .refreshable {
            await financeManager.refreshAll()
            await goalsManager.loadGoals()
            await subscriptionManager.loadSubscriptions()
        }
        .task {
            await financeManager.refreshAll()
            await goalsManager.loadGoals()
            await subscriptionManager.loadSubscriptions()
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .sheet(isPresented: $showHideSheet) {
            HideMoneySheet(financeManager: financeManager)
        }
        .sheet(isPresented: $showAddTransactionSheet) {
            AddTransactionSheet()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsListSheet()
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
}

// MARK: - Home Header

struct HomeHeader: View {
    let greeting: String
    var onNotifications: (() -> Void)? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(greeting)")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.6))

                Text("Your Dashboard")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)
            }

            Spacer()

            // Profile/notification area
            HStack(spacing: 12) {
                Button {
                    onNotifications?()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .foregroundColor(.furgMint)
                            .padding(12)
                            .glassCard(cornerRadius: 14, opacity: 0.1)

                        // Notification badge
                        Circle()
                            .fill(Color.furgWarning)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Spending Power Card

struct SpendingPowerCard: View {
    let balance: BalanceSummary
    let upcomingBills: UpcomingBillsResponse?
    let hasBankConnected: Bool

    var spendingPower: Double {
        let available = balance.availableBalance
        let pending = balance.pendingBalance
        let upcoming = upcomingBills?.totalAmount ?? 0
        return max(0, available - pending - upcoming)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Main spending power
            VStack(spacing: 8) {
                Text("SPENDING POWER")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundColor(.furgMint)

                    Text("\(Int(spendingPower))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(spendingPower > 500 ? Color.furgSuccess : (spendingPower > 100 ? Color.furgWarning : Color.furgError))
                        .frame(width: 8, height: 8)

                    Text(spendingPower > 500 ? "Looking good!" : (spendingPower > 100 ? "Spend carefully" : "Tight budget"))
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Breakdown grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BreakdownItem(
                    label: "Available",
                    value: "$\(Int(balance.availableBalance))",
                    icon: "dollarsign.circle.fill",
                    color: .furgSuccess
                )

                BreakdownItem(
                    label: "Hidden",
                    value: "$\(Int(balance.hiddenBalance))",
                    icon: "eye.slash.fill",
                    color: .furgMint
                )

                BreakdownItem(
                    label: "Pending",
                    value: "-$\(Int(balance.pendingBalance))",
                    icon: "clock.fill",
                    color: .furgInfo
                )

                BreakdownItem(
                    label: "Upcoming Bills",
                    value: "-$\(Int(upcomingBills?.totalAmount ?? 0))",
                    icon: "calendar.badge.clock",
                    color: .furgWarning
                )
            }

            // Demo mode indicator
            if !hasBankConnected {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.furgInfo)
                    Text("Demo Mode - Connect bank for real data")
                        .font(.furgCaption)
                        .foregroundColor(.furgInfo)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.furgInfo.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .glassCard()
    }
}

struct BreakdownItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Text(label)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Actions Row

struct QuickActionsRow: View {
    let onHide: () -> Void
    let onAskAI: () -> Void
    let onViewBills: () -> Void
    let onAddTransaction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "eye.slash.fill", label: "Hide", color: .furgMint, action: onHide)
            QuickActionButton(icon: "bubble.left.fill", label: "Ask AI", color: .furgSeafoam, action: onAskAI)
            QuickActionButton(icon: "doc.text.fill", label: "Bills", color: .furgPistachio, action: onViewBills)
            QuickActionButton(icon: "plus", label: "Add", color: .furgSuccess, action: onAddTransaction)
        }
    }
}

struct QuickActionButton: View {
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16, opacity: 0.08)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Progress Section

struct GoalProgressSection: View {
    let goals: [FurgSavingsGoal]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Goals")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink {
                    GoalsView()
                } label: {
                    Text("See All")
                        .font(.furgCaption)
                        .foregroundColor(.furgMint)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(goals.prefix(5)) { goal in
                        GoalProgressCard(goal: goal)
                    }
                }
            }
        }
    }
}

struct GoalProgressCard: View {
    let goal: FurgSavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and progress
            HStack {
                ZStack {
                    Circle()
                        .fill(goal.category.color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: goal.category.icon)
                        .font(.body)
                        .foregroundColor(goal.category.color)
                }

                Spacer()

                Text("\(Int(goal.percentComplete))%")
                    .font(.furgCaption.bold())
                    .foregroundColor(.furgMint)
            }

            // Goal name
            Text(goal.name)
                .font(.furgBody)
                .foregroundColor(.white)
                .lineLimit(1)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    Capsule()
                        .fill(LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(min(1, goal.percentComplete / 100)), height: 6)
                }
            }
            .frame(height: 6)

            // Amount
            HStack {
                Text("$\(NSDecimalNumber(decimal: goal.currentAmount).intValue)")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.7))

                Text("/ $\(NSDecimalNumber(decimal: goal.targetAmount).intValue)")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .frame(width: 160)
        .glassCard(cornerRadius: 16, opacity: 0.08)
    }
}

// MARK: - AI Insights Feed

struct AIInsightsFeed: View {
    let balance: BalanceSummary
    let subscriptions: [Subscription]
    let goals: [FurgSavingsGoal]

    var insights: [AIInsight] {
        var results: [AIInsight] = []

        // Spending power insight
        let spendingPower = balance.availableBalance - balance.pendingBalance
        if spendingPower < 500 {
            results.append(AIInsight(
                type: .warning,
                title: "Low Spending Power",
                message: "You've got $\(Int(spendingPower)) to work with. Maybe skip the takeout today?",
                icon: "exclamationmark.triangle.fill"
            ))
        }

        // Hidden savings insight
        if balance.hiddenBalance > 0 {
            results.append(AIInsight(
                type: .success,
                title: "Money Hidden",
                message: "You're hiding $\(Int(balance.hiddenBalance)) from yourself. Smart move, dummy!",
                icon: "eye.slash.fill"
            ))
        }

        // Unused subscriptions insight
        let unused = subscriptions.filter { $0.isUnused }
        if !unused.isEmpty {
            let monthlyCost = unused.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
            results.append(AIInsight(
                type: .alert,
                title: "Zombie Subscriptions",
                message: "You're paying $\(NSDecimalNumber(decimal: monthlyCost).intValue)/mo for stuff you don't use. Wake up!",
                icon: "face.dashed"
            ))
        }

        // Goal progress insight
        if let primaryGoal = goals.first {
            if primaryGoal.percentComplete < 25 {
                results.append(AIInsight(
                    type: .info,
                    title: "Goal Check",
                    message: "Your '\(primaryGoal.name)' goal is at \(Int(primaryGoal.percentComplete))%. Time to hustle!",
                    icon: "target"
                ))
            } else if primaryGoal.percentComplete >= 75 {
                results.append(AIInsight(
                    type: .success,
                    title: "Almost There!",
                    message: "Your '\(primaryGoal.name)' goal is at \(Int(primaryGoal.percentComplete))%. Don't stop now!",
                    icon: "star.fill"
                ))
            }
        }

        // Default insight if none generated
        if results.isEmpty {
            results.append(AIInsight(
                type: .info,
                title: "Financial Check-In",
                message: "Your finances look stable. But can we do better? Always.",
                icon: "chart.line.uptrend.xyaxis"
            ))
        }

        return results
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.furgMint)
                Text("FURG Insights")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()
            }

            ForEach(insights.prefix(3)) { insight in
                AIInsightCard(insight: insight)
            }
        }
    }
}

struct AIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String

    enum InsightType {
        case success, warning, alert, info

        var color: Color {
            switch self {
            case .success: return .furgSuccess
            case .warning: return .furgWarning
            case .alert: return .furgError
            case .info: return .furgInfo
            }
        }
    }
}

struct AIInsightCard: View {
    let insight: AIInsight

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(insight.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: insight.icon)
                    .font(.body)
                    .foregroundColor(insight.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.furgBody.bold())
                    .foregroundColor(.white)

                Text(insight.message)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .glassCard(cornerRadius: 14, opacity: 0.08)
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let transactions: [Transaction]

    var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    // Navigate to full transactions
                } label: {
                    Text("See All")
                        .font(.furgCaption)
                        .foregroundColor(.furgMint)
                }
            }

            if recentTransactions.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.3))
                        Text("No recent transactions")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
                .glassCard(cornerRadius: 14, opacity: 0.08)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, transaction in
                        RecentActivityRow(transaction: transaction)

                        if index < recentTransactions.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
                .glassCard(cornerRadius: 14, opacity: 0.08)
            }
        }
    }
}

struct RecentActivityRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: categoryIcon)
                    .font(.body)
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.furgBody)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(transaction.category)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.furgBody.bold())
                    .foregroundColor(transaction.amount < 0 ? .furgError : .furgSuccess)

                Text(transaction.date)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(14)
    }

    var categoryIcon: String {
        switch transaction.category.lowercased() {
        case "food", "dining", "restaurants": return "fork.knife"
        case "shopping": return "bag.fill"
        case "transportation", "travel": return "car.fill"
        case "entertainment": return "tv.fill"
        case "utilities": return "bolt.fill"
        case "health": return "heart.fill"
        case "groceries": return "cart.fill"
        default: return "dollarsign.circle.fill"
        }
    }

    var categoryColor: Color {
        switch transaction.category.lowercased() {
        case "food", "dining", "restaurants": return .orange
        case "shopping": return .pink
        case "transportation", "travel": return .blue
        case "entertainment": return .purple
        case "utilities": return .yellow
        case "health": return .red
        case "groceries": return .green
        default: return .furgMint
        }
    }
}

// MARK: - Subscription Alert Card

struct SubscriptionAlertCard: View {
    let unusedCount: Int
    let monthlyCost: Decimal

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.furgWarning.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.furgWarning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Unused Subscriptions")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Text("\(unusedCount) subscriptions wasting $\(NSDecimalNumber(decimal: monthlyCost).intValue)/month")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .glassCard(cornerRadius: 16, opacity: 0.08)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.furgWarning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Add Transaction Sheet

struct AddTransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeManager: FinanceManager
    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = "Shopping"
    @State private var isExpense = true
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    let categories = ["Shopping", "Food", "Transportation", "Entertainment", "Utilities", "Health", "Groceries", "Income", "Other"]

    private var isValidAmount: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        return true
    }

    private var isFormValid: Bool {
        !merchant.trimmingCharacters(in: .whitespaces).isEmpty && isValidAmount
    }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

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
                    Text("Add Transaction")
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                // Type toggle
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpense = true
                        }
                    } label: {
                        Text("Expense")
                            .font(.furgBody)
                            .foregroundColor(isExpense ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isExpense ? Color.furgError.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpense = false
                        }
                    } label: {
                        Text("Income")
                            .font(.furgBody)
                            .foregroundColor(!isExpense ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(!isExpense ? Color.furgSuccess.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(4)
                .glassCard(cornerRadius: 14, opacity: 0.1)

                // Amount
                VStack(spacing: 8) {
                    Text("AMOUNT")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    HStack(alignment: .center, spacing: 4) {
                        Text(isExpense ? "-$" : "+$")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(isExpense ? .furgError : .furgSuccess)

                        TextField("0", text: $amount)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 180)
                    }

                    if !amount.isEmpty && !isValidAmount {
                        Text("Please enter a valid amount")
                            .font(.furgCaption)
                            .foregroundColor(.furgError)
                    }
                }
                .padding(24)
                .glassCard()

                // Merchant
                VStack(alignment: .leading, spacing: 8) {
                    Text("MERCHANT")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    TextField("e.g., Starbucks", text: $merchant)
                        .font(.furgBody)
                        .foregroundColor(.white)
                        .padding(16)
                        .glassCard(cornerRadius: 12, opacity: 0.1)
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    category = cat
                                } label: {
                                    Text(cat)
                                        .font(.furgCaption)
                                        .foregroundColor(category == cat ? .furgCharcoal : .white.opacity(0.7))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(category == cat ? Color.furgMint : Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.furgCaption)
                        .foregroundColor(.furgError)
                        .padding(.horizontal)
                }

                Spacer()

                // Add button
                Button {
                    Task {
                        await saveTransaction()
                    }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .furgCharcoal))
                        } else if showSuccess {
                            Image(systemName: "checkmark")
                            Text("Added!")
                        } else {
                            Image(systemName: "plus")
                            Text("Add Transaction")
                        }
                    }
                    .font(.furgHeadline)
                    .foregroundColor(.furgCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        if showSuccess {
                            Color.furgSuccess
                        } else {
                            FurgGradients.mintGradient
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isFormValid || isSaving)
                .opacity(!isFormValid || isSaving ? 0.5 : 1)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
    }

    private func saveTransaction() async {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)
        guard !trimmedMerchant.isEmpty else {
            errorMessage = "Please enter a merchant name"
            return
        }

        isSaving = true
        errorMessage = nil

        let success = await financeManager.addTransaction(
            merchant: trimmedMerchant,
            amount: amountValue,
            category: category,
            isExpense: isExpense
        )

        isSaving = false

        if success {
            withAnimation {
                showSuccess = true
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            dismiss()
        } else {
            errorMessage = financeManager.errorMessage ?? "Failed to add transaction"
        }
    }
}

// MARK: - Notifications List Sheet

struct NotificationsListSheet: View {
    @Environment(\.dismiss) var dismiss

    // Sample notifications
    private let notifications: [NotificationItem] = [
        NotificationItem(
            icon: "flame.fill",
            iconColor: .furgWarning,
            title: "Spending Alert",
            message: "You spent $127 at Amazon today. That's 40% of your daily budget.",
            time: "2 hours ago",
            isRead: false
        ),
        NotificationItem(
            icon: "calendar.badge.exclamationmark",
            iconColor: .furgInfo,
            title: "Bill Reminder",
            message: "Your Netflix subscription of $15.99 is due tomorrow.",
            time: "5 hours ago",
            isRead: false
        ),
        NotificationItem(
            icon: "star.fill",
            iconColor: .furgMint,
            title: "Goal Milestone",
            message: "You're 75% of the way to your Emergency Fund goal!",
            time: "Yesterday",
            isRead: true
        ),
        NotificationItem(
            icon: "chart.bar.fill",
            iconColor: .purple,
            title: "Weekly Report",
            message: "Your spending was 12% lower than last week. Great job!",
            time: "2 days ago",
            isRead: true
        ),
        NotificationItem(
            icon: "dollarsign.circle.fill",
            iconColor: .furgSuccess,
            title: "Income Detected",
            message: "A deposit of $3,245.67 was detected from ACME Corp.",
            time: "3 days ago",
            isRead: true
        )
    ]

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 20) {
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

                    Text("Notifications")
                        .font(.furgTitle2)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        // Mark all as read
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.furgMint)
                    }
                }
                .padding(.top, 20)

                // Notifications list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct NotificationItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let time: String
    let isRead: Bool
}

struct NotificationRow: View {
    let notification: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: notification.icon)
                    .font(.system(size: 18))
                    .foregroundColor(notification.iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    if !notification.isRead {
                        Circle()
                            .fill(Color.furgMint)
                            .frame(width: 8, height: 8)
                    }

                    Spacer()

                    Text(notification.time)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }

                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(notification.isRead ? 0.05 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(notification.isRead ? Color.clear : Color.furgMint.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground()
        HomeView()
    }
    .environmentObject(FinanceManager())
    .environmentObject(GoalsManager())
    .environmentObject(SubscriptionManager())
}
