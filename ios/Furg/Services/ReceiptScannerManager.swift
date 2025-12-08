import Foundation
import Vision
import UIKit
import Combine

// MARK: - Receipt Scanner Models

struct ScannedReceipt: Identifiable, Codable {
    let id: String
    let scanDate: Date
    let merchantName: String
    let merchantAddress: String?
    let transactionDate: Date?
    let items: [ReceiptItem]
    let subtotal: Double
    let tax: Double
    let total: Double
    let paymentMethod: String?
    let cardLastFour: String?
    let receiptNumber: String?
    let imageData: Data?
    var linkedTransactionId: String?
    let confidence: Double
    let rawText: String

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalSavings: Double {
        items.reduce(0) { $0 + ($1.discount ?? 0) }
    }
}

struct ReceiptItem: Identifiable, Codable {
    let id: String
    var name: String
    var quantity: Int
    var unitPrice: Double
    var totalPrice: Double
    var discount: Double?
    var originalPrice: Double?
    var sku: String?
    var category: String?
    var isReturnable: Bool
    var returnDeadline: Date?

    var effectivePrice: Double {
        return totalPrice - (discount ?? 0)
    }
}

struct ReceiptCategory: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let keywords: [String]
    var itemCount: Int
    var totalSpent: Double
}

struct ReceiptInsight: Identifiable, Codable {
    let id: String
    let type: InsightType
    let title: String
    let message: String
    let potentialSavings: Double?
    let relatedItems: [String]
    let createdAt: Date

    enum InsightType: String, Codable {
        case priceComparison
        case buyingPattern
        case savingsOpportunity
        case wasteAlert
        case reorderSuggestion
        case bulkSavings
    }
}

struct MerchantProfile: Identifiable, Codable {
    let id: String
    var name: String
    var addresses: [String]
    var visitCount: Int
    var totalSpent: Double
    var averageTransaction: Double
    var frequentItems: [FrequentItem]
    var lastVisit: Date
    var preferredCategories: [String]

    struct FrequentItem: Codable {
        let name: String
        var purchaseCount: Int
        var lastPrice: Double
        var priceHistory: [PricePoint]

        struct PricePoint: Codable {
            let date: Date
            let price: Double
        }
    }
}

// MARK: - Receipt Scanner Manager

class ReceiptScannerManager: ObservableObject {
    static let shared = ReceiptScannerManager()

    // MARK: - Published Properties
    @Published var scannedReceipts: [ScannedReceipt] = []
    @Published var merchantProfiles: [MerchantProfile] = []
    @Published var itemDatabase: [String: [ReceiptItem]] = [:] // Item name -> purchase history
    @Published var categoryBreakdown: [ReceiptCategory] = []
    @Published var insights: [ReceiptInsight] = []

    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var lastScanError: String?

    @Published var totalItemsScanned: Int = 0
    @Published var totalReceiptsScanned: Int = 0
    @Published var averageReceiptAccuracy: Double = 0

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let receiptsKey = "receiptScanner_receipts"
    private let merchantsKey = "receiptScanner_merchants"
    private let itemsKey = "receiptScanner_items"

    private let textRecognitionRequest = VNRecognizeTextRequest()

    // Common receipt patterns
    private let pricePattern = "\\$?([0-9]+\\.?[0-9]{0,2})"
    private let quantityPattern = "(\\d+)\\s*(?:x|@|X)"
    private let datePatterns = [
        "\\d{1,2}/\\d{1,2}/\\d{2,4}",
        "\\d{1,2}-\\d{1,2}-\\d{2,4}",
        "\\w{3}\\s+\\d{1,2},?\\s+\\d{4}"
    ]

    // MARK: - Initialization

    init() {
        setupTextRecognition()
        loadData()
        calculateCategoryBreakdown()
    }

    private func setupTextRecognition() {
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        textRecognitionRequest.recognitionLanguages = ["en-US"]
    }

    // MARK: - Receipt Scanning

    func scanReceipt(from image: UIImage) async throws -> ScannedReceipt {
        isScanning = true
        scanProgress = 0
        lastScanError = nil

        defer { isScanning = false }

        guard let cgImage = image.cgImage else {
            throw ReceiptScanError.invalidImage
        }

        // Perform text recognition
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            textRecognitionRequest.recognitionLevel = .accurate

            let request = VNRecognizeTextRequest { [weak self] request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: ReceiptScanError.noTextFound)
                    return
                }

                // Extract text with positions
                var textBlocks: [(String, CGRect)] = []
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        textBlocks.append((topCandidate.string, observation.boundingBox))
                    }
                }

                // Parse receipt
                do {
                    let receipt = try self?.parseReceipt(from: textBlocks, rawText: textBlocks.map { $0.0 }.joined(separator: "\n"), imageData: image.jpegData(compressionQuality: 0.7))
                    if let receipt = receipt {
                        DispatchQueue.main.async {
                            self?.addScannedReceipt(receipt)
                        }
                        continuation.resume(returning: receipt)
                    } else {
                        continuation.resume(throwing: ReceiptScanError.parsingFailed)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func parseReceipt(from textBlocks: [(String, CGRect)], rawText: String, imageData: Data?) throws -> ScannedReceipt {
        scanProgress = 0.2

        let lines = textBlocks.map { $0.0 }

        // Extract merchant name (usually at top)
        let merchantName = extractMerchantName(from: lines)
        scanProgress = 0.3

        // Extract merchant address
        let merchantAddress = extractAddress(from: lines)
        scanProgress = 0.4

        // Extract date
        let transactionDate = extractDate(from: rawText)
        scanProgress = 0.5

        // Extract items
        let items = extractItems(from: lines)
        scanProgress = 0.7

        // Extract totals
        let (subtotal, tax, total) = extractTotals(from: lines)
        scanProgress = 0.8

        // Extract payment info
        let (paymentMethod, cardLastFour) = extractPaymentInfo(from: rawText)
        scanProgress = 0.9

        // Extract receipt number
        let receiptNumber = extractReceiptNumber(from: rawText)

        // Calculate confidence based on extracted data quality
        let confidence = calculateConfidence(
            merchantName: merchantName,
            items: items,
            total: total,
            rawText: rawText
        )

        scanProgress = 1.0

        return ScannedReceipt(
            id: UUID().uuidString,
            scanDate: Date(),
            merchantName: merchantName,
            merchantAddress: merchantAddress,
            transactionDate: transactionDate,
            items: items,
            subtotal: subtotal,
            tax: tax,
            total: total,
            paymentMethod: paymentMethod,
            cardLastFour: cardLastFour,
            receiptNumber: receiptNumber,
            imageData: imageData,
            linkedTransactionId: nil,
            confidence: confidence,
            rawText: rawText
        )
    }

    // MARK: - Extraction Methods

    private func extractMerchantName(from lines: [String]) -> String {
        // Merchant name is usually in the first few lines, often in caps
        let knownMerchants = [
            "WALMART", "TARGET", "COSTCO", "KROGER", "SAFEWAY", "WHOLE FOODS",
            "TRADER JOE'S", "CVS", "WALGREENS", "RITE AID", "HOME DEPOT",
            "LOWES", "BEST BUY", "AMAZON", "STARBUCKS", "MCDONALD'S"
        ]

        for line in lines.prefix(5) {
            let upperLine = line.uppercased()
            for merchant in knownMerchants {
                if upperLine.contains(merchant) {
                    return merchant.capitalized
                }
            }
        }

        // If no known merchant, use the first substantial line
        for line in lines.prefix(3) {
            let cleaned = line.trimmingCharacters(in: .whitespaces)
            if cleaned.count >= 3 && !cleaned.contains("$") && !containsOnlyNumbers(cleaned) {
                return cleaned
            }
        }

        return "Unknown Merchant"
    }

    private func extractAddress(from lines: [String]) -> String? {
        let addressPattern = "\\d+\\s+[\\w\\s]+(?:St|Street|Ave|Avenue|Rd|Road|Blvd|Dr|Drive|Ln|Lane)"

        for line in lines.prefix(7) {
            if let regex = try? NSRegularExpression(pattern: addressPattern, options: .caseInsensitive),
               regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                return line
            }
        }

        return nil
    }

    private func extractDate(from text: String) -> Date? {
        for pattern in datePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }

            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let matchRange = Range(match.range, in: text) {
                let dateString = String(text[matchRange])

                let formatters: [DateFormatter] = {
                    let formats = ["M/d/yyyy", "M/d/yy", "MM/dd/yyyy", "M-d-yyyy", "MMM d, yyyy", "MMM d yyyy"]
                    return formats.map { format in
                        let formatter = DateFormatter()
                        formatter.dateFormat = format
                        return formatter
                    }
                }()

                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    private func extractItems(from lines: [String]) -> [ReceiptItem] {
        var items: [ReceiptItem] = []
        var inItemSection = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Detect start of items section
            if trimmedLine.lowercased().contains("item") || trimmedLine.lowercased().contains("description") {
                inItemSection = true
                continue
            }

            // Detect end of items section
            if trimmedLine.lowercased().contains("subtotal") ||
               trimmedLine.lowercased().contains("total") ||
               trimmedLine.lowercased().contains("tax") {
                break
            }

            // Try to parse as item
            if let item = parseItemLine(trimmedLine) {
                items.append(item)
                inItemSection = true
            } else if inItemSection {
                // Try more aggressive parsing for item lines with prices
                if let item = parseItemLineAggressive(trimmedLine) {
                    items.append(item)
                }
            }
        }

        return items
    }

    private func parseItemLine(_ line: String) -> ReceiptItem? {
        // Pattern: [quantity] item name price
        // Examples:
        // "2 MILK 2% GAL    $7.98"
        // "BANANAS    $1.29"
        // "1 x Apple Juice $3.99"

        // Look for price at end
        guard let priceRegex = try? NSRegularExpression(pattern: "\\$?([0-9]+\\.[0-9]{2})\\s*$", options: []),
              let priceMatch = priceRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let priceRange = Range(priceMatch.range(at: 1), in: line) else {
            return nil
        }

        let priceString = String(line[priceRange])
        guard let price = Double(priceString), price > 0, price < 10000 else {
            return nil
        }

        // Get item name (everything before price)
        let nameEndIndex = line.index(priceRange.lowerBound, offsetBy: -1, limitedBy: line.startIndex) ?? priceRange.lowerBound
        var itemText = String(line[..<nameEndIndex]).trimmingCharacters(in: .whitespaces)

        // Extract quantity if present
        var quantity = 1
        if let qtyRegex = try? NSRegularExpression(pattern: "^(\\d+)\\s*(?:x|X|@)?\\s*", options: []),
           let qtyMatch = qtyRegex.firstMatch(in: itemText, range: NSRange(itemText.startIndex..., in: itemText)),
           let qtyRange = Range(qtyMatch.range(at: 1), in: itemText),
           let qty = Int(itemText[qtyRange]) {
            quantity = qty
            if let fullMatchRange = Range(qtyMatch.range, in: itemText) {
                itemText = String(itemText[fullMatchRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }

        // Clean up item name
        itemText = cleanItemName(itemText)

        guard !itemText.isEmpty else { return nil }

        // Check for discount
        var discount: Double? = nil
        var originalPrice: Double? = nil
        if line.lowercased().contains("save") || line.contains("-") {
            // Look for discount pattern
            if let discountRegex = try? NSRegularExpression(pattern: "-?\\$?([0-9]+\\.[0-9]{2})", options: []),
               let discountMatch = discountRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               discountMatch.range != priceMatch.range,
               let discountRange = Range(discountMatch.range(at: 1), in: line),
               let discountValue = Double(line[discountRange]) {
                discount = discountValue
                originalPrice = price + discountValue
            }
        }

        return ReceiptItem(
            id: UUID().uuidString,
            name: itemText,
            quantity: quantity,
            unitPrice: price / Double(quantity),
            totalPrice: price,
            discount: discount,
            originalPrice: originalPrice,
            sku: nil,
            category: categorizeItem(itemText),
            isReturnable: true,
            returnDeadline: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        )
    }

    private func parseItemLineAggressive(_ line: String) -> ReceiptItem? {
        // More aggressive parsing for lines that might be items
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        // Must have some letters and a number that looks like a price
        guard trimmedLine.contains(where: { $0.isLetter }),
              let priceRegex = try? NSRegularExpression(pattern: "([0-9]+\\.[0-9]{2})", options: []),
              let priceMatch = priceRegex.firstMatch(in: trimmedLine, range: NSRange(trimmedLine.startIndex..., in: trimmedLine)),
              let priceRange = Range(priceMatch.range(at: 1), in: trimmedLine),
              let price = Double(trimmedLine[priceRange]),
              price > 0, price < 1000 else {
            return nil
        }

        // Extract name as everything that's not the price
        var name = trimmedLine.replacingOccurrences(of: String(trimmedLine[priceRange]), with: "")
        name = name.replacingOccurrences(of: "$", with: "")
        name = cleanItemName(name)

        guard name.count >= 2 else { return nil }

        return ReceiptItem(
            id: UUID().uuidString,
            name: name,
            quantity: 1,
            unitPrice: price,
            totalPrice: price,
            discount: nil,
            originalPrice: nil,
            sku: nil,
            category: categorizeItem(name),
            isReturnable: true,
            returnDeadline: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        )
    }

    private func cleanItemName(_ name: String) -> String {
        var cleaned = name
        // Remove common prefixes/suffixes
        cleaned = cleaned.replacingOccurrences(of: "REG", with: "")
        cleaned = cleaned.replacingOccurrences(of: "ORG", with: "Organic")
        cleaned = cleaned.trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))
        // Capitalize properly
        cleaned = cleaned.capitalized
        return cleaned
    }

    private func extractTotals(from lines: [String]) -> (subtotal: Double, tax: Double, total: Double) {
        var subtotal: Double = 0
        var tax: Double = 0
        var total: Double = 0

        for line in lines {
            let lowercaseLine = line.lowercased()

            if let amount = extractAmount(from: line) {
                if lowercaseLine.contains("subtotal") && !lowercaseLine.contains("tax") {
                    subtotal = amount
                } else if lowercaseLine.contains("tax") && !lowercaseLine.contains("subtotal") {
                    tax = amount
                } else if lowercaseLine.contains("total") && !lowercaseLine.contains("sub") && !lowercaseLine.contains("tax") {
                    // Check if this is likely the grand total (usually largest)
                    if amount > total {
                        total = amount
                    }
                }
            }
        }

        // If no subtotal found, calculate from total and tax
        if subtotal == 0 && total > 0 {
            subtotal = total - tax
        }

        return (subtotal, tax, total)
    }

    private func extractAmount(from line: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: "\\$?([0-9]+\\.[0-9]{2})", options: []) else {
            return nil
        }

        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, range: range)

        // Get the last match (usually the amount)
        if let match = matches.last,
           let matchRange = Range(match.range(at: 1), in: line),
           let amount = Double(line[matchRange]) {
            return amount
        }

        return nil
    }

    private func extractPaymentInfo(from text: String) -> (method: String?, lastFour: String?) {
        var method: String? = nil
        var lastFour: String? = nil

        let lowercaseText = text.lowercased()

        // Detect payment method
        if lowercaseText.contains("visa") {
            method = "Visa"
        } else if lowercaseText.contains("mastercard") || lowercaseText.contains("master card") {
            method = "Mastercard"
        } else if lowercaseText.contains("amex") || lowercaseText.contains("american express") {
            method = "American Express"
        } else if lowercaseText.contains("discover") {
            method = "Discover"
        } else if lowercaseText.contains("debit") {
            method = "Debit"
        } else if lowercaseText.contains("cash") {
            method = "Cash"
        } else if lowercaseText.contains("apple pay") {
            method = "Apple Pay"
        }

        // Extract last 4 digits
        if let regex = try? NSRegularExpression(pattern: "(?:card|ending|\\*{4})\\s*([0-9]{4})", options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let matchRange = Range(match.range(at: 1), in: text) {
            lastFour = String(text[matchRange])
        }

        return (method, lastFour)
    }

    private func extractReceiptNumber(from text: String) -> String? {
        let patterns = [
            "(?:receipt|trans|transaction)\\s*#?\\s*:?\\s*([A-Z0-9-]+)",
            "#([0-9]{4,})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let matchRange = Range(match.range(at: 1), in: text) {
                return String(text[matchRange])
            }
        }

        return nil
    }

    private func calculateConfidence(merchantName: String, items: [ReceiptItem], total: Double, rawText: String) -> Double {
        var confidence: Double = 0.5

        // Merchant name found
        if merchantName != "Unknown Merchant" { confidence += 0.15 }

        // Items found
        if !items.isEmpty { confidence += 0.15 }
        if items.count >= 3 { confidence += 0.05 }

        // Total found
        if total > 0 { confidence += 0.1 }

        // Items total roughly matches receipt total
        let itemsTotal = items.reduce(0) { $0 + $1.totalPrice }
        if total > 0 && abs(itemsTotal - total) / total < 0.2 {
            confidence += 0.1
        }

        // Raw text quality
        if rawText.count > 100 { confidence += 0.05 }

        return min(confidence, 1.0)
    }

    private func categorizeItem(_ itemName: String) -> String {
        let lowercaseName = itemName.lowercased()

        let categories: [String: [String]] = [
            "Produce": ["apple", "banana", "orange", "lettuce", "tomato", "onion", "potato", "carrot", "fruit", "vegetable", "organic"],
            "Dairy": ["milk", "cheese", "yogurt", "butter", "cream", "egg"],
            "Meat": ["chicken", "beef", "pork", "fish", "salmon", "steak", "ground", "bacon", "sausage"],
            "Bakery": ["bread", "bagel", "muffin", "cake", "donut", "croissant", "roll"],
            "Beverages": ["water", "juice", "soda", "coffee", "tea", "drink", "cola", "sprite"],
            "Snacks": ["chip", "cookie", "cracker", "candy", "chocolate", "nut"],
            "Frozen": ["frozen", "ice cream", "pizza"],
            "Cleaning": ["soap", "detergent", "cleaner", "paper towel", "tissue"],
            "Personal Care": ["shampoo", "toothpaste", "deodorant", "lotion", "razor"],
            "Pharmacy": ["medicine", "vitamin", "supplement", "pain relief", "allergy"]
        ]

        for (category, keywords) in categories {
            for keyword in keywords {
                if lowercaseName.contains(keyword) {
                    return category
                }
            }
        }

        return "Other"
    }

    private func containsOnlyNumbers(_ string: String) -> Bool {
        return string.allSatisfy { $0.isNumber || $0 == "." || $0 == "-" || $0 == "/" }
    }

    // MARK: - Receipt Management

    func addScannedReceipt(_ receipt: ScannedReceipt) {
        scannedReceipts.insert(receipt, at: 0)
        updateMerchantProfile(from: receipt)
        updateItemDatabase(from: receipt)
        calculateCategoryBreakdown()
        generateInsights()
        saveReceipts()

        totalReceiptsScanned = scannedReceipts.count
        totalItemsScanned = scannedReceipts.reduce(0) { $0 + $1.items.count }
        averageReceiptAccuracy = scannedReceipts.reduce(0) { $0 + $1.confidence } / Double(scannedReceipts.count)
    }

    func linkReceiptToTransaction(_ receiptId: String, transactionId: String) {
        if let index = scannedReceipts.firstIndex(where: { $0.id == receiptId }) {
            var receipt = scannedReceipts[index]
            receipt = ScannedReceipt(
                id: receipt.id,
                scanDate: receipt.scanDate,
                merchantName: receipt.merchantName,
                merchantAddress: receipt.merchantAddress,
                transactionDate: receipt.transactionDate,
                items: receipt.items,
                subtotal: receipt.subtotal,
                tax: receipt.tax,
                total: receipt.total,
                paymentMethod: receipt.paymentMethod,
                cardLastFour: receipt.cardLastFour,
                receiptNumber: receipt.receiptNumber,
                imageData: receipt.imageData,
                linkedTransactionId: transactionId,
                confidence: receipt.confidence,
                rawText: receipt.rawText
            )
            scannedReceipts[index] = receipt
            saveReceipts()
        }
    }

    private func updateMerchantProfile(from receipt: ScannedReceipt) {
        if let index = merchantProfiles.firstIndex(where: { $0.name.lowercased() == receipt.merchantName.lowercased() }) {
            var profile = merchantProfiles[index]
            profile.visitCount += 1
            profile.totalSpent += receipt.total
            profile.averageTransaction = profile.totalSpent / Double(profile.visitCount)
            profile.lastVisit = receipt.transactionDate ?? receipt.scanDate

            if let address = receipt.merchantAddress, !profile.addresses.contains(address) {
                profile.addresses.append(address)
            }

            // Update frequent items
            for item in receipt.items {
                if let itemIndex = profile.frequentItems.firstIndex(where: { $0.name.lowercased() == item.name.lowercased() }) {
                    profile.frequentItems[itemIndex].purchaseCount += item.quantity
                    profile.frequentItems[itemIndex].lastPrice = item.unitPrice
                    profile.frequentItems[itemIndex].priceHistory.append(
                        MerchantProfile.FrequentItem.PricePoint(date: receipt.scanDate, price: item.unitPrice)
                    )
                } else {
                    profile.frequentItems.append(MerchantProfile.FrequentItem(
                        name: item.name,
                        purchaseCount: item.quantity,
                        lastPrice: item.unitPrice,
                        priceHistory: [MerchantProfile.FrequentItem.PricePoint(date: receipt.scanDate, price: item.unitPrice)]
                    ))
                }
            }

            // Keep top 20 frequent items
            profile.frequentItems.sort { $0.purchaseCount > $1.purchaseCount }
            profile.frequentItems = Array(profile.frequentItems.prefix(20))

            merchantProfiles[index] = profile
        } else {
            // New merchant
            let profile = MerchantProfile(
                id: UUID().uuidString,
                name: receipt.merchantName,
                addresses: receipt.merchantAddress.map { [$0] } ?? [],
                visitCount: 1,
                totalSpent: receipt.total,
                averageTransaction: receipt.total,
                frequentItems: receipt.items.map { item in
                    MerchantProfile.FrequentItem(
                        name: item.name,
                        purchaseCount: item.quantity,
                        lastPrice: item.unitPrice,
                        priceHistory: [MerchantProfile.FrequentItem.PricePoint(date: receipt.scanDate, price: item.unitPrice)]
                    )
                },
                lastVisit: receipt.transactionDate ?? receipt.scanDate,
                preferredCategories: Array(Set(receipt.items.compactMap { $0.category }))
            )
            merchantProfiles.append(profile)
        }

        saveMerchants()
    }

    private func updateItemDatabase(from receipt: ScannedReceipt) {
        for item in receipt.items {
            let key = item.name.lowercased()
            if var existingItems = itemDatabase[key] {
                existingItems.append(item)
                itemDatabase[key] = existingItems
            } else {
                itemDatabase[key] = [item]
            }
        }
        saveItems()
    }

    private func calculateCategoryBreakdown() {
        var categoryTotals: [String: (count: Int, total: Double)] = [:]

        for receipt in scannedReceipts {
            for item in receipt.items {
                let category = item.category ?? "Other"
                let current = categoryTotals[category] ?? (0, 0)
                categoryTotals[category] = (current.count + item.quantity, current.total + item.totalPrice)
            }
        }

        let categoryIcons: [String: String] = [
            "Produce": "leaf.fill",
            "Dairy": "cup.and.saucer.fill",
            "Meat": "fork.knife",
            "Bakery": "birthday.cake.fill",
            "Beverages": "drop.fill",
            "Snacks": "popcorn.fill",
            "Frozen": "snowflake",
            "Cleaning": "sparkles",
            "Personal Care": "heart.fill",
            "Pharmacy": "cross.case.fill",
            "Other": "bag.fill"
        ]

        categoryBreakdown = categoryTotals.map { category, data in
            ReceiptCategory(
                id: category,
                name: category,
                icon: categoryIcons[category] ?? "bag.fill",
                keywords: [],
                itemCount: data.count,
                totalSpent: data.total
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }

    private func generateInsights() {
        var newInsights: [ReceiptInsight] = []

        // Price comparison insights
        for (itemName, purchases) in itemDatabase where purchases.count >= 3 {
            let prices = purchases.map { $0.unitPrice }
            let avgPrice = prices.reduce(0, +) / Double(prices.count)
            let maxPrice = prices.max() ?? 0
            let minPrice = prices.min() ?? 0

            if maxPrice - minPrice > avgPrice * 0.3 {
                newInsights.append(ReceiptInsight(
                    id: "price_\(itemName)",
                    type: .priceComparison,
                    title: "Price Variation: \(itemName.capitalized)",
                    message: "You've paid between $\(String(format: "%.2f", minPrice)) and $\(String(format: "%.2f", maxPrice)) for this item",
                    potentialSavings: (avgPrice - minPrice) * Double(purchases.count),
                    relatedItems: [itemName],
                    createdAt: Date()
                ))
            }
        }

        // Frequent purchase insights
        let frequentItems = itemDatabase.filter { $0.value.count >= 5 }
            .sorted { $0.value.count > $1.value.count }
            .prefix(5)

        if !frequentItems.isEmpty {
            newInsights.append(ReceiptInsight(
                id: "frequent_items",
                type: .buyingPattern,
                title: "Your Most Purchased Items",
                message: frequentItems.map { "\($0.key.capitalized) (\($0.value.count)x)" }.joined(separator: ", "),
                potentialSavings: nil,
                relatedItems: Array(frequentItems.map { $0.key }),
                createdAt: Date()
            ))
        }

        insights = newInsights
    }

    // MARK: - Search & Query

    func searchItems(query: String) -> [ReceiptItem] {
        let lowercaseQuery = query.lowercased()
        return scannedReceipts.flatMap { $0.items }
            .filter { $0.name.lowercased().contains(lowercaseQuery) }
    }

    func getPriceHistory(for itemName: String) -> [(date: Date, price: Double, merchant: String)] {
        var history: [(Date, Double, String)] = []

        for receipt in scannedReceipts {
            for item in receipt.items {
                if item.name.lowercased().contains(itemName.lowercased()) {
                    history.append((receipt.transactionDate ?? receipt.scanDate, item.unitPrice, receipt.merchantName))
                }
            }
        }

        return history.sorted { $0.0 < $1.0 }
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: receiptsKey),
           let receipts = try? JSONDecoder().decode([ScannedReceipt].self, from: data) {
            scannedReceipts = receipts
        }

        if let data = userDefaults.data(forKey: merchantsKey),
           let merchants = try? JSONDecoder().decode([MerchantProfile].self, from: data) {
            merchantProfiles = merchants
        }

        if let data = userDefaults.data(forKey: itemsKey),
           let items = try? JSONDecoder().decode([String: [ReceiptItem]].self, from: data) {
            itemDatabase = items
        }
    }

    private func saveReceipts() {
        if let data = try? JSONEncoder().encode(scannedReceipts) {
            userDefaults.set(data, forKey: receiptsKey)
        }
    }

    private func saveMerchants() {
        if let data = try? JSONEncoder().encode(merchantProfiles) {
            userDefaults.set(data, forKey: merchantsKey)
        }
    }

    private func saveItems() {
        if let data = try? JSONEncoder().encode(itemDatabase) {
            userDefaults.set(data, forKey: itemsKey)
        }
    }
}

// MARK: - Errors

enum ReceiptScanError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case parsingFailed
    case lowConfidence

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image provided"
        case .noTextFound: return "No text found in image"
        case .parsingFailed: return "Failed to parse receipt"
        case .lowConfidence: return "Low confidence in scan results"
        }
    }
}
