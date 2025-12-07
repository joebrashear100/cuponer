//
//  AppleWalletView.swift
//  Furg
//
//  Connect and view Apple Card, Apple Cash, Apple Savings
//

import SwiftUI

@available(iOS 17.4, *)
struct AppleWalletView: View {
    @StateObject private var financeKit = FinanceKitManager()
    @Environment(\.dismiss) var dismiss
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                LinearGradient(
                    colors: [Color.white.opacity(0.03), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if !financeKit.isAuthorized {
                            connectSection
                        } else {
                            connectedContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Apple Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
        .task {
            await financeKit.checkAuthorizationStatus()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
    }

    // MARK: - Connect Section

    private var connectSection: some View {
        VStack(spacing: 32) {
            // Hero
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Connect Apple Wallet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Access your Apple Card, Apple Cash, and Apple Savings directly and securely on-device.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.top, 40)
            .offset(y: animate ? 0 : -20)
            .opacity(animate ? 1 : 0)

            // Benefits
            VStack(spacing: 16) {
                BenefitRow(icon: "creditcard.fill", title: "Apple Card", description: "See transactions, balance, and Daily Cash")
                BenefitRow(icon: "dollarsign.circle.fill", title: "Apple Cash", description: "Track P2P payments and balance")
                BenefitRow(icon: "building.columns.fill", title: "Apple Savings", description: "Monitor your high-yield savings")
                BenefitRow(icon: "lock.shield.fill", title: "Private & Secure", description: "Data stays on your device, never sent to servers")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            // Connect button
            Button {
                Task { await financeKit.requestAuthorization() }
            } label: {
                HStack(spacing: 12) {
                    if financeKit.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 18))
                    }

                    Text("Connect Apple Wallet")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(financeKit.isLoading)
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            if let error = financeKit.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.furgDanger)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        VStack(spacing: 24) {
            // Apple Card
            if let appleCard = financeKit.appleCardAccount {
                AppleCardWidget(account: appleCard, transactions: financeKit.transactions(for: appleCard.id))
            }

            // Apple Cash
            if let appleCash = financeKit.appleCashAccount {
                AppleCashWidget(account: appleCash)
            }

            // Apple Savings
            if let appleSavings = financeKit.appleSavingsAccount {
                AppleSavingsWidget(account: appleSavings)
            }

            // All accounts
            if !financeKit.accounts.isEmpty {
                allAccountsSection
            }

            // Recent transactions
            if !financeKit.transactions.isEmpty {
                recentTransactionsSection
            }

            // Refresh button
            Button {
                Task { await financeKit.loadAllData() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Data")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.furgMint)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.furgMint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - All Accounts Section

    private var allAccountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Accounts")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            ForEach(financeKit.accounts) { account in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(accountColor(for: account).opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: accountIcon(for: account))
                            .font(.system(size: 18))
                            .foregroundColor(accountColor(for: account))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        Text(account.institutionName)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Text(formatCurrency(account.balance))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(account.balance < 0 ? .furgDanger : .white)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
    }

    // MARK: - Recent Transactions Section

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(financeKit.transactions.count) total")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            ForEach(financeKit.recentTransactions) { txn in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(txn.isCredit ? Color.furgSuccess.opacity(0.15) : Color.furgDanger.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: txn.isCredit ? "arrow.down.left" : "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(txn.isCredit ? .furgSuccess : .furgDanger)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(txn.merchantName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(txn.amount))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(txn.isCredit ? .furgSuccess : .white)

                        if txn.status == .pending {
                            Text("Pending")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.furgWarning)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
    }

    private func accountIcon(for account: FinanceKitManager.FinanceKitAccount) -> String {
        switch account.accountType {
        case .credit: return "creditcard.fill"
        case .debit: return "banknote.fill"
        case .savings: return "building.columns.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "dollarsign.circle.fill"
        }
    }

    private func accountColor(for account: FinanceKitManager.FinanceKitAccount) -> Color {
        switch account.accountType {
        case .credit: return .white
        case .debit: return .furgMint
        case .savings: return .furgSeafoam
        case .investment: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Apple Card Widget

@available(iOS 17.4, *)
private struct AppleCardWidget: View {
    let account: FinanceKitManager.FinanceKitAccount
    let transactions: [FinanceKitManager.FinanceKitTransaction]

    var body: some View {
        VStack(spacing: 0) {
            // Card visual
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 24))
                            .foregroundColor(.black)

                        Spacer()

                        Text("Apple Card")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Balance")
                            .font(.system(size: 12))
                            .foregroundColor(.black.opacity(0.5))

                        Text(formatCurrency(abs(account.balance)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                    }

                    if let limit = account.creditLimit {
                        HStack {
                            Text("Credit Limit: \(formatCurrency(limit))")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.5))

                            Spacer()

                            let utilization = abs(account.balance) / limit * 100
                            Text("\(Int(utilization))% used")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(utilization > 30 ? .orange : .green)
                        }
                    }
                }
                .padding(20)
            }

            // Quick stats
            HStack(spacing: 0) {
                QuickStat(title: "This Month", value: calculateMonthSpending(), color: .furgDanger)
                QuickStat(title: "Daily Cash", value: "$12.45", color: .furgSuccess)
                QuickStat(title: "Transactions", value: "\(transactions.count)", color: .furgMint)
            }
            .padding(.top, 16)
        }
    }

    private func calculateMonthSpending() -> String {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let monthTotal = transactions
            .filter { $0.date >= monthStart && !$0.isCredit }
            .reduce(0) { $0 + $1.amount }
        return formatCurrency(monthTotal)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Apple Cash Widget

@available(iOS 17.4, *)
private struct AppleCashWidget: View {
    let account: FinanceKitManager.FinanceKitAccount

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 56, height: 56)

                Text("$")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Cash")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text("Available Balance")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text(formatCurrency(account.balance))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.furgMint)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Apple Savings Widget

@available(iOS 17.4, *)
private struct AppleSavingsWidget: View {
    let account: FinanceKitManager.FinanceKitAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.furgSeafoam)

                Text("Apple Savings")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("4.50% APY")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.furgMint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.furgMint.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(formatCurrency(account.balance))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interest Earned")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text("$42.18")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.furgSuccess)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("This Month")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text("+$8.32")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.furgSuccess)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.furgSeafoam.opacity(0.15), Color.furgMint.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgSeafoam.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Views

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
    }
}

private struct QuickStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 17.4, *)
#Preview {
    AppleWalletView()
}
