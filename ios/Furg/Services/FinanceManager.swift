//
//  FinanceManager.swift
//  Furg
//
//  Manages financial data: balances, transactions, bills
//

import Foundation

@MainActor
class FinanceManager: ObservableObject {
    @Published var balance: BalanceSummary?
    @Published var transactions: [Transaction] = []
    @Published var bills: [Bill] = []
    @Published var upcomingBills: UpcomingBillsResponse?
    @Published var spendingSummary: SpendingSummaryResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    // MARK: - Balance

    func loadBalance() async {
        do {
            balance = try await apiClient.getBalance()
        } catch {
            errorMessage = "Failed to load balance: \(error.localizedDescription)"
        }
    }

    func hideAmount(_ amount: Double, purpose: String = "forced_savings") async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.hideMoney(amount: amount, purpose: purpose)

            if response.success {
                // Reload balance to get updated values
                await loadBalance()
                return true
            } else {
                errorMessage = response.reason ?? response.message
                return false
            }
        } catch {
            errorMessage = "Failed to hide money: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Transactions

    func loadTransactions(days: Int = 30) async {
        do {
            let response = try await apiClient.getTransactions(days: days)
            transactions = response.transactions
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
    }

    func loadSpendingSummary(days: Int = 30) async {
        do {
            spendingSummary = try await apiClient.getSpendingSummary(days: days)
        } catch {
            errorMessage = "Failed to load spending summary: \(error.localizedDescription)"
        }
    }

    // MARK: - Bills

    func loadBills() async {
        do {
            let response = try await apiClient.getBills()
            bills = response.bills
        } catch {
            errorMessage = "Failed to load bills: \(error.localizedDescription)"
        }
    }

    func detectBills() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.detectBills()
            bills = response.bills
        } catch {
            errorMessage = "Failed to detect bills: \(error.localizedDescription)"
        }
    }

    func loadUpcomingBills(days: Int = 30) async {
        do {
            upcomingBills = try await apiClient.getUpcomingBills(days: days)
        } catch {
            errorMessage = "Failed to load upcoming bills: \(error.localizedDescription)"
        }
    }

    // MARK: - Refresh All

    func refreshAll() async {
        isLoading = true
        await loadBalance()
        await loadTransactions()
        await loadBills()
        await loadUpcomingBills()
        await loadSpendingSummary()
        isLoading = false
    }
}
