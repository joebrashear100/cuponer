//
//  TransactionsView.swift
//  Furg
//
//  Full transaction history with search and filtering
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedDateRange = DateRange.thirtyDays
    @State private var showFilters = false
    @State private var animate = false

    var filteredTransactions: [Transaction] {
        var results = financeManager.transactions

        // Search filter
        if !searchText.isEmpty {
            results = results.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Category filter
        if let category = selectedCategory {
            results = results.filter { $0.category.lowercased() == category.lowercased() }
        }

        return results
    }

    var totalSpending: Double {
        filteredTransactions
            .filter { $0.amount < 0 }
            .reduce(0) { $0 + abs($1.amount) }
    }

    var transactionsByDate: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            transaction.date
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var categories: [String] {
        Array(Set(financeManager.transactions.map { $0.category })).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transactions")
                            .font(.furgLargeTitle)
                            .foregroundColor(.white)

                        Text("\(filteredTransactions.count) transactions")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button {
                        withAnimation { showFilters.toggle() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(showFilters ? Color.furgMint.opacity(0.3) : Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: "slider.horizontal.3")
                                .font(.body)
                                .foregroundColor(showFilters ? .furgMint : .white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)

                // Search bar
                TransactionSearchBar(text: $searchText)
                    .padding(.horizontal)

                // Filter chips
                if showFilters {
                    TransactionFilterSection(
                        categories: categories,
                        selectedCategory: $selectedCategory,
                        selectedDateRange: $selectedDateRange
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Summary card
                TransactionSpendingSummaryCard(
                    totalSpending: totalSpending,
                    transactionCount: filteredTransactions.count,
                    dateRange: selectedDateRange
                )
                .padding(.horizontal)
            }
            .offset(y: animate ? 0 : -20)
            .opacity(animate ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: animate)

            // Transaction list
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    if filteredTransactions.isEmpty {
                        TransactionEmptyView(searchText: searchText)
                            .padding(.top, 60)
                    } else {
                        ForEach(transactionsByDate, id: \.0) { date, transactions in
                            Section {
                                ForEach(transactions) { transaction in
                                    GlassTransactionRow(transaction: transaction)
                                        .offset(y: animate ? 0 : 20)
                                        .opacity(animate ? 1 : 0)
                                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animate)
                                }
                            } header: {
                                TransactionDateSectionHeader(date: date)
                            }
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.top, 16)
            }
        }
        .task {
            await financeManager.loadTransactions(days: selectedDateRange.days)
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .onChange(of: selectedDateRange) {
            Task {
                await financeManager.loadTransactions(days: selectedDateRange.days)
            }
        }
    }
}

// MARK: - Date Range Enum

enum DateRange: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
    case allTime = "All Time"

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return 365
        }
    }
}

// MARK: - Search Bar

struct TransactionSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))

            TextField("Search transactions...", text: $text)
                .font(.furgBody)
                .foregroundColor(.white)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(14)
        .copilotCard(cornerRadius: 14, opacity: 0.1)
    }
}

// MARK: - Filter Section

struct TransactionFilterSection: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    @Binding var selectedDateRange: DateRange

    var body: some View {
        VStack(spacing: 12) {
            // Date range
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        TransactionFilterChip(
                            label: range.rawValue,
                            isSelected: selectedDateRange == range
                        ) {
                            selectedDateRange = range
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    TransactionFilterChip(
                        label: "All Categories",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(categories, id: \.self) { category in
                        TransactionFilterChip(
                            label: category,
                            isSelected: selectedCategory == category,
                            icon: categoryIcon(for: category)
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
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
}

struct TransactionFilterChip: View {
    let label: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.furgCaption)
            }
            .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.furgMint : Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Spending Summary Card

struct TransactionSpendingSummaryCard: View {
    let totalSpending: Double
    let transactionCount: Int
    let dateRange: DateRange

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))

                Text("$\(Int(totalSpending))")
                    .font(.furgTitle)
                    .foregroundColor(.furgError)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Avg/Day")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))

                let avgDaily = dateRange.days > 0 ? totalSpending / Double(dateRange.days) : 0
                Text("$\(Int(avgDaily))")
                    .font(.furgHeadline)
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .copilotCard(cornerRadius: 14, opacity: 0.08)
    }
}

// MARK: - Date Section Header

struct TransactionDateSectionHeader: View {
    let date: String

    var body: some View {
        HStack {
            Text(date)
                .font(.furgCaption.bold())
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Glass Transaction Row

struct GlassTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: categoryIcon)
                    .font(.body)
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.furgBody)
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(transaction.category)
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))

                    if transaction.isPending {
                        Text("Pending")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.furgWarning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.furgWarning.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    if transaction.isBill {
                        HStack(spacing: 2) {
                            Image(systemName: "repeat")
                                .font(.system(size: 8))
                            Text("Bill")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.furgInfo)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.furgInfo.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.furgBody.bold())
                .foregroundColor(transaction.amount < 0 ? .white : .furgSuccess)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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

// MARK: - Empty Transactions View

struct TransactionEmptyView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)

                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            }

            Text(searchText.isEmpty ? "No Transactions" : "No Results")
                .font(.furgTitle2)
                .foregroundColor(.white)

            Text(searchText.isEmpty
                 ? "Your transactions will appear here once you connect a bank account"
                 : "Try a different search term or clear filters")
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
        .copilotCard()
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        CopilotBackground()
        TransactionsView()
    }
    .environmentObject(FinanceManager())
}
