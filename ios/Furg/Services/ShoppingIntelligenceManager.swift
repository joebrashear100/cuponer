import Foundation
import Combine

// MARK: - Shopping Intelligence Models

struct ShoppingContext: Codable {
    var currentLocation: String?
    var nearbyStores: [NearbyStore]
    var activeDeals: [ActiveDeal]
    var shoppingList: [ShoppingListItem]
    var reorderSuggestions: [ReorderSuggestion]
    var priceAlerts: [PriceAlert]
    var lastUpdated: Date
}

struct NearbyStore: Identifiable, Codable {
    let id: String
    let name: String
    let category: StoreCategory
    let distance: Double // miles
    let address: String
    var hasDeals: Bool
    var priceLevel: Int // 1-4, like Google
    var userRating: Double?
    var relevantDeals: [String] // Deal IDs

    enum StoreCategory: String, Codable, CaseIterable {
        case grocery, pharmacy, electronics, clothing, homeGoods, department, warehouse, convenience, gas, restaurant, other
    }
}

struct ActiveDeal: Identifiable, Codable {
    let id: String
    let retailer: String
    let title: String
    let description: String
    let discountType: DiscountType
    let discountValue: Double
    let minimumPurchase: Double?
    let categories: [String]
    let validFrom: Date
    let validUntil: Date
    let code: String?
    let url: String?
    let source: DealSource
    var isUsed: Bool
    var isSaved: Bool

    enum DiscountType: String, Codable {
        case percentOff
        case dollarOff
        case bogo // Buy one get one
        case freeShipping
        case cashback
        case pointsMultiplier
    }

    enum DealSource: String, Codable {
        case retailerEmail
        case creditCardOffer
        case loyaltyProgram
        case couponSite
        case priceTracking
        case manual
    }

    var isActive: Bool {
        let now = Date()
        return now >= validFrom && now <= validUntil
    }

    var expiresIn: String {
        let components = Calendar.current.dateComponents([.day, .hour], from: Date(), to: validUntil)
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "Soon"
    }
}

struct ShoppingListItem: Identifiable, Codable {
    let id: String
    var name: String
    var quantity: Int
    var category: String
    var estimatedPrice: Double?
    var preferredStore: String?
    var notes: String?
    var isPurchased: Bool
    var addedDate: Date
    var dueDate: Date?
    var linkedProductId: String?
    var priceHistory: [PriceHistoryEntry]

    struct PriceHistoryEntry: Codable {
        let date: Date
        let price: Double
        let store: String
    }

    var bestKnownPrice: Double? {
        return priceHistory.min { $0.price < $1.price }?.price
    }
}

struct ReorderSuggestion: Identifiable, Codable {
    let id: String
    let itemName: String
    let category: String
    let lastPurchaseDate: Date
    let averagePurchaseInterval: Int // days
    let suggestedReorderDate: Date
    let lastPrice: Double
    let preferredStore: String
    let confidence: Double

    var isDue: Bool {
        return suggestedReorderDate <= Date()
    }

    var daysUntilDue: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: suggestedReorderDate).day ?? 0
    }
}

struct PriceAlert: Identifiable, Codable {
    let id: String
    let itemName: String
    let targetPrice: Double
    var currentPrice: Double?
    var currentStore: String?
    let createdAt: Date
    var isTriggered: Bool
    var triggeredAt: Date?
    var notificationSent: Bool
}

struct PriceComparison: Identifiable, Codable {
    let id: String
    let itemName: String
    let searchDate: Date
    let results: [StorePrice]
    let bestDeal: StorePrice?
    let averagePrice: Double

    struct StorePrice: Identifiable, Codable {
        let id: String
        let store: String
        let price: Double
        let inStock: Bool
        let url: String?
        let lastUpdated: Date
    }
}

struct SmartRecommendation: Identifiable, Codable {
    let id: String
    let type: RecommendationType
    let title: String
    let message: String
    let potentialSavings: Double?
    let items: [String]
    let store: String?
    let urgency: Urgency
    let createdAt: Date

    enum RecommendationType: String, Codable {
        case bulkBuy
        case priceDropped
        case dealAvailable
        case reorderReminder
        case substituteAvailable
        case storeSuggestion
        case timingOptimization
    }

    enum Urgency: String, Codable {
        case low, medium, high, urgent
    }
}

// MARK: - Shopping Intelligence Manager

class ShoppingIntelligenceManager: ObservableObject {
    static let shared = ShoppingIntelligenceManager()

    // MARK: - Published Properties
    @Published var shoppingContext: ShoppingContext
    @Published var shoppingList: [ShoppingListItem] = []
    @Published var savedDeals: [ActiveDeal] = []
    @Published var priceAlerts: [PriceAlert] = []
    @Published var reorderSuggestions: [ReorderSuggestion] = []
    @Published var recommendations: [SmartRecommendation] = []
    @Published var priceComparisons: [PriceComparison] = []

    // Summary stats
    @Published var potentialSavings: Double = 0
    @Published var activeDealsCount: Int = 0
    @Published var pendingReorders: Int = 0
    @Published var listItemCount: Int = 0

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let shoppingListKey = "shopping_list"
    private let dealsKey = "shopping_deals"
    private let alertsKey = "shopping_alerts"
    private let suggestionsKey = "shopping_suggestions"
    private let comparisonsKey = "shopping_comparisons"

    // Purchase pattern tracking
    private var purchaseHistory: [String: [Date]] = [:] // Item name -> purchase dates

    // MARK: - Initialization

    init() {
        self.shoppingContext = ShoppingContext(
            currentLocation: nil,
            nearbyStores: [],
            activeDeals: [],
            shoppingList: [],
            reorderSuggestions: [],
            priceAlerts: [],
            lastUpdated: Date()
        )

        loadData()
        generateRecommendations()
        calculateStats()
    }

    // MARK: - Shopping List Management

    func addToShoppingList(name: String, quantity: Int = 1, category: String = "Other", estimatedPrice: Double? = nil, preferredStore: String? = nil, notes: String? = nil, dueDate: Date? = nil) {
        let item = ShoppingListItem(
            id: UUID().uuidString,
            name: name,
            quantity: quantity,
            category: category,
            estimatedPrice: estimatedPrice,
            preferredStore: preferredStore,
            notes: notes,
            isPurchased: false,
            addedDate: Date(),
            dueDate: dueDate,
            linkedProductId: nil,
            priceHistory: []
        )

        shoppingList.append(item)
        saveShoppingList()
        checkDealsForItem(name)
        calculateStats()
    }

    func updateShoppingListItem(_ item: ShoppingListItem) {
        if let index = shoppingList.firstIndex(where: { $0.id == item.id }) {
            shoppingList[index] = item
            saveShoppingList()
        }
    }

    func markItemPurchased(_ itemId: String, price: Double? = nil, store: String? = nil) {
        if let index = shoppingList.firstIndex(where: { $0.id == itemId }) {
            shoppingList[index].isPurchased = true

            // Record purchase for pattern analysis
            let itemName = shoppingList[index].name.lowercased()
            var purchases = purchaseHistory[itemName] ?? []
            purchases.append(Date())
            purchaseHistory[itemName] = purchases

            // Update price history
            if let price = price, let store = store {
                shoppingList[index].priceHistory.append(
                    ShoppingListItem.PriceHistoryEntry(date: Date(), price: price, store: store)
                )
            }

            saveShoppingList()
            updateReorderSuggestions()
            calculateStats()
        }
    }

    func removeFromShoppingList(_ itemId: String) {
        shoppingList.removeAll { $0.id == itemId }
        saveShoppingList()
        calculateStats()
    }

    func clearPurchasedItems() {
        shoppingList.removeAll { $0.isPurchased }
        saveShoppingList()
        calculateStats()
    }

    // MARK: - Deal Management

    func addDeal(_ deal: ActiveDeal) {
        savedDeals.append(deal)
        saveDeals()
        generateRecommendations()
        calculateStats()
    }

    func saveDeal(_ dealId: String) {
        if let index = savedDeals.firstIndex(where: { $0.id == dealId }) {
            savedDeals[index].isSaved = true
            saveDeals()
        }
    }

    func markDealUsed(_ dealId: String) {
        if let index = savedDeals.firstIndex(where: { $0.id == dealId }) {
            savedDeals[index].isUsed = true
            saveDeals()
        }
    }

    func removeDeal(_ dealId: String) {
        savedDeals.removeAll { $0.id == dealId }
        saveDeals()
        calculateStats()
    }

    func cleanExpiredDeals() {
        savedDeals.removeAll { !$0.isActive && !$0.isSaved }
        saveDeals()
    }

    // MARK: - Price Alerts

    func createPriceAlert(itemName: String, targetPrice: Double) {
        let alert = PriceAlert(
            id: UUID().uuidString,
            itemName: itemName,
            targetPrice: targetPrice,
            currentPrice: nil,
            currentStore: nil,
            createdAt: Date(),
            isTriggered: false,
            triggeredAt: nil,
            notificationSent: false
        )

        priceAlerts.append(alert)
        savePriceAlerts()
    }

    func updatePriceAlert(alertId: String, currentPrice: Double, store: String) {
        if let index = priceAlerts.firstIndex(where: { $0.id == alertId }) {
            priceAlerts[index].currentPrice = currentPrice
            priceAlerts[index].currentStore = store

            if currentPrice <= priceAlerts[index].targetPrice && !priceAlerts[index].isTriggered {
                priceAlerts[index].isTriggered = true
                priceAlerts[index].triggeredAt = Date()
                // Trigger notification here
            }

            savePriceAlerts()
        }
    }

    func removePriceAlert(_ alertId: String) {
        priceAlerts.removeAll { $0.id == alertId }
        savePriceAlerts()
    }

    // MARK: - Price Comparison

    func comparePrices(for itemName: String) -> PriceComparison {
        // In production, this would call price comparison APIs
        // For now, generate simulated results

        let stores = ["Amazon", "Walmart", "Target", "Best Buy", "Costco"]
        let basePrice = Double.random(in: 20...100)

        let results = stores.map { store -> PriceComparison.StorePrice in
            let variance = Double.random(in: -0.2...0.2)
            let price = basePrice * (1 + variance)

            return PriceComparison.StorePrice(
                id: UUID().uuidString,
                store: store,
                price: price,
                inStock: Bool.random() || store == "Amazon",
                url: nil,
                lastUpdated: Date()
            )
        }.sorted { $0.price < $1.price }

        let comparison = PriceComparison(
            id: UUID().uuidString,
            itemName: itemName,
            searchDate: Date(),
            results: results,
            bestDeal: results.first { $0.inStock },
            averagePrice: results.reduce(0) { $0 + $1.price } / Double(results.count)
        )

        priceComparisons.insert(comparison, at: 0)
        saveComparisons()

        return comparison
    }

    // MARK: - Reorder Suggestions

    private func updateReorderSuggestions() {
        var suggestions: [ReorderSuggestion] = []

        for (itemName, purchases) in purchaseHistory where purchases.count >= 2 {
            let sortedPurchases = purchases.sorted()

            // Calculate average interval between purchases
            var intervals: [Int] = []
            for i in 1..<sortedPurchases.count {
                let days = Calendar.current.dateComponents([.day], from: sortedPurchases[i-1], to: sortedPurchases[i]).day ?? 0
                intervals.append(days)
            }

            guard !intervals.isEmpty else { continue }

            let avgInterval = intervals.reduce(0, +) / intervals.count
            let lastPurchase = sortedPurchases.last!
            let suggestedDate = Calendar.current.date(byAdding: .day, value: avgInterval, to: lastPurchase)!

            // Calculate confidence based on consistency
            let variance = intervals.map { abs($0 - avgInterval) }.reduce(0, +) / intervals.count
            let confidence = max(0, min(1, 1 - Double(variance) / Double(avgInterval)))

            if confidence > 0.5 {
                suggestions.append(ReorderSuggestion(
                    id: UUID().uuidString,
                    itemName: itemName.capitalized,
                    category: categorizeItem(itemName),
                    lastPurchaseDate: lastPurchase,
                    averagePurchaseInterval: avgInterval,
                    suggestedReorderDate: suggestedDate,
                    lastPrice: 0, // Would come from price history
                    preferredStore: "", // Would come from purchase history
                    confidence: confidence
                ))
            }
        }

        reorderSuggestions = suggestions.sorted { $0.suggestedReorderDate < $1.suggestedReorderDate }
        saveReorderSuggestions()
    }

    // MARK: - Smart Recommendations

    private func generateRecommendations() {
        var newRecommendations: [SmartRecommendation] = []

        // Deal recommendations for items on shopping list
        for item in shoppingList where !item.isPurchased {
            let matchingDeals = savedDeals.filter {
                $0.isActive &&
                ($0.categories.contains { item.category.lowercased().contains($0.lowercased()) } ||
                 $0.title.lowercased().contains(item.name.lowercased()))
            }

            for deal in matchingDeals {
                newRecommendations.append(SmartRecommendation(
                    id: UUID().uuidString,
                    type: .dealAvailable,
                    title: "Deal Available: \(deal.title)",
                    message: "Save on \(item.name) at \(deal.retailer)",
                    potentialSavings: deal.discountValue,
                    items: [item.name],
                    store: deal.retailer,
                    urgency: deal.validUntil < Calendar.current.date(byAdding: .day, value: 3, to: Date())! ? .high : .medium,
                    createdAt: Date()
                ))
            }
        }

        // Reorder reminders
        for suggestion in reorderSuggestions where suggestion.isDue {
            newRecommendations.append(SmartRecommendation(
                id: UUID().uuidString,
                type: .reorderReminder,
                title: "Time to Reorder: \(suggestion.itemName)",
                message: "Based on your purchase history, you might need \(suggestion.itemName) soon",
                potentialSavings: nil,
                items: [suggestion.itemName],
                store: suggestion.preferredStore.isEmpty ? nil : suggestion.preferredStore,
                urgency: .medium,
                createdAt: Date()
            ))
        }

        // Bulk buy recommendations
        let frequentItems = purchaseHistory.filter { $0.value.count >= 5 }
        for (item, _) in frequentItems {
            if let comparison = priceComparisons.first(where: { $0.itemName.lowercased() == item }) {
                if let costcoPrice = comparison.results.first(where: { $0.store == "Costco" }),
                   let avgPrice = comparison.results.filter({ $0.store != "Costco" }).first?.price,
                   costcoPrice.price < avgPrice * 0.8 {
                    newRecommendations.append(SmartRecommendation(
                        id: UUID().uuidString,
                        type: .bulkBuy,
                        title: "Buy in Bulk: \(item.capitalized)",
                        message: "Save 20%+ by buying at Costco",
                        potentialSavings: avgPrice - costcoPrice.price,
                        items: [item],
                        store: "Costco",
                        urgency: .low,
                        createdAt: Date()
                    ))
                }
            }
        }

        // Price drop alerts
        for alert in priceAlerts where alert.isTriggered && !alert.notificationSent {
            newRecommendations.append(SmartRecommendation(
                id: UUID().uuidString,
                type: .priceDropped,
                title: "Price Dropped: \(alert.itemName)",
                message: "Now $\(String(format: "%.2f", alert.currentPrice ?? 0)) at \(alert.currentStore ?? "store") (target: $\(String(format: "%.2f", alert.targetPrice)))",
                potentialSavings: alert.targetPrice - (alert.currentPrice ?? alert.targetPrice),
                items: [alert.itemName],
                store: alert.currentStore,
                urgency: .high,
                createdAt: Date()
            ))
        }

        recommendations = newRecommendations.sorted {
            urgencyOrder($0.urgency) < urgencyOrder($1.urgency)
        }
    }

    private func urgencyOrder(_ urgency: SmartRecommendation.Urgency) -> Int {
        switch urgency {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    // MARK: - Deal Discovery

    private func checkDealsForItem(_ itemName: String) {
        // In production, this would check deal databases and credit card offers
        // For now, we just trigger recommendation generation
        generateRecommendations()
    }

    func discoverDealsForCreditCard(_ cardName: String) -> [ActiveDeal] {
        // In production, this would fetch card-linked offers
        // Simulated deals based on common credit card offers
        let cardDeals: [ActiveDeal] = [
            ActiveDeal(
                id: UUID().uuidString,
                retailer: "Amazon",
                title: "5% Back on Amazon",
                description: "Earn 5% cash back on Amazon.com purchases",
                discountType: .cashback,
                discountValue: 5,
                minimumPurchase: nil,
                categories: ["Shopping", "Online"],
                validFrom: Date(),
                validUntil: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                code: nil,
                url: nil,
                source: .creditCardOffer,
                isUsed: false,
                isSaved: false
            ),
            ActiveDeal(
                id: UUID().uuidString,
                retailer: "Whole Foods",
                title: "10% Back at Whole Foods",
                description: "Earn 10% cash back for Prime members",
                discountType: .cashback,
                discountValue: 10,
                minimumPurchase: nil,
                categories: ["Grocery"],
                validFrom: Date(),
                validUntil: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                code: nil,
                url: nil,
                source: .creditCardOffer,
                isUsed: false,
                isSaved: false
            )
        ]

        return cardDeals
    }

    // MARK: - Store Intelligence

    func findBestStore(for items: [String]) -> (store: String, savings: Double, reasons: [String])? {
        guard !items.isEmpty else { return nil }

        // In production, this would use actual store inventory and pricing
        // Simulated analysis

        let storeScores: [(store: String, savings: Double, reasons: [String])] = [
            ("Costco", 50.0, ["Bulk prices on pantry items", "2% cash back for Executive members"]),
            ("Target", 25.0, ["RedCard 5% discount", "Deal on household items"]),
            ("Walmart", 30.0, ["Everyday low prices", "Price match guarantee"]),
            ("Amazon", 35.0, ["Prime shipping", "Subscribe & Save discount"])
        ]

        return storeScores.max { $0.savings < $1.savings }
    }

    func getOptimalShoppingRoute() -> [NearbyStore] {
        // Would use location data to optimize shopping trip
        return shoppingContext.nearbyStores.sorted { $0.distance < $1.distance }
    }

    // MARK: - Stats

    private func calculateStats() {
        potentialSavings = savedDeals.filter { $0.isActive && !$0.isUsed }
            .reduce(0) { $0 + $1.discountValue }

        activeDealsCount = savedDeals.filter { $0.isActive && !$0.isUsed }.count

        pendingReorders = reorderSuggestions.filter { $0.isDue }.count

        listItemCount = shoppingList.filter { !$0.isPurchased }.count
    }

    // MARK: - Helpers

    private func categorizeItem(_ name: String) -> String {
        let lowercaseName = name.lowercased()

        let categories: [String: [String]] = [
            "Groceries": ["milk", "bread", "eggs", "cheese", "butter", "fruit", "vegetable", "meat", "fish"],
            "Household": ["paper towel", "toilet paper", "soap", "detergent", "cleaner"],
            "Personal Care": ["shampoo", "toothpaste", "deodorant", "lotion"],
            "Electronics": ["battery", "cable", "charger"],
            "Pet": ["dog food", "cat food", "pet"]
        ]

        for (category, keywords) in categories {
            if keywords.contains(where: { lowercaseName.contains($0) }) {
                return category
            }
        }

        return "Other"
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: shoppingListKey),
           let list = try? JSONDecoder().decode([ShoppingListItem].self, from: data) {
            shoppingList = list
        }

        if let data = userDefaults.data(forKey: dealsKey),
           let deals = try? JSONDecoder().decode([ActiveDeal].self, from: data) {
            savedDeals = deals
        }

        if let data = userDefaults.data(forKey: alertsKey),
           let alerts = try? JSONDecoder().decode([PriceAlert].self, from: data) {
            priceAlerts = alerts
        }

        if let data = userDefaults.data(forKey: suggestionsKey),
           let suggestions = try? JSONDecoder().decode([ReorderSuggestion].self, from: data) {
            reorderSuggestions = suggestions
        }

        if let data = userDefaults.data(forKey: comparisonsKey),
           let comparisons = try? JSONDecoder().decode([PriceComparison].self, from: data) {
            priceComparisons = comparisons
        }
    }

    private func saveShoppingList() {
        if let data = try? JSONEncoder().encode(shoppingList) {
            userDefaults.set(data, forKey: shoppingListKey)
        }
    }

    private func saveDeals() {
        if let data = try? JSONEncoder().encode(savedDeals) {
            userDefaults.set(data, forKey: dealsKey)
        }
    }

    private func savePriceAlerts() {
        if let data = try? JSONEncoder().encode(priceAlerts) {
            userDefaults.set(data, forKey: alertsKey)
        }
    }

    private func saveReorderSuggestions() {
        if let data = try? JSONEncoder().encode(reorderSuggestions) {
            userDefaults.set(data, forKey: suggestionsKey)
        }
    }

    private func saveComparisons() {
        // Keep only last 50 comparisons
        let toSave = Array(priceComparisons.prefix(50))
        if let data = try? JSONEncoder().encode(toSave) {
            userDefaults.set(data, forKey: comparisonsKey)
        }
    }
}
