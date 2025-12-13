//
//  MerchantDetailView.swift
//  Furg
//
//  Detailed merchant analysis and transaction history
//

import SwiftUI

struct MerchantDetailView: View {
    let merchant: MerchantProfile
    @EnvironmentObject var financeManager: FinanceManager
    @Environment(\.dismiss) var dismiss

    var merchantTransactions: [Transaction] {
        financeManager.transactions.filter { transaction in
            transaction.merchant.lowercased() == merchant.name.lowercased()
        }.sorted { $0.date > $1.date }
    }

    var spendingTrend: [Double] {
        var monthlySpends: [Double] = []
        let calendar = Calendar.current

        for monthOffset in (0..<6).reversed() {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) ?? Date()
            let monthComponent = calendar.component(.month, from: monthDate)
            let yearComponent = calendar.component(.year, from: monthDate)

            let monthTotal = merchantTransactions.filter { transaction in
                let txMonth = calendar.component(.month, from: transaction.date)
                let txYear = calendar.component(.year, from: transaction.date)
                return txMonth == monthComponent && txYear == yearComponent
            }.reduce(0) { $0 + abs($1.amount) }

            monthlySpends.append(monthTotal)
        }

        return monthlySpends
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Merchant Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.furgMint.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(merchant.name.prefix(1)))
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.furgMint)
                                )

                            VStack(spacing: 4) {
                                Text(merchant.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)

                                Text(merchant.category)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)

                        // Key Stats
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatBox(
                                    title: "Total Spent",
                                    value: "$\(Int(merchant.totalSpent))",
                                    icon: "dollarsign.circle.fill",
                                    color: .furgMint
                                )

                                StatBox(
                                    title: "Visit Count",
                                    value: "\(merchant.visitCount)",
                                    icon: "mappin.circle.fill",
                                    color: .furgInfo
                                )
                            }

                            HStack(spacing: 12) {
                                StatBox(
                                    title: "Avg Transaction",
                                    value: "$\(Int(merchant.averageTransaction))",
                                    icon: "creditcard.circle.fill",
                                    color: .furgSuccess
                                )

                                StatBox(
                                    title: "Last Visit",
                                    value: merchant.lastVisitDate.formatted(.dateTime.month(.abbreviated).day()),
                                    icon: "calendar.circle.fill",
                                    color: .furgWarning
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Spending Trend
                        if !spendingTrend.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("6-Month Spending Trend")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)

                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(0..<spendingTrend.count, id: \.self) { index in
                                        VStack(spacing: 4) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.furgMint.opacity(0.7))
                                                .frame(height: CGFloat(spendingTrend[index] / (spendingTrend.max() ?? 1) * 100))

                                            Text("\(getMonthInitial(offset: index - 5))")
                                                .font(.system(size: 9))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                }
                                .frame(height: 120)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }

                        // Recent Transactions
                        if !merchantTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Transactions")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)

                                ForEach(merchantTransactions.prefix(5)) { transaction in
                                    TransactionRow(transaction: transaction)
                                        .padding(.horizontal, 20)
                                }

                                if merchantTransactions.count > 5 {
                                    Text("Showing 5 of \(merchantTransactions.count) transactions")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 8)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }

    private func getMonthInitial(offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
        let monthIndex = calendar.component(.month, from: date)
        let monthNames = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        return monthNames[monthIndex - 1]
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bag.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(transaction.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", abs(transaction.amount)))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgMint)

                if let category = transaction.category {
                    Text(category.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    MerchantDetailView(merchant: MerchantProfile(
        id: "1",
        name: "Starbucks",
        category: "Food & Dining",
        totalSpent: 456.78,
        visitCount: 24,
        averageTransaction: 19.03,
        lastVisitDate: Date(),
        rewards: 0
    ))
    .environmentObject(FinanceManager())
}
