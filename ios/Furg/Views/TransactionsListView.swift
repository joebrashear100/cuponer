//
//  TransactionsListView.swift
//  Furg
//
//  Enhanced transactions view with AI-powered categorization
//  Includes NLP-based transaction categorization and proactive AI insights
//

import SwiftUI
import Charts
import EventKit
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "TransactionsListView")

// MARK: - Transaction Models

struct EnhancedTransaction: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let date: Date
    var category: TransactionCategory
    let originalDescription: String
    let accountName: String
    let isPending: Bool
    var tags: [String]
    var aiSuggestion: TransactionCategory?
    var needsReview: Bool
    var isSubscription: Bool
    var subscriptionFrequency: SubscriptionFrequency?
}

enum SubscriptionFrequency: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weekly: return "7.circle.fill"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.clock"
        case .yearly: return "calendar.badge.exclamationmark"
        }
    }
}

enum TransactionCategory: String, CaseIterable, Identifiable {
    case housing = "Housing"
    case food = "Food & Dining"
    case transportation = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case health = "Health & Fitness"
    case travel = "Travel"
    case utilities = "Utilities"
    case subscriptions = "Subscriptions"
    case income = "Income"
    case transfer = "Transfer"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .housing: return "house.fill"
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        case .travel: return "airplane"
        case .utilities: return "bolt.fill"
        case .subscriptions: return "repeat"
        case .income: return "arrow.down.circle.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .housing: return .blue
        case .food: return .orange
        case .transportation: return .purple
        case .shopping: return .pink
        case .entertainment: return .green
        case .health: return .red
        case .travel: return .cyan
        case .utilities: return .yellow
        case .subscriptions: return .indigo
        case .income: return .furgMint
        case .transfer: return .gray
        case .other: return .secondary
        }
    }
}

// MARK: - Transaction AI Insight Model

struct TransactionAIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let action: String?
    let actionType: ActionType
    let priority: Int

    enum InsightType {
        case warning, tip, celebration, question

        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .tip: return "lightbulb.fill"
            case .celebration: return "star.fill"
            case .question: return "questionmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .warning: return .furgWarning
            case .tip: return .furgMint
            case .celebration: return .furgSuccess
            case .question: return .furgInfo
            }
        }
    }

    enum ActionType {
        case showChat
        case showSubscriptions
        case showBudget
        case showCategories
        case none
    }
}

// MARK: - Transactions List View

struct TransactionsListView: View {
    @State private var transactions: [EnhancedTransaction] = []
    @State private var searchText = ""
    @State private var selectedCategory: TransactionCategory?
    @State private var showCategoryPicker = false
    @State private var selectedTransaction: EnhancedTransaction?
    @State private var aiInsights: [TransactionAIInsight] = []
    @State private var showAIChat = false
    @State private var animate = false
    @State private var isCategorizingWithAI = false
    @State private var showSubscriptionSheet = false
    @State private var showBudgetCreator = false
    @State private var showTransactionDetail = false

    // Demo AI insights
    var demoInsights: [TransactionAIInsight] {
        [
            TransactionAIInsight(
                type: .warning,
                title: "Spending Alert",
                message: "You've spent $340 on dining out this week—that's 2x your usual average. Want me to suggest some meal prep ideas?",
                action: "Get Tips",
                actionType: .showChat,
                priority: 1
            ),
            TransactionAIInsight(
                type: .tip,
                title: "Subscription Found",
                message: "I noticed a new recurring charge from 'Paramount+' for $11.99. Should I track this as a subscription?",
                action: "Add Subscription",
                actionType: .showSubscriptions,
                priority: 2
            ),
            TransactionAIInsight(
                type: .celebration,
                title: "Nice Save!",
                message: "Your grocery spending is down 18% compared to last month. Keep it up!",
                action: nil,
                actionType: .none,
                priority: 3
            )
        ]
    }

    // Demo transactions
    var demoTransactions: [EnhancedTransaction] {
        let calendar = Calendar.current
        let now = Date()
        return [
            EnhancedTransaction(merchant: "Whole Foods Market", amount: -87.43, date: now, category: .food, originalDescription: "WHOLEFDS MKT 10432", accountName: "Chase Sapphire", isPending: false, tags: ["groceries"], aiSuggestion: nil, needsReview: false, isSubscription: false, subscriptionFrequency: nil),
            EnhancedTransaction(merchant: "Uber", amount: -24.50, date: calendar.date(byAdding: .hour, value: -5, to: now)!, category: .transportation, originalDescription: "UBER *TRIP", accountName: "Chase Sapphire", isPending: true, tags: [], aiSuggestion: nil, needsReview: false, isSubscription: false, subscriptionFrequency: nil),
            EnhancedTransaction(merchant: "Netflix", amount: -15.99, date: calendar.date(byAdding: .day, value: -1, to: now)!, category: .subscriptions, originalDescription: "NETFLIX.COM", accountName: "Apple Card", isPending: false, tags: ["streaming"], aiSuggestion: nil, needsReview: false, isSubscription: true, subscriptionFrequency: .monthly),
            EnhancedTransaction(merchant: "UNKNOWN MERCHANT", amount: -156.00, date: calendar.date(byAdding: .day, value: -1, to: now)!, category: .other, originalDescription: "POS DEBIT 8934729", accountName: "Chase Checking", isPending: false, tags: [], aiSuggestion: .shopping, needsReview: true, isSubscription: false, subscriptionFrequency: nil),
            EnhancedTransaction(merchant: "Shell Gas Station", amount: -45.67, date: calendar.date(byAdding: .day, value: -2, to: now)!, category: .transportation, originalDescription: "SHELL OIL 57432", accountName: "Chase Sapphire", isPending: false, tags: ["gas"], aiSuggestion: nil, needsReview: false, isSubscription: false, subscriptionFrequency: nil),
            EnhancedTransaction(merchant: "Spotify", amount: -9.99, date: calendar.date(byAdding: .day, value: -3, to: now)!, category: .subscriptions, originalDescription: "SPOTIFY USA", accountName: "Apple Card", isPending: false, tags: ["music"], aiSuggestion: nil, needsReview: false, isSubscription: true, subscriptionFrequency: .monthly),
            EnhancedTransaction(merchant: "Employer Direct Deposit", amount: 3250.00, date: calendar.date(byAdding: .day, value: -4, to: now)!, category: .income, originalDescription: "ACH DEPOSIT ACME CORP", accountName: "Chase Checking", isPending: false, tags: ["salary"], aiSuggestion: nil, needsReview: false, isSubscription: false, subscriptionFrequency: nil),
            EnhancedTransaction(merchant: "Starbucks", amount: -6.45, date: calendar.date(byAdding: .day, value: -4, to: now)!, category: .food, originalDescription: "STARBUCKS #12345", accountName: "Apple Card", isPending: false, tags: ["coffee"], aiSuggestion: nil, needsReview: false, isSubscription: false, subscriptionFrequency: nil),
            EnhancedTransaction(merchant: "Amazon Prime", amount: -14.99, date: calendar.date(byAdding: .day, value: -5, to: now)!, category: .subscriptions, originalDescription: "AMZN PRIME", accountName: "Chase Sapphire", isPending: false, tags: ["shopping"], aiSuggestion: nil, needsReview: false, isSubscription: true, subscriptionFrequency: .monthly),
            EnhancedTransaction(merchant: "Gym Membership", amount: -49.99, date: calendar.date(byAdding: .day, value: -6, to: now)!, category: .health, originalDescription: "EQUINOX *MONTHLY", accountName: "Chase Checking", isPending: false, tags: ["fitness"], aiSuggestion: nil, needsReview: false, isSubscription: true, subscriptionFrequency: .monthly),
        ]
    }

    var filteredTransactions: [EnhancedTransaction] {
        var result = transactions.isEmpty ? demoTransactions : transactions

        if !searchText.isEmpty {
            result = result.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        return result
    }

    var needsReviewCount: Int {
        (transactions.isEmpty ? demoTransactions : transactions).filter { $0.needsReview }.count
    }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    header
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // AI Insights carousel
                    if !demoInsights.isEmpty {
                        aiInsightsSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                    }

                    // Search and filters
                    searchAndFilters
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Needs review section
                    if needsReviewCount > 0 {
                        needsReviewSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                    }

                    // Transactions list
                    transactionsList
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }

            // AI Categorization overlay
            if showCategoryPicker, let transaction = selectedTransaction {
                AICategoryPicker(
                    transaction: transaction,
                    onSelect: { category in
                        // Update transaction category
                        showCategoryPicker = false
                        selectedTransaction = nil
                    },
                    onDismiss: {
                        showCategoryPicker = false
                        selectedTransaction = nil
                    }
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
            aiInsights = demoInsights
        }
        .sheet(isPresented: $showAIChat) {
            AICategorizeSheet()
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            if let transaction = selectedTransaction {
                SubscriptionManagementSheet(
                    transaction: transaction,
                    onSave: { isSubscription, frequency in
                        updateTransactionSubscription(transaction: transaction, isSubscription: isSubscription, frequency: frequency)
                        showSubscriptionSheet = false
                    }
                )
            }
        }
        .sheet(isPresented: $showBudgetCreator) {
            AIBudgetCreatorView()
        }
        .sheet(isPresented: $showTransactionDetail) {
            if let transaction = selectedTransaction {
                TransactionDetailSheet(transaction: transaction) {
                    selectedTransaction = nil
                    showTransactionDetail = false
                    showCategoryPicker = true
                    selectedTransaction = transaction
                } onSubscriptionTap: {
                    showTransactionDetail = false
                    showSubscriptionSheet = true
                }
            }
        }
    }

    private func updateTransactionSubscription(transaction: EnhancedTransaction, isSubscription: Bool, frequency: SubscriptionFrequency?) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index].isSubscription = isSubscription
            transactions[index].subscriptionFrequency = frequency
            if isSubscription {
                transactions[index].category = .subscriptions
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transactions")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(filteredTransactions.count) transactions")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                showAIChat = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))

                    Text("AI")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.furgCharcoal)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(.top, 16)
    }

    // MARK: - AI Insights Section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(.furgMint)

                Text("FURG Insights")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("\(aiInsights.count) new")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.furgMint)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(aiInsights) { insight in
                        InsightCard(insight: insight) { actionType in
                            handleInsightAction(actionType)
                        }
                    }
                }
            }
        }
    }

    private func handleInsightAction(_ actionType: TransactionAIInsight.ActionType) {
        switch actionType {
        case .showChat:
            showAIChat = true
        case .showSubscriptions:
            showSubscriptionSheet = true
        case .showBudget:
            showBudgetCreator = true
        case .showCategories:
            showCategoryPicker = true
        case .none:
            break
        }
    }

    // MARK: - Search and Filters

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))

                    TextField("Search transactions...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .tint(.furgMint)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                )

                Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                    }
                    Divider()
                    ForEach(TransactionCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)

                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                            .foregroundColor(selectedCategory != nil ? .furgMint : .white.opacity(0.6))
                    }
                }
            }

            // Category chips
            if selectedCategory != nil {
                HStack {
                    Text("Filtered by:")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    if let category = selectedCategory {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 10))

                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))

                            Button {
                                selectedCategory = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundColor(category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(category.color.opacity(0.2))
                        )
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Needs Review Section

    private var needsReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Needs Review")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                ZStack {
                    Circle()
                        .fill(Color.furgWarning)
                        .frame(width: 20, height: 20)

                    Text("\(needsReviewCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.furgCharcoal)
                }

                Spacer()

                Button("Review All") {
                    showAIChat = true
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.furgMint)
            }

            let reviewTransactions = (transactions.isEmpty ? demoTransactions : transactions).filter { $0.needsReview }

            ForEach(reviewTransactions) { transaction in
                ReviewTransactionCard(transaction: transaction) {
                    selectedTransaction = transaction
                    showCategoryPicker = true
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.furgWarning.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgWarning.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Transactions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // Group by date
            let grouped = Dictionary(grouping: filteredTransactions) { transaction in
                Calendar.current.startOfDay(for: transaction.date)
            }
            let sortedDates = grouped.keys.sorted(by: >)

            ForEach(sortedDates, id: \.self) { date in
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatDateHeader(date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 8)

                    ForEach(grouped[date] ?? []) { transaction in
                        TransactionRow(transaction: transaction) {
                            selectedTransaction = transaction
                            showTransactionDetail = true
                        } onCategoryTap: {
                            selectedTransaction = transaction
                            showCategoryPicker = true
                        } onSubscriptionTap: {
                            selectedTransaction = transaction
                            showSubscriptionSheet = true
                        }
                    }
                }
            }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.weekday(.wide).month().day())
        }
    }
}

// MARK: - Insight Card

private struct TransactionInsightCard: View {
    let insight: TransactionAIInsight
    let onAction: (TransactionAIInsight.ActionType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(insight.type.color)

                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            Text(insight.message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
                .lineSpacing(2)

            if let action = insight.action {
                Button {
                    onAction(insight.actionType)
                } label: {
                    HStack(spacing: 4) {
                        Text(action)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(insight.type.color)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(insight.type.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Transaction Row

private struct TransactionRow: View {
    let transaction: EnhancedTransaction
    var onTap: () -> Void
    var onCategoryTap: () -> Void
    var onSubscriptionTap: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
        HStack(spacing: 14) {
            // Category icon
            Button(action: onCategoryTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(transaction.category.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(transaction.category.color)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(transaction.merchant)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if transaction.isSubscription {
                        HStack(spacing: 3) {
                            Image(systemName: "repeat")
                                .font(.system(size: 9))
                            if let freq = transaction.subscriptionFrequency {
                                Text(freq.rawValue)
                                    .font(.system(size: 9, weight: .medium))
                            }
                        }
                        .foregroundColor(.indigo)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.indigo.opacity(0.2))
                        )
                    }

                    if transaction.isPending {
                        Text("Pending")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.furgWarning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.furgWarning.opacity(0.2))
                            )
                    }
                }

                HStack(spacing: 8) {
                    Text(transaction.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    if !transaction.tags.isEmpty {
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        Text(transaction.tags.first ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(.furgMint.opacity(0.8))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount > 0 ? CurrencyFormatter.formatSigned(transaction.amount) : CurrencyFormatter.format(transaction.amount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(transaction.amount > 0 ? .furgSuccess : .white)

                Text(transaction.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onSubscriptionTap?()
            } label: {
                Label(
                    transaction.isSubscription ? "Remove Subscription" : "Mark as Subscription",
                    systemImage: transaction.isSubscription ? "repeat.circle.fill" : "repeat"
                )
            }

            Button(action: onCategoryTap) {
                Label("Change Category", systemImage: "folder")
            }
        }
    }
}

// MARK: - Review Transaction Card

private struct ReviewTransactionCard: View {
    let transaction: EnhancedTransaction
    var onCategorize: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.furgWarning.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "questionmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.furgWarning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                if let suggestion = transaction.aiSuggestion {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 10))

                        Text("AI suggests: \(suggestion.rawValue)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.furgMint)
                }
            }

            Spacer()

            Button(action: onCategorize) {
                Text("Categorize")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.furgMint)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - AI Category Picker

private struct AICategoryPicker: View {
    let transaction: EnhancedTransaction
    var onSelect: (TransactionCategory) -> Void
    var onDismiss: () -> Void

    @State private var userInput = ""
    @State private var aiSuggestion: TransactionCategory?
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Categorize Transaction")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Transaction info
                VStack(spacing: 8) {
                    Text(transaction.merchant)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(transaction.originalDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))

                    Text(CurrencyFormatter.format(transaction.amount))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(transaction.amount > 0 ? .furgSuccess : .furgDanger)
                }
                .padding(.vertical, 10)

                // AI Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tell FURG what this is:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 12) {
                        TextField("e.g., 'groceries' or 'doctor visit'", text: $userInput)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .tint(.furgMint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )

                        Button {
                            processWithAI()
                        } label: {
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

                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(userInput.isEmpty || isProcessing)
                    }
                }

                // Category grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Or select a category:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(TransactionCategory.allCases) { category in
                            Button {
                                onSelect(category)
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.opacity(0.2))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: category.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(category.color)
                                    }

                                    Text(category.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    aiSuggestion == category ? category.color : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                )
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.furgCharcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private func processWithAI() {
        isProcessing = true

        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Simple keyword matching for demo
            let input = userInput.lowercased()
            if input.contains("grocery") || input.contains("food") || input.contains("restaurant") {
                aiSuggestion = .food
            } else if input.contains("uber") || input.contains("gas") || input.contains("car") {
                aiSuggestion = .transportation
            } else if input.contains("doctor") || input.contains("gym") || input.contains("health") {
                aiSuggestion = .health
            } else if input.contains("amazon") || input.contains("shop") || input.contains("buy") {
                aiSuggestion = .shopping
            } else {
                aiSuggestion = .other
            }

            isProcessing = false
        }
    }
}

// MARK: - AI Categorize Sheet

private struct AICategorizeSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var chatText = ""
    @State private var isProcessing = false
    @State private var response = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 20) {
                    // AI Avatar
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.furgMint.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)

                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    Text("AI Transaction Assistant")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("Describe your transactions in natural language and I'll help categorize them automatically.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Example prompts
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Try saying:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        ForEach([
                            "Categorize all my Amazon purchases as shopping",
                            "Mark Starbucks as coffee under food",
                            "The $156 charge was from Target"
                        ], id: \.self) { prompt in
                            Button {
                                chatText = prompt
                            } label: {
                                Text(prompt)
                                    .font(.system(size: 13))
                                    .foregroundColor(.furgMint)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.furgMint.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Spacer()

                    // Response area
                    if !response.isEmpty {
                        Text(response)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .padding(.horizontal)
                    }

                    // Input
                    HStack(spacing: 12) {
                        TextField("Describe your transactions...", text: $chatText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .tint(.furgMint)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                            )

                        Button {
                            processRequest()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: chatText.isEmpty ? [.gray.opacity(0.3), .gray.opacity(0.3)] : [.furgMint, .furgSeafoam],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(chatText.isEmpty || isProcessing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("AI Categorize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }

    private func processRequest() {
        isProcessing = true
        let input = chatText
        chatText = ""

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            response = "Got it! I've categorized your transactions based on '\(input)'. 3 transactions updated. Want me to create a rule for future similar transactions?"
            isProcessing = false
        }
    }
}

// MARK: - Subscription Management Sheet

private struct SubscriptionManagementSheet: View {
    let transaction: EnhancedTransaction
    var onSave: (Bool, SubscriptionFrequency?) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var isSubscription: Bool
    @State private var frequency: SubscriptionFrequency
    @State private var createReminder = false

    init(transaction: EnhancedTransaction, onSave: @escaping (Bool, SubscriptionFrequency?) -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        _isSubscription = State(initialValue: transaction.isSubscription)
        _frequency = State(initialValue: transaction.subscriptionFrequency ?? .monthly)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Transaction info
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(transaction.category.color.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: transaction.category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(transaction.category.color)
                        }

                        Text(transaction.merchant)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text(CurrencyFormatter.format(abs(transaction.amount)))
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Subscription toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This is a subscription")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)

                            Text("Track recurring charges automatically")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Toggle("", isOn: $isSubscription)
                            .tint(.furgMint)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )

                    if isSubscription {
                        // Frequency selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Billing Frequency")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 8) {
                                ForEach(SubscriptionFrequency.allCases) { freq in
                                    Button {
                                        frequency = freq
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: freq.icon)
                                                .font(.system(size: 16))

                                            Text(freq.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(frequency == freq ? .furgCharcoal : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(frequency == freq ? Color.furgMint : Color.white.opacity(0.05))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Reminder toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.badge")
                                        .foregroundColor(.furgMint)
                                    Text("Create Reminder")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }

                                Text("Get notified before this charge")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Toggle("", isOn: $createReminder)
                                .tint(.furgMint)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                    }

                    Spacer()

                    // Save button
                    Button {
                        if createReminder && isSubscription {
                            RemindersService.shared.createSubscriptionReminder(
                                merchant: transaction.merchant,
                                amount: transaction.amount,
                                frequency: frequency
                            )
                        }
                        onSave(isSubscription, isSubscription ? frequency : nil)
                    } label: {
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgCharcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Subscription Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - AI Budget Creator View

struct AIBudgetCreatorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var step = 0
    @State private var monthlyIncome = ""
    @State private var selectedGoals: Set<BudgetGoal> = []
    @State private var spendingPriorities: [SpendingPriority] = []
    @State private var isProcessing = false
    @State private var budgetResult: AIBudgetResult?
    @State private var chatMessages: [BudgetChatMessage] = []
    @State private var userInput = ""

    enum BudgetGoal: String, CaseIterable, Identifiable {
        case saveMoney = "Save More Money"
        case payDebt = "Pay Off Debt"
        case buildEmergency = "Build Emergency Fund"
        case investMore = "Invest More"
        case reduceBills = "Reduce Bills"
        case vacation = "Save for Vacation"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .saveMoney: return "dollarsign.circle.fill"
            case .payDebt: return "creditcard.fill"
            case .buildEmergency: return "shield.fill"
            case .investMore: return "chart.line.uptrend.xyaxis"
            case .reduceBills: return "arrow.down.circle.fill"
            case .vacation: return "airplane"
            }
        }
    }

    struct SpendingPriority: Identifiable {
        let id = UUID()
        let category: TransactionCategory
        var importance: Int // 1-5
    }

    struct AIBudgetResult {
        let categories: [(TransactionCategory, Double)]
        let savingsGoal: Double
        let tips: [String]
    }

    struct BudgetChatMessage: Identifiable {
        let id = UUID()
        let isUser: Bool
        let text: String
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(chatMessages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }

                                if isProcessing {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.furgMint)
                                        Text("FURG is thinking...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: chatMessages.count) { _, _ in
                            if let lastMessage = chatMessages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input area
                    VStack(spacing: 12) {
                        // Quick action chips for current step
                        if budgetResult == nil {
                            quickActionChips
                        }

                        // Text input
                        HStack(spacing: 12) {
                            TextField("Type your response...", text: $userInput)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .tint(.furgMint)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))
                                )

                            Button {
                                sendMessage()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: userInput.isEmpty ? [.gray.opacity(0.3), .gray.opacity(0.3)] : [.furgMint, .furgSeafoam],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(userInput.isEmpty || isProcessing)
                        }
                    }
                    .padding()
                    .background(Color.furgCharcoal)
                }
            }
            .navigationTitle("AI Budget Creator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if budgetResult != nil {
                        Button("Apply") {
                            applyBudget()
                            dismiss()
                        }
                        .foregroundColor(.furgMint)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                startConversation()
            }
        }
    }

    @ViewBuilder
    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                switch step {
                case 0:
                    ForEach(["$3,000", "$4,000", "$5,000", "$6,000", "$8,000", "$10,000+"], id: \.self) { amount in
                        QuickChip(text: amount) {
                            userInput = amount
                            sendMessage()
                        }
                    }
                case 1:
                    ForEach(BudgetGoal.allCases) { goal in
                        QuickChip(text: goal.rawValue, icon: goal.icon) {
                            userInput = goal.rawValue
                            sendMessage()
                        }
                    }
                case 2:
                    ForEach(["Conservative", "Balanced", "Aggressive"], id: \.self) { style in
                        QuickChip(text: style) {
                            userInput = style
                            sendMessage()
                        }
                    }
                default:
                    EmptyView()
                }
            }
        }
    }

    private func startConversation() {
        chatMessages.append(BudgetChatMessage(
            isUser: false,
            text: "Hey! I'm FURG, your AI financial assistant. Let's create a personalized budget together. First, what's your monthly take-home income (after taxes)?"
        ))
    }

    private func sendMessage() {
        let message = userInput
        userInput = ""

        chatMessages.append(BudgetChatMessage(isUser: true, text: message))
        isProcessing = true

        // Process the response based on current step
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            processUserResponse(message)
        }
    }

    private func processUserResponse(_ message: String) {
        switch step {
        case 0:
            // Income step
            monthlyIncome = message.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
            chatMessages.append(BudgetChatMessage(
                isUser: false,
                text: "Got it! \(message)/month. Now, what are your main financial goals? You can pick multiple or describe them in your own words."
            ))
            step = 1
        case 1:
            // Goals step
            chatMessages.append(BudgetChatMessage(
                isUser: false,
                text: "Great goals! Last question: How would you describe your spending style? Are you more conservative (prioritize saving), balanced, or aggressive (okay with tighter savings for more spending)?"
            ))
            step = 2
        case 2:
            // Style step - Generate budget
            chatMessages.append(BudgetChatMessage(
                isUser: false,
                text: "Perfect! I've analyzed your info and created a personalized budget. Here's what I recommend:"
            ))

            // Create budget result
            let income = Double(monthlyIncome) ?? 5000
            budgetResult = AIBudgetResult(
                categories: [
                    (.housing, income * 0.30),
                    (.food, income * 0.12),
                    (.transportation, income * 0.10),
                    (.utilities, income * 0.05),
                    (.subscriptions, income * 0.03),
                    (.shopping, income * 0.08),
                    (.entertainment, income * 0.05),
                    (.health, income * 0.05)
                ],
                savingsGoal: income * 0.20,
                tips: [
                    "Aim to keep housing costs at 30% or less",
                    "Set up automatic transfers to savings",
                    "Review subscriptions monthly for unused services"
                ]
            )

            // Add budget summary
            chatMessages.append(BudgetChatMessage(
                isUser: false,
                text: "💰 **Your Budget Breakdown:**\n\n• Housing: $\(Int(income * 0.30))\n• Food: $\(Int(income * 0.12))\n• Transportation: $\(Int(income * 0.10))\n• Utilities: $\(Int(income * 0.05))\n• Subscriptions: $\(Int(income * 0.03))\n• Shopping: $\(Int(income * 0.08))\n• Entertainment: $\(Int(income * 0.05))\n• Health: $\(Int(income * 0.05))\n• **Savings: $\(Int(income * 0.20))**\n\nTap 'Apply' to save this budget!"
            ))
            step = 3
        default:
            // Free chat after budget created
            chatMessages.append(BudgetChatMessage(
                isUser: false,
                text: "Would you like me to adjust any category? Just tell me what you'd like to change!"
            ))
        }
        isProcessing = false
    }

    private func applyBudget() {
        // Save budget to UserDefaults or backend
        RemindersService.shared.createBudgetReminder()
    }
}

private struct QuickChip: View {
    let text: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

private struct ChatBubble: View {
    let message: AIBudgetCreatorView.BudgetChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(message.isUser ? .white : .white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(message.isUser ?
                              LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                        )
                )
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Reminders Service

class RemindersService {
    static let shared = RemindersService()
    let eventStore = EKEventStore()

    private init() {}

    func createSubscriptionReminder(merchant: String, amount: Double, frequency: SubscriptionFrequency) {
        Task {
            guard await requestRemindersAccess() else {
                logger.warning("Reminders access denied")
                return
            }

            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = "💳 \(merchant) subscription - $\(String(format: "%.2f", amount))"
            reminder.notes = "Your \(frequency.rawValue) \(merchant) subscription will renew."
            reminder.calendar = eventStore.defaultCalendarForNewReminders()

            // Set due date based on frequency
            let dueDate: Date
            switch frequency {
            case .monthly:
                dueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            case .yearly:
                dueDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            case .weekly:
                dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
            case .quarterly:
                dueDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            }
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: dueDate)

            do {
                try eventStore.save(reminder, commit: true)
                logger.info("Created reminder for \(merchant) subscription")
            } catch {
                logger.error("Failed to create subscription reminder: \(error.localizedDescription)")
            }
        }
    }

    func createBudgetReminder() {
        Task {
            guard await requestRemindersAccess() else {
                logger.warning("Reminders access denied")
                return
            }

            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = "📊 Weekly Budget Check-in"
            reminder.notes = "Time to review your spending and adjust your budget in Furg."
            reminder.calendar = eventStore.defaultCalendarForNewReminders()

            // Set for next Sunday at 7 PM
            var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
            components.weekday = 1 // Sunday
            components.hour = 19
            components.weekOfYear! += 1
            reminder.dueDateComponents = components

            // Make it recurring weekly
            let recurrenceRule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
            reminder.addRecurrenceRule(recurrenceRule)

            do {
                try eventStore.save(reminder, commit: true)
                logger.info("Created weekly budget check-in reminder")
            } catch {
                logger.error("Failed to create budget reminder: \(error.localizedDescription)")
            }
        }
    }

    func createBillReminder(merchant: String, amount: Double, dueDate: Date) {
        Task {
            guard await requestRemindersAccess() else {
                logger.warning("Reminders access denied")
                return
            }

            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = "📅 \(merchant) bill due - $\(String(format: "%.2f", amount))"
            reminder.notes = "Your \(merchant) payment is due."
            reminder.calendar = eventStore.defaultCalendarForNewReminders()

            // Set reminder for 2 days before due date
            let reminderDate = Calendar.current.date(byAdding: .day, value: -2, to: dueDate) ?? dueDate
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)

            // Add alarm for the day before
            let alarm = EKAlarm(absoluteDate: Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate)
            reminder.addAlarm(alarm)

            do {
                try eventStore.save(reminder, commit: true)
                logger.info("Created bill reminder for \(merchant)")
            } catch {
                logger.error("Failed to create bill reminder: \(error.localizedDescription)")
            }
        }
    }

    func createSavingsGoalReminder(goalName: String, targetAmount: Double) {
        Task {
            guard await requestRemindersAccess() else {
                logger.warning("Reminders access denied")
                return
            }

            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = "🎯 Check \(goalName) progress"
            reminder.notes = "Goal: $\(String(format: "%.0f", targetAmount)). Open Furg to track your progress!"
            reminder.calendar = eventStore.defaultCalendarForNewReminders()

            // Set for next month
            let dueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)

            // Make it recurring monthly
            let recurrenceRule = EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
            reminder.addRecurrenceRule(recurrenceRule)

            do {
                try eventStore.save(reminder, commit: true)
                logger.info("Created savings goal reminder for \(goalName)")
            } catch {
                logger.error("Failed to create savings goal reminder: \(error.localizedDescription)")
            }
        }
    }

    private func requestRemindersAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToReminders()
        } catch {
            logger.error("Failed to request reminders access: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Transaction Detail Sheet

private struct TransactionDetailSheet: View {
    let transaction: EnhancedTransaction
    var onCategoryTap: () -> Void
    var onSubscriptionTap: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with icon and amount
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(transaction.category.color.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: transaction.category.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(transaction.category.color)
                            }

                            Text(transaction.merchant)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(formatCurrency(transaction.amount))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(transaction.amount > 0 ? .furgSuccess : .white)

                            if transaction.isPending {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12))
                                    Text("Pending")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.furgWarning)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.furgWarning.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 20)

                        // Details card
                        VStack(spacing: 0) {
                            DetailRow(label: "Date", value: transaction.date.formatted(date: .long, time: .shortened))
                            Divider().background(Color.white.opacity(0.1))
                            DetailRow(label: "Category", value: transaction.category.rawValue, color: transaction.category.color)
                            Divider().background(Color.white.opacity(0.1))
                            DetailRow(label: "Account", value: transaction.accountName)
                            Divider().background(Color.white.opacity(0.1))
                            DetailRow(label: "Original Description", value: transaction.originalDescription)

                            if transaction.isSubscription, let frequency = transaction.subscriptionFrequency {
                                Divider().background(Color.white.opacity(0.1))
                                DetailRow(label: "Subscription", value: frequency.rawValue, color: .indigo)
                            }

                            if !transaction.tags.isEmpty {
                                Divider().background(Color.white.opacity(0.1))
                                HStack {
                                    Text("Tags")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    HStack(spacing: 6) {
                                        ForEach(transaction.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.furgMint)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.furgMint.opacity(0.2))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(16)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                        )

                        // Actions
                        VStack(spacing: 12) {
                            Button(action: onCategoryTap) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("Change Category")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.06))
                                )
                            }

                            Button(action: onSubscriptionTap) {
                                HStack {
                                    Image(systemName: transaction.isSubscription ? "repeat.circle.fill" : "repeat")
                                    Text(transaction.isSubscription ? "Manage Subscription" : "Mark as Subscription")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.06))
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
        .presentationBackground(Color.furgCharcoal)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

private struct TransactionDetailRow: View {
    let label: String
    let value: String
    var color: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
    }
}

#Preview {
    TransactionsListView()
}
