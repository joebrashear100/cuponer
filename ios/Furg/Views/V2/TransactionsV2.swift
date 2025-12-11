//
//  TransactionsV2.swift
//  Furg
//
//  Full transactions list with search, filters, and detailed views
//

import SwiftUI

// MARK: - Full Transactions List

struct FullTransactionsListV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: TransactionV2?
    @State private var showFilters = false

    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expenses = "Expenses"
    }

    var filteredTransactions: [TransactionV2] {
        var result = sampleTransactionsV2

        // Filter by type
        switch selectedFilter {
        case .income:
            result = result.filter { $0.amount > 0 }
        case .expenses:
            result = result.filter { $0.amount < 0 }
        case .all:
            break
        }

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var groupedTransactions: [(String, [TransactionV2])] {
        Dictionary(grouping: filteredTransactions) { $0.dateGroup }
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Filter pills
                    filterPills

                    // Transactions list
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedTransactions, id: \.0) { date, transactions in
                                Section {
                                    ForEach(transactions) { transaction in
                                        Button {
                                            selectedTransaction = transaction
                                        } label: {
                                            TransactionRowV2(transaction: transaction)
                                        }

                                        if transaction.id != transactions.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.06))
                                                .padding(.leading, 70)
                                        }
                                    }
                                } header: {
                                    sectionHeader(for: date, transactions: transactions)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFilters = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailSheetV2(transaction: transaction)
                    .presentationBackground(Color.v2Background)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.v2TextTertiary)

            TextField("Search transactions", text: $searchText)
                .font(.v2Body)
                .foregroundColor(.v2TextPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.v2TextTertiary)
                }
            }
        }
        .padding(14)
        .background(Color.v2CardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    var filterPills: some View {
        HStack(spacing: 8) {
            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                } label: {
                    V2Pill(
                        text: filter.rawValue,
                        color: .v2Mint,
                        isSelected: selectedFilter == filter
                    )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    func sectionHeader(for date: String, transactions: [TransactionV2]) -> some View {
        HStack {
            Text(date)
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)

            Spacer()

            let total = transactions.reduce(0) { $0 + $1.amount }
            Text(total >= 0 ? "+$\(Int(total))" : "-$\(Int(abs(total)))")
                .font(.v2Caption)
                .foregroundColor(total >= 0 ? .v2Lime : .v2TextTertiary)
        }
        .padding(.vertical, 12)
        .background(Color.v2Background)
    }
}

// MARK: - Transaction Row V2

struct TransactionRowV2: View {
    let transaction: TransactionV2

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: transaction.icon)
                    .font(.system(size: 18))
                    .foregroundColor(transaction.color)
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.merchant)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.category)
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)

                    if transaction.isPending {
                        Text("• Pending")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2Gold)
                    }
                }
            }

            Spacer()

            // Amount
            Text(transaction.formattedAmount)
                .font(.v2BodyBold)
                .foregroundColor(transaction.amount > 0 ? .v2Lime : .v2TextPrimary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheetV2: View {
    let transaction: TransactionV2
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(transaction.color.opacity(0.15))
                                .frame(width: 72, height: 72)

                            Image(systemName: transaction.icon)
                                .font(.system(size: 32))
                                .foregroundColor(transaction.color)
                        }

                        Text(transaction.merchant)
                            .font(.v2Title)
                            .foregroundColor(.v2TextPrimary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if transaction.amount < 0 {
                                Text("-")
                                    .font(.v2DisplayMedium)
                                    .foregroundColor(.v2TextPrimary)
                            }
                            Text("$")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.v2Mint)
                            Text(String(format: "%.2f", abs(transaction.amount)))
                                .font(.v2DisplayMedium)
                                .foregroundColor(.v2TextPrimary)
                        }
                    }
                    .padding(.top, 20)

                    // Details
                    V2Card(padding: 16) {
                        VStack(spacing: 0) {
                            DetailRowV2(label: "Category", value: transaction.category)
                            Divider().background(Color.white.opacity(0.06))
                            DetailRowV2(label: "Date", value: transaction.fullDateString)
                            Divider().background(Color.white.opacity(0.06))
                            DetailRowV2(label: "Status", value: transaction.isPending ? "Pending" : "Completed")
                            if let accountName = transaction.accountName {
                                Divider().background(Color.white.opacity(0.06))
                                DetailRowV2(label: "Account", value: accountName)
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        ActionButtonV2(icon: "tag.fill", title: "Change Category", color: .v2Purple) {
                            // Change category action
                        }

                        ActionButtonV2(icon: "flag.fill", title: "Report Issue", color: .v2Gold) {
                            // Report action
                        }

                        if transaction.amount < 0 {
                            ActionButtonV2(icon: "arrow.counterclockwise", title: "Mark as Recurring", color: .v2Blue) {
                                // Recurring action
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.v2Background)
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

struct DetailRowV2: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.v2Body)
                .foregroundColor(.v2TextSecondary)
            Spacer()
            Text(value)
                .font(.v2BodyBold)
                .foregroundColor(.v2TextPrimary)
        }
        .padding(.vertical, 14)
    }
}

struct ActionButtonV2: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.v2TextTertiary)
            }
            .padding(16)
            .background(Color.v2CardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Transaction Model V2

struct TransactionV2: Identifiable {
    let id = UUID()
    let merchant: String
    let category: String
    let amount: Double
    let icon: String
    let color: Color
    let date: Date
    let isPending: Bool
    let accountName: String?

    var formattedAmount: String {
        if amount > 0 {
            return "+$\(String(format: "%.2f", amount))"
        } else {
            return "-$\(String(format: "%.2f", abs(amount)))"
        }
    }

    var dateGroup: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        }
    }

    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Data

let sampleTransactionsV2: [TransactionV2] = [
    TransactionV2(merchant: "Whole Foods Market", category: "Food & Dining", amount: -67.42, icon: "cart.fill", color: .v2CategoryFood, date: Date(), isPending: false, accountName: "Chase Checking"),
    TransactionV2(merchant: "Uber", category: "Transportation", amount: -24.50, icon: "car.fill", color: .v2CategoryTransport, date: Date(), isPending: true, accountName: "Apple Card"),
    TransactionV2(merchant: "Starbucks", category: "Food & Dining", amount: -7.85, icon: "cup.and.saucer.fill", color: .v2CategoryFood, date: Date(), isPending: false, accountName: "Apple Card"),
    TransactionV2(merchant: "Netflix", category: "Entertainment", amount: -15.99, icon: "tv.fill", color: .v2CategoryEntertainment, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isPending: false, accountName: "Chase Checking"),
    TransactionV2(merchant: "Amazon", category: "Shopping", amount: -89.00, icon: "bag.fill", color: .v2CategoryShopping, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isPending: false, accountName: "Amazon Card"),
    TransactionV2(merchant: "Paycheck - Acme Corp", category: "Income", amount: 2250.00, icon: "dollarsign.circle.fill", color: .v2Lime, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, isPending: false, accountName: "Chase Checking"),
    TransactionV2(merchant: "Chipotle", category: "Food & Dining", amount: -14.25, icon: "fork.knife", color: .v2CategoryFood, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, isPending: false, accountName: "Apple Card"),
    TransactionV2(merchant: "Spotify", category: "Entertainment", amount: -10.99, icon: "music.note", color: .v2CategoryEntertainment, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, isPending: false, accountName: "Chase Checking"),
    TransactionV2(merchant: "Gas Station", category: "Transportation", amount: -45.00, icon: "fuelpump.fill", color: .v2CategoryTransport, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, isPending: false, accountName: "Chase Checking"),
    TransactionV2(merchant: "Target", category: "Shopping", amount: -156.32, icon: "bag.fill", color: .v2CategoryShopping, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, isPending: false, accountName: "Target Card")
]

// MARK: - Preview

#Preview {
    FullTransactionsListV2()
}
