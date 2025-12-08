import Foundation
import AuthenticationServices
import Combine

// MARK: - Retailer Connection Models

struct RetailerAccount: Identifiable, Codable {
    let id: String
    let retailer: Retailer
    var isConnected: Bool
    var lastSynced: Date?
    var membershipId: String?
    var membershipTier: String?
    var totalPurchases: Int
    var totalSpent: Double
    var accountEmail: String?
    var rewardsBalance: Double?
    var rewardsPointsName: String?

    enum Retailer: String, Codable, CaseIterable {
        case amazon
        case target
        case walmart
        case costco
        case instacart
        case doordash
        case ubereats
        case cvs
        case walgreens
        case bestbuy
        case homedepot
        case lowes
        case kroger
        case safeway
        case wholefoods
        case traderjoes
        case starbucks

        var displayName: String {
            switch self {
            case .amazon: return "Amazon"
            case .target: return "Target"
            case .walmart: return "Walmart"
            case .costco: return "Costco"
            case .instacart: return "Instacart"
            case .doordash: return "DoorDash"
            case .ubereats: return "Uber Eats"
            case .cvs: return "CVS"
            case .walgreens: return "Walgreens"
            case .bestbuy: return "Best Buy"
            case .homedepot: return "Home Depot"
            case .lowes: return "Lowe's"
            case .kroger: return "Kroger"
            case .safeway: return "Safeway"
            case .wholefoods: return "Whole Foods"
            case .traderjoes: return "Trader Joe's"
            case .starbucks: return "Starbucks"
            }
        }

        var icon: String {
            switch self {
            case .amazon: return "shippingbox.fill"
            case .target: return "target"
            case .walmart: return "cart.fill"
            case .costco: return "building.2.fill"
            case .instacart: return "basket.fill"
            case .doordash, .ubereats: return "takeoutbag.and.cup.and.straw.fill"
            case .cvs, .walgreens: return "cross.case.fill"
            case .bestbuy: return "desktopcomputer"
            case .homedepot, .lowes: return "hammer.fill"
            case .kroger, .safeway, .wholefoods, .traderjoes: return "leaf.fill"
            case .starbucks: return "cup.and.saucer.fill"
            }
        }

        var color: String {
            switch self {
            case .amazon: return "orange"
            case .target: return "red"
            case .walmart: return "blue"
            case .costco: return "red"
            case .instacart: return "green"
            case .doordash: return "red"
            case .ubereats: return "green"
            case .cvs: return "red"
            case .walgreens: return "red"
            case .bestbuy: return "blue"
            case .homedepot: return "orange"
            case .lowes: return "blue"
            case .kroger: return "blue"
            case .safeway: return "red"
            case .wholefoods: return "green"
            case .traderjoes: return "red"
            case .starbucks: return "green"
            }
        }

        var supportsOAuth: Bool {
            switch self {
            case .amazon, .target, .walmart, .instacart, .doordash, .ubereats, .starbucks:
                return true
            default:
                return false
            }
        }

        var supportsDataExport: Bool {
            switch self {
            case .amazon, .walmart, .target, .costco:
                return true
            default:
                return false
            }
        }

        var loyaltyProgramName: String? {
            switch self {
            case .amazon: return "Prime"
            case .target: return "Target Circle"
            case .walmart: return "Walmart+"
            case .costco: return "Executive Membership"
            case .cvs: return "ExtraCare"
            case .walgreens: return "myWalgreens"
            case .starbucks: return "Starbucks Rewards"
            case .kroger: return "Kroger Plus"
            case .safeway: return "Club Card"
            default: return nil
            }
        }
    }
}

struct RetailerPurchaseHistory: Identifiable, Codable {
    let id: String
    let retailer: RetailerAccount.Retailer
    let purchases: [RetailerPurchase]
    let dateRange: DateRange
    let totalSpent: Double
    let totalItems: Int

    struct DateRange: Codable {
        let start: Date
        let end: Date
    }
}

struct RetailerPurchase: Identifiable, Codable {
    let id: String
    let orderId: String
    let retailer: RetailerAccount.Retailer
    let orderDate: Date
    let items: [PurchasedItem]
    let subtotal: Double
    let tax: Double
    let shipping: Double?
    let total: Double
    let paymentMethod: String?
    let deliveryDate: Date?
    let status: OrderStatus

    enum OrderStatus: String, Codable {
        case placed
        case processing
        case shipped
        case delivered
        case cancelled
        case returned
    }
}

struct PurchasedItem: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let category: String?
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
    let imageUrl: String?
    let productUrl: String?
    let asin: String? // Amazon specific
    let upc: String?
    let sku: String?
    var tags: [String]
}

struct RetailerInsight: Identifiable, Codable {
    let id: String
    let retailer: RetailerAccount.Retailer
    let type: InsightType
    let title: String
    let message: String
    let data: InsightData
    let createdAt: Date

    enum InsightType: String, Codable {
        case frequentPurchase
        case priceIncrease
        case subscriptionOpportunity
        case loyaltyReward
        case spendingTrend
        case comparison
    }

    struct InsightData: Codable {
        let itemName: String?
        let amount: Double?
        let frequency: Int?
        let savingsOpportunity: Double?
    }
}

struct DataImport: Identifiable, Codable {
    let id: String
    let retailer: RetailerAccount.Retailer
    let importDate: Date
    let status: ImportStatus
    let recordsImported: Int
    let dateRangeCovered: RetailerPurchaseHistory.DateRange?
    let errorMessage: String?

    enum ImportStatus: String, Codable {
        case pending
        case processing
        case completed
        case failed
    }
}

// MARK: - Retailer Connection Manager

class RetailerConnectionManager: ObservableObject {
    static let shared = RetailerConnectionManager()

    // MARK: - Published Properties
    @Published var connectedAccounts: [RetailerAccount] = []
    @Published var purchaseHistory: [String: RetailerPurchaseHistory] = [:] // Retailer ID -> History
    @Published var allPurchases: [RetailerPurchase] = []
    @Published var insights: [RetailerInsight] = []
    @Published var dataImports: [DataImport] = []

    @Published var isConnecting = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    // Aggregated stats
    @Published var totalConnectedRetailers: Int = 0
    @Published var totalPurchasesTracked: Int = 0
    @Published var lifetimeSpending: Double = 0
    @Published var mostFrequentRetailer: RetailerAccount.Retailer?

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let accountsKey = "retailer_accounts"
    private let purchasesKey = "retailer_purchases"
    private let importsKey = "retailer_imports"

    // OAuth configuration (would be in secure config in production)
    private let oauthConfigs: [RetailerAccount.Retailer: OAuthConfig] = [
        .amazon: OAuthConfig(clientId: "amazon_client_id", scope: "profile orders", authUrl: "https://www.amazon.com/ap/oa"),
        .target: OAuthConfig(clientId: "target_client_id", scope: "orders profile", authUrl: "https://api.target.com/oauth"),
        .walmart: OAuthConfig(clientId: "walmart_client_id", scope: "orders", authUrl: "https://developer.walmart.com/oauth")
    ]

    private struct OAuthConfig {
        let clientId: String
        let scope: String
        let authUrl: String
    }

    // MARK: - Initialization

    init() {
        loadData()
        calculateStats()
    }

    // MARK: - Account Connection

    func connectRetailer(_ retailer: RetailerAccount.Retailer) async throws {
        isConnecting = true
        defer { isConnecting = false }

        // In production, this would:
        // 1. Initiate OAuth flow using ASWebAuthenticationSession
        // 2. Exchange auth code for tokens
        // 3. Store tokens securely in Keychain
        // 4. Fetch initial account data

        // For now, simulate connection
        let account = RetailerAccount(
            id: UUID().uuidString,
            retailer: retailer,
            isConnected: true,
            lastSynced: Date(),
            membershipId: generateMembershipId(),
            membershipTier: retailer.loyaltyProgramName != nil ? "Standard" : nil,
            totalPurchases: 0,
            totalSpent: 0,
            accountEmail: nil,
            rewardsBalance: retailer.loyaltyProgramName != nil ? Double.random(in: 10...500) : nil,
            rewardsPointsName: getRewardsPointsName(for: retailer)
        )

        connectedAccounts.append(account)
        saveAccounts()
        calculateStats()

        // Trigger initial sync
        try await syncRetailer(retailer)
    }

    func disconnectRetailer(_ retailer: RetailerAccount.Retailer) {
        connectedAccounts.removeAll { $0.retailer == retailer }
        purchaseHistory.removeValue(forKey: retailer.rawValue)
        allPurchases.removeAll { $0.retailer == retailer }

        saveAccounts()
        savePurchases()
        calculateStats()
    }

    func isConnected(_ retailer: RetailerAccount.Retailer) -> Bool {
        return connectedAccounts.contains { $0.retailer == retailer && $0.isConnected }
    }

    // MARK: - Data Sync

    func syncAllRetailers() async throws {
        isSyncing = true
        defer { isSyncing = false }

        for account in connectedAccounts where account.isConnected {
            try await syncRetailer(account.retailer)
        }

        lastSyncDate = Date()
        generateInsights()
    }

    func syncRetailer(_ retailer: RetailerAccount.Retailer) async throws {
        // In production, this would call the retailer's API
        // For now, simulate fetching purchase history

        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000)

        let purchases = generateSimulatedPurchases(for: retailer, count: Int.random(in: 5...20))

        let history = RetailerPurchaseHistory(
            id: UUID().uuidString,
            retailer: retailer,
            purchases: purchases,
            dateRange: RetailerPurchaseHistory.DateRange(
                start: purchases.last?.orderDate ?? Date(),
                end: purchases.first?.orderDate ?? Date()
            ),
            totalSpent: purchases.reduce(0) { $0 + $1.total },
            totalItems: purchases.reduce(0) { $0 + $1.items.count }
        )

        purchaseHistory[retailer.rawValue] = history

        // Update account stats
        if let index = connectedAccounts.firstIndex(where: { $0.retailer == retailer }) {
            var account = connectedAccounts[index]
            account = RetailerAccount(
                id: account.id,
                retailer: account.retailer,
                isConnected: true,
                lastSynced: Date(),
                membershipId: account.membershipId,
                membershipTier: account.membershipTier,
                totalPurchases: history.purchases.count,
                totalSpent: history.totalSpent,
                accountEmail: account.accountEmail,
                rewardsBalance: account.rewardsBalance,
                rewardsPointsName: account.rewardsPointsName
            )
            connectedAccounts[index] = account
        }

        // Merge into all purchases
        allPurchases.removeAll { $0.retailer == retailer }
        allPurchases.append(contentsOf: purchases)
        allPurchases.sort { $0.orderDate > $1.orderDate }

        saveAccounts()
        savePurchases()
        calculateStats()
    }

    // MARK: - Data Import

    func importDataExport(for retailer: RetailerAccount.Retailer, fileData: Data) async throws {
        let importRecord = DataImport(
            id: UUID().uuidString,
            retailer: retailer,
            importDate: Date(),
            status: .processing,
            recordsImported: 0,
            dateRangeCovered: nil,
            errorMessage: nil
        )

        dataImports.insert(importRecord, at: 0)
        saveImports()

        // Parse the data based on retailer format
        // In production, this would handle CSV/JSON parsing specific to each retailer

        // Simulate processing
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Update import record
        if let index = dataImports.firstIndex(where: { $0.id == importRecord.id }) {
            dataImports[index] = DataImport(
                id: importRecord.id,
                retailer: retailer,
                importDate: importRecord.importDate,
                status: .completed,
                recordsImported: Int.random(in: 50...500),
                dateRangeCovered: RetailerPurchaseHistory.DateRange(
                    start: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
                    end: Date()
                ),
                errorMessage: nil
            )
        }

        saveImports()
    }

    func parseAmazonExport(_ data: Data) throws -> [RetailerPurchase] {
        // Parse Amazon order history CSV
        // Format: Order Date, Order ID, Title, Category, ASIN, Quantity, Purchase Price, etc.
        var purchases: [RetailerPurchase] = []

        guard let content = String(data: data, encoding: .utf8) else {
            throw RetailerError.invalidDataFormat
        }

        let rows = content.components(separatedBy: .newlines)
        guard rows.count > 1 else { return [] }

        // Skip header row
        for row in rows.dropFirst() {
            let columns = parseCSVRow(row)
            guard columns.count >= 7 else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yy"

            guard let orderDate = dateFormatter.date(from: columns[0]) else { continue }
            let orderId = columns[1]
            let title = columns[2]
            let category = columns[3]
            let asin = columns[4]
            let quantity = Int(columns[5]) ?? 1
            let price = Double(columns[6].replacingOccurrences(of: "$", with: "")) ?? 0

            let item = PurchasedItem(
                id: UUID().uuidString,
                name: title,
                brand: nil,
                category: category,
                quantity: quantity,
                unitPrice: price / Double(quantity),
                totalPrice: price,
                imageUrl: nil,
                productUrl: "https://www.amazon.com/dp/\(asin)",
                asin: asin,
                upc: nil,
                sku: nil,
                tags: []
            )

            // Group by order
            if let existingIndex = purchases.firstIndex(where: { $0.orderId == orderId }) {
                var existing = purchases[existingIndex]
                var items = existing.items
                items.append(item)
                purchases[existingIndex] = RetailerPurchase(
                    id: existing.id,
                    orderId: orderId,
                    retailer: .amazon,
                    orderDate: orderDate,
                    items: items,
                    subtotal: items.reduce(0) { $0 + $1.totalPrice },
                    tax: 0,
                    shipping: nil,
                    total: items.reduce(0) { $0 + $1.totalPrice },
                    paymentMethod: nil,
                    deliveryDate: nil,
                    status: .delivered
                )
            } else {
                purchases.append(RetailerPurchase(
                    id: UUID().uuidString,
                    orderId: orderId,
                    retailer: .amazon,
                    orderDate: orderDate,
                    items: [item],
                    subtotal: price,
                    tax: 0,
                    shipping: nil,
                    total: price,
                    paymentMethod: nil,
                    deliveryDate: nil,
                    status: .delivered
                ))
            }
        }

        return purchases
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        columns.append(current.trimmingCharacters(in: .whitespaces))

        return columns
    }

    // MARK: - Insights

    private func generateInsights() {
        var newInsights: [RetailerInsight] = []

        // Analyze purchase frequency
        let itemFrequency = analyzeItemFrequency()
        for (item, count) in itemFrequency.prefix(5) {
            newInsights.append(RetailerInsight(
                id: UUID().uuidString,
                retailer: .amazon, // Would be actual retailer
                type: .frequentPurchase,
                title: "Frequently Purchased",
                message: "You've bought \(item) \(count) times. Consider a subscription for savings.",
                data: RetailerInsight.InsightData(
                    itemName: item,
                    amount: nil,
                    frequency: count,
                    savingsOpportunity: Double(count) * 2.0 // Estimated savings
                ),
                createdAt: Date()
            ))
        }

        // Analyze spending trends
        let monthlySpending = analyzeMonthlySpending()
        if let trend = detectSpendingTrend(monthlySpending) {
            newInsights.append(RetailerInsight(
                id: UUID().uuidString,
                retailer: mostFrequentRetailer ?? .amazon,
                type: .spendingTrend,
                title: trend.title,
                message: trend.message,
                data: RetailerInsight.InsightData(
                    itemName: nil,
                    amount: trend.amount,
                    frequency: nil,
                    savingsOpportunity: nil
                ),
                createdAt: Date()
            ))
        }

        insights = newInsights
    }

    private func analyzeItemFrequency() -> [(String, Int)] {
        var frequency: [String: Int] = [:]

        for purchase in allPurchases {
            for item in purchase.items {
                frequency[item.name, default: 0] += item.quantity
            }
        }

        return frequency.sorted { $0.value > $1.value }
    }

    private func analyzeMonthlySpending() -> [Date: Double] {
        var monthly: [Date: Double] = [:]
        let calendar = Calendar.current

        for purchase in allPurchases {
            let components = calendar.dateComponents([.year, .month], from: purchase.orderDate)
            if let monthStart = calendar.date(from: components) {
                monthly[monthStart, default: 0] += purchase.total
            }
        }

        return monthly
    }

    private func detectSpendingTrend(_ monthly: [Date: Double]) -> (title: String, message: String, amount: Double)? {
        let sorted = monthly.sorted { $0.key > $1.key }
        guard sorted.count >= 2 else { return nil }

        let recent = sorted[0].value
        let previous = sorted[1].value

        let change = ((recent - previous) / previous) * 100

        if change > 20 {
            return (
                "Spending Increase",
                "Your spending increased by \(Int(change))% this month",
                recent
            )
        } else if change < -20 {
            return (
                "Spending Decrease",
                "Great job! You reduced spending by \(Int(abs(change)))% this month",
                recent
            )
        }

        return nil
    }

    // MARK: - Query Methods

    func getPurchases(for retailer: RetailerAccount.Retailer) -> [RetailerPurchase] {
        return allPurchases.filter { $0.retailer == retailer }
    }

    func searchPurchases(query: String) -> [PurchasedItem] {
        let lowercaseQuery = query.lowercased()
        return allPurchases.flatMap { $0.items }
            .filter { $0.name.lowercased().contains(lowercaseQuery) }
    }

    func getCategorySpending() -> [String: Double] {
        var categoryTotals: [String: Double] = [:]

        for purchase in allPurchases {
            for item in purchase.items {
                let category = item.category ?? "Uncategorized"
                categoryTotals[category, default: 0] += item.totalPrice
            }
        }

        return categoryTotals
    }

    func getReorderSuggestions() -> [PurchasedItem] {
        // Find items purchased multiple times that might need reordering
        let frequency = analyzeItemFrequency()

        return frequency.prefix(10).compactMap { (itemName, count) -> PurchasedItem? in
            guard count >= 2 else { return nil }

            // Find most recent purchase of this item
            for purchase in allPurchases {
                if let item = purchase.items.first(where: { $0.name == itemName }) {
                    return item
                }
            }
            return nil
        }
    }

    // MARK: - Stats

    private func calculateStats() {
        totalConnectedRetailers = connectedAccounts.filter { $0.isConnected }.count
        totalPurchasesTracked = allPurchases.count
        lifetimeSpending = connectedAccounts.reduce(0) { $0 + $1.totalSpent }

        // Find most frequent retailer
        let retailerCounts = allPurchases.reduce(into: [:]) { counts, purchase in
            counts[purchase.retailer, default: 0] += 1
        }
        mostFrequentRetailer = retailerCounts.max { $0.value < $1.value }?.key
    }

    // MARK: - Helpers

    private func generateMembershipId() -> String {
        return String((0..<10).map { _ in "0123456789".randomElement()! })
    }

    private func getRewardsPointsName(for retailer: RetailerAccount.Retailer) -> String? {
        switch retailer {
        case .target: return "votes"
        case .cvs: return "ExtraBucks"
        case .walgreens: return "Cash"
        case .starbucks: return "Stars"
        default: return "points"
        }
    }

    private func generateSimulatedPurchases(for retailer: RetailerAccount.Retailer, count: Int) -> [RetailerPurchase] {
        var purchases: [RetailerPurchase] = []

        let itemsByRetailer: [RetailerAccount.Retailer: [(name: String, price: Double, category: String)]] = [
            .amazon: [
                ("Echo Dot", 49.99, "Electronics"),
                ("USB-C Cable", 12.99, "Electronics"),
                ("Kitchen Towels", 15.99, "Home"),
                ("Protein Powder", 34.99, "Health"),
                ("Book", 14.99, "Books")
            ],
            .target: [
                ("Laundry Detergent", 12.99, "Home"),
                ("Snacks", 4.99, "Food"),
                ("T-Shirt", 19.99, "Clothing"),
                ("Shampoo", 8.99, "Personal Care"),
                ("Candle", 9.99, "Home")
            ],
            .walmart: [
                ("Groceries", 45.99, "Food"),
                ("Paper Towels", 15.99, "Home"),
                ("Dog Food", 29.99, "Pets"),
                ("Batteries", 12.99, "Electronics"),
                ("Cleaning Supplies", 8.99, "Home")
            ],
            .costco: [
                ("Bulk Snacks", 15.99, "Food"),
                ("Toilet Paper", 24.99, "Home"),
                ("Olive Oil", 18.99, "Food"),
                ("Vitamins", 29.99, "Health"),
                ("Gas", 55.00, "Auto")
            ]
        ]

        let items = itemsByRetailer[retailer] ?? itemsByRetailer[.amazon]!

        for i in 0..<count {
            let daysAgo = Int.random(in: 1...(365 * 2))
            let orderDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            let selectedItems = items.shuffled().prefix(Int.random(in: 1...3))
            let purchasedItems = selectedItems.map { item in
                PurchasedItem(
                    id: UUID().uuidString,
                    name: item.name,
                    brand: nil,
                    category: item.category,
                    quantity: Int.random(in: 1...3),
                    unitPrice: item.price,
                    totalPrice: item.price * Double(Int.random(in: 1...3)),
                    imageUrl: nil,
                    productUrl: nil,
                    asin: retailer == .amazon ? "B0\(String(format: "%08d", Int.random(in: 0...99999999)))" : nil,
                    upc: nil,
                    sku: nil,
                    tags: []
                )
            }

            let subtotal = purchasedItems.reduce(0) { $0 + $1.totalPrice }
            let tax = subtotal * 0.08

            purchases.append(RetailerPurchase(
                id: UUID().uuidString,
                orderId: "\(retailer.rawValue.uppercased())-\(String(format: "%06d", i))",
                retailer: retailer,
                orderDate: orderDate,
                items: Array(purchasedItems),
                subtotal: subtotal,
                tax: tax,
                shipping: retailer == .amazon ? (subtotal > 35 ? 0 : 5.99) : nil,
                total: subtotal + tax + (retailer == .amazon && subtotal <= 35 ? 5.99 : 0),
                paymentMethod: "Credit Card",
                deliveryDate: Calendar.current.date(byAdding: .day, value: Int.random(in: 2...7), to: orderDate),
                status: .delivered
            ))
        }

        return purchases.sorted { $0.orderDate > $1.orderDate }
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: accountsKey),
           let accounts = try? JSONDecoder().decode([RetailerAccount].self, from: data) {
            connectedAccounts = accounts
        }

        if let data = userDefaults.data(forKey: purchasesKey),
           let purchases = try? JSONDecoder().decode([RetailerPurchase].self, from: data) {
            allPurchases = purchases
        }

        if let data = userDefaults.data(forKey: importsKey),
           let imports = try? JSONDecoder().decode([DataImport].self, from: data) {
            dataImports = imports
        }
    }

    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(connectedAccounts) {
            userDefaults.set(data, forKey: accountsKey)
        }
    }

    private func savePurchases() {
        if let data = try? JSONEncoder().encode(allPurchases) {
            userDefaults.set(data, forKey: purchasesKey)
        }
    }

    private func saveImports() {
        if let data = try? JSONEncoder().encode(dataImports) {
            userDefaults.set(data, forKey: importsKey)
        }
    }
}

// MARK: - Errors

enum RetailerError: Error, LocalizedError {
    case connectionFailed
    case authenticationFailed
    case syncFailed
    case invalidDataFormat
    case unsupportedRetailer

    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "Failed to connect to retailer"
        case .authenticationFailed: return "Authentication failed"
        case .syncFailed: return "Failed to sync purchase history"
        case .invalidDataFormat: return "Invalid data format"
        case .unsupportedRetailer: return "Retailer not supported"
        }
    }
}
