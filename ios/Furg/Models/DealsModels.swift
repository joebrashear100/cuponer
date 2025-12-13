//
//  DealsModels.swift
//  Furg
//
//  Models for Deals - Amazon Shopping AI Integration
//  Price tracking, deal discovery, and smart shopping assistance
//

import Foundation

// MARK: - Amazon Product

struct DealsProduct: Identifiable, Codable, Equatable {
    let asin: String
    let title: String
    let price: Double
    let originalPrice: Double?
    let currency: String
    let imageUrl: String?
    let url: String
    let rating: Double?
    let reviewCount: Int?
    let isPrime: Bool
    let dealBadge: String?
    let savingsPercent: Double?
    let category: String?
    let availability: String

    var id: String { asin }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var formattedOriginalPrice: String? {
        guard let original = originalPrice else { return nil }
        return String(format: "$%.2f", original)
    }

    var formattedSavings: String? {
        guard let percent = savingsPercent else { return nil }
        return String(format: "%.0f%% off", percent)
    }

    var savingsAmount: Double? {
        guard let original = originalPrice else { return nil }
        return original - price
    }

    enum CodingKeys: String, CodingKey {
        case asin, title, price, currency, url, rating, category, availability
        case originalPrice = "original_price"
        case imageUrl = "image_url"
        case reviewCount = "review_count"
        case isPrime = "is_prime"
        case dealBadge = "deal_badge"
        case savingsPercent = "savings_percent"
    }
}

// MARK: - Deals Deal

struct DealsDeal: Identifiable, Codable {
    let product: DealsProduct
    let dealType: DealType
    let expiresAt: Date?
    let matchReason: String
    let savingsAmount: Double
    let relevanceScore: Double

    var id: String { product.asin }

    enum DealType: String, Codable, CaseIterable {
        case lightning = "lightning"
        case daily = "daily"
        case prime = "prime"
        case priceDrop = "price_drop"
        case wishlistMatch = "wishlist_match"
        case holiday = "holiday"
        case saved = "saved"

        var label: String {
            switch self {
            case .lightning: return "Lightning Deal"
            case .daily: return "Daily Deal"
            case .prime: return "Prime Deal"
            case .priceDrop: return "Price Drop"
            case .wishlistMatch: return "Wishlist Match"
            case .holiday: return "Holiday Sale"
            case .saved: return "Saved"
            }
        }

        var icon: String {
            switch self {
            case .lightning: return "bolt.fill"
            case .daily: return "sun.max.fill"
            case .prime: return "star.fill"
            case .priceDrop: return "arrow.down.circle.fill"
            case .wishlistMatch: return "heart.fill"
            case .holiday: return "gift.fill"
            case .saved: return "bookmark.fill"
            }
        }

        var color: String {
            switch self {
            case .lightning: return "#FFD700"
            case .daily: return "#FF6B6B"
            case .prime: return "#00A8E1"
            case .priceDrop: return "#4ECDC4"
            case .wishlistMatch: return "#FF69B4"
            case .holiday: return "#FF4500"
            case .saved: return "#9B59B6"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case product
        case dealType = "deal_type"
        case expiresAt = "expires_at"
        case matchReason = "match_reason"
        case savingsAmount = "savings_amount"
        case relevanceScore = "relevance_score"
    }
}

// MARK: - Tracked Product

struct DealsTrackedProduct: Identifiable, Codable {
    let id: String
    let asin: String
    let title: String
    let currentPrice: Double
    let targetPrice: Double
    let lastCheckedPrice: Double?
    let lastCheckedAt: Date?
    let imageUrl: String?
    let priceDropped: Bool

    var formattedCurrentPrice: String {
        String(format: "$%.2f", currentPrice)
    }

    var formattedTargetPrice: String {
        String(format: "$%.2f", targetPrice)
    }

    var savings: Double? {
        guard let lastPrice = lastCheckedPrice, currentPrice < lastPrice else { return nil }
        return lastPrice - currentPrice
    }

    var progressToTarget: Double {
        guard let lastPrice = lastCheckedPrice, lastPrice > targetPrice else { return 0 }
        let totalDrop = lastPrice - targetPrice
        let currentDrop = lastPrice - currentPrice
        return min(1.0, currentDrop / totalDrop)
    }

    enum CodingKeys: String, CodingKey {
        case id, asin, title
        case currentPrice = "current_price"
        case targetPrice = "target_price"
        case lastCheckedPrice = "last_checked_price"
        case lastCheckedAt = "last_checked"
        case imageUrl = "image_url"
        case priceDropped = "price_dropped"
    }
}

// MARK: - Saved Deal

struct DealsSavedDeal: Identifiable, Codable {
    let asin: String
    let title: String
    let price: Double
    let originalPrice: Double?
    let savingsPercent: Double?
    let imageUrl: String?
    let url: String?
    let dealType: String
    let savedAt: Date

    var id: String { asin }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var formattedSavings: String? {
        guard let percent = savingsPercent else { return nil }
        return String(format: "%.0f%% off", percent)
    }

    enum CodingKeys: String, CodingKey {
        case asin, title, price, url
        case originalPrice = "original_price"
        case savingsPercent = "savings_percent"
        case imageUrl = "image_url"
        case dealType = "deal_type"
        case savedAt = "saved_at"
    }
}

// MARK: - Price Prediction

struct DealsPricePrediction: Codable {
    let currentPrice: Double
    let averagePrice: Double
    let lowestPrice30d: Double
    let highestPrice30d: Double
    let recommendation: PriceRecommendation
    let confidence: Double
    let reason: String
    let nextExpectedSale: String?

    enum PriceRecommendation: String, Codable {
        case buy = "buy"
        case wait = "wait"

        var label: String {
            switch self {
            case .buy: return "Buy Now"
            case .wait: return "Wait"
            }
        }

        var icon: String {
            switch self {
            case .buy: return "checkmark.circle.fill"
            case .wait: return "clock.fill"
            }
        }

        var color: String {
            switch self {
            case .buy: return "#4ECDC4"
            case .wait: return "#FF6B6B"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case currentPrice = "current_price"
        case averagePrice = "average_price"
        case lowestPrice30d = "lowest_price_30d"
        case highestPrice30d = "highest_price_30d"
        case recommendation, confidence, reason
        case nextExpectedSale = "next_expected_sale"
    }
}

// MARK: - Price History Point

struct DealsPricePoint: Identifiable, Codable {
    let price: Double
    let date: Date

    var id: Date { date }
}

// MARK: - Deals Stats

struct DealsStats: Codable {
    let productsTracked: Int
    let priceDropsFound: Int
    let potentialSavings: Double
    let savedDeals: Int
    let totalSavingsAvailable: Double

    var formattedPotentialSavings: String {
        String(format: "$%.2f", potentialSavings)
    }

    var formattedTotalSavings: String {
        String(format: "$%.2f", totalSavingsAvailable)
    }

    enum CodingKeys: String, CodingKey {
        case productsTracked = "products_tracked"
        case priceDropsFound = "price_drops_found"
        case potentialSavings = "potential_savings"
        case savedDeals = "saved_deals"
        case totalSavingsAvailable = "total_savings_available"
    }
}

// MARK: - API Response Models

struct DealsHomeResponse: Codable {
    let greeting: String
    let stats: DealsStats
    let priceDrops: [DealsPriceDrop]
    let savedDealsCount: Int
    let suggestedDeals: [DealsDeal]
    let tip: String

    enum CodingKeys: String, CodingKey {
        case greeting, stats, tip
        case priceDrops = "price_drops"
        case savedDealsCount = "saved_deals_count"
        case suggestedDeals = "suggested_deals"
    }
}

struct DealsPriceDrop: Identifiable, Codable {
    let asin: String
    let title: String
    let currentPrice: Double
    let targetPrice: Double
    let savings: Double
    let imageUrl: String?

    var id: String { asin }

    enum CodingKeys: String, CodingKey {
        case asin, title, savings
        case currentPrice = "current_price"
        case targetPrice = "target_price"
        case imageUrl = "image_url"
    }
}

struct DealsSearchResponse: Codable {
    let query: String
    let resultsCount: Int
    let products: [DealsProduct]
    let dealsTip: String

    enum CodingKeys: String, CodingKey {
        case query, products
        case resultsCount = "results_count"
        case dealsTip = "deals_tip"
    }
}

struct DealsDealsResponse: Codable {
    let totalDeals: Int
    let byType: [String: [DealsDeal]]
    let deals: [DealsDeal]
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case deals
        case totalDeals = "total_deals"
        case byType = "by_type"
        case lastUpdated = "last_updated"
    }
}

struct DealsProductDetailResponse: Codable {
    let product: DealsProduct
    let isTracked: Bool
    let trackingTarget: Double?
    let pricePrediction: DealsPricePrediction
    let priceHistory: [DealsPricePoint]
    let dealsVerdict: String

    enum CodingKeys: String, CodingKey {
        case product
        case isTracked = "is_tracked"
        case trackingTarget = "tracking_target"
        case pricePrediction = "price_prediction"
        case priceHistory = "price_history"
        case dealsVerdict = "deals_verdict"
    }
}

struct DealsTrackResponse: Codable {
    let success: Bool
    let message: String
    let tracking: DealsTrackingInfo
    let dealsSays: String

    enum CodingKeys: String, CodingKey {
        case success, message, tracking
        case dealsSays = "deals_says"
    }
}

struct DealsTrackingInfo: Codable {
    let asin: String
    let currentPrice: Double
    let targetPrice: Double
    let potentialSavings: Double

    enum CodingKeys: String, CodingKey {
        case asin
        case currentPrice = "current_price"
        case targetPrice = "target_price"
        case potentialSavings = "potential_savings"
    }
}

struct DealsTrackedResponse: Codable {
    let trackedCount: Int
    let totalPotentialSavings: Double
    let products: [DealsTrackedProduct]

    enum CodingKeys: String, CodingKey {
        case products
        case trackedCount = "tracked_count"
        case totalPotentialSavings = "total_potential_savings"
    }
}

struct DealsSavedDealsResponse: Codable {
    let savedCount: Int
    let totalSavingsAvailable: Double
    let deals: [DealsSavedDeal]

    enum CodingKeys: String, CodingKey {
        case deals
        case savedCount = "saved_count"
        case totalSavingsAvailable = "total_savings_available"
    }
}

struct DealsAlternativesResponse: Codable {
    let originalAsin: String
    let alternativesCount: Int
    let alternatives: [DealsProduct]
    let dealsSays: String

    enum CodingKeys: String, CodingKey {
        case alternatives
        case originalAsin = "original_asin"
        case alternativesCount = "alternatives_count"
        case dealsSays = "deals_says"
    }
}

struct DealsWishlistMatchResponse: Codable {
    let matchesCount: Int
    let wishlistItemsChecked: Int
    let matches: [String: [DealsDeal]]
    let dealsSays: String

    enum CodingKeys: String, CodingKey {
        case matches
        case matchesCount = "matches_count"
        case wishlistItemsChecked = "wishlist_items_checked"
        case dealsSays = "deals_says"
    }
}

struct DealsChatResponse: Codable {
    let query: String
    let responseType: String
    let message: String
    let products: [DealsProduct]
    let dealsTip: String
    let budgetAware: String

    enum CodingKeys: String, CodingKey {
        case query, message, products
        case responseType = "response_type"
        case dealsTip = "deals_tip"
        case budgetAware = "budget_aware"
    }
}

struct DealsStatsResponse: Codable {
    let stats: DealsStats
    let dealsMessage: String

    enum CodingKeys: String, CodingKey {
        case stats
        case dealsMessage = "deals_message"
    }
}

// MARK: - Request Models

struct DealsSearchRequest: Encodable {
    let keywords: String
    let category: String?
    let minPrice: Double?
    let maxPrice: Double?
    let minRating: Double?
    let primeOnly: Bool
    let sortBy: String

    enum CodingKeys: String, CodingKey {
        case keywords, category
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case minRating = "min_rating"
        case primeOnly = "prime_only"
        case sortBy = "sort_by"
    }
}

struct DealsTrackRequest: Encodable {
    let asin: String
    let targetPrice: Double?

    enum CodingKeys: String, CodingKey {
        case asin
        case targetPrice = "target_price"
    }
}

struct DealsSaveDealRequest: Encodable {
    let asin: String
    let title: String
    let price: Double
    let originalPrice: Double?
    let savingsPercent: Double?
    let imageUrl: String?
    let url: String?
    let dealType: String

    enum CodingKeys: String, CodingKey {
        case asin, title, price, url
        case originalPrice = "original_price"
        case savingsPercent = "savings_percent"
        case imageUrl = "image_url"
        case dealType = "deal_type"
    }
}

// MARK: - Search Sort Options

enum DealsSortOption: String, CaseIterable {
    case relevance = "Relevance"
    case priceLowToHigh = "Price:LowToHigh"
    case priceHighToLow = "Price:HighToLow"
    case reviews = "AvgCustomerReviews"

    var label: String {
        switch self {
        case .relevance: return "Most Relevant"
        case .priceLowToHigh: return "Price: Low to High"
        case .priceHighToLow: return "Price: High to Low"
        case .reviews: return "Best Reviews"
        }
    }
}

// MARK: - Amazon Categories

enum DealsCategory: String, CaseIterable {
    case all = "All"
    case electronics = "Electronics"
    case home = "HomeAndGarden"
    case fashion = "Fashion"
    case toys = "ToysAndGames"
    case beauty = "Beauty"
    case sports = "SportingGoods"
    case books = "Books"
    case grocery = "GourmetFood"
    case automotive = "Automotive"

    var label: String {
        switch self {
        case .all: return "All Categories"
        case .electronics: return "Electronics"
        case .home: return "Home & Garden"
        case .fashion: return "Fashion"
        case .toys: return "Toys & Games"
        case .beauty: return "Beauty"
        case .sports: return "Sports & Outdoors"
        case .books: return "Books"
        case .grocery: return "Grocery"
        case .automotive: return "Automotive"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .electronics: return "iphone"
        case .home: return "house"
        case .fashion: return "tshirt"
        case .toys: return "gamecontroller"
        case .beauty: return "sparkles"
        case .sports: return "figure.run"
        case .books: return "book"
        case .grocery: return "cart"
        case .automotive: return "car"
        }
    }
}
