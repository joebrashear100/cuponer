import Foundation
import ARKit
import Vision
import Combine
import CoreML

// MARK: - AR Shopping Models

struct ARProductDetection: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let productName: String
    let brand: String?
    let category: String
    let detectedPrice: Double?
    let confidence: Double
    let boundingBox: CGRect
    let barcode: String?

    // Affordability
    var affordabilityAnalysis: ARAffordabilityAnalysis?
    var priceComparison: ARPriceComparison?
    var bestCard: ARCardRecommendation?
}

struct ARAffordabilityAnalysis: Codable {
    let canAfford: Bool
    let hoursOfWork: Double
    let percentOfDailyBudget: Double
    let percentOfMonthlyBudget: Double
    let impactLevel: ImpactLevel
    let recommendation: String
    let color: String // green, yellow, orange, red

    enum ImpactLevel: String, Codable {
        case negligible = "Negligible"
        case minor = "Minor"
        case moderate = "Moderate"
        case significant = "Significant"
        case major = "Major"

        var emoji: String {
            switch self {
            case .negligible: return "✅"
            case .minor: return "👍"
            case .moderate: return "🤔"
            case .significant: return "⚠️"
            case .major: return "🛑"
            }
        }
    }
}

struct ARPriceComparison: Codable {
    let currentStore: String
    let currentPrice: Double
    let alternatives: [StorePrice]
    let bestPrice: StorePrice?
    let potentialSavings: Double
    let priceRating: PriceRating

    struct StorePrice: Codable, Identifiable {
        var id: String { store }
        let store: String
        let price: Double
        let distance: Double? // miles
        let inStock: Bool
        let url: String?
    }

    enum PriceRating: String, Codable {
        case excellent = "Excellent Price"
        case good = "Good Price"
        case fair = "Fair Price"
        case high = "High Price"
        case overpriced = "Overpriced"

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "yellow"
            case .high: return "orange"
            case .overpriced: return "red"
            }
        }
    }
}

struct ARCardRecommendation: Codable {
    let cardName: String
    let cardIssuer: String
    let rewardRate: Double
    let rewardType: String // cash back, points, miles
    let estimatedReward: Double
    let specialOffer: String?
    let isRotatingCategory: Bool
}

struct ARAnnotation: Identifiable {
    let id: String
    let position: simd_float3
    let product: ARProductDetection
    var isExpanded: Bool = false
}

struct ARShoppingSession: Identifiable, Codable {
    let id: String
    let startTime: Date
    var endTime: Date?
    let storeName: String?
    var detectedProducts: [ARProductDetection]
    var totalPotentialSpend: Double
    var totalPotentialSavings: Double
    var productsAddedToCart: [String] // Product IDs
    var productsDismissed: [String]
}

struct ProductRecognitionResult {
    let name: String
    let brand: String?
    let category: String
    let confidence: Double
    let boundingBox: CGRect
    let barcode: String?
    let priceTag: Double?
}

// MARK: - AR Shopping Manager

class ARShoppingManager: NSObject, ObservableObject {
    static let shared = ARShoppingManager()

    // MARK: - Published Properties
    @Published var isARSupported: Bool = false
    @Published var isSessionActive: Bool = false
    @Published var currentSession: ARShoppingSession?
    @Published var detectedProducts: [ARProductDetection] = []
    @Published var annotations: [ARAnnotation] = []
    @Published var pastSessions: [ARShoppingSession] = []

    @Published var isProcessing: Bool = false
    @Published var currentStoreName: String?
    @Published var scanMode: ScanMode = .automatic

    // Budget context
    @Published var dailyBudgetRemaining: Double = 100
    @Published var monthlyBudgetRemaining: Double = 2000
    @Published var hourlyRate: Double = 25 // From TimeWealthManager

    enum ScanMode: String, CaseIterable {
        case automatic = "Auto Scan"
        case manual = "Tap to Scan"
        case barcode = "Barcode Only"
    }

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "arShopping_sessions"

    // Vision requests
    private lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }()

    private lazy var barcodeRequest: VNDetectBarcodesRequest = {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128, .qr, .dataMatrix]
        return request
    }()

    // Product database (simplified - would be ML model or API in production)
    private let productPatterns: [String: (category: String, avgPrice: Double)] = [
        "iphone": ("Electronics", 999),
        "airpods": ("Electronics", 179),
        "macbook": ("Electronics", 1299),
        "ipad": ("Electronics", 449),
        "apple watch": ("Electronics", 399),
        "samsung galaxy": ("Electronics", 899),
        "playstation": ("Gaming", 499),
        "xbox": ("Gaming", 499),
        "nintendo switch": ("Gaming", 299),
        "dyson": ("Home", 400),
        "vitamix": ("Kitchen", 450),
        "kitchenaid": ("Kitchen", 350),
        "nike": ("Clothing", 120),
        "adidas": ("Clothing", 100),
        "lululemon": ("Clothing", 98),
        "yeti": ("Outdoor", 35),
        "hydroflask": ("Outdoor", 40),
        "instant pot": ("Kitchen", 100),
        "roomba": ("Home", 350),
        "sonos": ("Electronics", 200),
        "bose": ("Electronics", 279),
        "sony": ("Electronics", 299),
        "lg": ("Electronics", 500),
        "samsung tv": ("Electronics", 800),
        "gopro": ("Electronics", 350),
        "fitbit": ("Electronics", 150),
        "kindle": ("Electronics", 100),
        "echo": ("Electronics", 50),
        "nest": ("Home", 130)
    ]

    // Store price variations (simulated)
    private let storeMultipliers: [String: Double] = [
        "Amazon": 0.95,
        "Walmart": 0.92,
        "Target": 1.0,
        "Best Buy": 1.02,
        "Costco": 0.88,
        "Apple Store": 1.0,
        "Home Depot": 0.97,
        "Bed Bath & Beyond": 1.05
    ]

    // MARK: - Initialization

    override init() {
        super.init()
        checkARSupport()
        loadSessions()
        loadBudgetContext()
    }

    private func checkARSupport() {
        isARSupported = ARWorldTrackingConfiguration.isSupported
    }

    private func loadBudgetContext() {
        // Integrate with TimeWealthManager
        hourlyRate = TimeWealthManager.shared.profile.trueHourlyRate

        // Would integrate with actual budget tracking
        // For now, use defaults
    }

    // MARK: - Session Management

    func startSession(storeName: String? = nil) {
        let session = ARShoppingSession(
            id: UUID().uuidString,
            startTime: Date(),
            endTime: nil,
            storeName: storeName ?? currentStoreName,
            detectedProducts: [],
            totalPotentialSpend: 0,
            totalPotentialSavings: 0,
            productsAddedToCart: [],
            productsDismissed: []
        )

        currentSession = session
        isSessionActive = true
        detectedProducts = []
        annotations = []
    }

    /// Alias for startSession - used by views
    func startShoppingSession(storeName: String? = nil) {
        startSession(storeName: storeName)
    }

    func endSession() {
        guard var session = currentSession else { return }

        session.endTime = Date()
        session.detectedProducts = detectedProducts
        session.totalPotentialSpend = detectedProducts.compactMap { $0.detectedPrice }.reduce(0, +)
        session.totalPotentialSavings = detectedProducts.compactMap { $0.priceComparison?.potentialSavings }.reduce(0, +)

        pastSessions.insert(session, at: 0)
        saveSessions()

        currentSession = nil
        isSessionActive = false
        detectedProducts = []
        annotations = []
    }

    /// Alias for endSession - used by views
    func endShoppingSession() {
        endSession()
    }

    // MARK: - Product Detection

    func processFrame(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) async -> [ProductRecognitionResult] {
        guard !isProcessing else { return [] }
        isProcessing = true
        defer { isProcessing = false }

        var results: [ProductRecognitionResult] = []

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])

        // Run text recognition
        var recognizedTexts: [(String, CGRect)] = []
        let textRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            for observation in observations {
                if let text = observation.topCandidates(1).first?.string {
                    recognizedTexts.append((text, observation.boundingBox))
                }
            }
        }
        textRequest.recognitionLevel = .fast

        // Run barcode detection
        var detectedBarcodes: [(String, CGRect)] = []
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            guard let observations = request.results as? [VNBarcodeObservation] else { return }
            for observation in observations {
                if let payload = observation.payloadStringValue {
                    detectedBarcodes.append((payload, observation.boundingBox))
                }
            }
        }

        do {
            try handler.perform([textRequest, barcodeRequest])
        } catch {
            print("Vision error: \(error)")
            return []
        }

        // Process recognized text for products
        let allText = recognizedTexts.map { $0.0 }.joined(separator: " ").lowercased()

        for (keyword, info) in productPatterns {
            if allText.contains(keyword) {
                // Find the bounding box for this product
                let relevantBox = recognizedTexts.first { $0.0.lowercased().contains(keyword) }?.1 ?? .zero

                // Try to find price nearby
                let detectedPrice = findPriceNearby(in: recognizedTexts, near: relevantBox)

                results.append(ProductRecognitionResult(
                    name: keyword.capitalized,
                    brand: extractBrand(from: keyword),
                    category: info.category,
                    confidence: 0.8,
                    boundingBox: relevantBox,
                    barcode: nil,
                    priceTag: detectedPrice ?? info.avgPrice
                ))
            }
        }

        // Process barcodes
        for (barcode, box) in detectedBarcodes {
            // In production, would lookup barcode in database
            let priceNearby = findPriceNearby(in: recognizedTexts, near: box)

            results.append(ProductRecognitionResult(
                name: "Product (\(barcode.prefix(8))...)",
                brand: nil,
                category: "Unknown",
                confidence: 0.9,
                boundingBox: box,
                barcode: barcode,
                priceTag: priceNearby
            ))
        }

        return results
    }

    private func findPriceNearby(in texts: [(String, CGRect)], near box: CGRect) -> Double? {
        let pricePattern = "\\$([0-9,]+\\.?[0-9]{0,2})"

        for (text, textBox) in texts {
            // Check if text is near the product (within reasonable distance)
            let distance = abs(textBox.midY - box.midY) + abs(textBox.midX - box.midX)
            guard distance < 0.5 else { continue }

            if let regex = try? NSRegularExpression(pattern: pricePattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let priceRange = Range(match.range(at: 1), in: text) {
                let priceString = String(text[priceRange]).replacingOccurrences(of: ",", with: "")
                if let price = Double(priceString) {
                    return price
                }
            }
        }

        return nil
    }

    private func extractBrand(from keyword: String) -> String? {
        let brands = ["apple", "samsung", "nike", "adidas", "sony", "bose", "lg", "dyson", "kitchenaid", "nintendo", "microsoft", "gopro", "fitbit", "nest", "sonos", "yeti", "lululemon"]

        for brand in brands {
            if keyword.contains(brand) {
                return brand.capitalized
            }
        }
        return nil
    }

    // MARK: - Product Analysis

    func analyzeProduct(_ result: ProductRecognitionResult, at position: simd_float3? = nil) -> ARProductDetection {
        let price = result.priceTag ?? productPatterns[result.name.lowercased()]?.avgPrice ?? 50

        // Affordability analysis
        let affordability = calculateAffordability(price: price)

        // Price comparison
        let comparison = generatePriceComparison(productName: result.name, currentPrice: price)

        // Card recommendation
        let cardRec = getCardRecommendation(category: result.category, price: price)

        var detection = ARProductDetection(
            id: UUID().uuidString,
            timestamp: Date(),
            productName: result.name,
            brand: result.brand,
            category: result.category,
            detectedPrice: price,
            confidence: result.confidence,
            boundingBox: result.boundingBox,
            barcode: result.barcode,
            affordabilityAnalysis: affordability,
            priceComparison: comparison,
            bestCard: cardRec
        )

        // Add to current detections if not duplicate
        if !detectedProducts.contains(where: { $0.productName == detection.productName }) {
            detectedProducts.append(detection)

            // Create AR annotation if position provided
            if let pos = position {
                annotations.append(ARAnnotation(
                    id: detection.id,
                    position: pos,
                    product: detection
                ))
            }
        }

        return detection
    }

    private func calculateAffordability(price: Double) -> ARAffordabilityAnalysis {
        let hoursOfWork = price / hourlyRate
        let percentDaily = (price / dailyBudgetRemaining) * 100
        let percentMonthly = (price / monthlyBudgetRemaining) * 100

        let impactLevel: ARAffordabilityAnalysis.ImpactLevel
        let color: String
        let recommendation: String
        let canAfford: Bool

        if percentDaily < 10 {
            impactLevel = .negligible
            color = "green"
            recommendation = "This fits easily in your budget"
            canAfford = true
        } else if percentDaily < 25 {
            impactLevel = .minor
            color = "green"
            recommendation = "Affordable - consider if you need it"
            canAfford = true
        } else if percentDaily < 50 {
            impactLevel = .moderate
            color = "yellow"
            recommendation = "Think about it - this is a noticeable expense"
            canAfford = true
        } else if percentDaily < 100 {
            impactLevel = .significant
            color = "orange"
            recommendation = "This will use most of your daily budget"
            canAfford = percentMonthly < 50
        } else {
            impactLevel = .major
            color = "red"
            recommendation = "This exceeds your daily budget - sleep on it"
            canAfford = percentMonthly < 25
        }

        return ARAffordabilityAnalysis(
            canAfford: canAfford,
            hoursOfWork: hoursOfWork,
            percentOfDailyBudget: percentDaily,
            percentOfMonthlyBudget: percentMonthly,
            impactLevel: impactLevel,
            recommendation: recommendation,
            color: color
        )
    }

    private func generatePriceComparison(productName: String, currentPrice: Double) -> ARPriceComparison {
        let currentStore = currentStoreName ?? "This Store"

        var alternatives: [ARPriceComparison.StorePrice] = []

        for (store, multiplier) in storeMultipliers where store != currentStore {
            let storePrice = currentPrice * multiplier * Double.random(in: 0.95...1.05)
            alternatives.append(ARPriceComparison.StorePrice(
                store: store,
                price: storePrice,
                distance: Double.random(in: 0.5...10),
                inStock: Bool.random() || store == "Amazon",
                url: store == "Amazon" ? "https://amazon.com" : nil
            ))
        }

        alternatives.sort { $0.price < $1.price }
        let bestPrice = alternatives.first { $0.inStock }
        let potentialSavings = bestPrice.map { currentPrice - $0.price } ?? 0

        // Rate the current price
        let avgPrice = alternatives.reduce(0) { $0 + $1.price } / Double(alternatives.count)
        let priceRating: ARPriceComparison.PriceRating

        let ratio = currentPrice / avgPrice
        if ratio < 0.9 {
            priceRating = .excellent
        } else if ratio < 0.98 {
            priceRating = .good
        } else if ratio < 1.05 {
            priceRating = .fair
        } else if ratio < 1.15 {
            priceRating = .high
        } else {
            priceRating = .overpriced
        }

        return ARPriceComparison(
            currentStore: currentStore,
            currentPrice: currentPrice,
            alternatives: alternatives,
            bestPrice: bestPrice,
            potentialSavings: max(0, potentialSavings),
            priceRating: priceRating
        )
    }

    private func getCardRecommendation(category: String, price: Double) -> ARCardRecommendation {
        // TODO: Fix CardReward member access in AR shopping
        // Default recommendation
        return ARCardRecommendation(
            cardName: "Cash Back Card",
            cardIssuer: "Generic",
            rewardRate: 2.0,
            rewardType: "Cash Back",
            estimatedReward: price * 0.02,
            specialOffer: nil,
            isRotatingCategory: false
        )
    }

    // MARK: - User Actions

    func addToCart(_ productId: String) {
        currentSession?.productsAddedToCart.append(productId)

        // Also add to shopping list
        if let product = detectedProducts.first(where: { $0.id == productId }) {
            ShoppingIntelligenceManager.shared.addToShoppingList(
                name: product.productName,
                quantity: 1,
                category: product.category,
                estimatedPrice: product.detectedPrice,
                preferredStore: currentStoreName
            )
        }
    }

    func dismissProduct(_ productId: String) {
        currentSession?.productsDismissed.append(productId)
        detectedProducts.removeAll { $0.id == productId }
        annotations.removeAll { $0.id == productId }
    }

    func addToWishlist(_ productId: String) {
        guard let product = detectedProducts.first(where: { $0.id == productId }) else { return }

        PhotoIntelligenceManager.shared.addToWishlist(
            name: product.productName,
            targetPrice: product.priceComparison?.bestPrice?.price,
            category: product.category,
            imageData: nil
        )
    }

    func toggleAnnotationExpanded(_ annotationId: String) {
        if let index = annotations.firstIndex(where: { $0.id == annotationId }) {
            annotations[index].isExpanded.toggle()
        }
    }

    // MARK: - Quick Scan (Non-AR)

    func quickScan(image: UIImage) async -> ARProductDetection? {
        guard let cgImage = image.cgImage else { return nil }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        var texts: [(String, CGRect)] = []
        var barcodes: [(String, CGRect)] = []

        let textRequest = VNRecognizeTextRequest { request, _ in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                texts = observations.compactMap { obs in
                    obs.topCandidates(1).first.map { ($0.string, obs.boundingBox) }
                }
            }
        }

        let barcodeRequest = VNDetectBarcodesRequest { request, _ in
            if let observations = request.results as? [VNBarcodeObservation] {
                barcodes = observations.compactMap { obs in
                    obs.payloadStringValue.map { ($0, obs.boundingBox) }
                }
            }
        }

        try? handler.perform([textRequest, barcodeRequest])

        let allText = texts.map { $0.0 }.joined(separator: " ").lowercased()

        // Find product
        for (keyword, info) in productPatterns {
            if allText.contains(keyword) {
                let price = findPriceNearby(in: texts, near: .zero) ?? info.avgPrice

                let result = ProductRecognitionResult(
                    name: keyword.capitalized,
                    brand: extractBrand(from: keyword),
                    category: info.category,
                    confidence: 0.8,
                    boundingBox: .zero,
                    barcode: barcodes.first?.0,
                    priceTag: price
                )

                return analyzeProduct(result)
            }
        }

        // Check barcodes
        if let barcode = barcodes.first {
            let price = findPriceNearby(in: texts, near: barcode.1)

            let result = ProductRecognitionResult(
                name: "Scanned Product",
                brand: nil,
                category: "Unknown",
                confidence: 0.9,
                boundingBox: barcode.1,
                barcode: barcode.0,
                priceTag: price
            )

            return analyzeProduct(result)
        }

        return nil
    }

    // MARK: - Persistence

    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([ARShoppingSession].self, from: data) {
            pastSessions = sessions
        }
    }

    private func saveSessions() {
        let toSave = Array(pastSessions.prefix(50))
        if let data = try? JSONEncoder().encode(toSave) {
            userDefaults.set(data, forKey: sessionsKey)
        }
    }
}

// MARK: - AR Session Delegate Extension

extension ARShoppingManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isSessionActive, scanMode == .automatic, !isProcessing else { return }

        Task {
            let results = await processFrame(frame.capturedImage)

            for result in results {
                // Get 3D position from AR hit test
                let screenCenter = CGPoint(x: 0.5, y: 0.5)
                let query = frame.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any)
                let raycastResults = session.raycast(query)
                if let firstResult = raycastResults.first {
                    let position = simd_float3(
                        firstResult.worldTransform.columns.3.x,
                        firstResult.worldTransform.columns.3.y,
                        firstResult.worldTransform.columns.3.z
                    )
                    _ = await MainActor.run {
                        analyzeProduct(result, at: position)
                    }
                }
            }
        }
    }
}
