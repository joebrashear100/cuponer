//
//  WishlistManager.swift
//  Furg
//
//  Manages wishlist items, purchase planning, and financing calculations
//

import Foundation

@MainActor
class WishlistManager: ObservableObject {
    @Published var wishlist: [WishlistItem] = []
    @Published var budget: PurchaseBudget = PurchaseBudget()
    @Published var financingOptions: [FinancingOption] = FinancingOption.defaults
    @Published var purchasePlans: [PurchasePlan] = []

    private let storageKey = "furg_wishlist_data"

    init() {
        loadFromStorage()
    }

    // MARK: - Wishlist Management

    func addItem(_ item: WishlistItem) {
        wishlist.append(item)
        recalculatePlans()
        saveToStorage()
    }

    func updateItem(_ item: WishlistItem) {
        if let index = wishlist.firstIndex(where: { $0.id == item.id }) {
            wishlist[index] = item
            recalculatePlans()
            saveToStorage()
        }
    }

    func deleteItem(id: String) {
        wishlist.removeAll { $0.id == id }
        recalculatePlans()
        saveToStorage()
    }

    func markAsPurchased(id: String) {
        if let index = wishlist.firstIndex(where: { $0.id == id }) {
            wishlist[index].isPurchased = true
            wishlist[index].purchasedDate = Date()
            recalculatePlans()
            saveToStorage()
        }
    }

    // MARK: - Budget Management

    func updateBudget(_ newBudget: PurchaseBudget) {
        budget = newBudget
        recalculatePlans()
        saveToStorage()
    }

    // MARK: - Financing Calculations

    func calculateFinancing(amount: Double, option: FinancingOption) -> FinancingCalculation {
        let termMonths = option.termMonths
        let fees = option.fees ?? 0

        var totalInterest: Double = 0
        var monthlyPayment: Double

        if let promoPeriod = option.promotionalPeriod,
           option.promotionalApr != nil,
           promoPeriod >= termMonths {
            // Entire term within promotional period
            monthlyPayment = amount / Double(termMonths)
            totalInterest = 0
        } else if option.apr == 0 {
            // Zero interest
            monthlyPayment = amount / Double(termMonths)
            totalInterest = 0
        } else {
            // Standard amortization
            let monthlyRate = option.apr / 100 / 12

            if let promoPeriod = option.promotionalPeriod,
               let promoApr = option.promotionalApr {
                // Split calculation
                let promoMonthlyRate = promoApr / 100 / 12
                let remainingMonths = termMonths - promoPeriod

                // Calculate payments during promo period
                let promoPayment: Double
                if promoMonthlyRate == 0 {
                    promoPayment = amount / Double(termMonths)
                } else {
                    promoPayment = (amount * promoMonthlyRate * pow(1 + promoMonthlyRate, Double(termMonths))) /
                        (pow(1 + promoMonthlyRate, Double(termMonths)) - 1)
                }

                // Calculate remaining balance after promo
                var balance = amount
                for _ in 0..<promoPeriod {
                    let interestPayment = balance * promoMonthlyRate
                    let principalPayment = promoPayment - interestPayment
                    balance -= principalPayment
                    totalInterest += interestPayment
                }

                // Calculate regular period
                if remainingMonths > 0 && balance > 0 {
                    let regularPayment = (balance * monthlyRate * pow(1 + monthlyRate, Double(remainingMonths))) /
                        (pow(1 + monthlyRate, Double(remainingMonths)) - 1)

                    for _ in 0..<remainingMonths {
                        let interestPayment = balance * monthlyRate
                        let principalPayment = regularPayment - interestPayment
                        balance -= principalPayment
                        totalInterest += interestPayment
                    }

                    monthlyPayment = (promoPayment * Double(promoPeriod) + regularPayment * Double(remainingMonths)) / Double(termMonths)
                } else {
                    monthlyPayment = promoPayment
                }
            } else {
                // Standard loan calculation
                monthlyPayment = (amount * monthlyRate * pow(1 + monthlyRate, Double(termMonths))) /
                    (pow(1 + monthlyRate, Double(termMonths)) - 1)

                var balance = amount
                for _ in 0..<termMonths {
                    let interestPayment = balance * monthlyRate
                    let principalPayment = monthlyPayment - interestPayment
                    balance -= principalPayment
                    totalInterest += interestPayment
                }
            }
        }

        let totalPayment = amount + totalInterest + fees
        let payoffDate = Calendar.current.date(byAdding: .month, value: termMonths, to: Date()) ?? Date()

        return FinancingCalculation(
            monthlyPayment: monthlyPayment,
            totalPayment: totalPayment,
            totalInterest: totalInterest,
            payoffDate: payoffDate
        )
    }

    func getApplicableOptions(forAmount amount: Double) -> [FinancingOption] {
        financingOptions.filter { $0.isApplicable(forAmount: amount) }
    }

    func getBestFinancingOption(forAmount amount: Double) -> (option: FinancingOption, calculation: FinancingCalculation)? {
        let applicable = getApplicableOptions(forAmount: amount)
        guard !applicable.isEmpty else { return nil }

        var best: (option: FinancingOption, calculation: FinancingCalculation)?

        for option in applicable {
            let calc = calculateFinancing(amount: amount, option: option)
            if best == nil || calc.totalInterest < best!.calculation.totalInterest {
                best = (option, calc)
            }
        }

        return best
    }

    // MARK: - Purchase Planning

    func recalculatePlans() {
        let monthlySavings = budget.monthlySavings
        let unpurchasedItems = wishlist
            .filter { !$0.isPurchased }
            .sorted { a, b in
                if a.priority.sortOrder != b.priority.sortOrder {
                    return a.priority.sortOrder < b.priority.sortOrder
                }
                return a.price < b.price
            }

        var plans: [PurchasePlan] = []
        var cumulativeMonths = 0
        var availableSavings = budget.currentSavings

        for item in unpurchasedItems {
            let remainingAmount = max(0, item.price - availableSavings)
            let monthsNeeded: Int

            if monthlySavings <= 0 {
                monthsNeeded = Int.max
            } else {
                monthsNeeded = Int(ceil(remainingAmount / monthlySavings))
            }

            cumulativeMonths += monthsNeeded

            let estimatedDate = Calendar.current.date(byAdding: .month, value: cumulativeMonths, to: Date()) ?? Date()
            let monthlySavingsRequired = monthsNeeded > 0 ? remainingAmount / Double(monthsNeeded) : 0

            // Find best financing option
            let bestFinancing = getBestFinancingOption(forAmount: item.price)

            let plan = PurchasePlan(
                id: item.id,
                item: item,
                estimatedPurchaseDate: estimatedDate,
                monthsToSave: cumulativeMonths,
                monthlySavingsRequired: monthlySavingsRequired,
                financingOption: bestFinancing?.option,
                financingCalculation: bestFinancing?.calculation
            )

            plans.append(plan)

            // Reduce available savings for next item
            availableSavings = max(0, availableSavings - item.price)
        }

        purchasePlans = plans
    }

    // MARK: - Computed Properties

    var activeItems: [WishlistItem] {
        wishlist.filter { !$0.isPurchased }
    }

    var purchasedItems: [WishlistItem] {
        wishlist.filter { $0.isPurchased }
    }

    var totalWishlistValue: Double {
        activeItems.reduce(0) { $0 + $1.price }
    }

    var totalMonthsToComplete: Int {
        purchasePlans.last?.monthsToSave ?? 0
    }

    // MARK: - Storage

    private func saveToStorage() {
        let data = WishlistStorageData(
            wishlist: wishlist,
            budget: budget,
            financingOptions: financingOptions
        )

        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(WishlistStorageData.self, from: data) else {
            return
        }

        wishlist = decoded.wishlist
        budget = decoded.budget
        financingOptions = decoded.financingOptions.isEmpty ? FinancingOption.defaults : decoded.financingOptions
        recalculatePlans()
    }

    func clearAllData() {
        wishlist = []
        budget = PurchaseBudget()
        financingOptions = FinancingOption.defaults
        purchasePlans = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - Storage Data Structure

private struct WishlistStorageData: Codable {
    let wishlist: [WishlistItem]
    let budget: PurchaseBudget
    let financingOptions: [FinancingOption]
}
