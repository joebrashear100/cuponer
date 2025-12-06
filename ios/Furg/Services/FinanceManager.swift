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
    @Published var hasBankConnected = false

    private let apiClient = APIClient()

    // Demo data for when no bank is connected
    var demoBalance: BalanceSummary {
        BalanceSummary(
            totalBalance: 4250.00,
            availableBalance: 2850.00,
            hiddenBalance: 1200.00,
            pendingBalance: 200.00,
            safetyBuffer: 950.00,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
    }

    var demoBills: [Bill] {
        [
            Bill(id: "1", merchant: "Netflix", amount: 15.99, frequency: "monthly", nextDue: "Dec 15", category: "Entertainment", confidence: 0.95),
            Bill(id: "2", merchant: "Spotify", amount: 9.99, frequency: "monthly", nextDue: "Dec 18", category: "Entertainment", confidence: 0.92),
            Bill(id: "3", merchant: "Electric Company", amount: 125.00, frequency: "monthly", nextDue: "Dec 20", category: "Utilities", confidence: 0.88)
        ]
    }

    // MARK: - Balance

    func loadBalance() async {
        do {
            balance = try await apiClient.getBalance()
            hasBankConnected = true
        } catch {
            // Use demo data if API fails
            balance = demoBalance
            hasBankConnected = false
            errorMessage = nil // Don't show error, just use demo data
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

    func revealAmount(_ amount: Double? = nil) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.revealMoney(amount: amount)

            if response.success {
                await loadBalance()
                return true
            } else {
                errorMessage = response.reason ?? response.message
                return false
            }
        } catch {
            errorMessage = "Failed to reveal money: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Transactions

    func loadTransactions(days: Int = 30) async {
        do {
            let response = try await apiClient.getTransactions(days: days)
            transactions = response.transactions
        } catch {
            // Keep empty or existing transactions on error
            errorMessage = nil
        }
    }

    func loadSpendingSummary(days: Int = 30) async {
        do {
            spendingSummary = try await apiClient.getSpendingSummary(days: days)
        } catch {
            errorMessage = nil
        }
    }

    // MARK: - Bills

    func loadBills() async {
        do {
            let response = try await apiClient.getBills()
            bills = response.bills
        } catch {
            // Use demo bills if API fails
            bills = demoBills
            errorMessage = nil
        }
    }

    func detectBills() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.detectBills()
            bills = response.bills
        } catch {
            errorMessage = "Connect a bank to detect bills automatically"
        }
    }

    func loadUpcomingBills(days: Int = 30) async {
        do {
            upcomingBills = try await apiClient.getUpcomingBills(days: days)
        } catch {
            // Create demo upcoming bills
            upcomingBills = UpcomingBillsResponse(
                bills: demoBills,
                totalDue: demoBills.reduce(0) { $0 + $1.amount },
                daysAhead: days
            )
            errorMessage = nil
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
