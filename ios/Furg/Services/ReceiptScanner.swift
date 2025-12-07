//
//  ReceiptScanner.swift
//  Furg
//
//  On-device receipt scanning using Vision framework
//  Extracts itemized data for expense categorization
//

import Foundation
import Vision
import UIKit

@MainActor
class ReceiptScanner: ObservableObject {
    @Published var isScanning = false
    @Published var lastReceipt: ScannedReceipt?
    @Published var errorMessage: String?

    // MARK: - Models

    struct ScannedReceipt: Identifiable {
        let id = UUID()
        let merchantName: String?
        let date: Date?
        let subtotal: Double?
        let tax: Double?
        let total: Double?
        let items: [ReceiptItem]
        let rawText: String
        let scannedAt: Date

        var formattedTotal: String? {
            guard let total = total else { return nil }
            return String(format: "$%.2f", total)
        }
    }

    struct ReceiptItem: Identifiable {
        let id = UUID()
        let name: String
        let price: Double
        let quantity: Int
        var category: String?

        var formattedPrice: String {
            String(format: "$%.2f", price)
        }
    }

    // MARK: - Scanning

    func scanReceipt(from image: UIImage) async {
        guard let cgImage = image.cgImage else {
            errorMessage = "Invalid image format"
            return
        }

        isScanning = true
        errorMessage = nil

        do {
            let recognizedText = try await performOCR(on: cgImage)
            let receipt = parseReceipt(from: recognizedText)
            lastReceipt = receipt
        } catch {
            errorMessage = "Failed to scan receipt: \(error.localizedDescription)"
        }

        isScanning = false
    }

    private func performOCR(on cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Sort observations by vertical position (top to bottom)
                let sortedObservations = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

                let recognizedStrings = sortedObservations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let text = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Parsing

    private func parseReceipt(from text: String) -> ScannedReceipt {
        let lines = text.components(separatedBy: .newlines)

        // Extract merchant name (usually first line or most prominent)
        let merchantName = extractMerchantName(from: lines)

        // Extract date
        let date = extractDate(from: text)

        // Extract prices and totals
        let (subtotal, tax, total) = extractTotals(from: lines)

        // Extract items with prices
        let items = extractItems(from: lines)

        return ScannedReceipt(
            merchantName: merchantName,
            date: date,
            subtotal: subtotal,
            tax: tax,
            total: total,
            items: items,
            rawText: text,
            scannedAt: Date()
        )
    }

    private func extractMerchantName(from lines: [String]) -> String? {
        // Merchant name is usually in the first few lines
        // Look for lines that are all caps or prominent
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 3 && !containsPrice(trimmed) && !isDateString(trimmed) {
                // Skip common receipt headers
                let lowercased = trimmed.lowercased()
                if !lowercased.contains("receipt") &&
                   !lowercased.contains("thank you") &&
                   !lowercased.contains("welcome") {
                    return trimmed
                }
            }
        }
        return nil
    }

    private func extractDate(from text: String) -> Date? {
        // Common date patterns
        let patterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",           // MM/DD/YYYY or M/D/YY
            "\\d{1,2}-\\d{1,2}-\\d{2,4}",           // MM-DD-YYYY
            "\\d{4}-\\d{2}-\\d{2}",                 // YYYY-MM-DD
            "[A-Za-z]{3}\\s+\\d{1,2},?\\s+\\d{4}"  // Jan 15, 2024
        ]

        let formatters: [DateFormatter] = {
            let formats = [
                "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy", "M/d/yy",
                "MM-dd-yyyy", "yyyy-MM-dd",
                "MMM dd, yyyy", "MMM d, yyyy"
            ]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US")
                return formatter
            }
        }()

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])
                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    private func extractTotals(from lines: [String]) -> (subtotal: Double?, tax: Double?, total: Double?) {
        var subtotal: Double?
        var tax: Double?
        var total: Double?

        for line in lines {
            let lowercased = line.lowercased()
            if let price = extractPrice(from: line) {
                if lowercased.contains("subtotal") || lowercased.contains("sub total") {
                    subtotal = price
                } else if lowercased.contains("tax") {
                    tax = price
                } else if lowercased.contains("total") || lowercased.contains("balance") ||
                          lowercased.contains("amount due") || lowercased.contains("grand total") {
                    // Take the largest "total" as the actual total
                    if total == nil || price > (total ?? 0) {
                        total = price
                    }
                }
            }
        }

        return (subtotal, tax, total)
    }

    private func extractItems(from lines: [String]) -> [ReceiptItem] {
        var items: [ReceiptItem] = []

        for line in lines {
            // Skip lines that are likely totals/tax/etc
            let lowercased = line.lowercased()
            if lowercased.contains("total") || lowercased.contains("tax") ||
               lowercased.contains("subtotal") || lowercased.contains("balance") ||
               lowercased.contains("cash") || lowercased.contains("change") ||
               lowercased.contains("visa") || lowercased.contains("mastercard") ||
               lowercased.contains("debit") || lowercased.contains("credit") {
                continue
            }

            // Look for lines with a price pattern
            if let price = extractPrice(from: line), price > 0 && price < 1000 {
                // Extract item name (text before the price)
                let name = extractItemName(from: line)
                if !name.isEmpty && name.count > 2 {
                    // Extract quantity if present
                    let quantity = extractQuantity(from: line)

                    items.append(ReceiptItem(
                        name: name,
                        price: price,
                        quantity: quantity,
                        category: nil
                    ))
                }
            }
        }

        return items
    }

    private func extractItemName(from line: String) -> String {
        // Remove price from line and clean up
        var name = line

        // Remove price patterns
        let pricePattern = "\\$?\\d+\\.\\d{2}"
        if let regex = try? NSRegularExpression(pattern: pricePattern, options: []) {
            name = regex.stringByReplacingMatches(
                in: name,
                options: [],
                range: NSRange(name.startIndex..., in: name),
                withTemplate: ""
            )
        }

        // Remove quantity patterns like "2x", "x2", "2 @"
        let qtyPatterns = ["\\d+\\s*[xX@]", "[xX@]\\s*\\d+"]
        for pattern in qtyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                name = regex.stringByReplacingMatches(
                    in: name,
                    options: [],
                    range: NSRange(name.startIndex..., in: name),
                    withTemplate: ""
                )
            }
        }

        // Clean up
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-*#"))
            .trimmingCharacters(in: .whitespaces)
    }

    private func extractPrice(from line: String) -> Double? {
        // Match price patterns: $12.34, 12.34, etc
        let pattern = "\\$?(\\d+\\.\\d{2})"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
           let range = Range(match.range(at: 1), in: line) {
            return Double(line[range])
        }
        return nil
    }

    private func extractQuantity(from line: String) -> Int {
        // Match patterns like "2x", "x2", "2 @", "QTY: 2"
        let patterns = [
            "(\\d+)\\s*[xX@]",
            "[xX@]\\s*(\\d+)",
            "QTY:?\\s*(\\d+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line),
               let qty = Int(line[range]) {
                return qty
            }
        }

        return 1
    }

    private func containsPrice(_ text: String) -> Bool {
        let pattern = "\\$?\\d+\\.\\d{2}"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private func isDateString(_ text: String) -> Bool {
        let pattern = "\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Category Suggestions

    func categorizeItem(_ item: ReceiptItem) -> String {
        let name = item.name.lowercased()

        // Food & Groceries
        if name.contains("milk") || name.contains("bread") || name.contains("eggs") ||
           name.contains("cheese") || name.contains("butter") || name.contains("yogurt") ||
           name.contains("fruit") || name.contains("vegetable") || name.contains("meat") ||
           name.contains("chicken") || name.contains("beef") || name.contains("produce") {
            return "Groceries"
        }

        // Beverages
        if name.contains("soda") || name.contains("cola") || name.contains("water") ||
           name.contains("juice") || name.contains("coffee") || name.contains("tea") ||
           name.contains("drink") || name.contains("beer") || name.contains("wine") {
            return "Beverages"
        }

        // Snacks
        if name.contains("chips") || name.contains("candy") || name.contains("cookie") ||
           name.contains("snack") || name.contains("chocolate") || name.contains("gum") {
            return "Snacks"
        }

        // Household
        if name.contains("paper") || name.contains("towel") || name.contains("tissue") ||
           name.contains("soap") || name.contains("detergent") || name.contains("cleaner") ||
           name.contains("trash") || name.contains("bag") {
            return "Household"
        }

        // Personal Care
        if name.contains("shampoo") || name.contains("toothpaste") || name.contains("deodorant") ||
           name.contains("lotion") || name.contains("razor") || name.contains("brush") {
            return "Personal Care"
        }

        return "Other"
    }
}
