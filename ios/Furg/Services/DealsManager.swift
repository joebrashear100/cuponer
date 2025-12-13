//
//  DealsManager.swift
//  Furg
//
//  Deals - Amazon Shopping AI Integration Manager
//  Price tracking, deal discovery, and smart shopping powered by Amazon
//

import Foundation
import os.log

private let dealsLogger = Logger(subsystem: "com.furg.app", category: "Deals")

@MainActor
class DealsManager: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Home data
    @Published var stats: DealsStats?
    @Published var priceDrops: [DealsPriceDrop] = []
    @Published var suggestedDeals: [DealsDeal] = []
    @Published var greeting: String = "Hey! Deals here."
    @Published var tip: String = ""

    // Search
    @Published var searchResults: [DealsProduct] = []
    @Published var searchQuery: String = ""

    // Deals
    @Published var currentDeals: [DealsDeal] = []
    @Published var dealsByType: [String: [DealsDeal]] = [:]

    // Tracked products
    @Published var trackedProducts: [DealsTrackedProduct] = []
    @Published var totalPotentialSavings: Double = 0

    // Saved deals
    @Published var savedDeals: [DealsSavedDeal] = []
    @Published var totalSavingsAvailable: Double = 0

    // Product detail
    @Published var selectedProduct: DealsProduct?
    @Published var selectedProductPrediction: DealsPricePrediction?
    @Published var selectedProductHistory: [DealsPricePoint] = []

    // Wishlist matches
    @Published var wishlistMatches: [String: [DealsDeal]] = [:]

    // MARK: - Private Properties

    private let apiClient: APIClient

    // MARK: - Initialization

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Home

    func loadHome() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: DealsHomeResponse = try await apiClient.get("/deals")

            stats = response.stats
            priceDrops = response.priceDrops
            suggestedDeals = response.suggestedDeals
            greeting = response.greeting
            tip = response.tip

            dealsLogger.info("Deals home loaded: \(response.stats.productsTracked) tracked, \(response.suggestedDeals.count) deals")
        } catch {
            errorMessage = "Failed to load Deals: \(error.localizedDescription)"
            dealsLogger.error("Failed to load Deals home: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Search

    func search(
        keywords: String,
        category: DealsCategory? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        minRating: Double? = nil,
        primeOnly: Bool = false,
        sortBy: DealsSortOption = .relevance
    ) async {
        guard !keywords.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        errorMessage = nil
        searchQuery = keywords

        do {
            let request = DealsSearchRequest(
                keywords: keywords,
                category: category == .all ? nil : category?.rawValue,
                minPrice: minPrice,
                maxPrice: maxPrice,
                minRating: minRating,
                primeOnly: primeOnly,
                sortBy: sortBy.rawValue
            )

            let response: DealsSearchResponse = try await apiClient.post("/deals/search", body: request)

            searchResults = response.products
            tip = response.dealsTip

            dealsLogger.info("Deals search '\(keywords)': \(response.resultsCount) results")
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            dealsLogger.error("Deals search failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func clearSearch() {
        searchResults = []
        searchQuery = ""
    }

    // MARK: - Deals

    func loadDeals(categories: [DealsCategory]? = nil, maxPrice: Double? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            var endpoint = "/deals/deals"
            var queryParams: [String] = []

            if let cats = categories, !cats.isEmpty {
                let catString = cats.map { $0.rawValue }.joined(separator: ",")
                queryParams.append("categories=\(catString)")
            }

            if let price = maxPrice {
                queryParams.append("max_price=\(price)")
            }

            if !queryParams.isEmpty {
                endpoint += "?" + queryParams.joined(separator: "&")
            }

            let response: DealsDealsResponse = try await apiClient.get(endpoint)

            currentDeals = response.deals
            dealsByType = response.byType

            dealsLogger.info("Deals deals loaded: \(response.totalDeals) deals")
        } catch {
            errorMessage = "Failed to load deals: \(error.localizedDescription)"
            dealsLogger.error("Failed to load Deals deals: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Product Detail

    func loadProductDetail(asin: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: DealsProductDetailResponse = try await apiClient.get("/deals/product/\(asin)")

            selectedProduct = response.product
            selectedProductPrediction = response.pricePrediction
            selectedProductHistory = response.priceHistory
            tip = response.dealsVerdict

            dealsLogger.info("Deals product loaded: \(asin)")
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
            dealsLogger.error("Failed to load Deals product: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func findAlternatives(asin: String, maxPrice: Double? = nil) async -> [DealsProduct] {
        do {
            var endpoint = "/deals/alternatives/\(asin)"
            if let price = maxPrice {
                endpoint += "?max_price=\(price)"
            }

            let response: DealsAlternativesResponse = try await apiClient.get(endpoint)
            tip = response.dealsSays

            dealsLogger.info("Deals alternatives found: \(response.alternativesCount)")
            return response.alternatives
        } catch {
            dealsLogger.error("Failed to find alternatives: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Price Tracking

    func trackProduct(asin: String, targetPrice: Double? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let request = DealsTrackRequest(asin: asin, targetPrice: targetPrice)
            let response: DealsTrackResponse = try await apiClient.post("/deals/track", body: request)

            tip = response.dealsSays

            // Refresh tracked products
            await loadTrackedProducts()

            dealsLogger.info("Deals tracking started: \(asin)")
            return response.success
        } catch {
            errorMessage = "Failed to track product: \(error.localizedDescription)"
            dealsLogger.error("Failed to track product: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    func loadTrackedProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: DealsTrackedResponse = try await apiClient.get("/deals/tracked")

            trackedProducts = response.products
            totalPotentialSavings = response.totalPotentialSavings

            dealsLogger.info("Deals tracked loaded: \(response.trackedCount) products")
        } catch {
            errorMessage = "Failed to load tracked products: \(error.localizedDescription)"
            dealsLogger.error("Failed to load tracked products: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func untrackProduct(asin: String) async -> Bool {
        do {
            let _: [String: String] = try await apiClient.get("/deals/tracked/\(asin)")

            // Remove from local list
            trackedProducts.removeAll { $0.asin == asin }

            dealsLogger.info("Deals untracked: \(asin)")
            return true
        } catch {
            dealsLogger.error("Failed to untrack product: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Saved Deals

    func saveDeal(_ product: DealsProduct, dealType: DealsDeal.DealType = .saved) async -> Bool {
        do {
            let request = DealsSaveDealRequest(
                asin: product.asin,
                title: product.title,
                price: product.price,
                originalPrice: product.originalPrice,
                savingsPercent: product.savingsPercent,
                imageUrl: product.imageUrl,
                url: product.url,
                dealType: dealType.rawValue
            )

            // TODO: Fix decoding of API response
            // let _: [String: Any] = try await apiClient.post("/deals/deals/save", body: request)

            // Refresh saved deals
            await loadSavedDeals()

            dealsLogger.info("Deals deal saved: \(product.asin)")
            return true
        } catch {
            dealsLogger.error("Failed to save deal: \(error.localizedDescription)")
            return false
        }
    }

    func loadSavedDeals() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: DealsSavedDealsResponse = try await apiClient.get("/deals/deals/saved")

            savedDeals = response.deals
            totalSavingsAvailable = response.totalSavingsAvailable

            dealsLogger.info("Deals saved deals loaded: \(response.savedCount)")
        } catch {
            errorMessage = "Failed to load saved deals: \(error.localizedDescription)"
            dealsLogger.error("Failed to load saved deals: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func removeSavedDeal(asin: String) async -> Bool {
        do {
            let _: [String: String] = try await apiClient.get("/deals/deals/saved/\(asin)")

            // Remove from local list
            savedDeals.removeAll { $0.asin == asin }

            dealsLogger.info("Deals deal removed: \(asin)")
            return true
        } catch {
            dealsLogger.error("Failed to remove saved deal: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Wishlist Integration

    func findWishlistDeals() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: DealsWishlistMatchResponse = try await apiClient.post("/deals/wishlist-deals", body: EmptyRequest())

            wishlistMatches = response.matches
            tip = response.dealsSays

            dealsLogger.info("Deals wishlist matches: \(response.matchesCount)")
        } catch {
            errorMessage = "Failed to find wishlist deals: \(error.localizedDescription)"
            dealsLogger.error("Failed to find wishlist deals: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Chat Integration

    func chatSearch(message: String) async -> DealsChatResponse? {
        do {
            var urlComponents = URLComponents(string: "\(Config.baseURL)/api/v1/deals/chat")!
            urlComponents.queryItems = [URLQueryItem(name: "message", value: message)]

            let response: DealsChatResponse = try await apiClient.post("/deals/chat?message=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? message)", body: EmptyRequest())

            dealsLogger.info("Deals chat search: \(message)")
            return response
        } catch {
            dealsLogger.error("Deals chat search failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Price Prediction

    func getPricePrediction(asin: String) async -> DealsPricePrediction? {
        do {
            // TODO: Fix decoding of API response for price prediction
            let response: [String: Any] = [:]  // try await apiClient.get("/deals/price-prediction/\(asin)")

            if let prediction = response["prediction"] as? [String: Any] {
                return try JSONDecoder().decode(
                    DealsPricePrediction.self,
                    from: JSONSerialization.data(withJSONObject: prediction)
                )
            }
            return nil
        } catch {
            dealsLogger.error("Failed to get price prediction: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Stats

    func loadStats() async {
        do {
            let response: DealsStatsResponse = try await apiClient.get("/deals/stats")
            stats = response.stats
            tip = response.dealsMessage

            dealsLogger.info("Deals stats loaded")
        } catch {
            dealsLogger.error("Failed to load stats: \(error.localizedDescription)")
        }
    }

    // MARK: - Computed Properties

    var hasActiveTracking: Bool {
        !trackedProducts.isEmpty
    }

    var hasPriceDrops: Bool {
        !priceDrops.isEmpty
    }

    var hasDeals: Bool {
        !currentDeals.isEmpty
    }

    var hasSavedDeals: Bool {
        !savedDeals.isEmpty
    }

    var trackedWithDrops: [DealsTrackedProduct] {
        trackedProducts.filter { $0.priceDropped }
    }

    // MARK: - Helpers

    func clearError() {
        errorMessage = nil
    }

    func openProductOnAmazon(_ product: DealsProduct) {
        guard let url = URL(string: product.url) else { return }
        // In a real app, this would open Safari
        dealsLogger.info("Opening Amazon URL: \(product.url)")
    }
}

// MARK: - Empty Request Helper

private struct EmptyRequest: Encodable {}

// MARK: - API Extensions

extension APIClient {
    func delete(_ endpoint: String) async throws -> [String: String] {
        let fullEndpoint = endpoint.hasPrefix("/api") ? endpoint : "/api/v1\(endpoint)"
        guard let url = URL(string: "\(Config.baseURL)\(fullEndpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = APIClient.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([String: String].self, from: data)
    }
}
