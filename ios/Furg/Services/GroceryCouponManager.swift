//
//  GroceryCouponManager.swift
//  Furg
//
//  Manages location-based grocery coupons with personal preference overrides
//

import Foundation
import CoreLocation
import Combine

class GroceryCouponManager: ObservableObject {
    static let shared = GroceryCouponManager()

    // MARK: - Published State

    @Published var coupons: [GroceryCoupon] = []
    @Published var nearbyStores: [GroceryStore] = []
    @Published var clippedCoupons: Set<String> = []
    @Published var preferences: GroceryCouponPreferences
    @Published var storeStats: [StoreStats] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var totalPotentialSavings: Double = 0
    @Published var lastUpdated: Date?

    // Filter state
    @Published var selectedChain: GroceryChain?
    @Published var selectedCategory: GroceryCouponCategory?
    @Published var searchQuery: String = ""

    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let preferencesKey = "grocery_coupon_preferences"
    private let clippedCouponsKey = "clipped_coupons"

    // MARK: - Computed Properties

    var filteredCoupons: [GroceryCoupon] {
        var result = coupons

        // Apply chain filter
        if let chain = selectedChain {
            result = result.filter { $0.chain == chain }
        }

        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Apply search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                ($0.brand?.lowercased().contains(query) ?? false) ||
                ($0.productName?.lowercased().contains(query) ?? false)
            }
        }

        // Apply dietary preferences
        if !preferences.dietaryPreferences.isEmpty {
            let dietaryTags = preferences.dietaryPreferences.map { $0.rawValue }
            result = result.filter { coupon in
                // Include coupons that match dietary preferences or are in neutral categories
                let neutralCategories: [GroceryCouponCategory] = [.household, .personal, .baby, .pet]
                if neutralCategories.contains(coupon.category) {
                    return true
                }
                return coupon.tags.contains { dietaryTags.contains($0) } ||
                       dietaryTags.contains(coupon.category.rawValue)
            }
        }

        // Apply excluded categories
        if !preferences.excludedCategories.isEmpty {
            result = result.filter { !preferences.excludedCategories.contains($0.category) }
        }

        // Apply minimum discount filter
        if let minDiscount = preferences.minimumDiscountPercent {
            result = result.filter { coupon in
                if coupon.discountType == .percentOff {
                    return coupon.discountValue >= minDiscount
                }
                return true // Don't filter non-percent discounts
            }
        }

        // Apply digital only filter
        if preferences.showDigitalOnly {
            result = result.filter { $0.isDigital }
        }

        return sortCoupons(result)
    }

    var availableChains: [GroceryChain] {
        let chainsInCoupons = Set(coupons.map { $0.chain })
        return GroceryChain.allCases.filter { chainsInCoupons.contains($0) }
    }

    var availableCategories: [GroceryCouponCategory] {
        let categoriesInCoupons = Set(coupons.map { $0.category })
        return GroceryCouponCategory.allCases.filter { categoriesInCoupons.contains($0) }
    }

    var couponsByStore: [GroceryChain: [GroceryCoupon]] {
        Dictionary(grouping: filteredCoupons, by: { $0.chain })
    }

    var couponsByCategory: [GroceryCouponCategory: [GroceryCoupon]] {
        Dictionary(grouping: filteredCoupons, by: { $0.category })
    }

    var expiringSoonCoupons: [GroceryCoupon] {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return filteredCoupons.filter { $0.expiresAt <= threeDaysFromNow && !$0.isExpired }
    }

    // MARK: - Initialization

    init() {
        self.preferences = GroceryCouponPreferences.defaultPreferences
        loadPreferences()
        loadClippedCoupons()
        setupLocationObserver()
    }

    private func setupLocationObserver() {
        locationManager.$currentLocation
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] location in
                guard let self = self, location != nil else { return }
                Task { @MainActor in
                    await self.fetchCouponsForCurrentLocation()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Preferences Management

    func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let prefs = try? JSONDecoder().decode(GroceryCouponPreferences.self, from: data) {
            preferences = prefs
        }
    }

    func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: preferencesKey)
        }
        // Refresh coupons with new preferences
        Task { @MainActor in
            await fetchCouponsForCurrentLocation()
        }
    }

    func updatePreferredStores(_ stores: [GroceryChain]) {
        preferences.preferredStores = stores
        savePreferences()
    }

    func updateExcludedStores(_ stores: [GroceryChain]) {
        preferences.excludedStores = stores
        savePreferences()
    }

    func updateDietaryPreferences(_ dietary: [DietaryPreference]) {
        preferences.dietaryPreferences = dietary
        savePreferences()
    }

    func updateMaxDistance(_ miles: Double) {
        preferences.maxDistanceMiles = miles
        savePreferences()
    }

    func togglePreferredStore(_ chain: GroceryChain) {
        if preferences.preferredStores.contains(chain) {
            preferences.preferredStores.removeAll { $0 == chain }
        } else {
            preferences.preferredStores.append(chain)
            // Remove from excluded if adding to preferred
            preferences.excludedStores.removeAll { $0 == chain }
        }
        savePreferences()
    }

    func toggleExcludedStore(_ chain: GroceryChain) {
        if preferences.excludedStores.contains(chain) {
            preferences.excludedStores.removeAll { $0 == chain }
        } else {
            preferences.excludedStores.append(chain)
            // Remove from preferred if adding to excluded
            preferences.preferredStores.removeAll { $0 == chain }
        }
        savePreferences()
    }

    func toggleDietaryPreference(_ dietary: DietaryPreference) {
        if preferences.dietaryPreferences.contains(dietary) {
            preferences.dietaryPreferences.removeAll { $0 == dietary }
        } else {
            preferences.dietaryPreferences.append(dietary)
        }
        savePreferences()
    }

    // MARK: - Clipped Coupons

    private func loadClippedCoupons() {
        if let data = UserDefaults.standard.data(forKey: clippedCouponsKey),
           let clipped = try? JSONDecoder().decode(Set<String>.self, from: data) {
            clippedCoupons = clipped
        }
    }

    private func saveClippedCoupons() {
        if let data = try? JSONEncoder().encode(clippedCoupons) {
            UserDefaults.standard.set(data, forKey: clippedCouponsKey)
        }
    }

    func clipCoupon(_ coupon: GroceryCoupon) {
        clippedCoupons.insert(coupon.id)
        saveClippedCoupons()
        // TODO: Sync with backend
    }

    func unclipCoupon(_ coupon: GroceryCoupon) {
        clippedCoupons.remove(coupon.id)
        saveClippedCoupons()
    }

    func isCouponClipped(_ coupon: GroceryCoupon) -> Bool {
        clippedCoupons.contains(coupon.id)
    }

    // MARK: - Fetch Coupons

    @MainActor
    func fetchCouponsForCurrentLocation() async {
        guard let location = locationManager.currentLocation else {
            // Request location if not available
            locationManager.startUpdatingLocation()
            return
        }

        await fetchCoupons(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    @MainActor
    func fetchCoupons(latitude: Double, longitude: Double) async {
        isLoading = true
        error = nil

        // For now, load demo data
        // In production, this would call the backend API
        loadDemoCoupons(latitude: latitude, longitude: longitude)

        isLoading = false
        lastUpdated = Date()
        calculateTotalSavings()
    }

    @MainActor
    func refreshCoupons() async {
        await fetchCouponsForCurrentLocation()
    }

    // MARK: - Sorting

    private func sortCoupons(_ coupons: [GroceryCoupon]) -> [GroceryCoupon] {
        switch preferences.sortBy {
        case .relevance:
            return sortByRelevance(coupons)
        case .distance:
            return sortByDistance(coupons)
        case .savings:
            return coupons.sorted { $0.discountValue > $1.discountValue }
        case .expiringSoon:
            return coupons.sorted { $0.expiresAt < $1.expiresAt }
        case .newest:
            return coupons // Assume already sorted by newest from API
        case .category:
            return coupons.sorted { $0.category.displayName < $1.category.displayName }
        }
    }

    private func sortByRelevance(_ coupons: [GroceryCoupon]) -> [GroceryCoupon] {
        coupons.sorted { c1, c2 in
            var score1 = 0
            var score2 = 0

            // Preferred stores get priority
            if preferences.preferredStores.contains(c1.chain) { score1 += 10 }
            if preferences.preferredStores.contains(c2.chain) { score2 += 10 }

            // Preferred categories get priority
            if preferences.preferredCategories.contains(c1.category) { score1 += 5 }
            if preferences.preferredCategories.contains(c2.category) { score2 += 5 }

            // Clipped coupons get priority
            if clippedCoupons.contains(c1.id) { score1 += 3 }
            if clippedCoupons.contains(c2.id) { score2 += 3 }

            // Higher discounts get slight priority
            score1 += Int(c1.discountValue)
            score2 += Int(c2.discountValue)

            return score1 > score2
        }
    }

    private func sortByDistance(_ coupons: [GroceryCoupon]) -> [GroceryCoupon] {
        let storeDistances = Dictionary(uniqueKeysWithValues: nearbyStores.map { ($0.id, $0.distance ?? Double.infinity) })
        return coupons.sorted {
            (storeDistances[$0.storeId] ?? Double.infinity) < (storeDistances[$1.storeId] ?? Double.infinity)
        }
    }

    // MARK: - Calculations

    private func calculateTotalSavings() {
        totalPotentialSavings = filteredCoupons.reduce(0) { total, coupon in
            switch coupon.discountType {
            case .dollarOff, .cashback, .freeItem:
                return total + coupon.discountValue
            case .percentOff:
                // Estimate $5 average savings for percentage discounts
                return total + min(coupon.discountValue * 0.2, coupon.maxSavings ?? 10)
            case .buyOneGetOne:
                return total + (coupon.maxSavings ?? 5)
            case .buyOneGetOneHalf:
                return total + (coupon.maxSavings ?? 2.5)
            case .pointsMultiplier:
                return total // Points don't have direct dollar value
            }
        }
    }

    // MARK: - Demo Data

    private func loadDemoCoupons(latitude: Double, longitude: Double) {
        // Demo nearby stores
        nearbyStores = [
            GroceryStore(
                id: "kroger-1",
                name: "Kroger",
                chain: .kroger,
                address: "123 Main St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                latitude: latitude + 0.005,
                longitude: longitude + 0.003,
                distance: 0.4,
                isOpen: true,
                closingTime: "10:00 PM"
            ),
            GroceryStore(
                id: "safeway-1",
                name: "Safeway",
                chain: .safeway,
                address: "456 Oak Ave",
                city: "San Francisco",
                state: "CA",
                zipCode: "94103",
                latitude: latitude + 0.008,
                longitude: longitude - 0.002,
                distance: 0.7,
                isOpen: true,
                closingTime: "11:00 PM"
            ),
            GroceryStore(
                id: "wholefoods-1",
                name: "Whole Foods Market",
                chain: .wholefoods,
                address: "789 Market St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94104",
                latitude: latitude - 0.003,
                longitude: longitude + 0.006,
                distance: 0.5,
                isOpen: true,
                closingTime: "9:00 PM"
            ),
            GroceryStore(
                id: "target-1",
                name: "Target",
                chain: .target,
                address: "321 Mission St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                latitude: latitude + 0.012,
                longitude: longitude + 0.008,
                distance: 1.2,
                isOpen: true,
                closingTime: "10:00 PM"
            ),
            GroceryStore(
                id: "traderjoes-1",
                name: "Trader Joe's",
                chain: .traderjoes,
                address: "555 Folsom St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94107",
                latitude: latitude - 0.007,
                longitude: longitude - 0.004,
                distance: 0.8,
                isOpen: true,
                closingTime: "9:00 PM"
            )
        ]

        // Filter stores by preferences
        var filteredStores = nearbyStores

        if !preferences.preferredStores.isEmpty {
            // Show preferred stores first, then others
            filteredStores = nearbyStores.sorted { s1, s2 in
                let s1Preferred = preferences.preferredStores.contains(s1.chain)
                let s2Preferred = preferences.preferredStores.contains(s2.chain)
                if s1Preferred && !s2Preferred { return true }
                if !s1Preferred && s2Preferred { return false }
                return (s1.distance ?? 0) < (s2.distance ?? 0)
            }
        }

        if !preferences.excludedStores.isEmpty {
            filteredStores = filteredStores.filter { !preferences.excludedStores.contains($0.chain) }
        }

        nearbyStores = filteredStores.filter { ($0.distance ?? 0) <= preferences.maxDistanceMiles }

        // Demo coupons
        let calendar = Calendar.current
        let now = Date()

        coupons = [
            // Kroger Coupons
            GroceryCoupon(
                id: "kroger-c1",
                storeId: "kroger-1",
                chain: .kroger,
                title: "$2 off Fresh Organic Strawberries",
                description: "Save on 1 lb container of organic strawberries",
                discountType: .dollarOff,
                discountValue: 2.00,
                minimumPurchase: nil,
                maxSavings: 2.00,
                code: nil,
                barcode: "4901234567890",
                category: .produce,
                brand: nil,
                productName: "Organic Strawberries",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 7, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: true,
                limitPerCustomer: 2,
                tags: ["organic", "fruit", "produce"]
            ),
            GroceryCoupon(
                id: "kroger-c2",
                storeId: "kroger-1",
                chain: .kroger,
                title: "25% off Kroger Brand Cereal",
                description: "Any Kroger brand cereal, 12oz or larger",
                discountType: .percentOff,
                discountValue: 25,
                minimumPurchase: nil,
                maxSavings: 3.00,
                code: nil,
                barcode: "4901234567891",
                category: .pantry,
                brand: "Kroger",
                productName: "Kroger Cereal",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 14, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: false,
                requiresLoyaltyCard: true,
                limitPerCustomer: 4,
                tags: ["breakfast", "cereal"]
            ),
            GroceryCoupon(
                id: "kroger-c3",
                storeId: "kroger-1",
                chain: .kroger,
                title: "BOGO Chobani Greek Yogurt",
                description: "Buy one, get one free on any Chobani product",
                discountType: .buyOneGetOne,
                discountValue: 1.50,
                minimumPurchase: nil,
                maxSavings: 1.50,
                code: nil,
                barcode: "4901234567892",
                category: .dairy,
                brand: "Chobani",
                productName: "Greek Yogurt",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 5, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: false,
                requiresLoyaltyCard: true,
                limitPerCustomer: 1,
                tags: ["dairy", "yogurt", "protein"]
            ),

            // Safeway Coupons
            GroceryCoupon(
                id: "safeway-c1",
                storeId: "safeway-1",
                chain: .safeway,
                title: "$5 off $25 Purchase",
                description: "Save $5 on any purchase of $25 or more",
                discountType: .dollarOff,
                discountValue: 5.00,
                minimumPurchase: 25.00,
                maxSavings: 5.00,
                code: "SAVE5",
                barcode: nil,
                category: .other,
                brand: nil,
                productName: nil,
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 3, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: false,
                requiresLoyaltyCard: true,
                limitPerCustomer: 1,
                tags: ["storewide"]
            ),
            GroceryCoupon(
                id: "safeway-c2",
                storeId: "safeway-1",
                chain: .safeway,
                title: "$1 off Beyond Meat",
                description: "Any Beyond Meat product",
                discountType: .dollarOff,
                discountValue: 1.00,
                minimumPurchase: nil,
                maxSavings: 1.00,
                code: nil,
                barcode: "4901234567893",
                category: .meat,
                brand: "Beyond Meat",
                productName: "Beyond Burger",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 10, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: true,
                limitPerCustomer: 2,
                tags: ["vegan", "plant-based", "meat_alternative"]
            ),

            // Whole Foods Coupons
            GroceryCoupon(
                id: "wf-c1",
                storeId: "wholefoods-1",
                chain: .wholefoods,
                title: "10% off All Vitamins",
                description: "Prime members save 10% on all vitamins and supplements",
                discountType: .percentOff,
                discountValue: 10,
                minimumPurchase: nil,
                maxSavings: nil,
                code: nil,
                barcode: nil,
                category: .personal,
                brand: nil,
                productName: nil,
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 30, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: false,
                limitPerCustomer: nil,
                tags: ["vitamins", "supplements", "prime"]
            ),
            GroceryCoupon(
                id: "wf-c2",
                storeId: "wholefoods-1",
                chain: .wholefoods,
                title: "$3 off Organic Chicken",
                description: "Save on organic free-range chicken breast",
                discountType: .dollarOff,
                discountValue: 3.00,
                minimumPurchase: nil,
                maxSavings: 3.00,
                code: nil,
                barcode: "4901234567894",
                category: .meat,
                brand: nil,
                productName: "Organic Chicken Breast",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 4, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: false,
                requiresLoyaltyCard: false,
                limitPerCustomer: 2,
                tags: ["organic", "meat", "chicken"]
            ),
            GroceryCoupon(
                id: "wf-c3",
                storeId: "wholefoods-1",
                chain: .wholefoods,
                title: "FREE Organic Apple with $10 Purchase",
                description: "Get a free organic Honeycrisp apple with any $10 purchase",
                discountType: .freeItem,
                discountValue: 2.50,
                minimumPurchase: 10.00,
                maxSavings: 2.50,
                code: nil,
                barcode: nil,
                category: .produce,
                brand: nil,
                productName: "Organic Honeycrisp Apple",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 2, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: false,
                limitPerCustomer: 1,
                tags: ["organic", "fruit", "free"]
            ),

            // Target Coupons
            GroceryCoupon(
                id: "target-c1",
                storeId: "target-1",
                chain: .target,
                title: "15% off Good & Gather",
                description: "Save on any Good & Gather grocery item",
                discountType: .percentOff,
                discountValue: 15,
                minimumPurchase: nil,
                maxSavings: 5.00,
                code: nil,
                barcode: nil,
                category: .pantry,
                brand: "Good & Gather",
                productName: nil,
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 21, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: false,
                limitPerCustomer: nil,
                tags: ["pantry", "store_brand"]
            ),
            GroceryCoupon(
                id: "target-c2",
                storeId: "target-1",
                chain: .target,
                title: "$2 off Oatly Oat Milk",
                description: "Any Oatly product, 64 oz or larger",
                discountType: .dollarOff,
                discountValue: 2.00,
                minimumPurchase: nil,
                maxSavings: 2.00,
                code: nil,
                barcode: "4901234567895",
                category: .dairy,
                brand: "Oatly",
                productName: "Oat Milk",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 14, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: false,
                limitPerCustomer: 2,
                tags: ["dairy_free", "vegan", "milk_alternative"]
            ),
            GroceryCoupon(
                id: "target-c3",
                storeId: "target-1",
                chain: .target,
                title: "20% off Baby Food",
                description: "Save on all organic baby food pouches",
                discountType: .percentOff,
                discountValue: 20,
                minimumPurchase: nil,
                maxSavings: 10.00,
                code: nil,
                barcode: nil,
                category: .baby,
                brand: nil,
                productName: "Organic Baby Food",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 7, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: false,
                limitPerCustomer: nil,
                tags: ["baby", "organic"]
            ),

            // Additional coupons for variety
            GroceryCoupon(
                id: "kroger-c4",
                storeId: "kroger-1",
                chain: .kroger,
                title: "3x Fuel Points on Gift Cards",
                description: "Earn triple fuel points on all gift card purchases",
                discountType: .pointsMultiplier,
                discountValue: 3,
                minimumPurchase: nil,
                maxSavings: nil,
                code: nil,
                barcode: nil,
                category: .other,
                brand: nil,
                productName: nil,
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 5, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: false,
                requiresLoyaltyCard: true,
                limitPerCustomer: nil,
                tags: ["fuel_points", "gift_cards"]
            ),
            GroceryCoupon(
                id: "safeway-c3",
                storeId: "safeway-1",
                chain: .safeway,
                title: "$1.50 off Gluten-Free Bread",
                description: "Any Canyon Bakehouse gluten-free bread",
                discountType: .dollarOff,
                discountValue: 1.50,
                minimumPurchase: nil,
                maxSavings: 1.50,
                code: nil,
                barcode: "4901234567896",
                category: .bakery,
                brand: "Canyon Bakehouse",
                productName: "Gluten-Free Bread",
                imageUrl: nil,
                expiresAt: calendar.date(byAdding: .day, value: 12, to: now)!,
                isDigital: true,
                isClipped: false,
                isStackable: true,
                requiresLoyaltyCard: true,
                limitPerCustomer: 2,
                tags: ["gluten_free", "bread", "bakery"]
            )
        ]

        // Filter out coupons from excluded stores
        if !preferences.excludedStores.isEmpty {
            coupons = coupons.filter { !preferences.excludedStores.contains($0.chain) }
        }

        // Generate store stats
        generateStoreStats()
    }

    private func generateStoreStats() {
        let groupedByChain = Dictionary(grouping: coupons, by: { $0.chain })

        storeStats = groupedByChain.map { chain, chainCoupons in
            let totalSavings = chainCoupons.reduce(0.0) { total, coupon in
                switch coupon.discountType {
                case .dollarOff, .cashback, .freeItem:
                    return total + coupon.discountValue
                case .percentOff:
                    return total + (coupon.maxSavings ?? coupon.discountValue * 0.2)
                case .buyOneGetOne, .buyOneGetOneHalf:
                    return total + (coupon.maxSavings ?? 3.0)
                case .pointsMultiplier:
                    return total
                }
            }

            let clippedCount = chainCoupons.filter { clippedCoupons.contains($0.id) }.count
            let categories = Dictionary(grouping: chainCoupons, by: { $0.category })
            let favoriteCategory = categories.max(by: { $0.value.count < $1.value.count })?.key

            return StoreStats(
                id: chain.rawValue,
                chain: chain,
                totalCoupons: chainCoupons.count,
                totalSavings: totalSavings,
                clippedCoupons: clippedCount,
                usedCoupons: 0,
                favoriteCategory: favoriteCategory
            )
        }.sorted { $0.totalCoupons > $1.totalCoupons }
    }
}
