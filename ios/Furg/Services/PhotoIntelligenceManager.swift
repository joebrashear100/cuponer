import Foundation
import Vision
import UIKit
import CoreML
import Combine

// MARK: - Photo Intelligence Models

struct ProductAnalysis: Identifiable, Codable {
    let id: String
    let analysisDate: Date
    let imageData: Data?
    let detectedProducts: [DetectedProduct]
    let priceInfo: PriceInfo?
    let affordabilityAnalysis: AffordabilityAnalysis
    let alternatives: [ProductAlternative]
    let source: AnalysisSource

    enum AnalysisSource: String, Codable {
        case camera
        case screenshot
        case photoLibrary
        case sharedExtension
    }
}

struct DetectedProduct: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let category: String
    let confidence: Double
    let boundingBox: CGRect?
    var upc: String?
    var asin: String?
    var currentPrice: Double?
    var typicalPriceRange: PriceRange?

    struct PriceRange: Codable {
        let low: Double
        let average: Double
        let high: Double
    }
}

struct PriceInfo: Codable {
    let detectedPrice: Double?
    let currency: String
    let retailer: String?
    let originalPrice: Double?
    let salePrice: Double?
    let discountPercentage: Double?
    let pricePerUnit: String?
    let confidence: Double
}

struct AffordabilityAnalysis: Codable {
    let canAfford: Bool
    let impactOnBudget: BudgetImpact
    let hoursOfWork: Double
    let percentageOfIncome: Double
    let recommendation: String
    let waitSuggestion: WaitSuggestion?

    enum BudgetImpact: String, Codable {
        case minimal = "Minimal Impact"
        case moderate = "Moderate Impact"
        case significant = "Significant Impact"
        case overBudget = "Over Budget"
    }

    struct WaitSuggestion: Codable {
        let reason: String
        let suggestedDate: Date?
        let potentialSavings: Double?
    }
}

struct ProductAlternative: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let price: Double
    let retailer: String
    let savings: Double
    let url: String?
    let rating: Double?
    let reviewCount: Int?
}

enum PhotoWishlistPriority: String, Codable, CaseIterable {
    case low, medium, high, urgent

    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

struct PhotoWishlistItem: Identifiable, Codable {
    let id: String
    var name: String
    var brand: String?
    var targetPrice: Double?
    var currentLowestPrice: Double?
    var imageData: Data?
    var category: String
    var addedDate: Date
    var priceHistory: [PriceHistoryEntry]
    var priceAlertEnabled: Bool
    var priceAlertThreshold: Double?
    var retailers: [RetailerListing]
    var notes: String?
    var priority: PhotoWishlistPriority

    struct PriceHistoryEntry: Codable {
        let date: Date
        let price: Double
        let retailer: String
    }

    struct RetailerListing: Codable {
        let retailer: String
        let price: Double
        let url: String?
        let inStock: Bool
        let lastChecked: Date
    }

    var lowestAvailablePrice: Double? {
        retailers.filter { $0.inStock }.min { $0.price < $1.price }?.price
    }

    var isOnSale: Bool {
        guard let target = targetPrice, let current = currentLowestPrice else { return false }
        return current <= target
    }
}

struct ProductScan: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let imageData: Data?
    let products: [DetectedProduct]
    let context: ScanContext

    enum ScanContext: String, Codable {
        case inStore
        case online
        case wishlist
        case priceCheck
        case comparison
    }
}

// MARK: - Photo Intelligence Manager

class PhotoIntelligenceManager: ObservableObject {
    static let shared = PhotoIntelligenceManager()

    // MARK: - Published Properties
    @Published var recentAnalyses: [ProductAnalysis] = []
    @Published var wishlist: [PhotoWishlistItem] = []
    @Published var productScans: [ProductScan] = []

    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0
    @Published var lastError: String?

    // Price alerts
    @Published var activePriceAlerts: Int = 0
    @Published var recentPriceDrops: [WishlistItem] = []

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let analysesKey = "photoIntel_analyses"
    private let wishlistKey = "photoIntel_wishlist"
    private let scansKey = "photoIntel_scans"

    // Vision requests
    private lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }()

    private lazy var barcodeDetectionRequest: VNDetectBarcodesRequest = {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128, .qr]
        return request
    }()

    // Product database (simplified - in production would use API)
    private let productKeywords: [String: (category: String, avgPrice: Double)] = [
        "iphone": ("Electronics", 999),
        "airpods": ("Electronics", 179),
        "macbook": ("Electronics", 1299),
        "ipad": ("Electronics", 449),
        "apple watch": ("Electronics", 399),
        "samsung": ("Electronics", 799),
        "nike": ("Clothing", 120),
        "adidas": ("Clothing", 100),
        "lululemon": ("Clothing", 98),
        "dyson": ("Home", 400),
        "kitchenaid": ("Home", 350),
        "sony": ("Electronics", 299),
        "bose": ("Electronics", 279),
        "nintendo switch": ("Gaming", 299),
        "playstation": ("Gaming", 499),
        "xbox": ("Gaming", 499)
    ]

    // MARK: - Initialization

    init() {
        loadData()
        updatePriceAlertStats()
    }

    // MARK: - Image Analysis

    func analyzeImage(_ image: UIImage, source: ProductAnalysis.AnalysisSource) async throws -> ProductAnalysis {
        isAnalyzing = true
        analysisProgress = 0
        lastError = nil

        defer { isAnalyzing = false }

        guard let cgImage = image.cgImage else {
            throw PhotoAnalysisError.invalidImage
        }

        // Run text recognition and barcode detection in parallel
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        analysisProgress = 0.1

        // Recognize text
        var recognizedText: [String] = []
        var detectedBarcodes: [String] = []

        let textRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
        }
        textRequest.recognitionLevel = .accurate

        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            guard let observations = request.results as? [VNBarcodeObservation] else { return }
            detectedBarcodes = observations.compactMap { $0.payloadStringValue }
        }

        try handler.perform([textRequest, barcodeRequest])

        analysisProgress = 0.4

        // Detect products from text
        let detectedProducts = detectProducts(from: recognizedText, barcodes: detectedBarcodes)
        analysisProgress = 0.6

        // Extract price information
        let priceInfo = extractPriceInfo(from: recognizedText)
        analysisProgress = 0.7

        // Perform affordability analysis
        let affordability = analyzeAffordability(
            price: priceInfo?.detectedPrice ?? detectedProducts.first?.currentPrice,
            category: detectedProducts.first?.category ?? "Other"
        )
        analysisProgress = 0.8

        // Find alternatives
        let alternatives = findAlternatives(for: detectedProducts.first, currentPrice: priceInfo?.detectedPrice)
        analysisProgress = 0.9

        let analysis = ProductAnalysis(
            id: UUID().uuidString,
            analysisDate: Date(),
            imageData: image.jpegData(compressionQuality: 0.6),
            detectedProducts: detectedProducts,
            priceInfo: priceInfo,
            affordabilityAnalysis: affordability,
            alternatives: alternatives,
            source: source
        )

        recentAnalyses.insert(analysis, at: 0)
        saveAnalyses()

        analysisProgress = 1.0

        return analysis
    }

    func analyzeScreenshot(_ image: UIImage) async throws -> ProductAnalysis {
        // Screenshots often have cleaner text and prices
        return try await analyzeImage(image, source: .screenshot)
    }

    func quickPriceCheck(_ image: UIImage) async throws -> PriceInfo? {
        guard let cgImage = image.cgImage else { return nil }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var recognizedText: [String] = []

        let textRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
        }
        textRequest.recognitionLevel = .fast

        try handler.perform([textRequest])

        return extractPriceInfo(from: recognizedText)
    }

    // MARK: - Product Detection

    private func detectProducts(from text: [String], barcodes: [String]) -> [DetectedProduct] {
        var products: [DetectedProduct] = []
        let combinedText = text.joined(separator: " ").lowercased()

        // Check for known product keywords
        for (keyword, info) in productKeywords {
            if combinedText.contains(keyword) {
                // Try to extract specific model/name
                let productName = extractProductName(from: text, keyword: keyword)

                products.append(DetectedProduct(
                    id: UUID().uuidString,
                    name: productName ?? keyword.capitalized,
                    brand: extractBrand(from: keyword),
                    category: info.category,
                    confidence: 0.8,
                    boundingBox: nil,
                    upc: barcodes.first,
                    asin: nil,
                    currentPrice: nil,
                    typicalPriceRange: DetectedProduct.PriceRange(
                        low: info.avgPrice * 0.8,
                        average: info.avgPrice,
                        high: info.avgPrice * 1.2
                    )
                ))
            }
        }

        // If no known products, try to identify from barcodes
        if products.isEmpty && !barcodes.isEmpty {
            for barcode in barcodes {
                products.append(DetectedProduct(
                    id: UUID().uuidString,
                    name: "Product (UPC: \(barcode))",
                    brand: nil,
                    category: "Unknown",
                    confidence: 0.5,
                    boundingBox: nil,
                    upc: barcode,
                    asin: nil,
                    currentPrice: nil,
                    typicalPriceRange: nil
                ))
            }
        }

        // Generic product detection from text
        if products.isEmpty {
            let potentialProduct = extractGenericProduct(from: text)
            if let product = potentialProduct {
                products.append(product)
            }
        }

        return products
    }

    private func extractProductName(from text: [String], keyword: String) -> String? {
        for line in text {
            if line.lowercased().contains(keyword) {
                return line.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func extractBrand(from keyword: String) -> String? {
        let brands = ["apple", "samsung", "nike", "adidas", "lululemon", "dyson", "sony", "bose", "nintendo", "microsoft"]
        for brand in brands {
            if keyword.lowercased().contains(brand) {
                return brand.capitalized
            }
        }
        return nil
    }

    private func extractGenericProduct(from text: [String]) -> DetectedProduct? {
        // Look for product-like text (capitalized words, not too long)
        for line in text {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.count > 3 && trimmed.count < 50 &&
               !trimmed.contains("$") &&
               trimmed.first?.isUppercase == true {
                return DetectedProduct(
                    id: UUID().uuidString,
                    name: trimmed,
                    brand: nil,
                    category: "Unknown",
                    confidence: 0.4,
                    boundingBox: nil,
                    upc: nil,
                    asin: nil,
                    currentPrice: nil,
                    typicalPriceRange: nil
                )
            }
        }
        return nil
    }

    // MARK: - Price Extraction

    private func extractPriceInfo(from text: [String]) -> PriceInfo? {
        var detectedPrice: Double?
        var originalPrice: Double?
        var retailer: String?
        var currency = "USD"

        let pricePatterns = [
            "\\$([0-9,]+\\.?[0-9]{0,2})",
            "([0-9,]+\\.?[0-9]{0,2})\\s*(?:USD|dollars)",
            "price[:\\s]*\\$?([0-9,]+\\.?[0-9]{0,2})"
        ]

        var prices: [Double] = []

        for line in text {
            for pattern in pricePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(line.startIndex..., in: line)
                    let matches = regex.matches(in: line, range: range)

                    for match in matches {
                        if let priceRange = Range(match.range(at: 1), in: line) {
                            let priceString = String(line[priceRange]).replacingOccurrences(of: ",", with: "")
                            if let price = Double(priceString), price > 0, price < 100000 {
                                prices.append(price)
                            }
                        }
                    }
                }
            }

            // Check for retailer
            let retailers = ["amazon", "walmart", "target", "best buy", "costco", "apple", "ebay"]
            for r in retailers {
                if line.lowercased().contains(r) {
                    retailer = r.capitalized
                    break
                }
            }
        }

        guard !prices.isEmpty else { return nil }

        // Sort prices - usually current price is the prominent one
        prices.sort()

        // If we have multiple prices, try to identify sale vs original
        if prices.count >= 2 {
            detectedPrice = prices.first
            originalPrice = prices.last
        } else {
            detectedPrice = prices.first
        }

        var discountPercentage: Double?
        if let original = originalPrice, let current = detectedPrice, original > current {
            discountPercentage = ((original - current) / original) * 100
        }

        return PriceInfo(
            detectedPrice: detectedPrice,
            currency: currency,
            retailer: retailer,
            originalPrice: originalPrice,
            salePrice: (originalPrice != nil && detectedPrice != originalPrice) ? detectedPrice : nil,
            discountPercentage: discountPercentage,
            pricePerUnit: nil,
            confidence: prices.count == 1 ? 0.9 : 0.7
        )
    }

    // MARK: - Affordability Analysis

    private func analyzeAffordability(price: Double?, category: String) -> AffordabilityAnalysis {
        guard let price = price else {
            return AffordabilityAnalysis(
                canAfford: true,
                impactOnBudget: .minimal,
                hoursOfWork: 0,
                percentageOfIncome: 0,
                recommendation: "Unable to determine price",
                waitSuggestion: nil
            )
        }

        let timeWealthManager = TimeWealthManager.shared
        let hoursOfWork = timeWealthManager.hoursForAmount(price)

        // Get monthly income estimate
        let monthlyIncome = timeWealthManager.profile.annualIncome / 12
        let percentageOfIncome = (price / monthlyIncome) * 100

        // Determine budget impact
        let impact: AffordabilityAnalysis.BudgetImpact
        if percentageOfIncome < 1 {
            impact = .minimal
        } else if percentageOfIncome < 5 {
            impact = .moderate
        } else if percentageOfIncome < 15 {
            impact = .significant
        } else {
            impact = .overBudget
        }

        // Generate recommendation
        let recommendation: String
        var waitSuggestion: AffordabilityAnalysis.WaitSuggestion?

        switch impact {
        case .minimal:
            recommendation = "This purchase fits comfortably within your budget."
        case .moderate:
            recommendation = "This is a moderate expense. Consider if it aligns with your financial goals."
        case .significant:
            recommendation = "This is a significant purchase. Make sure you've budgeted for it."
            waitSuggestion = AffordabilityAnalysis.WaitSuggestion(
                reason: "Consider waiting for a sale or saving up first",
                suggestedDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                potentialSavings: price * 0.15
            )
        case .overBudget:
            recommendation = "This purchase may strain your budget. Consider alternatives or saving up."
            waitSuggestion = AffordabilityAnalysis.WaitSuggestion(
                reason: "This exceeds recommended spending. Save up over time.",
                suggestedDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                potentialSavings: price * 0.20
            )
        }

        return AffordabilityAnalysis(
            canAfford: impact != .overBudget,
            impactOnBudget: impact,
            hoursOfWork: hoursOfWork,
            percentageOfIncome: percentageOfIncome,
            recommendation: recommendation,
            waitSuggestion: waitSuggestion
        )
    }

    // MARK: - Alternatives

    private func findAlternatives(for product: DetectedProduct?, currentPrice: Double?) -> [ProductAlternative] {
        guard let product = product, let price = currentPrice else { return [] }

        // In production, this would call price comparison APIs
        // For now, generate simulated alternatives
        var alternatives: [ProductAlternative] = []

        let retailers = ["Amazon", "Walmart", "Target", "Best Buy", "eBay"]
        let variations: [(retailer: String, discount: Double)] = [
            (retailers[0], 0.05),
            (retailers[1], 0.08),
            (retailers[2], 0.03),
            (retailers[3], 0.10),
            (retailers[4], 0.15)
        ].shuffled().prefix(3).map { $0 }

        for variation in variations {
            let altPrice = price * (1 - variation.discount)
            alternatives.append(ProductAlternative(
                id: UUID().uuidString,
                name: product.name,
                brand: product.brand,
                price: altPrice,
                retailer: variation.retailer,
                savings: price - altPrice,
                url: nil,
                rating: Double.random(in: 4.0...5.0),
                reviewCount: Int.random(in: 100...5000)
            ))
        }

        return alternatives.sorted { $0.price < $1.price }
    }

    // MARK: - Wishlist Management

    func addToWishlist(from analysis: ProductAnalysis) {
        guard let product = analysis.detectedProducts.first else { return }

        let item = PhotoWishlistItem(
            id: UUID().uuidString,
            name: product.name,
            brand: product.brand,
            targetPrice: analysis.priceInfo?.detectedPrice.map { $0 * 0.85 },
            currentLowestPrice: analysis.priceInfo?.detectedPrice,
            imageData: analysis.imageData,
            category: product.category,
            addedDate: Date(),
            priceHistory: analysis.priceInfo?.detectedPrice.map {
                [PhotoWishlistItem.PriceHistoryEntry(
                    date: Date(),
                    price: $0,
                    retailer: analysis.priceInfo?.retailer ?? "Unknown"
                )]
            } ?? [],
            priceAlertEnabled: true,
            priceAlertThreshold: analysis.priceInfo?.detectedPrice.map { $0 * 0.85 },
            retailers: analysis.alternatives.map {
                PhotoWishlistItem.RetailerListing(
                    retailer: $0.retailer,
                    price: $0.price,
                    url: $0.url,
                    inStock: true,
                    lastChecked: Date()
                )
            },
            notes: nil,
            priority: .medium
        )

        wishlist.insert(item, at: 0)
        saveWishlist()
        updatePriceAlertStats()
    }

    func addToWishlist(name: String, targetPrice: Double?, category: String, imageData: Data?) {
        let item = PhotoWishlistItem(
            id: UUID().uuidString,
            name: name,
            brand: nil,
            targetPrice: targetPrice,
            currentLowestPrice: nil,
            imageData: imageData,
            category: category,
            addedDate: Date(),
            priceHistory: [],
            priceAlertEnabled: targetPrice != nil,
            priceAlertThreshold: targetPrice,
            retailers: [],
            notes: nil,
            priority: .medium
        )

        wishlist.insert(item, at: 0)
        saveWishlist()
        updatePriceAlertStats()
    }

    func updateWishlistItem(_ item: PhotoWishlistItem) {
        if let index = wishlist.firstIndex(where: { $0.id == item.id }) {
            wishlist[index] = item
            saveWishlist()
            updatePriceAlertStats()
        }
    }

    func removeFromWishlist(_ itemId: String) {
        wishlist.removeAll { $0.id == itemId }
        saveWishlist()
        updatePriceAlertStats()
    }

    func checkWishlistPrices() async {
        // In production, this would check actual retailer prices
        // For now, simulate price changes
        for i in 0..<wishlist.count {
            var item = wishlist[i]

            // Simulate price check
            if let currentPrice = item.currentLowestPrice {
                let priceChange = Double.random(in: -0.1...0.05)
                let newPrice = currentPrice * (1 + priceChange)

                item.priceHistory.append(PhotoWishlistItem.PriceHistoryEntry(
                    date: Date(),
                    price: newPrice,
                    retailer: item.retailers.first?.retailer ?? "Unknown"
                ))
                item.currentLowestPrice = newPrice

                // Update retailers
                for j in 0..<item.retailers.count {
                    var retailer = item.retailers[j]
                    retailer = PhotoWishlistItem.RetailerListing(
                        retailer: retailer.retailer,
                        price: retailer.price * (1 + Double.random(in: -0.1...0.05)),
                        url: retailer.url,
                        inStock: Bool.random(),
                        lastChecked: Date()
                    )
                    item.retailers[j] = retailer
                }

                wishlist[i] = item
            }
        }

        saveWishlist()
        updatePriceAlertStats()
    }

    private func updatePriceAlertStats() {
        activePriceAlerts = wishlist.filter { $0.priceAlertEnabled }.count
        recentPriceDrops = wishlist.filter { $0.isOnSale }
    }

    // MARK: - Best Card Recommendation

    func getBestCardForPurchase(amount: Double, category: String, retailer: String?) -> (cardName: String, cashBack: Double, reason: String)? {
        // Integrate with CardOptimizer
        let cardOptimizer = CardOptimizer.shared

        if let recommendation = cardOptimizer.getRecommendation(for: retailer ?? category, amount: amount) {
            return (
                recommendation.card.name,
                recommendation.estimatedReward,
                "Best for \(category)"
            )
        }

        return nil
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: analysesKey),
           let analyses = try? JSONDecoder().decode([ProductAnalysis].self, from: data) {
            recentAnalyses = analyses
        }

        if let data = userDefaults.data(forKey: wishlistKey),
           let items = try? JSONDecoder().decode([PhotoWishlistItem].self, from: data) {
            wishlist = items
        }

        if let data = userDefaults.data(forKey: scansKey),
           let scans = try? JSONDecoder().decode([ProductScan].self, from: data) {
            productScans = scans
        }
    }

    private func saveAnalyses() {
        // Keep last 50 analyses
        let toSave = Array(recentAnalyses.prefix(50))
        if let data = try? JSONEncoder().encode(toSave) {
            userDefaults.set(data, forKey: analysesKey)
        }
    }

    private func saveWishlist() {
        if let data = try? JSONEncoder().encode(wishlist) {
            userDefaults.set(data, forKey: wishlistKey)
        }
    }

    private func saveScans() {
        if let data = try? JSONEncoder().encode(productScans) {
            userDefaults.set(data, forKey: scansKey)
        }
    }
}

// MARK: - Errors

enum PhotoAnalysisError: Error, LocalizedError {
    case invalidImage
    case analysisFailef
    case noProductDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image provided"
        case .analysisFailef: return "Failed to analyze image"
        case .noProductDetected: return "No product detected in image"
        }
    }
}
