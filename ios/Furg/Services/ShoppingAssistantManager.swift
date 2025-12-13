//
//  ShoppingAssistantManager.swift
//  Furg
//
//  AI-powered shopping assistant with ChatGPT-style shopping mode.
//  Provides conversational product search, deal discovery, and smart recommendations.
//

import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "ShoppingAssistant")

// MARK: - Shopping Assistant Models

struct ShoppingChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var actions: [String]?
    var productResults: [ProductResult]?
    var dealResults: [DealResult]?
    var priceComparison: PriceComparisonResult?

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct ProductResult: Identifiable, Codable {
    let id: String
    let name: String
    let price: Double
    let originalPrice: Double?
    let discountPercent: Int?
    let rating: Double
    let reviews: Int
    let retailer: String
    let inStock: Bool
    let url: String?

    var hasDiscount: Bool {
        return discountPercent != nil && discountPercent! > 0
    }

    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }

    var formattedOriginalPrice: String? {
        guard let original = originalPrice else { return nil }
        return String(format: "$%.2f", original)
    }
}

struct DealResult: Identifiable, Codable {
    let id: String
    let retailer: String
    let title: String
    let code: String?
    let discountType: String
    let discountValue: Double
    let categories: [String]
    let expires: String?
    let minPurchase: Double?

    var formattedDiscount: String {
        switch discountType {
        case "percent_off":
            return "\(Int(discountValue))% off"
        case "dollar_off":
            return String(format: "$%.0f off", discountValue)
        case "cashback":
            return "\(Int(discountValue))% cashback"
        case "bogo":
            return "BOGO \(Int(discountValue))% off"
        case "free_shipping":
            return "Free Shipping"
        default:
            return "\(Int(discountValue))% off"
        }
    }
}

struct PriceComparisonResult: Codable {
    let product: String
    let comparisons: [RetailerPrice]
    let bestDeal: RetailerPrice?
    let averagePrice: Double
    let potentialSavings: Double

    struct RetailerPrice: Identifiable, Codable {
        var id: String { retailer }
        let retailer: String
        let price: Double
        let inStock: Bool
        let shipping: String
        let deliveryDays: Int
        let condition: String

        var formattedPrice: String {
            return String(format: "$%.2f", price)
        }
    }
}

struct ShoppingRecommendation: Identifiable, Codable {
    let id: String
    let name: String
    let price: Double
    let why: String
    let rating: Double
    let matchScore: Int

    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }
}

struct CreditCardRecommendation: Codable {
    let merchant: String
    let amount: Double?
    let bestCard: CardOption
    let allOptions: [CardOption]
    let recommendation: String

    struct CardOption: Identifiable, Codable {
        var id: String { name }
        let name: String
        let categoryMatch: String
        let multiplier: Int
        let rewardType: String
        let estimatedValue: Double

        var formattedValue: String {
            return String(format: "$%.2f", estimatedValue)
        }
    }
}

struct LoyaltyPointsResult: Codable {
    let programs: [LoyaltyProgram]
    let totalPointsValue: Double
    let tip: String?

    struct LoyaltyProgram: Identifiable, Codable {
        var id: String { retailer }
        let retailer: String
        let program: String
        let points: Int
        let value: Double

        var formattedValue: String {
            return String(format: "$%.2f", value)
        }
    }
}

struct ReorderSuggestion: Identifiable, Codable {
    let id: String
    let item: String
    let lastPurchased: String
    let typicalInterval: String
    let suggestedDate: String
    let bestPrice: BestPrice

    struct BestPrice: Codable {
        let retailer: String
        let price: Double

        var formattedPrice: String {
            return String(format: "$%.2f", price)
        }
    }
}

// MARK: - API Response Models

struct ShoppingChatResponse: Codable {
    let message: String
    let actions: [String]?
    let functionResults: [[String: AnyCodable]]?
    let tokensUsed: TokenUsage?

    struct TokenUsage: Codable {
        let input: Int
        let output: Int
    }

    enum CodingKeys: String, CodingKey {
        case message
        case actions
        case functionResults = "function_results"
        case tokensUsed = "tokens_used"
    }
}

struct ProductSearchResponse: Codable {
    let query: String
    let totalResults: Int
    let products: [ProductResult]

    enum CodingKeys: String, CodingKey {
        case query
        case totalResults = "total_results"
        case products
    }
}

struct DealSearchResponse: Codable {
    let query: String
    let dealsFound: Int
    let deals: [DealResult]

    enum CodingKeys: String, CodingKey {
        case query
        case dealsFound = "deals_found"
        case deals
    }
}

struct RecommendationsResponse: Codable {
    let recommendations: [ShoppingRecommendation]
    let basedOn: [String]
    let category: String?
    let budget: Double?

    enum CodingKeys: String, CodingKey {
        case recommendations
        case basedOn = "based_on"
        case category
        case budget
    }
}

struct ReorderSuggestionsResponse: Codable {
    let suggestions: [ReorderSuggestion]
    let daysAhead: Int
    let estimatedSpend: Double

    enum CodingKeys: String, CodingKey {
        case suggestions
        case daysAhead = "days_ahead"
        case estimatedSpend = "estimated_spend"
    }
}

// Helper for dynamic JSON decoding
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Shopping Assistant Manager

@MainActor
class ShoppingAssistantManager: ObservableObject {
    static let shared = ShoppingAssistantManager()

    // MARK: - Published Properties

    @Published var messages: [ShoppingChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Recent results for quick access
    @Published var recentProducts: [ProductResult] = []
    @Published var recentDeals: [DealResult] = []
    @Published var recommendations: [ShoppingRecommendation] = []
    @Published var cardRecommendation: CreditCardRecommendation?
    @Published var loyaltyPoints: LoyaltyPointsResult?
    @Published var reorderSuggestions: [ReorderSuggestion] = []

    // MARK: - Private Properties

    private let baseURL: String

    // MARK: - Initialization

    init() {
        self.baseURL = Config.baseURL

        // Add welcome message
        let welcomeMessage = ShoppingChatMessage(
            role: .assistant,
            content: """
            Hey! I'm your shopping assistant. I can help you:

            - Find products and compare prices
            - Discover deals and coupons
            - Track price drops
            - Recommend the best credit card for purchases
            - Manage your shopping list

            Try asking: "Find running shoes under $100" or "What deals are at Target?"
            """
        )
        messages.append(welcomeMessage)
    }

    // MARK: - Chat Interface

    /// Send a message to the shopping assistant
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Add user message
        let userMessage = ShoppingChatMessage(role: .user, content: text)
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            let response = try await chatWithAssistant(message: text)

            // Create assistant message with any results
            var assistantMessage = ShoppingChatMessage(
                role: .assistant,
                content: response.message
            )
            assistantMessage.actions = response.actions

            // Parse function results if any
            if let results = response.functionResults {
                for result in results {
                    await parseFunctionResult(result, into: &assistantMessage)
                }
            }

            messages.append(assistantMessage)

        } catch {
            logger.error("Shopping chat error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription

            let errorMessage = ShoppingChatMessage(
                role: .assistant,
                content: "Sorry, I had trouble with that request. Please try again."
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    /// Clear chat history
    func clearHistory() {
        messages.removeAll()

        // Re-add welcome message
        let welcomeMessage = ShoppingChatMessage(
            role: .assistant,
            content: "Chat cleared. How can I help you shop smarter today?"
        )
        messages.append(welcomeMessage)

        // Clear server-side history
        Task {
            try? await clearServerHistory()
        }
    }

    // MARK: - Direct API Methods

    /// Search for products
    func searchProducts(
        query: String,
        category: String? = nil,
        maxPrice: Double? = nil,
        minPrice: Double? = nil,
        sortBy: String = "relevance",
        limit: Int = 10
    ) async throws -> [ProductResult] {
        let endpoint = "/api/v1/shopping/search"

        var body: [String: Any] = [
            "query": query,
            "sort_by": sortBy,
            "limit": limit
        ]

        if let category = category { body["category"] = category }
        if let maxPrice = maxPrice { body["max_price"] = maxPrice }
        if let minPrice = minPrice { body["min_price"] = minPrice }

        let response: ProductSearchResponse = try await post(endpoint, body: body)
        recentProducts = response.products
        return response.products
    }

    /// Find deals and coupons
    func findDeals(
        query: String,
        retailer: String? = nil,
        discountType: String? = nil,
        minDiscount: Double? = nil
    ) async throws -> [DealResult] {
        let endpoint = "/api/v1/shopping/deals"

        var body: [String: Any] = ["query": query]
        if let retailer = retailer { body["retailer"] = retailer }
        if let discountType = discountType { body["discount_type"] = discountType }
        if let minDiscount = minDiscount { body["min_discount"] = minDiscount }

        let response: DealSearchResponse = try await post(endpoint, body: body)
        recentDeals = response.deals
        return response.deals
    }

    /// Compare prices across retailers
    func comparePrices(
        productName: String,
        includeUsed: Bool = false
    ) async throws -> PriceComparisonResult {
        let endpoint = "/api/v1/shopping/compare"

        let body: [String: Any] = [
            "product_name": productName,
            "include_used": includeUsed
        ]

        return try await post(endpoint, body: body)
    }

    /// Get product recommendations
    func getRecommendations(
        category: String? = nil,
        budget: Double? = nil,
        useCase: String? = nil
    ) async throws -> [ShoppingRecommendation] {
        var endpoint = "/api/v1/shopping/recommendations?"

        var params: [String] = []
        if let category = category { params.append("category=\(category)") }
        if let budget = budget { params.append("budget=\(budget)") }
        if let useCase = useCase { params.append("use_case=\(useCase)") }

        endpoint += params.joined(separator: "&")

        let response: RecommendationsResponse = try await get(endpoint)
        recommendations = response.recommendations
        return response.recommendations
    }

    /// Find the best credit card for a purchase
    func findBestCard(
        merchant: String,
        amount: Double? = nil
    ) async throws -> CreditCardRecommendation {
        var endpoint = "/api/v1/shopping/best-card?merchant=\(merchant.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? merchant)"

        if let amount = amount {
            endpoint += "&amount=\(amount)"
        }

        let response: CreditCardRecommendation = try await get(endpoint)
        cardRecommendation = response
        return response
    }

    /// Check loyalty points balance
    func checkLoyaltyPoints(retailer: String? = nil) async throws -> LoyaltyPointsResult {
        var endpoint = "/api/v1/shopping/loyalty-points"
        if let retailer = retailer {
            endpoint += "?retailer=\(retailer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? retailer)"
        }

        let response: LoyaltyPointsResult = try await get(endpoint)
        loyaltyPoints = response
        return response
    }

    /// Get reorder suggestions
    func getReorderSuggestions(daysAhead: Int = 7) async throws -> [ReorderSuggestion] {
        let endpoint = "/api/v1/shopping/reorder-suggestions?days_ahead=\(daysAhead)"

        let response: ReorderSuggestionsResponse = try await get(endpoint)
        reorderSuggestions = response.suggestions
        return response.suggestions
    }

    /// Create a price alert
    func createPriceAlert(productName: String, targetPrice: Double) async throws {
        let endpoint = "/api/v1/shopping/price-alert"

        let body: [String: Any] = [
            "product_name": productName,
            "target_price": targetPrice
        ]

        let _: [String: AnyCodable] = try await post(endpoint, body: body)
    }

    /// Add item to shopping list
    func addToShoppingList(
        itemName: String,
        quantity: Int = 1,
        category: String? = nil,
        targetPrice: Double? = nil,
        preferredStore: String? = nil,
        notes: String? = nil
    ) async throws {
        let endpoint = "/api/v1/shopping/list"

        var body: [String: Any] = [
            "item_name": itemName,
            "quantity": quantity
        ]

        if let category = category { body["category"] = category }
        if let targetPrice = targetPrice { body["target_price"] = targetPrice }
        if let preferredStore = preferredStore { body["preferred_store"] = preferredStore }
        if let notes = notes { body["notes"] = notes }

        let _: [String: AnyCodable] = try await post(endpoint, body: body)
    }

    // MARK: - Private Methods

    private func chatWithAssistant(message: String) async throws -> ShoppingChatResponse {
        let endpoint = "/api/v1/shopping/chat"

        let body: [String: Any] = [
            "message": message,
            "include_context": true
        ]

        return try await post(endpoint, body: body)
    }

    private func clearServerHistory() async throws {
        let endpoint = "/api/v1/shopping/chat/history"

        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = APIClient.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    private func parseFunctionResult(_ result: [String: AnyCodable], into message: inout ShoppingChatMessage) async {
        // Extract function name and results
        guard let functionName = result["function"]?.value as? String else { return }

        switch functionName {
        case "search_products":
            if let resultData = result["result"]?.value as? [String: Any],
               let products = resultData["products"] as? [[String: Any]] {
                message.productResults = products.compactMap { parseProduct($0) }
                recentProducts = message.productResults ?? []
            }

        case "find_deals":
            if let resultData = result["result"]?.value as? [String: Any],
               let deals = resultData["deals"] as? [[String: Any]] {
                message.dealResults = deals.compactMap { parseDeal($0) }
                recentDeals = message.dealResults ?? []
            }

        case "compare_prices":
            if let resultData = result["result"]?.value as? [String: Any] {
                message.priceComparison = parsePriceComparison(resultData)
            }

        default:
            break
        }
    }

    private func parseProduct(_ dict: [String: Any]) -> ProductResult? {
        guard let name = dict["name"] as? String,
              let price = dict["price"] as? Double,
              let retailer = dict["retailer"] as? String else {
            return nil
        }

        return ProductResult(
            id: UUID().uuidString,
            name: name,
            price: price,
            originalPrice: dict["original_price"] as? Double,
            discountPercent: dict["discount_percent"] as? Int,
            rating: dict["rating"] as? Double ?? 0,
            reviews: dict["reviews"] as? Int ?? 0,
            retailer: retailer,
            inStock: dict["in_stock"] as? Bool ?? true,
            url: dict["url"] as? String
        )
    }

    private func parseDeal(_ dict: [String: Any]) -> DealResult? {
        guard let retailer = dict["retailer"] as? String,
              let title = dict["title"] as? String,
              let discountType = dict["discount_type"] as? String,
              let discountValue = dict["discount_value"] as? Double else {
            return nil
        }

        return DealResult(
            id: UUID().uuidString,
            retailer: retailer,
            title: title,
            code: dict["code"] as? String,
            discountType: discountType,
            discountValue: discountValue,
            categories: dict["categories"] as? [String] ?? [],
            expires: dict["expires"] as? String,
            minPurchase: dict["min_purchase"] as? Double
        )
    }

    private func parsePriceComparison(_ dict: [String: Any]) -> PriceComparisonResult? {
        guard let product = dict["product"] as? String,
              let comparisons = dict["comparisons"] as? [[String: Any]] else {
            return nil
        }

        let parsedComparisons = comparisons.compactMap { comp -> PriceComparisonResult.RetailerPrice? in
            guard let retailer = comp["retailer"] as? String,
                  let price = comp["price"] as? Double else {
                return nil
            }

            return PriceComparisonResult.RetailerPrice(
                retailer: retailer,
                price: price,
                inStock: comp["in_stock"] as? Bool ?? true,
                shipping: comp["shipping"] as? String ?? "Unknown",
                deliveryDays: comp["delivery_days"] as? Int ?? 0,
                condition: comp["condition"] as? String ?? "New"
            )
        }

        let bestDealDict = dict["best_deal"] as? [String: Any]
        let bestDeal: PriceComparisonResult.RetailerPrice? = bestDealDict.flatMap { bd in
            guard let retailer = bd["retailer"] as? String,
                  let price = bd["price"] as? Double else { return nil }
            return PriceComparisonResult.RetailerPrice(
                retailer: retailer,
                price: price,
                inStock: bd["in_stock"] as? Bool ?? true,
                shipping: bd["shipping"] as? String ?? "Unknown",
                deliveryDays: bd["delivery_days"] as? Int ?? 0,
                condition: bd["condition"] as? String ?? "New"
            )
        }

        return PriceComparisonResult(
            product: product,
            comparisons: parsedComparisons,
            bestDeal: bestDeal,
            averagePrice: dict["average_price"] as? Double ?? 0,
            potentialSavings: dict["potential_savings"] as? Double ?? 0
        )
    }

    // MARK: - Network Helpers

    private func get<T: Decodable>(_ endpoint: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = APIClient.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            logger.error("API error: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ endpoint: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = APIClient.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            logger.error("API error: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Quick Access Extensions

extension ShoppingAssistantManager {
    /// Quick search shortcut
    func quickSearch(_ query: String) async {
        await sendMessage("Find \(query)")
    }

    /// Quick deal search shortcut
    func quickFindDeals(at retailer: String) async {
        await sendMessage("What deals are available at \(retailer)?")
    }

    /// Quick price compare shortcut
    func quickCompare(_ product: String) async {
        await sendMessage("Compare prices for \(product)")
    }

    /// Quick card recommendation
    func quickCardRecommendation(for merchant: String, amount: Double? = nil) async {
        if let amount = amount {
            await sendMessage("What card should I use to spend $\(Int(amount)) at \(merchant)?")
        } else {
            await sendMessage("What card should I use at \(merchant)?")
        }
    }
}
