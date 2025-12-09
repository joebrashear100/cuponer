//
//  FinanceManager.swift
//  Furg
//
//  Manages financial data: balances, transactions, bills
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "FinanceManager")

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
    @Published var isUsingDemoData = false // Track if showing demo data

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
            Bill(id: "3", merchant: "Electric Company", amount: 125.00, frequency: "monthly", nextDue: "Dec 20", category: "Utilities", confidence: 0.88),
            Bill(id: "4", merchant: "Gym Membership", amount: 49.99, frequency: "monthly", nextDue: "Dec 22", category: "Health", confidence: 0.90),
            Bill(id: "5", merchant: "Internet Provider", amount: 79.99, frequency: "monthly", nextDue: "Dec 25", category: "Utilities", confidence: 0.95)
        ]
    }

    var demoTransactions: [Transaction] {
        let formatter = ISO8601DateFormatter()
        let today = Date()
        return [
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 0)), amount: -42.50, merchant: "Whole Foods", category: "Groceries"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 0)), amount: -15.99, merchant: "Netflix", category: "Entertainment"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 1)), amount: -28.75, merchant: "Shell Gas Station", category: "Transportation"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 1)), amount: -65.00, merchant: "Target", category: "Shopping"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 2)), amount: -12.50, merchant: "Starbucks", category: "Food"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 2)), amount: -89.99, merchant: "Amazon", category: "Shopping"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 3)), amount: 2500.00, merchant: "Direct Deposit - Payroll", category: "Income"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 3)), amount: -35.00, merchant: "Chipotle", category: "Food"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 4)), amount: -125.00, merchant: "Electric Company", category: "Utilities"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 4)), amount: -18.99, merchant: "Hulu", category: "Entertainment"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 5)), amount: -55.00, merchant: "Uber", category: "Transportation"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 5)), amount: -78.50, merchant: "Trader Joe's", category: "Groceries"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 6)), amount: -9.99, merchant: "Spotify", category: "Entertainment"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 6)), amount: -45.00, merchant: "CVS Pharmacy", category: "Health"),
            Transaction(date: formatter.string(from: today.addingTimeInterval(-86400 * 7)), amount: -220.00, merchant: "Best Buy", category: "Shopping")
        ]
    }

    /// Computed category spending from transactions
    var categorySpending: [String: Double] {
        let expenses = (transactions.isEmpty ? demoTransactions : transactions).filter { $0.amount < 0 }
        var spending: [String: Double] = [:]
        for tx in expenses {
            spending[tx.category, default: 0] += abs(tx.amount)
        }
        return spending
    }

    /// Weekly spending totals
    var weeklySpending: [(day: String, amount: Double)] {
        let calendar = Calendar.current
        let today = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayStr = dayFormatter.string(from: date)

            // Sum transactions for this day
            let txs = (transactions.isEmpty ? demoTransactions : transactions)
            let dayTotal = txs.filter { tx in
                guard let txDate = ISO8601DateFormatter().date(from: tx.date) else { return false }
                return calendar.isDate(txDate, inSameDayAs: date) && tx.amount < 0
            }.reduce(0.0) { $0 + abs($1.amount) }

            return (dayStr, dayTotal)
        }
    }

    /// Total spent this month
    var monthlySpending: Double {
        let expenses = (transactions.isEmpty ? demoTransactions : transactions).filter { $0.amount < 0 }
        return expenses.reduce(0.0) { $0 + abs($1.amount) }
    }

    /// Financial health score (0-100)
    var financialHealthScore: Int {
        let bal = balance ?? demoBalance
        var score = 50 // Base score

        // Savings ratio bonus (up to +20)
        let savingsRatio = bal.hiddenBalance / max(1, bal.totalBalance)
        score += Int(min(20, savingsRatio * 100))

        // Available balance bonus (up to +15)
        if bal.availableBalance > 1000 { score += 15 }
        else if bal.availableBalance > 500 { score += 10 }
        else if bal.availableBalance > 200 { score += 5 }

        // Spending trend bonus (up to +15)
        let avgDaily = monthlySpending / 30
        if avgDaily < 50 { score += 15 }
        else if avgDaily < 100 { score += 10 }
        else if avgDaily < 150 { score += 5 }

        return min(100, max(0, score))
    }

    // MARK: - Balance

    func loadBalance() async {
        do {
            balance = try await apiClient.getBalance()
            hasBankConnected = true
            isUsingDemoData = false
            logger.debug("Loaded real balance data")
        } catch {
            // Use demo data if API fails - log the error but show demo data
            logger.warning("Failed to load balance, using demo data: \(error.localizedDescription)")
            balance = demoBalance
            hasBankConnected = false
            isUsingDemoData = true
            // Keep errorMessage nil to not alarm user, but they can check isUsingDemoData
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
            logger.debug("Loaded \(response.transactions.count) transactions")
        } catch {
            // Load from local storage if API fails
            logger.warning("Failed to load transactions from API: \(error.localizedDescription)")
            if let saved = loadLocalTransactions(), !saved.isEmpty {
                transactions = saved
                logger.info("Loaded \(saved.count) transactions from local storage")
            } else {
                // Use demo transactions
                transactions = demoTransactions
                logger.info("Using demo transactions")
            }
        }
    }

    func addTransaction(merchant: String, amount: Double, category: String, isExpense: Bool) async -> Bool {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: Date())

        let transaction = Transaction(
            date: dateString,
            amount: isExpense ? -abs(amount) : abs(amount),
            merchant: merchant,
            category: category
        )

        // Add to local list immediately
        transactions.insert(transaction, at: 0)
        saveLocalTransactions()

        // Try to sync with API
        let request = CreateTransactionRequest(
            merchant: merchant,
            amount: isExpense ? -abs(amount) : abs(amount),
            category: category,
            date: dateString
        )

        do {
            try await apiClient.postVoid("/transactions", body: request)
            return true
        } catch {
            // Transaction still saved locally
            return true
        }
    }

    func deleteTransaction(_ transaction: Transaction) async -> Bool {
        transactions.removeAll { $0.id == transaction.id }
        saveLocalTransactions()

        do {
            try await apiClient.postVoid("/transactions/\(transaction.id)/delete", body: EmptyRequest())
            return true
        } catch {
            return true // Still removed locally
        }
    }

    private struct CreateTransactionRequest: Encodable {
        let merchant: String
        let amount: Double
        let category: String
        let date: String
    }

    private struct EmptyRequest: Encodable {}

    private func saveLocalTransactions() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: "local_transactions")
        }
    }

    private func loadLocalTransactions() -> [Transaction]? {
        guard let data = UserDefaults.standard.data(forKey: "local_transactions") else { return nil }
        return try? JSONDecoder().decode([Transaction].self, from: data)
    }

    func loadSpendingSummary(days: Int = 30) async {
        do {
            spendingSummary = try await apiClient.getSpendingSummary(days: days)
            logger.debug("Loaded spending summary for \(days) days")
        } catch {
            logger.warning("Failed to load spending summary: \(error.localizedDescription)")
        }
    }

    // MARK: - Bills

    func loadBills() async {
        do {
            let response = try await apiClient.getBills()
            bills = response.bills
            logger.debug("Loaded \(response.bills.count) bills")
        } catch {
            // Use demo bills if API fails
            logger.warning("Failed to load bills, using demo data: \(error.localizedDescription)")
            bills = demoBills
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
