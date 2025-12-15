//
//  AccountsPageV2.swift
//  Furg
//
//  Connected accounts page for V2 gesture navigation
//  Shows net worth, account balances, and Plaid connection status
//

import SwiftUI

struct AccountsPageV2: View {
    // MARK: - Actions
    var onShowConnectBank: () -> Void = {}

    // MARK: - Environment
    @EnvironmentObject var plaidManager: PlaidManager

    // MARK: - State
    @State private var selectedAccountType: AccountType? = nil

    enum AccountType: String, CaseIterable {
        case all = "All"
        case checking = "Checking"
        case savings = "Savings"
        case credit = "Credit"
        case investment = "Investment"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Net Worth Card
                netWorthCard

                // Account Type Filter
                accountTypeFilter

                // Connected Accounts
                connectedAccountsSection

                // Add Account Button
                addAccountButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Accounts")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)

                Text("Your connected financial accounts")
                    .font(.v2Caption)
                    .foregroundColor(.v2TextTertiary)
            }
            Spacer()

            // Sync indicator
            Button {
                // Refresh accounts
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.v2Success)
                        .frame(width: 8, height: 8)

                    Text("Synced")
                        .font(.v2Footnote)
                        .foregroundColor(.v2TextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.v2CardBackground)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Net Worth Card
    private var netWorthCard: some View {
        V2Card {
            VStack(spacing: 20) {
                // Net Worth
                VStack(spacing: 8) {
                    Text("Net Worth")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextTertiary)

                    V2AmountDisplay(amount: netWorth, size: .large)

                    // Change indicator
                    HStack(spacing: 4) {
                        Image(systemName: netWorthChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))

                        Text(String(format: "%@$%.0f this month", netWorthChange >= 0 ? "+" : "", netWorthChange))
                            .font(.v2CaptionMedium)
                    }
                    .foregroundColor(netWorthChange >= 0 ? .v2Success : .v2Danger)
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Assets vs Liabilities
                HStack {
                    VStack(spacing: 4) {
                        Text("Assets")
                            .font(.v2Footnote)
                            .foregroundColor(.v2TextTertiary)

                        Text(String(format: "$%.0f", totalAssets))
                            .font(.v2BodyMedium)
                            .foregroundColor(.v2Success)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .frame(height: 40)

                    VStack(spacing: 4) {
                        Text("Liabilities")
                            .font(.v2Footnote)
                            .foregroundColor(.v2TextTertiary)

                        Text(String(format: "$%.0f", totalLiabilities))
                            .font(.v2BodyMedium)
                            .foregroundColor(.v2Danger)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Account Type Filter
    private var accountTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AccountType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAccountType = selectedAccountType == type ? nil : type
                        }
                    } label: {
                        V2Pill(
                            text: type.rawValue,
                            isSelected: selectedAccountType == type || (selectedAccountType == nil && type == .all)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Connected Accounts
    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Connected Accounts")

            VStack(spacing: 10) {
                ForEach(filteredAccounts, id: \.name) { account in
                    accountRow(account)
                }
            }
        }
    }

    private func accountRow(_ account: (name: String, institution: String, balance: Double, type: String, lastUpdated: String)) -> some View {
        HStack(spacing: 12) {
            // Institution icon
            Image(systemName: institutionIcon(for: account.institution))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.v2Primary)
                .frame(width: 44, height: 44)
                .background(Color.v2Primary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.v2BodyMedium)
                    .foregroundColor(.v2TextPrimary)

                HStack(spacing: 6) {
                    Text(account.institution)
                        .font(.v2Footnote)
                        .foregroundColor(.v2TextTertiary)

                    Text("•")
                        .foregroundColor(.v2TextTertiary)

                    Text(account.type)
                        .font(.v2Footnote)
                        .foregroundColor(.v2TextTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: account.balance >= 0 ? "$%.2f" : "-$%.2f", abs(account.balance)))
                    .font(.v2BodyMedium)
                    .foregroundColor(account.balance >= 0 ? .v2TextPrimary : .v2Danger)

                Text(account.lastUpdated)
                    .font(.v2Footnote)
                    .foregroundColor(.v2TextTertiary)
            }
        }
        .padding(14)
        .background(Color.v2CardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Add Account Button
    private var addAccountButton: some View {
        Button(action: onShowConnectBank) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))

                Text("Connect Account")
                    .font(.v2BodyMedium)
            }
            .foregroundColor(.v2Primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.v2Primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.v2Primary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Computed Properties
    private var netWorth: Double {
        totalAssets - totalLiabilities
    }

    private var netWorthChange: Double {
        1250 // Sample - would come from historical data
    }

    private var totalAssets: Double {
        accounts.filter { $0.balance >= 0 }.reduce(0) { $0 + $1.balance }
    }

    private var totalLiabilities: Double {
        abs(accounts.filter { $0.balance < 0 }.reduce(0) { $0 + $1.balance })
    }

    private var accounts: [(name: String, institution: String, balance: Double, type: String, lastUpdated: String)] {
        [
            ("Primary Checking", "Chase", 4520.50, "Checking", "Just now"),
            ("Savings", "Chase", 15000.00, "Savings", "Just now"),
            ("Roth IRA", "Fidelity", 28500.00, "Investment", "1h ago"),
            ("Credit Card", "Amex", -2450.00, "Credit", "Just now"),
            ("Emergency Fund", "Marcus", 12000.00, "Savings", "2h ago"),
            ("Student Loan", "SoFi", -18500.00, "Credit", "1d ago")
        ]
    }

    private var filteredAccounts: [(name: String, institution: String, balance: Double, type: String, lastUpdated: String)] {
        guard let selected = selectedAccountType, selected != .all else {
            return accounts
        }
        return accounts.filter { $0.type == selected.rawValue }
    }

    // MARK: - Helpers
    private func institutionIcon(for institution: String) -> String {
        switch institution.lowercased() {
        case "chase": return "building.columns.fill"
        case "fidelity": return "chart.line.uptrend.xyaxis"
        case "amex": return "creditcard.fill"
        case "marcus": return "dollarsign.circle.fill"
        case "sofi": return "graduationcap.fill"
        default: return "building.2.fill"
        }
    }
}

#Preview {
    AccountsPageV2()
        .environmentObject(PlaidManager())
        .v2Background()
}
