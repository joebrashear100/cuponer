//
//  RufusManager.swift
//  Furg
//
//  Rufus - Amazon Shopping AI Integration Manager
//  Price tracking, deal discovery, and smart shopping powered by Amazon
//

import Foundation
import os.log

private let rufusLogger = Logger(subsystem: "com.furg.app", category: "Rufus")

@MainActor
class RufusManager: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Home data
    @Published var stats: RufusStats?
    @Published var priceDrops: [RufusPriceDrop] = []
    @Published var suggestedDeals: [RufusDeal] = []
    @Published var greeting: String = "Hey! Rufus here."
    @Published var tip: String = ""

    // Search
    @Published var searchResults: [RufusProduct] = []
    @Published var searchQuery: String = ""

    // Deals
    @Published var currentDeals: [RufusDeal] = []
    @Published var dealsByType: [String: [RufusDeal]] = [:]

    // Tracked products
    @Published var trackedProducts: [RufusTrackedProduct] = []
    @Published var totalPotentialSavings: Double = 0

    // Saved deals
    @Published var savedDeals: [RufusSavedDeal] = []
    @Published var totalSavingsAvailable: Double = 0

    // Product detail
    @Published var selectedProduct: RufusProduct?
    @Published var selectedProductPrediction: RufusPricePrediction?
    @Published var selectedProductHistory: [RufusPricePoint] = []

    // Wishlist matches
    @Published var wishlistMatches: [String: [RufusDeal]] = [:]

    // MARK: - Private Properties

    private let apiClient: APIClient

    // MARK: - Initialization

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Home

    func loadHome() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: RufusHomeResponse = try await apiClient.get("/rufus")

            stats = response.stats
            priceDrops = response.priceDrops
            suggestedDeals = response.suggestedDeals
            greeting = response.greeting
            tip = response.tip

            rufusLogger.info("Rufus home loaded: \(response.stats.productsTracked) tracked, \(response.suggestedDeals.count) deals")
        } catch {
            errorMessage = "Failed to load Rufus: \(error.localizedDescription)"
            rufusLogger.error("Failed to load Rufus home: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Search

    func search(
        keywords: String,
        category: RufusCategory? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        minRating: Double? = nil,
        primeOnly: Bool = false,
        sortBy: RufusSortOption = .relevance
    ) async {
        guard !keywords.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        errorMessage = nil
        searchQuery = keywords

        do {
            let request = RufusSearchRequest(
                keywords: keywords,
                category: category == .all ? nil : category?.rawValue,
                minPrice: minPrice,
                maxPrice: maxPrice,
                minRating: minRating,
                primeOnly: primeOnly,
                sortBy: sortBy.rawValue
            )

            let response: RufusSearchResponse = try await apiClient.post("/rufus/search", body: request)

            searchResults = response.products
            tip = response.rufusTip

            rufusLogger.info("Rufus search '\(keywords)': \(response.resultsCount) results")
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            rufusLogger.error("Rufus search failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func clearSearch() {
        searchResults = []
        searchQuery = ""
    }

    // MARK: - Deals

    func loadDeals(categories: [RufusCategory]? = nil, maxPrice: Double? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            var endpoint = "/rufus/deals"
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

            let response: RufusDealsResponse = try await apiClient.get(endpoint)

            currentDeals = response.deals
            dealsByType = response.byType

            rufusLogger.info("Rufus deals loaded: \(response.totalDeals) deals")
        } catch {
            errorMessage = "Failed to load deals: \(error.localizedDescription)"
            rufusLogger.error("Failed to load Rufus deals: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Product Detail

    func loadProductDetail(asin: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: RufusProductDetailResponse = try await apiClient.get("/rufus/product/\(asin)")

            selectedProduct = response.product
            selectedProductPrediction = response.pricePrediction
            selectedProductHistory = response.priceHistory
            tip = response.rufusVerdict

            rufusLogger.info("Rufus product loaded: \(asin)")
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
            rufusLogger.error("Failed to load Rufus product: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func findAlternatives(asin: String, maxPrice: Double? = nil) async -> [RufusProduct] {
        do {
            var endpoint = "/rufus/alternatives/\(asin)"
            if let price = maxPrice {
                endpoint += "?max_price=\(price)"
            }

            let response: RufusAlternativesResponse = try await apiClient.get(endpoint)
            tip = response.rufusSays

            rufusLogger.info("Rufus alternatives found: \(response.alternativesCount)")
            return response.alternatives
        } catch {
            rufusLogger.error("Failed to find alternatives: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Price Tracking

    func trackProduct(asin: String, targetPrice: Double? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let request = RufusTrackRequest(asin: asin, targetPrice: targetPrice)
            let response: RufusTrackResponse = try await apiClient.post("/rufus/track", body: request)

            tip = response.rufusSays

            // Refresh tracked products
            await loadTrackedProducts()

            rufusLogger.info("Rufus tracking started: \(asin)")
            return response.success
        } catch {
            errorMessage = "Failed to track product: \(error.localizedDescription)"
            rufusLogger.error("Failed to track product: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    func loadTrackedProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: RufusTrackedResponse = try await apiClient.get("/rufus/tracked")

            trackedProducts = response.products
            totalPotentialSavings = response.totalPotentialSavings

            rufusLogger.info("Rufus tracked loaded: \(response.trackedCount) products")
        } catch {
            errorMessage = "Failed to load tracked products: \(error.localizedDescription)"
            rufusLogger.error("Failed to load tracked products: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func untrackProduct(asin: String) async -> Bool {
        do {
            let _: [String: String] = try await apiClient.get("/rufus/tracked/\(asin)")

            // Remove from local list
            trackedProducts.removeAll { $0.asin == asin }

            rufusLogger.info("Rufus untracked: \(asin)")
            return true
        } catch {
            rufusLogger.error("Failed to untrack product: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Saved Deals

    func saveDeal(_ product: RufusProduct, dealType: RufusDeal.DealType = .saved) async -> Bool {
        do {
            let request = RufusSaveDealRequest(
                asin: product.asin,
                title: product.title,
                price: product.price,
                originalPrice: product.originalPrice,
                savingsPercent: product.savingsPercent,
                imageUrl: product.imageUrl,
                url: product.url,
                dealType: dealType.rawValue
            )

            let _: [String: Any] = try await apiClient.post("/rufus/deals/save", body: request)

            // Refresh saved deals
            await loadSavedDeals()

            rufusLogger.info("Rufus deal saved: \(product.asin)")
            return true
        } catch {
            rufusLogger.error("Failed to save deal: \(error.localizedDescription)")
            return false
        }
    }

    func loadSavedDeals() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: RufusSavedDealsResponse = try await apiClient.get("/rufus/deals/saved")

            savedDeals = response.deals
            totalSavingsAvailable = response.totalSavingsAvailable

            rufusLogger.info("Rufus saved deals loaded: \(response.savedCount)")
        } catch {
            errorMessage = "Failed to load saved deals: \(error.localizedDescription)"
            rufusLogger.error("Failed to load saved deals: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func removeSavedDeal(asin: String) async -> Bool {
        do {
            let _: [String: String] = try await apiClient.get("/rufus/deals/saved/\(asin)")

            // Remove from local list
            savedDeals.removeAll { $0.asin == asin }

            rufusLogger.info("Rufus deal removed: \(asin)")
            return true
        } catch {
            rufusLogger.error("Failed to remove saved deal: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Wishlist Integration

    func findWishlistDeals() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: RufusWishlistMatchResponse = try await apiClient.post("/rufus/wishlist-deals", body: EmptyRequest())

            wishlistMatches = response.matches
            tip = response.rufusSays

            rufusLogger.info("Rufus wishlist matches: \(response.matchesCount)")
        } catch {
            errorMessage = "Failed to find wishlist deals: \(error.localizedDescription)"
            rufusLogger.error("Failed to find wishlist deals: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Chat Integration

    func chatSearch(message: String) async -> RufusChatResponse? {
        do {
            var urlComponents = URLComponents(string: "\(Config.baseURL)/api/v1/rufus/chat")!
            urlComponents.queryItems = [URLQueryItem(name: "message", value: message)]

            let response: RufusChatResponse = try await apiClient.post("/rufus/chat?message=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? message)", body: EmptyRequest())

            rufusLogger.info("Rufus chat search: \(message)")
            return response
        } catch {
            rufusLogger.error("Rufus chat search failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Price Prediction

    func getPricePrediction(asin: String) async -> RufusPricePrediction? {
        do {
            let response: [String: Any] = try await apiClient.get("/rufus/price-prediction/\(asin)")

            if let prediction = response["prediction"] as? [String: Any] {
                return try JSONDecoder().decode(
                    RufusPricePrediction.self,
                    from: JSONSerialization.data(withJSONObject: prediction)
                )
            }
            return nil
        } catch {
            rufusLogger.error("Failed to get price prediction: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Stats

    func loadStats() async {
        do {
            let response: RufusStatsResponse = try await apiClient.get("/rufus/stats")
            stats = response.stats
            tip = response.rufusMessage

            rufusLogger.info("Rufus stats loaded")
        } catch {
            rufusLogger.error("Failed to load stats: \(error.localizedDescription)")
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

    var trackedWithDrops: [RufusTrackedProduct] {
        trackedProducts.filter { $0.priceDropped }
    }

    // MARK: - Helpers

    func clearError() {
        errorMessage = nil
    }

    func openProductOnAmazon(_ product: RufusProduct) {
        guard let url = URL(string: product.url) else { return }
        // In a real app, this would open Safari
        rufusLogger.info("Opening Amazon URL: \(product.url)")
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
