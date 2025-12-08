//
//  MerchantIntelligenceManager.swift
//  Furg
//
//  Created for radical life integration - deep merchant knowledge graph
//

import Foundation
import CoreLocation
import Combine

// MARK: - Merchant Models

struct MerchantProfile: Identifiable, Codable {
    let id: String
    let name: String
    let category: MerchantCategory
    let logoURL: String?
    let website: String?
    let policies: MerchantPolicies
    let priceIntelligence: PriceIntelligence
    let loyaltyInfo: MerchantLoyaltyInfo?
    let paymentOptions: [PaymentOption]
    let operatingHours: OperatingHours?
    let crowdData: CrowdData?
    let userStats: UserMerchantStats?
    let rating: Double
    let reviewCount: Int
    let priceLevel: Int // 1-4 ($-$$$$)
}

enum MerchantCategory: String, Codable, CaseIterable {
    case grocery = "Grocery"
    case electronics = "Electronics"
    case clothing = "Clothing"
    case homeGoods = "Home Goods"
    case pharmacy = "Pharmacy"
    case restaurant = "Restaurant"
    case gasStation = "Gas Station"
    case department = "Department Store"
    case warehouse = "Warehouse Club"
    case beauty = "Beauty"
    case sporting = "Sporting Goods"
    case automotive = "Automotive"
    case petSupplies = "Pet Supplies"
    case officeSupplies = "Office Supplies"
    case bookstore = "Bookstore"
    case convenience = "Convenience"
    case other = "Other"
}

struct MerchantPolicies: Codable {
    let returnPolicy: ReturnPolicy
    let priceMatch: PriceMatchPolicy?
    let warrantyPolicy: WarrantyPolicy?
    let exchangePolicy: ExchangePolicy?
    let specialPolicies: [String]
}

struct ReturnPolicy: Codable {
    let standardDays: Int
    let extendedHolidayDays: Int?
    let receiptRequired: Bool
    let originalPackagingRequired: Bool
    let restockingFee: Double?
    let exceptions: [String]
    let easyReturns: Bool
    let freeReturns: Bool
    let returnMethods: [ReturnMethod]
}

enum ReturnMethod: String, Codable {
    case inStore = "In Store"
    case mail = "Mail"
    case dropOff = "Drop Off Location"
    case pickup = "Scheduled Pickup"
}

struct PriceMatchPolicy: Codable {
    let enabled: Bool
    let competitorsMatched: [String]
    let onlineMatching: Bool
    let requiresProof: Bool
    let timeLimit: Int? // Days after purchase
    let beatByPercent: Double? // Some stores beat by X%
    let exclusions: [String]
}

struct WarrantyPolicy: Codable {
    let standardWarranty: Int? // Months
    let extendedAvailable: Bool
    let manufacturerWarrantyHonored: Bool
}

struct ExchangePolicy: Codable {
    let allowedDays: Int
    let evenExchangeOnly: Bool
    let canUpgrade: Bool
}

struct PriceIntelligence: Codable {
    let priceHistory: [PriceHistoryPoint]
    let bestTimeToBuy: BestTimeToBuy
    let seasonalPatterns: [SeasonalPattern]
    let saleFrequency: SaleFrequency
    let couponAvailability: CouponAvailability
    let priceMatchSavings: Double? // Historical savings from price matching
}

struct PriceHistoryPoint: Codable {
    let date: Date
    let averageBasketPrice: Double
    let itemCount: Int
}

struct BestTimeToBuy: Codable {
    let dayOfWeek: [DayRecommendation]
    let timeOfDay: [TimeRecommendation]
    let monthlyTrends: [MonthlyTrend]
}

struct DayRecommendation: Codable {
    let day: String
    let savings: Double // Percentage
    let reason: String
}

struct TimeRecommendation: Codable {
    let timeRange: String
    let crowdLevel: String
    let markdownLikelihood: Double
}

struct MonthlyTrend: Codable {
    let month: Int
    let trend: String // "high_prices", "sales", "clearance"
    let majorSales: [String]
}

struct SeasonalPattern: Codable {
    let season: String
    let categories: [String]
    let averageDiscount: Double
    let bestItems: [String]
}

struct SaleFrequency: Codable {
    let weeklySales: Bool
    let monthlySales: Bool
    let majorSaleEvents: [SaleEvent]
    let flashSales: Bool
    let memberExclusiveSales: Bool
}

struct SaleEvent: Codable {
    let name: String
    let typicalMonth: Int
    let averageDiscount: Double
    let popularCategories: [String]
}

struct CouponAvailability: Codable {
    let digitalCoupons: Bool
    let paperCoupons: Bool
    let appExclusiveCoupons: Bool
    let stackable: Bool
    let averageSavings: Double
    let couponSources: [String]
}

struct MerchantLoyaltyInfo: Codable {
    let programName: String
    let pointsPerDollar: Double
    let pointValue: Double // Value per point in cents
    let tiers: [LoyaltyTier]
    let specialPerks: [String]
    let creditCardLinked: Bool
    let gasDiscount: Double? // Cents per gallon
}

struct LoyaltyTier: Codable {
    let name: String
    let spendRequired: Double
    let benefits: [String]
}

struct PaymentOption: Codable {
    let type: PaymentType
    let bonusRewards: Double? // Extra percentage
    let financing: FinancingOption?
}

enum PaymentType: String, Codable {
    case credit = "Credit Card"
    case debit = "Debit Card"
    case storeCard = "Store Card"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
    case paypal = "PayPal"
    case affirm = "Affirm"
    case klarna = "Klarna"
    case afterpay = "Afterpay"
    case cash = "Cash"
    case check = "Check"
    case giftCard = "Gift Card"
}

struct FinancingOption: Codable {
    let provider: String
    let minPurchase: Double
    let interestFree: Bool
    let months: Int
}

struct OperatingHours: Codable {
    let regular: [DayHours]
    let holidayHours: [HolidayHours]
    let isOpen24Hours: Bool
}

struct DayHours: Codable {
    let day: String
    let open: String
    let close: String
}

struct HolidayHours: Codable {
    let holiday: String
    let date: Date?
    let open: String?
    let close: String?
    let isClosed: Bool
}

struct CrowdData: Codable {
    let currentLevel: CrowdLevel
    let peakHours: [String]
    let quietHours: [String]
    let averageWaitTime: Int // Minutes
    let bestTimeToVisit: String
}

enum CrowdLevel: String, Codable {
    case empty = "Empty"
    case light = "Light"
    case moderate = "Moderate"
    case busy = "Busy"
    case veryBusy = "Very Busy"
    case packed = "Packed"
}

struct UserMerchantStats: Codable {
    let totalSpent: Double
    let visitCount: Int
    let averageTransaction: Double
    let lastVisit: Date?
    let favoriteCategories: [String]
    let savingsEarned: Double
    let loyaltyPointsEarned: Int
}

// MARK: - Merchant Relationships

struct MerchantRelationship: Codable {
    let merchantId: String
    let relatedMerchants: [RelatedMerchant]
    let priceComparisons: [CategoryPriceComparison]
}

struct RelatedMerchant: Codable {
    let merchantId: String
    let name: String
    let relationship: String // "competitor", "same_category", "price_match_target"
    let priceComparison: String // "cheaper", "similar", "more_expensive"
    let averagePriceDiff: Double // Percentage
}

struct CategoryPriceComparison: Codable {
    let category: String
    let thisStoreRank: Int // 1 = cheapest
    let competitorCount: Int
    let averageSavings: Double
}

// MARK: - Insights

struct MerchantInsight: Identifiable {
    let id = UUID()
    let merchantId: String
    let merchantName: String
    let type: InsightType
    let title: String
    let description: String
    let actionable: Bool
    let action: String?
    let savings: Double?
    let priority: Int // 1-10
    let timestamp: Date
}

enum InsightType: String {
    case priceDrop = "Price Drop"
    case saleAlert = "Sale Alert"
    case returnDeadline = "Return Deadline"
    case priceMatchOpportunity = "Price Match"
    case bestTimeToBuy = "Best Time to Buy"
    case loyaltyReward = "Loyalty Reward"
    case crowdAlert = "Crowd Alert"
    case newCoupon = "New Coupon"
    case seasonalDeal = "Seasonal Deal"
    case spendingPattern = "Spending Pattern"
}

// MARK: - Manager

class MerchantIntelligenceManager: ObservableObject {
    static let shared = MerchantIntelligenceManager()

    @Published var merchantProfiles: [String: MerchantProfile] = [:]
    @Published var merchantRelationships: [String: MerchantRelationship] = [:]
    @Published var activeInsights: [MerchantInsight] = []
    @Published var recentMerchants: [MerchantProfile] = []
    @Published var favoriteMerchants: [MerchantProfile] = []
    @Published var nearbyMerchants: [MerchantProfile] = []

    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()

    private init() {
        loadMerchantData()
        loadUserPreferences()
        setupMerchantDatabase()
    }

    // MARK: - Setup

    private func loadMerchantData() {
        if let data = UserDefaults.standard.data(forKey: "merchantProfiles"),
           let profiles = try? JSONDecoder().decode([String: MerchantProfile].self, from: data) {
            merchantProfiles = profiles
        }
    }

    private func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: "favoriteMerchants"),
           let favorites = try? JSONDecoder().decode([MerchantProfile].self, from: data) {
            favoriteMerchants = favorites
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(merchantProfiles) {
            UserDefaults.standard.set(data, forKey: "merchantProfiles")
        }
        if let data = try? JSONEncoder().encode(favoriteMerchants) {
            UserDefaults.standard.set(data, forKey: "favoriteMerchants")
        }
    }

    // MARK: - Merchant Database

    private func setupMerchantDatabase() {
        // Pre-populate with common merchants and their policies
        let merchants = generateMerchantDatabase()
        for merchant in merchants {
            merchantProfiles[merchant.id] = merchant
        }

        generateMerchantRelationships()
    }

    private func generateMerchantDatabase() -> [MerchantProfile] {
        return [
            // WALMART
            MerchantProfile(
                id: "walmart",
                name: "Walmart",
                category: .department,
                logoURL: nil,
                website: "walmart.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 90,
                        extendedHolidayDays: nil,
                        receiptRequired: false,
                        originalPackagingRequired: false,
                        restockingFee: nil,
                        exceptions: ["Electronics (30 days)", "Cell phones (14 days)", "Air mattresses (15 days)"],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.inStore, .mail]
                    ),
                    priceMatch: PriceMatchPolicy(
                        enabled: false, // Walmart ended price matching in 2020
                        competitorsMatched: [],
                        onlineMatching: false,
                        requiresProof: false,
                        timeLimit: nil,
                        beatByPercent: nil,
                        exclusions: []
                    ),
                    warrantyPolicy: WarrantyPolicy(standardWarranty: nil, extendedAvailable: true, manufacturerWarrantyHonored: true),
                    exchangePolicy: ExchangePolicy(allowedDays: 90, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["Free returns by mail or in-store", "No receipt needed for items under $10"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Tuesday", savings: 5, reason: "New weekly deals start"),
                            DayRecommendation(day: "Wednesday", savings: 3, reason: "Mid-week markdowns")
                        ],
                        timeOfDay: [
                            TimeRecommendation(timeRange: "7-9 AM", crowdLevel: "Light", markdownLikelihood: 0.7),
                            TimeRecommendation(timeRange: "9-11 PM", crowdLevel: "Light", markdownLikelihood: 0.8)
                        ],
                        monthlyTrends: [
                            MonthlyTrend(month: 1, trend: "clearance", majorSales: ["Post-Holiday Clearance"]),
                            MonthlyTrend(month: 11, trend: "sales", majorSales: ["Black Friday", "Deals for Days"])
                        ]
                    ),
                    seasonalPatterns: [
                        SeasonalPattern(season: "Back to School", categories: ["School Supplies", "Electronics"], averageDiscount: 30, bestItems: ["Notebooks", "Backpacks"])
                    ],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Black Friday", typicalMonth: 11, averageDiscount: 40, popularCategories: ["Electronics", "Toys"]),
                            SaleEvent(name: "Rollbacks", typicalMonth: 0, averageDiscount: 15, popularCategories: ["All"])
                        ],
                        flashSales: true,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: false,
                        appExclusiveCoupons: true,
                        stackable: false,
                        averageSavings: 8,
                        couponSources: ["Walmart App", "Ibotta"]
                    ),
                    priceMatchSavings: nil
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "Walmart+",
                    pointsPerDollar: 0,
                    pointValue: 0,
                    tiers: [],
                    specialPerks: ["Free delivery", "Fuel discounts", "Scan & Go"],
                    creditCardLinked: true,
                    gasDiscount: 10
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .debit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .applePay, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .affirm, bonusRewards: nil, financing: FinancingOption(provider: "Affirm", minPurchase: 50, interestFree: false, months: 12))
                ],
                operatingHours: OperatingHours(
                    regular: [
                        DayHours(day: "Mon-Sun", open: "6:00 AM", close: "11:00 PM")
                    ],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .moderate, peakHours: ["12-2 PM", "5-7 PM"], quietHours: ["6-8 AM", "9-11 PM"], averageWaitTime: 8, bestTimeToVisit: "Tuesday 7 AM"),
                userStats: nil,
                rating: 4.0,
                reviewCount: 125000,
                priceLevel: 1
            ),

            // TARGET
            MerchantProfile(
                id: "target",
                name: "Target",
                category: .department,
                logoURL: nil,
                website: "target.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 90,
                        extendedHolidayDays: 120,
                        receiptRequired: false,
                        originalPackagingRequired: false,
                        restockingFee: nil,
                        exceptions: ["Electronics (30 days)", "Apple products (15 days)", "Mobile phones (14 days)"],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.inStore, .mail]
                    ),
                    priceMatch: PriceMatchPolicy(
                        enabled: true,
                        competitorsMatched: ["Amazon", "Walmart", "Best Buy", "Costco", "Home Depot", "Lowe's"],
                        onlineMatching: true,
                        requiresProof: true,
                        timeLimit: 14,
                        beatByPercent: nil,
                        exclusions: ["Marketplace sellers", "Doorbusters", "Lightning deals"]
                    ),
                    warrantyPolicy: WarrantyPolicy(standardWarranty: nil, extendedAvailable: true, manufacturerWarrantyHonored: true),
                    exchangePolicy: ExchangePolicy(allowedDays: 90, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["RedCard holders get extra 30 days", "Target Circle members can scan receipt for returns"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Sunday", savings: 7, reason: "Weekly ad deals start"),
                            DayRecommendation(day: "Monday", savings: 3, reason: "Weekend clearance marked down")
                        ],
                        timeOfDay: [
                            TimeRecommendation(timeRange: "8-10 AM", crowdLevel: "Light", markdownLikelihood: 0.6),
                            TimeRecommendation(timeRange: "After 8 PM", crowdLevel: "Light", markdownLikelihood: 0.5)
                        ],
                        monthlyTrends: [
                            MonthlyTrend(month: 1, trend: "clearance", majorSales: ["After Christmas Clearance"]),
                            MonthlyTrend(month: 7, trend: "sales", majorSales: ["Target Circle Week"])
                        ]
                    ),
                    seasonalPatterns: [],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Target Circle Week", typicalMonth: 7, averageDiscount: 30, popularCategories: ["All"]),
                            SaleEvent(name: "Black Friday", typicalMonth: 11, averageDiscount: 35, popularCategories: ["Electronics", "Toys"])
                        ],
                        flashSales: false,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: true,
                        appExclusiveCoupons: true,
                        stackable: true,
                        averageSavings: 12,
                        couponSources: ["Target App", "Target Circle", "Manufacturer coupons"]
                    ),
                    priceMatchSavings: 45.0
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "Target Circle",
                    pointsPerDollar: 1,
                    pointValue: 1,
                    tiers: [
                        LoyaltyTier(name: "Target Circle 360", spendRequired: 0, benefits: ["Free same-day delivery", "Extra savings"])
                    ],
                    specialPerks: ["1% earnings on purchases", "Birthday reward", "Community giving votes"],
                    creditCardLinked: true,
                    gasDiscount: nil
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .storeCard, bonusRewards: 5, financing: nil),
                    PaymentOption(type: .applePay, bonusRewards: nil, financing: nil)
                ],
                operatingHours: OperatingHours(
                    regular: [DayHours(day: "Mon-Sat", open: "8:00 AM", close: "10:00 PM"), DayHours(day: "Sun", open: "8:00 AM", close: "9:00 PM")],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .moderate, peakHours: ["11 AM-1 PM", "4-6 PM"], quietHours: ["8-10 AM"], averageWaitTime: 6, bestTimeToVisit: "Tuesday 9 AM"),
                userStats: nil,
                rating: 4.3,
                reviewCount: 98000,
                priceLevel: 2
            ),

            // COSTCO
            MerchantProfile(
                id: "costco",
                name: "Costco",
                category: .warehouse,
                logoURL: nil,
                website: "costco.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: -1, // Unlimited
                        extendedHolidayDays: nil,
                        receiptRequired: false,
                        originalPackagingRequired: false,
                        restockingFee: nil,
                        exceptions: ["Electronics (90 days)", "Diamonds (48 hours inspection)"],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.inStore]
                    ),
                    priceMatch: PriceMatchPolicy(
                        enabled: true,
                        competitorsMatched: [],
                        onlineMatching: false,
                        requiresProof: true,
                        timeLimit: 30,
                        beatByPercent: nil,
                        exclusions: []
                    ),
                    warrantyPolicy: WarrantyPolicy(standardWarranty: 24, extendedAvailable: true, manufacturerWarrantyHonored: true),
                    exchangePolicy: ExchangePolicy(allowedDays: -1, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["Satisfaction guarantee on almost everything", "Concierge service for electronics", "2-year warranty on electronics"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Tuesday", savings: 5, reason: "Least crowded weekday"),
                            DayRecommendation(day: "Wednesday", savings: 4, reason: "New markdowns often appear")
                        ],
                        timeOfDay: [
                            TimeRecommendation(timeRange: "10-11 AM", crowdLevel: "Light", markdownLikelihood: 0.4),
                            TimeRecommendation(timeRange: "7-8 PM", crowdLevel: "Moderate", markdownLikelihood: 0.3)
                        ],
                        monthlyTrends: [
                            MonthlyTrend(month: 1, trend: "clearance", majorSales: ["January Savings Event"]),
                            MonthlyTrend(month: 11, trend: "sales", majorSales: ["Black Friday (but limited)"])
                        ]
                    ),
                    seasonalPatterns: [],
                    saleFrequency: SaleFrequency(
                        weeklySales: false,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Monthly Savings Book", typicalMonth: 0, averageDiscount: 20, popularCategories: ["All"])
                        ],
                        flashSales: false,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: false,
                        paperCoupons: true,
                        appExclusiveCoupons: false,
                        stackable: false,
                        averageSavings: 5,
                        couponSources: ["Monthly coupon book"]
                    ),
                    priceMatchSavings: nil
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "Executive Membership",
                    pointsPerDollar: 2,
                    pointValue: 1,
                    tiers: [
                        LoyaltyTier(name: "Gold Star", spendRequired: 0, benefits: ["Member pricing"]),
                        LoyaltyTier(name: "Executive", spendRequired: 0, benefits: ["2% annual reward", "Extra discounts"])
                    ],
                    specialPerks: ["2% cash back (Executive)", "Free samples", "Gas discount"],
                    creditCardLinked: true,
                    gasDiscount: 4
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .debit, bonusRewards: nil, financing: nil)
                ],
                operatingHours: OperatingHours(
                    regular: [DayHours(day: "Mon-Fri", open: "10:00 AM", close: "8:30 PM"), DayHours(day: "Sat", open: "9:30 AM", close: "6:00 PM"), DayHours(day: "Sun", open: "10:00 AM", close: "6:00 PM")],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .busy, peakHours: ["11 AM-2 PM", "Saturday all day"], quietHours: ["Weekday evenings"], averageWaitTime: 12, bestTimeToVisit: "Tuesday 10 AM"),
                userStats: nil,
                rating: 4.5,
                reviewCount: 87000,
                priceLevel: 2
            ),

            // BEST BUY
            MerchantProfile(
                id: "bestbuy",
                name: "Best Buy",
                category: .electronics,
                logoURL: nil,
                website: "bestbuy.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 15,
                        extendedHolidayDays: nil,
                        receiptRequired: true,
                        originalPackagingRequired: true,
                        restockingFee: 15, // Percentage for some items
                        exceptions: ["Activatable devices (14 days)", "Major appliances (15 days)"],
                        easyReturns: false,
                        freeReturns: true,
                        returnMethods: [.inStore, .mail]
                    ),
                    priceMatch: PriceMatchPolicy(
                        enabled: true,
                        competitorsMatched: ["Amazon", "Walmart", "Target", "Costco", "Micro Center"],
                        onlineMatching: true,
                        requiresProof: true,
                        timeLimit: 15,
                        beatByPercent: nil,
                        exclusions: ["Marketplace sellers", "Open-box items", "Refurbished"]
                    ),
                    warrantyPolicy: WarrantyPolicy(standardWarranty: nil, extendedAvailable: true, manufacturerWarrantyHonored: true),
                    exchangePolicy: ExchangePolicy(allowedDays: 15, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["My Best Buy Plus/Total members get 60 days", "Geek Squad protection available", "Total Tech members get extended returns"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Sunday", savings: 8, reason: "New weekly deals"),
                            DayRecommendation(day: "Friday", savings: 5, reason: "Daily deals refresh")
                        ],
                        timeOfDay: [
                            TimeRecommendation(timeRange: "10-11 AM", crowdLevel: "Light", markdownLikelihood: 0.5),
                            TimeRecommendation(timeRange: "8-9 PM", crowdLevel: "Light", markdownLikelihood: 0.4)
                        ],
                        monthlyTrends: [
                            MonthlyTrend(month: 1, trend: "clearance", majorSales: ["Post-Holiday Clearance"]),
                            MonthlyTrend(month: 11, trend: "sales", majorSales: ["Black Friday"])
                        ]
                    ),
                    seasonalPatterns: [
                        SeasonalPattern(season: "Back to School", categories: ["Laptops", "Tablets"], averageDiscount: 25, bestItems: ["Student laptops", "iPad"])
                    ],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Black Friday", typicalMonth: 11, averageDiscount: 35, popularCategories: ["TVs", "Laptops", "Gaming"]),
                            SaleEvent(name: "Anniversary Sale", typicalMonth: 8, averageDiscount: 25, popularCategories: ["All"])
                        ],
                        flashSales: true,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: false,
                        appExclusiveCoupons: true,
                        stackable: false,
                        averageSavings: 15,
                        couponSources: ["Best Buy app", "Email offers"]
                    ),
                    priceMatchSavings: 78.0
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "My Best Buy",
                    pointsPerDollar: 1,
                    pointValue: 0.5,
                    tiers: [
                        LoyaltyTier(name: "Member", spendRequired: 0, benefits: ["1 point per $1"]),
                        LoyaltyTier(name: "Plus", spendRequired: 0, benefits: ["1.25 points per $1", "60-day returns"]),
                        LoyaltyTier(name: "Total", spendRequired: 0, benefits: ["1.5 points per $1", "60-day returns", "Protection plans"])
                    ],
                    specialPerks: ["Member-only deals", "Early access to sales"],
                    creditCardLinked: true,
                    gasDiscount: nil
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: FinancingOption(provider: "Best Buy Card", minPurchase: 299, interestFree: true, months: 12)),
                    PaymentOption(type: .storeCard, bonusRewards: 5, financing: FinancingOption(provider: "Best Buy Card", minPurchase: 299, interestFree: true, months: 18)),
                    PaymentOption(type: .applePay, bonusRewards: nil, financing: nil)
                ],
                operatingHours: OperatingHours(
                    regular: [DayHours(day: "Mon-Sat", open: "10:00 AM", close: "9:00 PM"), DayHours(day: "Sun", open: "11:00 AM", close: "7:00 PM")],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .moderate, peakHours: ["12-2 PM", "Weekend afternoons"], quietHours: ["Weekday mornings"], averageWaitTime: 5, bestTimeToVisit: "Tuesday 10 AM"),
                userStats: nil,
                rating: 4.2,
                reviewCount: 76000,
                priceLevel: 3
            ),

            // AMAZON (for comparison)
            MerchantProfile(
                id: "amazon",
                name: "Amazon",
                category: .department,
                logoURL: nil,
                website: "amazon.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 30,
                        extendedHolidayDays: 90,
                        receiptRequired: false,
                        originalPackagingRequired: false,
                        restockingFee: nil,
                        exceptions: ["Third-party sellers vary", "Hazmat items", "Digital content"],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.mail, .dropOff]
                    ),
                    priceMatch: nil,
                    warrantyPolicy: WarrantyPolicy(standardWarranty: nil, extendedAvailable: true, manufacturerWarrantyHonored: true),
                    exchangePolicy: ExchangePolicy(allowedDays: 30, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["Free returns on most items", "Return at Whole Foods, Kohl's, UPS", "A-to-Z guarantee"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [],
                        timeOfDay: [],
                        monthlyTrends: [
                            MonthlyTrend(month: 7, trend: "sales", majorSales: ["Prime Day"]),
                            MonthlyTrend(month: 11, trend: "sales", majorSales: ["Black Friday", "Cyber Monday"])
                        ]
                    ),
                    seasonalPatterns: [],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Prime Day", typicalMonth: 7, averageDiscount: 30, popularCategories: ["Electronics", "Amazon devices"]),
                            SaleEvent(name: "Black Friday", typicalMonth: 11, averageDiscount: 35, popularCategories: ["All"])
                        ],
                        flashSales: true,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: false,
                        appExclusiveCoupons: false,
                        stackable: true,
                        averageSavings: 10,
                        couponSources: ["Amazon coupons page", "Subscribe & Save"]
                    ),
                    priceMatchSavings: nil
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "Amazon Prime",
                    pointsPerDollar: 0,
                    pointValue: 0,
                    tiers: [],
                    specialPerks: ["Free 2-day shipping", "Prime Video", "Prime Music", "Early access to deals"],
                    creditCardLinked: true,
                    gasDiscount: nil
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .storeCard, bonusRewards: 5, financing: nil),
                    PaymentOption(type: .affirm, bonusRewards: nil, financing: FinancingOption(provider: "Affirm", minPurchase: 50, interestFree: false, months: 12))
                ],
                operatingHours: nil,
                crowdData: nil,
                userStats: nil,
                rating: 4.4,
                reviewCount: 500000,
                priceLevel: 2
            ),

            // KROGER
            MerchantProfile(
                id: "kroger",
                name: "Kroger",
                category: .grocery,
                logoURL: nil,
                website: "kroger.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 30,
                        extendedHolidayDays: nil,
                        receiptRequired: true,
                        originalPackagingRequired: false,
                        restockingFee: nil,
                        exceptions: [],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.inStore]
                    ),
                    priceMatch: nil,
                    warrantyPolicy: nil,
                    exchangePolicy: nil,
                    specialPolicies: ["Freshness guarantee", "Double your money back on Kroger brands"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Wednesday", savings: 10, reason: "New weekly ad + overlap with old ad"),
                            DayRecommendation(day: "Sunday", savings: 5, reason: "Manager specials on expiring items")
                        ],
                        timeOfDay: [
                            TimeRecommendation(timeRange: "7-9 AM", crowdLevel: "Light", markdownLikelihood: 0.8),
                            TimeRecommendation(timeRange: "After 8 PM", crowdLevel: "Light", markdownLikelihood: 0.9)
                        ],
                        monthlyTrends: []
                    ),
                    seasonalPatterns: [],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Mega Sale", typicalMonth: 0, averageDiscount: 25, popularCategories: ["Groceries"])
                        ],
                        flashSales: true,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: true,
                        appExclusiveCoupons: true,
                        stackable: true,
                        averageSavings: 18,
                        couponSources: ["Kroger app", "Manufacturer coupons", "Ibotta"]
                    ),
                    priceMatchSavings: nil
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "Kroger Plus",
                    pointsPerDollar: 1,
                    pointValue: 0.1,
                    tiers: [],
                    specialPerks: ["Fuel points", "Digital coupons", "Personalized deals"],
                    creditCardLinked: false,
                    gasDiscount: 3
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .debit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .applePay, bonusRewards: nil, financing: nil)
                ],
                operatingHours: OperatingHours(
                    regular: [DayHours(day: "Mon-Sun", open: "6:00 AM", close: "12:00 AM")],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .moderate, peakHours: ["4-7 PM"], quietHours: ["6-8 AM"], averageWaitTime: 5, bestTimeToVisit: "Wednesday 7 AM"),
                userStats: nil,
                rating: 4.1,
                reviewCount: 45000,
                priceLevel: 2
            ),

            // HOME DEPOT
            MerchantProfile(
                id: "homedepot",
                name: "Home Depot",
                category: .homeGoods,
                logoURL: nil,
                website: "homedepot.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 90,
                        extendedHolidayDays: nil,
                        receiptRequired: false,
                        originalPackagingRequired: true,
                        restockingFee: 15, // For special orders
                        exceptions: ["Major appliances (48 hours for damage)", "Generators (30 days)"],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.inStore]
                    ),
                    priceMatch: PriceMatchPolicy(
                        enabled: true,
                        competitorsMatched: ["Lowe's", "Menards", "Ace Hardware"],
                        onlineMatching: true,
                        requiresProof: true,
                        timeLimit: 0, // At time of purchase
                        beatByPercent: 10,
                        exclusions: ["Clearance", "Open-box"]
                    ),
                    warrantyPolicy: WarrantyPolicy(standardWarranty: nil, extendedAvailable: true, manufacturerWarrantyHonored: true),
                    exchangePolicy: ExchangePolicy(allowedDays: 90, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["Low Price Guarantee - beat by 10%", "Pro Xtra members get 365 days", "Easy returns even without receipt"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Thursday", savings: 5, reason: "New weekly ad"),
                            DayRecommendation(day: "Monday", savings: 8, reason: "Holiday markdowns processed")
                        ],
                        timeOfDay: [
                            TimeRecommendation(timeRange: "6-8 AM", crowdLevel: "Light", markdownLikelihood: 0.4),
                            TimeRecommendation(timeRange: "8-9 PM", crowdLevel: "Light", markdownLikelihood: 0.5)
                        ],
                        monthlyTrends: [
                            MonthlyTrend(month: 5, trend: "sales", majorSales: ["Memorial Day Sale"]),
                            MonthlyTrend(month: 7, trend: "sales", majorSales: ["July 4th Sale"]),
                            MonthlyTrend(month: 9, trend: "sales", majorSales: ["Labor Day Sale"]),
                            MonthlyTrend(month: 11, trend: "sales", majorSales: ["Black Friday"])
                        ]
                    ),
                    seasonalPatterns: [
                        SeasonalPattern(season: "Spring", categories: ["Garden", "Outdoor"], averageDiscount: 20, bestItems: ["Plants", "Patio furniture"]),
                        SeasonalPattern(season: "Fall", categories: ["Grills", "Patio"], averageDiscount: 40, bestItems: ["Clearance outdoor"])
                    ],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [
                            SaleEvent(name: "Spring Black Friday", typicalMonth: 4, averageDiscount: 30, popularCategories: ["Garden", "Tools"]),
                            SaleEvent(name: "Black Friday", typicalMonth: 11, averageDiscount: 35, popularCategories: ["Tools", "Appliances"])
                        ],
                        flashSales: true,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: true,
                        appExclusiveCoupons: true,
                        stackable: false,
                        averageSavings: 10,
                        couponSources: ["Home Depot app", "Email offers", "Movers coupon"]
                    ),
                    priceMatchSavings: 125.0
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "Pro Xtra",
                    pointsPerDollar: 0,
                    pointValue: 0,
                    tiers: [],
                    specialPerks: ["Volume pricing", "365-day returns", "Purchase tracking", "Tool rental discounts"],
                    creditCardLinked: true,
                    gasDiscount: nil
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: FinancingOption(provider: "Home Depot Card", minPurchase: 299, interestFree: true, months: 6)),
                    PaymentOption(type: .storeCard, bonusRewards: 0, financing: FinancingOption(provider: "Home Depot Card", minPurchase: 299, interestFree: true, months: 24)),
                    PaymentOption(type: .applePay, bonusRewards: nil, financing: nil)
                ],
                operatingHours: OperatingHours(
                    regular: [DayHours(day: "Mon-Sat", open: "6:00 AM", close: "10:00 PM"), DayHours(day: "Sun", open: "8:00 AM", close: "8:00 PM")],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .moderate, peakHours: ["10 AM-2 PM", "Saturday all day"], quietHours: ["6-8 AM", "After 7 PM"], averageWaitTime: 8, bestTimeToVisit: "Tuesday 6 AM"),
                userStats: nil,
                rating: 4.3,
                reviewCount: 89000,
                priceLevel: 2
            ),

            // CVS
            MerchantProfile(
                id: "cvs",
                name: "CVS",
                category: .pharmacy,
                logoURL: nil,
                website: "cvs.com",
                policies: MerchantPolicies(
                    returnPolicy: ReturnPolicy(
                        standardDays: 60,
                        extendedHolidayDays: nil,
                        receiptRequired: true,
                        originalPackagingRequired: true,
                        restockingFee: nil,
                        exceptions: ["Prescription items", "Sexual wellness", "Opened cosmetics (14 days)"],
                        easyReturns: true,
                        freeReturns: true,
                        returnMethods: [.inStore]
                    ),
                    priceMatch: nil,
                    warrantyPolicy: nil,
                    exchangePolicy: ExchangePolicy(allowedDays: 60, evenExchangeOnly: false, canUpgrade: true),
                    specialPolicies: ["ExtraCare receipt lookup", "Satisfaction guaranteed"]
                ),
                priceIntelligence: PriceIntelligence(
                    priceHistory: [],
                    bestTimeToBuy: BestTimeToBuy(
                        dayOfWeek: [
                            DayRecommendation(day: "Sunday", savings: 15, reason: "New weekly ad + ExtraBucks deals")
                        ],
                        timeOfDay: [],
                        monthlyTrends: []
                    ),
                    seasonalPatterns: [],
                    saleFrequency: SaleFrequency(
                        weeklySales: true,
                        monthlySales: true,
                        majorSaleEvents: [],
                        flashSales: false,
                        memberExclusiveSales: true
                    ),
                    couponAvailability: CouponAvailability(
                        digitalCoupons: true,
                        paperCoupons: true,
                        appExclusiveCoupons: true,
                        stackable: true,
                        averageSavings: 25,
                        couponSources: ["CVS app", "ExtraCare card", "Manufacturer coupons"]
                    ),
                    priceMatchSavings: nil
                ),
                loyaltyInfo: MerchantLoyaltyInfo(
                    programName: "ExtraCare",
                    pointsPerDollar: 2,
                    pointValue: 1,
                    tiers: [
                        LoyaltyTier(name: "CarePass", spendRequired: 0, benefits: ["$10 monthly reward", "Free delivery", "20% off CVS brand"])
                    ],
                    specialPerks: ["ExtraBucks rewards", "Personalized coupons", "Birthday reward"],
                    creditCardLinked: false,
                    gasDiscount: nil
                ),
                paymentOptions: [
                    PaymentOption(type: .credit, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .applePay, bonusRewards: nil, financing: nil),
                    PaymentOption(type: .paypal, bonusRewards: nil, financing: nil)
                ],
                operatingHours: OperatingHours(
                    regular: [DayHours(day: "Mon-Sun", open: "7:00 AM", close: "10:00 PM")],
                    holidayHours: [],
                    isOpen24Hours: false
                ),
                crowdData: CrowdData(currentLevel: .light, peakHours: ["12-1 PM", "5-6 PM"], quietHours: ["7-9 AM"], averageWaitTime: 3, bestTimeToVisit: "Weekday morning"),
                userStats: nil,
                rating: 3.8,
                reviewCount: 34000,
                priceLevel: 3
            )
        ]
    }

    private func generateMerchantRelationships() {
        // Target relationships
        merchantRelationships["target"] = MerchantRelationship(
            merchantId: "target",
            relatedMerchants: [
                RelatedMerchant(merchantId: "walmart", name: "Walmart", relationship: "competitor", priceComparison: "more_expensive", averagePriceDiff: 5),
                RelatedMerchant(merchantId: "amazon", name: "Amazon", relationship: "price_match_target", priceComparison: "similar", averagePriceDiff: 2),
                RelatedMerchant(merchantId: "costco", name: "Costco", relationship: "competitor", priceComparison: "more_expensive", averagePriceDiff: 15)
            ],
            priceComparisons: [
                CategoryPriceComparison(category: "Groceries", thisStoreRank: 3, competitorCount: 5, averageSavings: 8),
                CategoryPriceComparison(category: "Household", thisStoreRank: 2, competitorCount: 5, averageSavings: 12)
            ]
        )

        // Best Buy relationships
        merchantRelationships["bestbuy"] = MerchantRelationship(
            merchantId: "bestbuy",
            relatedMerchants: [
                RelatedMerchant(merchantId: "amazon", name: "Amazon", relationship: "price_match_target", priceComparison: "more_expensive", averagePriceDiff: 3),
                RelatedMerchant(merchantId: "walmart", name: "Walmart", relationship: "competitor", priceComparison: "more_expensive", averagePriceDiff: 8),
                RelatedMerchant(merchantId: "costco", name: "Costco", relationship: "price_match_target", priceComparison: "more_expensive", averagePriceDiff: 10)
            ],
            priceComparisons: [
                CategoryPriceComparison(category: "Electronics", thisStoreRank: 3, competitorCount: 5, averageSavings: 45),
                CategoryPriceComparison(category: "Computers", thisStoreRank: 2, competitorCount: 4, averageSavings: 75)
            ]
        )
    }

    // MARK: - Public Methods

    func getMerchant(id: String) -> MerchantProfile? {
        return merchantProfiles[id]
    }

    func getMerchant(name: String) -> MerchantProfile? {
        return merchantProfiles.values.first { $0.name.lowercased() == name.lowercased() }
    }

    func searchMerchants(query: String) -> [MerchantProfile] {
        let lowercased = query.lowercased()
        return merchantProfiles.values.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.category.rawValue.lowercased().contains(lowercased)
        }
    }

    func getMerchants(category: MerchantCategory) -> [MerchantProfile] {
        return merchantProfiles.values.filter { $0.category == category }
    }

    func getReturnPolicy(merchantId: String) -> ReturnPolicy? {
        return merchantProfiles[merchantId]?.policies.returnPolicy
    }

    func getPriceMatchPolicy(merchantId: String) -> PriceMatchPolicy? {
        return merchantProfiles[merchantId]?.policies.priceMatch
    }

    func getBestTimeToBuy(merchantId: String) -> BestTimeToBuy? {
        return merchantProfiles[merchantId]?.priceIntelligence.bestTimeToBuy
    }

    func getRelatedMerchants(merchantId: String) -> [RelatedMerchant] {
        return merchantRelationships[merchantId]?.relatedMerchants ?? []
    }

    func comparePrices(merchantId: String, category: String) -> CategoryPriceComparison? {
        return merchantRelationships[merchantId]?.priceComparisons.first { $0.category == category }
    }

    // MARK: - Insights Generation

    func generateInsights(for merchantId: String, purchaseDate: Date? = nil, purchaseAmount: Double? = nil) -> [MerchantInsight] {
        guard let merchant = merchantProfiles[merchantId] else { return [] }

        var insights: [MerchantInsight] = []

        // Return deadline insight
        if let purchaseDate = purchaseDate {
            let returnDeadline = Calendar.current.date(byAdding: .day, value: merchant.policies.returnPolicy.standardDays, to: purchaseDate)!
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: returnDeadline).day ?? 0

            if daysLeft > 0 && daysLeft <= 7 {
                insights.append(MerchantInsight(
                    merchantId: merchantId,
                    merchantName: merchant.name,
                    type: .returnDeadline,
                    title: "Return Window Closing",
                    description: "You have \(daysLeft) days left to return items from your \(merchant.name) purchase.",
                    actionable: true,
                    action: "View return options",
                    savings: nil,
                    priority: 8,
                    timestamp: Date()
                ))
            }
        }

        // Price match opportunity
        if let priceMatch = merchant.policies.priceMatch, priceMatch.enabled {
            insights.append(MerchantInsight(
                merchantId: merchantId,
                merchantName: merchant.name,
                type: .priceMatchOpportunity,
                title: "Price Match Available",
                description: "\(merchant.name) matches prices from \(priceMatch.competitorsMatched.prefix(3).joined(separator: ", ")) and more.",
                actionable: true,
                action: "Compare prices",
                savings: merchant.priceIntelligence.priceMatchSavings,
                priority: 6,
                timestamp: Date()
            ))
        }

        // Best time to buy
        if let bestDay = merchant.priceIntelligence.bestTimeToBuy.dayOfWeek.first {
            insights.append(MerchantInsight(
                merchantId: merchantId,
                merchantName: merchant.name,
                type: .bestTimeToBuy,
                title: "Best Day to Shop",
                description: "Shop at \(merchant.name) on \(bestDay.day) for \(Int(bestDay.savings))% more savings. \(bestDay.reason)",
                actionable: false,
                action: nil,
                savings: nil,
                priority: 4,
                timestamp: Date()
            ))
        }

        // Coupon availability
        if merchant.priceIntelligence.couponAvailability.stackable {
            insights.append(MerchantInsight(
                merchantId: merchantId,
                merchantName: merchant.name,
                type: .newCoupon,
                title: "Stackable Coupons",
                description: "\(merchant.name) allows stacking manufacturer coupons with store coupons for extra savings!",
                actionable: true,
                action: "Find coupons",
                savings: merchant.priceIntelligence.couponAvailability.averageSavings,
                priority: 5,
                timestamp: Date()
            ))
        }

        // Upcoming sales
        let currentMonth = Calendar.current.component(.month, from: Date())
        if let upcomingSale = merchant.priceIntelligence.saleFrequency.majorSaleEvents.first(where: { $0.typicalMonth == currentMonth || $0.typicalMonth == currentMonth + 1 }) {
            insights.append(MerchantInsight(
                merchantId: merchantId,
                merchantName: merchant.name,
                type: .saleAlert,
                title: "Upcoming Sale",
                description: "\(merchant.name)'s \(upcomingSale.name) is coming! Average discounts of \(Int(upcomingSale.averageDiscount))% on \(upcomingSale.popularCategories.joined(separator: ", ")).",
                actionable: false,
                action: nil,
                savings: nil,
                priority: 7,
                timestamp: Date()
            ))
        }

        // Loyalty rewards
        if let loyalty = merchant.loyaltyInfo {
            if loyalty.gasDiscount != nil {
                insights.append(MerchantInsight(
                    merchantId: merchantId,
                    merchantName: merchant.name,
                    type: .loyaltyReward,
                    title: "Fuel Savings Available",
                    description: "\(merchant.name)'s \(loyalty.programName) offers fuel discounts. Save \(Int(loyalty.gasDiscount!))¢/gallon!",
                    actionable: true,
                    action: "Link loyalty card",
                    savings: nil,
                    priority: 5,
                    timestamp: Date()
                ))
            }
        }

        return insights.sorted { $0.priority > $1.priority }
    }

    func generateAllInsights() {
        var allInsights: [MerchantInsight] = []

        for (merchantId, _) in merchantProfiles {
            let insights = generateInsights(for: merchantId)
            allInsights.append(contentsOf: insights)
        }

        activeInsights = allInsights.sorted { $0.priority > $1.priority }
    }

    // MARK: - User Stats

    func recordVisit(merchantId: String, amount: Double) {
        guard var merchant = merchantProfiles[merchantId] else { return }

        var stats = merchant.userStats ?? UserMerchantStats(
            totalSpent: 0,
            visitCount: 0,
            averageTransaction: 0,
            lastVisit: nil,
            favoriteCategories: [],
            savingsEarned: 0,
            loyaltyPointsEarned: 0
        )

        let newTotal = stats.totalSpent + amount
        let newCount = stats.visitCount + 1
        let newAverage = newTotal / Double(newCount)

        let loyaltyPoints = Int(amount * (merchant.loyaltyInfo?.pointsPerDollar ?? 0))

        stats = UserMerchantStats(
            totalSpent: newTotal,
            visitCount: newCount,
            averageTransaction: newAverage,
            lastVisit: Date(),
            favoriteCategories: stats.favoriteCategories,
            savingsEarned: stats.savingsEarned,
            loyaltyPointsEarned: stats.loyaltyPointsEarned + loyaltyPoints
        )

        // Update the merchant with new stats
        merchantProfiles[merchantId] = MerchantProfile(
            id: merchant.id,
            name: merchant.name,
            category: merchant.category,
            logoURL: merchant.logoURL,
            website: merchant.website,
            policies: merchant.policies,
            priceIntelligence: merchant.priceIntelligence,
            loyaltyInfo: merchant.loyaltyInfo,
            paymentOptions: merchant.paymentOptions,
            operatingHours: merchant.operatingHours,
            crowdData: merchant.crowdData,
            userStats: stats,
            rating: merchant.rating,
            reviewCount: merchant.reviewCount,
            priceLevel: merchant.priceLevel
        )

        // Update recent merchants
        if let index = recentMerchants.firstIndex(where: { $0.id == merchantId }) {
            recentMerchants.remove(at: index)
        }
        if let updated = merchantProfiles[merchantId] {
            recentMerchants.insert(updated, at: 0)
            if recentMerchants.count > 10 {
                recentMerchants.removeLast()
            }
        }

        save()
    }

    func toggleFavorite(merchantId: String) {
        guard let merchant = merchantProfiles[merchantId] else { return }

        if let index = favoriteMerchants.firstIndex(where: { $0.id == merchantId }) {
            favoriteMerchants.remove(at: index)
        } else {
            favoriteMerchants.append(merchant)
        }
        save()
    }

    func isFavorite(merchantId: String) -> Bool {
        return favoriteMerchants.contains { $0.id == merchantId }
    }

    // MARK: - Smart Recommendations

    func getBestCardForMerchant(merchantId: String) -> String? {
        guard let merchant = merchantProfiles[merchantId] else { return nil }

        // Check if store card offers better rewards
        if let storeCardOption = merchant.paymentOptions.first(where: { $0.type == .storeCard }),
           let bonus = storeCardOption.bonusRewards, bonus > 0 {
            return "\(merchant.name) Store Card (\(Int(bonus))% back)"
        }

        // Defer to CardOptimizer for best credit card
        return nil
    }

    func getFinancingOptions(merchantId: String, purchaseAmount: Double) -> [FinancingOption] {
        guard let merchant = merchantProfiles[merchantId] else { return [] }

        return merchant.paymentOptions.compactMap { option in
            if let financing = option.financing, purchaseAmount >= financing.minPurchase {
                return financing
            }
            return nil
        }
    }

    func shouldWaitForSale(merchantId: String, category: String) -> (wait: Bool, reason: String, expectedSavings: Double)? {
        guard let merchant = merchantProfiles[merchantId] else { return nil }

        let currentMonth = Calendar.current.component(.month, from: Date())

        // Check for upcoming major sales in next 30 days
        for sale in merchant.priceIntelligence.saleFrequency.majorSaleEvents {
            if sale.typicalMonth == currentMonth + 1 ||
               (currentMonth == 12 && sale.typicalMonth == 1) {
                if sale.popularCategories.contains(category) || sale.popularCategories.contains("All") {
                    return (true, "\(sale.name) is coming next month", sale.averageDiscount)
                }
            }
        }

        // Check seasonal patterns
        let currentSeason = getCurrentSeason()
        if let pattern = merchant.priceIntelligence.seasonalPatterns.first(where: {
            $0.season == currentSeason && $0.categories.contains(category)
        }) {
            return (false, "Good time to buy - \(pattern.season) deals", pattern.averageDiscount)
        }

        return nil
    }

    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "Spring"
        case 6...8: return "Summer"
        case 9...11: return "Fall"
        default: return "Winter"
        }
    }
}
