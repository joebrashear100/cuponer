//
//  GroceryCouponModels.swift
//  Furg
//
//  Models for location-based grocery coupons with personal preferences
//

import Foundation
import CoreLocation

// MARK: - Grocery Store

struct GroceryStore: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let chain: GroceryChain
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    let distance: Double? // miles from user
    let isOpen: Bool
    let closingTime: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedDistance: String {
        guard let distance = distance else { return "" }
        if distance < 0.1 {
            return "< 0.1 mi"
        } else if distance < 10 {
            return String(format: "%.1f mi", distance)
        } else {
            return String(format: "%.0f mi", distance)
        }
    }
}

enum GroceryChain: String, Codable, CaseIterable, Identifiable {
    case kroger = "kroger"
    case safeway = "safeway"
    case wholefoods = "wholefoods"
    case traderjoes = "traderjoes"
    case costco = "costco"
    case walmart = "walmart"
    case target = "target"
    case aldis = "aldis"
    case publix = "publix"
    case heb = "heb"
    case wegmans = "wegmans"
    case sprouts = "sprouts"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kroger: return "Kroger"
        case .safeway: return "Safeway"
        case .wholefoods: return "Whole Foods"
        case .traderjoes: return "Trader Joe's"
        case .costco: return "Costco"
        case .walmart: return "Walmart"
        case .target: return "Target"
        case .aldis: return "ALDI"
        case .publix: return "Publix"
        case .heb: return "H-E-B"
        case .wegmans: return "Wegmans"
        case .sprouts: return "Sprouts"
        case .other: return "Other"
        }
    }

    var iconColor: String {
        switch self {
        case .kroger: return "#0066CC"
        case .safeway: return "#E21836"
        case .wholefoods: return "#00674B"
        case .traderjoes: return "#DA291C"
        case .costco: return "#005DAA"
        case .walmart: return "#0071CE"
        case .target: return "#CC0000"
        case .aldis: return "#00529B"
        case .publix: return "#3D8B37"
        case .heb: return "#EE2E24"
        case .wegmans: return "#D71920"
        case .sprouts: return "#5B8F22"
        case .other: return "#666666"
        }
    }

    var icon: String {
        switch self {
        case .costco: return "cart.fill.badge.plus"
        case .wholefoods, .sprouts: return "leaf.fill"
        case .traderjoes: return "basket.fill"
        default: return "cart.fill"
        }
    }

    var hasCouponProgram: Bool {
        switch self {
        case .kroger, .safeway, .walmart, .target, .publix, .heb, .wegmans:
            return true
        case .traderjoes, .aldis, .costco:
            return false // These stores use everyday low pricing
        default:
            return true
        }
    }
}

// MARK: - Grocery Coupon

struct GroceryCoupon: Identifiable, Codable {
    let id: String
    let storeId: String
    let chain: GroceryChain
    let title: String
    let description: String
    let discountType: DiscountType
    let discountValue: Double
    let minimumPurchase: Double?
    let maxSavings: Double?
    let code: String?
    let barcode: String?
    let category: GroceryCouponCategory
    let brand: String?
    let productName: String?
    let imageUrl: String?
    let expiresAt: Date
    let isDigital: Bool
    let isClipped: Bool
    let isStackable: Bool
    let requiresLoyaltyCard: Bool
    let limitPerCustomer: Int?
    let tags: [String]

    var isExpired: Bool {
        expiresAt < Date()
    }

    var expiresIn: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "Expires today"
        } else if days == 1 {
            return "Expires tomorrow"
        } else if days < 7 {
            return "Expires in \(days) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Expires \(formatter.string(from: expiresAt))"
        }
    }

    var formattedDiscount: String {
        switch discountType {
        case .percentOff:
            return "\(Int(discountValue))% off"
        case .dollarOff:
            return String(format: "$%.2f off", discountValue)
        case .buyOneGetOne:
            return "BOGO"
        case .buyOneGetOneHalf:
            return "BOGO 50% off"
        case .freeItem:
            return "FREE"
        case .cashback:
            return String(format: "$%.2f cashback", discountValue)
        case .pointsMultiplier:
            return "\(Int(discountValue))x points"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, code, barcode, category, brand, tags
        case storeId = "store_id"
        case chain
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case minimumPurchase = "minimum_purchase"
        case maxSavings = "max_savings"
        case productName = "product_name"
        case imageUrl = "image_url"
        case expiresAt = "expires_at"
        case isDigital = "is_digital"
        case isClipped = "is_clipped"
        case isStackable = "is_stackable"
        case requiresLoyaltyCard = "requires_loyalty_card"
        case limitPerCustomer = "limit_per_customer"
    }
}

enum DiscountType: String, Codable {
    case percentOff = "percent_off"
    case dollarOff = "dollar_off"
    case buyOneGetOne = "bogo"
    case buyOneGetOneHalf = "bogo_half"
    case freeItem = "free"
    case cashback = "cashback"
    case pointsMultiplier = "points_multiplier"
}

enum GroceryCouponCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "produce"
    case dairy = "dairy"
    case meat = "meat"
    case seafood = "seafood"
    case bakery = "bakery"
    case frozen = "frozen"
    case pantry = "pantry"
    case snacks = "snacks"
    case beverages = "beverages"
    case household = "household"
    case personal = "personal"
    case baby = "baby"
    case pet = "pet"
    case organic = "organic"
    case glutenFree = "gluten_free"
    case vegan = "vegan"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .produce: return "Produce"
        case .dairy: return "Dairy & Eggs"
        case .meat: return "Meat"
        case .seafood: return "Seafood"
        case .bakery: return "Bakery"
        case .frozen: return "Frozen"
        case .pantry: return "Pantry"
        case .snacks: return "Snacks"
        case .beverages: return "Beverages"
        case .household: return "Household"
        case .personal: return "Personal Care"
        case .baby: return "Baby"
        case .pet: return "Pet"
        case .organic: return "Organic"
        case .glutenFree: return "Gluten-Free"
        case .vegan: return "Vegan"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .meat: return "fork.knife"
        case .seafood: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        case .frozen: return "snowflake"
        case .pantry: return "cabinet.fill"
        case .snacks: return "popcorn.fill"
        case .beverages: return "waterbottle.fill"
        case .household: return "house.fill"
        case .personal: return "heart.fill"
        case .baby: return "figure.and.child.holdinghands"
        case .pet: return "pawprint.fill"
        case .organic: return "leaf.circle.fill"
        case .glutenFree: return "g.circle.fill"
        case .vegan: return "carrot.fill"
        case .other: return "tag.fill"
        }
    }
}

// MARK: - User Preferences

struct GroceryCouponPreferences: Codable {
    var preferredStores: [GroceryChain]
    var excludedStores: [GroceryChain]
    var preferredCategories: [GroceryCouponCategory]
    var excludedCategories: [GroceryCouponCategory]
    var dietaryPreferences: [DietaryPreference]
    var maxDistanceMiles: Double
    var showExpiringSoon: Bool
    var showDigitalOnly: Bool
    var minimumDiscountPercent: Double?
    var sortBy: CouponSortOption
    var notifyNewCoupons: Bool
    var notifyExpiringCoupons: Bool

    static var defaultPreferences: GroceryCouponPreferences {
        GroceryCouponPreferences(
            preferredStores: [],
            excludedStores: [],
            preferredCategories: [],
            excludedCategories: [],
            dietaryPreferences: [],
            maxDistanceMiles: 10.0,
            showExpiringSoon: true,
            showDigitalOnly: false,
            minimumDiscountPercent: nil,
            sortBy: .relevance,
            notifyNewCoupons: true,
            notifyExpiringCoupons: true
        )
    }
}

enum DietaryPreference: String, Codable, CaseIterable, Identifiable {
    case vegan = "vegan"
    case vegetarian = "vegetarian"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case nutFree = "nut_free"
    case organic = "organic"
    case keto = "keto"
    case paleo = "paleo"
    case lowSodium = "low_sodium"
    case sugarFree = "sugar_free"
    case halal = "halal"
    case kosher = "kosher"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vegan: return "Vegan"
        case .vegetarian: return "Vegetarian"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        case .nutFree: return "Nut-Free"
        case .organic: return "Organic"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .lowSodium: return "Low Sodium"
        case .sugarFree: return "Sugar-Free"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        }
    }

    var icon: String {
        switch self {
        case .vegan, .vegetarian: return "leaf.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.fill"
        case .nutFree: return "xmark.circle.fill"
        case .organic: return "leaf.circle.fill"
        case .keto, .paleo: return "flame.fill"
        case .lowSodium: return "heart.fill"
        case .sugarFree: return "cube.fill"
        case .halal, .kosher: return "checkmark.seal.fill"
        }
    }
}

enum CouponSortOption: String, Codable, CaseIterable, Identifiable {
    case relevance = "relevance"
    case distance = "distance"
    case savings = "savings"
    case expiringSoon = "expiring_soon"
    case newest = "newest"
    case category = "category"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relevance: return "Best Match"
        case .distance: return "Nearest"
        case .savings: return "Biggest Savings"
        case .expiringSoon: return "Expiring Soon"
        case .newest: return "Newest"
        case .category: return "Category"
        }
    }
}

// MARK: - API Response Models

struct GroceryCouponSearchResponse: Codable {
    let coupons: [GroceryCoupon]
    let stores: [GroceryStore]
    let totalCount: Int
    let hasMore: Bool
    let nextPage: Int?

    enum CodingKeys: String, CodingKey {
        case coupons, stores
        case totalCount = "total_count"
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

struct GroceryCouponSearchRequest: Codable {
    let latitude: Double
    let longitude: Double
    let radiusMiles: Double
    let preferredStores: [String]?
    let excludedStores: [String]?
    let categories: [String]?
    let dietaryPreferences: [String]?
    let sortBy: String
    let page: Int
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, categories, page, limit
        case radiusMiles = "radius_miles"
        case preferredStores = "preferred_stores"
        case excludedStores = "excluded_stores"
        case dietaryPreferences = "dietary_preferences"
        case sortBy = "sort_by"
    }
}

// MARK: - Coupon Clip Result

struct CouponClipResult: Codable {
    let success: Bool
    let couponId: String
    let message: String?
    let loyaltyCardRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case success, message
        case couponId = "coupon_id"
        case loyaltyCardRequired = "loyalty_card_required"
    }
}

// MARK: - Store Stats

struct StoreStats: Identifiable, Codable {
    let id: String
    let chain: GroceryChain
    let totalCoupons: Int
    let totalSavings: Double
    let clippedCoupons: Int
    let usedCoupons: Int
    let favoriteCategory: GroceryCouponCategory?

    var formattedSavings: String {
        String(format: "$%.2f", totalSavings)
    }

    enum CodingKeys: String, CodingKey {
        case id, chain
        case totalCoupons = "total_coupons"
        case totalSavings = "total_savings"
        case clippedCoupons = "clipped_coupons"
        case usedCoupons = "used_coupons"
        case favoriteCategory = "favorite_category"
    }
}
