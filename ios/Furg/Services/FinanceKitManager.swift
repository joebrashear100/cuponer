//
//  FinanceKitManager.swift
//  Furg
//
//  Apple FinanceKit integration for Apple Card, Apple Cash, Apple Savings
//  Free, on-device access to Apple financial data
//
//  Note: FinanceKit requires iOS 17.4+ and a physical device with
//  Apple Card, Apple Cash, or Apple Savings configured in Wallet.
//

import Foundation
import FinanceKit
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "FinanceKitManager")

@available(iOS 17.4, *)
@MainActor
class FinanceKitManager: ObservableObject {
    @Published var accounts: [FinanceKitAccount] = []
    @Published var transactions: [FinanceKitTransaction] = []
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let store = FinanceStore.shared

    // MARK: - Models

    struct FinanceKitAccount: Identifiable {
        let id: String
        let displayName: String
        let accountType: AccountType
        let balance: Double
        let currencyCode: String
        let institutionName: String
        let creditLimit: Double?
        let apr: Double?
        let lastUpdated: Date

        enum AccountType: String {
            case credit = "Credit"
            case debit = "Debit"
            case savings = "Savings"
            case investment = "Investment"
            case other = "Other"
        }
    }

    struct FinanceKitTransaction: Identifiable {
        let id: String
        let accountId: String
        let merchantName: String
        let amount: Double
        let currencyCode: String
        let date: Date
        let category: String?
        let isCredit: Bool
        let status: TransactionStatus

        enum TransactionStatus: String {
            case pending = "Pending"
            case posted = "Posted"
            case declined = "Declined"
        }
    }

    // MARK: - Authorization

    var isAvailable: Bool {
        FinanceStore.isDataAvailable(.financialData)
    }

    func requestAuthorization() async {
        guard isAvailable else {
            errorMessage = "FinanceKit is not available on this device"
            return
        }

        isLoading = true

        do {
            let status = try await store.requestAuthorization()

            switch status {
            case .authorized:
                isAuthorized = true
                await loadAllData()
            case .denied:
                isAuthorized = false
                errorMessage = "Access denied. Enable in Settings > Privacy > Finance"
            case .notDetermined:
                isAuthorized = false
            @unknown default:
                isAuthorized = false
            }
        } catch {
            errorMessage = "Authorization failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func checkAuthorizationStatus() async {
        guard isAvailable else { return }

        do {
            let status = try await store.authorizationStatus()
            isAuthorized = (status == .authorized)

            if isAuthorized {
                await loadAllData()
            }
        } catch {
            logger.error("Failed to check authorization: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Data

    func loadAllData() async {
        guard isAuthorized else { return }

        isLoading = true

        await loadAccounts()
        await loadTransactions()

        isLoading = false
    }

    private func loadAccounts() async {
        do {
            let query = AccountQuery()
            let fetchedAccounts = try await store.accounts(query: query)

            accounts = fetchedAccounts.compactMap { account -> FinanceKitAccount? in
                switch account {
                case .asset(let asset):
                    let accountType: FinanceKitAccount.AccountType
                    if asset.displayName.lowercased().contains("savings") {
                        accountType = .savings
                    } else if asset.displayName.lowercased().contains("cash") {
                        accountType = .debit
                    } else {
                        accountType = .debit
                    }

                    return FinanceKitAccount(
                        id: asset.id.uuidString,
                        displayName: asset.displayName,
                        accountType: accountType,
                        balance: 0, // Balance fetched separately
                        currencyCode: asset.currencyCode,
                        institutionName: asset.institutionName,
                        creditLimit: nil,
                        apr: nil,
                        lastUpdated: Date()
                    )
                case .liability(let liability):
                    return FinanceKitAccount(
                        id: liability.id.uuidString,
                        displayName: liability.displayName,
                        accountType: .credit,
                        balance: 0, // Balance fetched separately
                        currencyCode: liability.currencyCode,
                        institutionName: liability.institutionName,
                        creditLimit: nil,
                        apr: nil,
                        lastUpdated: Date()
                    )
                @unknown default:
                    return nil
                }
            }
        } catch {
            logger.error("Failed to load accounts: \(error.localizedDescription)")
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
        }
    }

    private func loadTransactions(days: Int = 90) async {
        do {
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

            let query = TransactionQuery(
                sortDescriptors: [SortDescriptor(\.postedDate, order: .reverse)],
                predicate: #Predicate { $0.transactionDate > startDate },
                limit: 500
            )

            let fetchedTransactions = try await store.transactions(query: query)

            transactions = fetchedTransactions.map { txn in
                let amount = NSDecimalNumber(decimal: txn.transactionAmount.amount).doubleValue

                // Map status based on transaction state
                let status: FinanceKitTransaction.TransactionStatus
                switch txn.status {
                case .pending:
                    status = .pending
                case .rejected:
                    status = .declined
                default:
                    status = .posted
                }

                return FinanceKitTransaction(
                    id: txn.id.uuidString,
                    accountId: txn.accountID.uuidString,
                    merchantName: txn.merchantName ?? txn.originalTransactionDescription,
                    amount: amount,
                    currencyCode: txn.transactionAmount.currencyCode,
                    date: txn.postedDate ?? txn.transactionDate,
                    category: txn.merchantCategoryCode.flatMap { String($0) },
                    isCredit: txn.creditDebitIndicator == .credit,
                    status: status
                )
            }
        } catch {
            logger.error("Failed to load transactions: \(error.localizedDescription)")
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    var appleCardAccount: FinanceKitAccount? {
        accounts.first { $0.institutionName.lowercased().contains("apple") && $0.accountType == .credit }
    }

    var appleCashAccount: FinanceKitAccount? {
        accounts.first { $0.displayName.lowercased().contains("apple cash") }
    }

    var appleSavingsAccount: FinanceKitAccount? {
        accounts.first { $0.institutionName.lowercased().contains("apple") && $0.accountType == .savings }
    }

    var totalAppleBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var recentTransactions: [FinanceKitTransaction] {
        Array(transactions.prefix(20))
    }

    func transactions(for accountId: String) -> [FinanceKitTransaction] {
        transactions.filter { $0.accountId == accountId }
    }
}
