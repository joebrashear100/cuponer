//
//  TransactionsView.swift
//  Furg
//
//  Transaction history and spending breakdown
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var selectedPeriod = 30

    var body: some View {
        NavigationView {
            List {
                // Period selector
                Section {
                    Picker("Period", selection: $selectedPeriod) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.segmented)
                }

                // Spending summary
                if let summary = financeManager.spendingSummary {
                    Section("Spending Summary") {
                        HStack {
                            Text("Total Spent")
                                .font(.headline)
                            Spacer()
                            Text("$\(Int(summary.totalSpent))")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.orange)
                        }

                        ForEach(Array(summary.byCategory.keys.sorted()), id: \.self) { category in
                            if let amount = summary.byCategory[category] {
                                HStack {
                                    Text(category)
                                    Spacer()
                                    Text("$\(Int(amount))")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }

                // Transactions list
                Section("Transactions") {
                    if financeManager.transactions.isEmpty {
                        Text("No transactions")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(financeManager.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }

                // Bills section
                Section("Detected Bills") {
                    if financeManager.bills.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No bills detected yet")
                                .foregroundColor(.gray)

                            Button("Detect Bills") {
                                Task {
                                    await financeManager.detectBills()
                                }
                            }
                            .font(.caption)
                        }
                    } else {
                        ForEach(financeManager.bills) { bill in
                            BillRow(bill: bill)
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await financeManager.loadTransactions(days: selectedPeriod)
                            await financeManager.loadSpendingSummary(days: selectedPeriod)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await financeManager.loadTransactions(days: selectedPeriod)
                await financeManager.loadSpendingSummary(days: selectedPeriod)
                await financeManager.loadBills()
            }
            .onChange(of: selectedPeriod) { oldValue, newValue in
                Task {
                    await financeManager.loadTransactions(days: newValue)
                    await financeManager.loadSpendingSummary(days: newValue)
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.body)

                HStack {
                    if let category = transaction.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    if transaction.isBill {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.body)
                    .bold()
                    .foregroundColor(transaction.isExpense ? .red : .green)

                Text(transaction.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BillRow: View {
    let bill: Bill

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.merchant)
                    .font(.body)

                HStack {
                    Text(bill.frequencyText)
                        .font(.caption)
                        .foregroundColor(.gray)

                    if let category = bill.category {
                        Text("• \(category)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(bill.formattedAmount)
                    .font(.body)
                    .bold()

                Text("Next: \(bill.nextDue)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TransactionsView()
        .environmentObject(FinanceManager())
}
