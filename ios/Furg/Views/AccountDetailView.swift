//
//  AccountDetailView.swift
//  Furg
//
//  Detailed view for individual accounts with transactions and analytics
//

import SwiftUI
import Charts

struct AccountDetailView: View {
    let account: AccountInfo
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedTimeframe: Timeframe = .month

    enum Timeframe: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case quarter = "3M"
        case year = "1Y"
    }

    // Demo transactions
    var transactions: [AccountTransaction] {
        [
            AccountTransaction(date: Date(), description: "Direct Deposit - ACME Corp", amount: 3245.67, type: .credit),
            AccountTransaction(date: Date().addingTimeInterval(-86400), description: "Whole Foods Market", amount: -87.43, type: .debit),
            AccountTransaction(date: Date().addingTimeInterval(-86400 * 2), description: "Netflix", amount: -15.99, type: .debit),
            AccountTransaction(date: Date().addingTimeInterval(-86400 * 3), description: "Amazon.com", amount: -127.99, type: .debit),
            AccountTransaction(date: Date().addingTimeInterval(-86400 * 4), description: "Transfer from Savings", amount: 500.00, type: .credit),
            AccountTransaction(date: Date().addingTimeInterval(-86400 * 5), description: "Starbucks", amount: -6.45, type: .debit),
            AccountTransaction(date: Date().addingTimeInterval(-86400 * 6), description: "Shell Gas Station", amount: -52.30, type: .debit),
            AccountTransaction(date: Date().addingTimeInterval(-86400 * 7), description: "Venmo - John S.", amount: -25.00, type: .debit)
        ]
    }

    var balanceHistory: [BalancePoint] {
        let calendar = Calendar.current
        let now = Date()
        var balance = account.balance
        return (0..<30).reversed().map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            balance += Double.random(in: -200...300)
            return BalancePoint(date: date, balance: max(0, balance))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Account header
                        accountHeader
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Balance chart
                        balanceChart
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Account details
                        accountDetails
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Recent transactions
                        recentTransactions
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        // Quick actions
                        quickActions
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.4), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Account Header

    private var accountHeader: some View {
        VStack(spacing: 20) {
            // Icon and name
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(account.color.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: account.icon)
                        .font(.system(size: 24))
                        .foregroundColor(account.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(account.institution)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Sync status
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.furgSuccess)
                            .frame(width: 8, height: 8)
                        Text("Synced")
                            .font(.system(size: 11))
                            .foregroundColor(.furgSuccess)
                    }

                    Text("Just now")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Balance
            VStack(spacing: 8) {
                Text(account.type.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                Text(formatCurrency(account.balance))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(account.balance < 0 ? .furgDanger : .white)

                // Change indicator
                HStack(spacing: 4) {
                    Image(systemName: account.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))

                    Text("\(account.change >= 0 ? "+" : "")\(formatCurrency(account.change)) this month")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(account.change >= 0 ? .furgSuccess : .furgDanger)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(account.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Balance Chart

    private var balanceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Balance History")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTimeframe = timeframe
                            }
                        } label: {
                            Text(timeframe.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedTimeframe == timeframe ? .furgCharcoal : .white.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedTimeframe == timeframe ? Color.furgMint : Color.clear)
                                )
                        }
                    }
                }
            }

            Chart {
                ForEach(balanceHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Balance", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [account.color, account.color.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Balance", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [account.color.opacity(0.3), account.color.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatCompact(amount))
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Account Details

    private var accountDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                DetailRow(label: "Account Number", value: "••••\(account.lastFour)")
                DetailRow(label: "Routing Number", value: "•••••1234")
                DetailRow(label: "Account Type", value: account.type.rawValue)
                DetailRow(label: "Interest Rate", value: account.interestRate != nil ? "\(String(format: "%.2f", account.interestRate!))% APY" : "N/A")
                DetailRow(label: "Opened", value: account.openedDate)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Recent Transactions

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    // Show all transactions
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.furgMint)
                }
            }

            ForEach(transactions.prefix(5)) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                QuickActionCard(icon: "arrow.left.arrow.right", title: "Transfer", color: .blue)
                QuickActionCard(icon: "doc.on.doc", title: "Copy #", color: .purple)
                QuickActionCard(icon: "bell.fill", title: "Alerts", color: .orange)
                QuickActionCard(icon: "ellipsis", title: "More", color: .gray)
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatCompact(_ amount: Double) -> String {
        if amount >= 1000 {
            return "$\(String(format: "%.0f", amount / 1000))K"
        }
        return "$\(Int(amount))"
    }
}

// MARK: - Supporting Types

struct AccountInfo: Identifiable {
    let id = UUID()
    let name: String
    let institution: String
    let type: AccountType
    let balance: Double
    let change: Double
    let lastFour: String
    let interestRate: Double?
    let openedDate: String
    let color: Color
    let icon: String

    enum AccountType: String {
        case checking = "Checking"
        case savings = "Savings"
        case investment = "Investment"
        case credit = "Credit Card"
    }
}

struct AccountTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let description: String
    let amount: Double
    let type: TransactionType

    enum TransactionType {
        case credit, debit
    }
}

struct BalancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

// MARK: - Supporting Views

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}

private struct TransactionRow: View {
    let transaction: AccountTransaction

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(transaction.type == .credit ? Color.furgSuccess.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.type == .credit ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(transaction.type == .credit ? .furgSuccess : .white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(transaction.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text(formatAmount(transaction.amount))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(transaction.type == .credit ? .furgSuccess : .white)
        }
        .padding(.vertical, 8)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        let prefix = amount > 0 ? "+" : ""
        return prefix + (formatter.string(from: NSNumber(value: amount)) ?? "$0")
    }
}

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AccountDetailView(
        account: AccountInfo(
            name: "Primary Checking",
            institution: "Chase",
            type: .checking,
            balance: 4520.45,
            change: 340.25,
            lastFour: "4521",
            interestRate: nil,
            openedDate: "Mar 2019",
            color: .blue,
            icon: "building.columns.fill"
        )
    )
}
