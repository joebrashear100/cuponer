import Foundation
import Combine
import MessageUI

// MARK: - Email Intelligence Models

struct ParsedEmail: Identifiable, Codable {
    let id: String
    let emailId: String
    let sender: String
    let subject: String
    let receivedDate: Date
    let type: EmailType
    let extractedData: ExtractedData
    let confidence: Double
    let processed: Bool
    let linkedTransactionId: String?

    enum EmailType: String, Codable, CaseIterable {
        case orderConfirmation = "Order Confirmation"
        case shippingNotification = "Shipping Notification"
        case deliveryConfirmation = "Delivery Confirmation"
        case receipt = "Receipt"
        case subscription = "Subscription"
        case subscriptionRenewal = "Subscription Renewal"
        case priceChange = "Price Change"
        case refund = "Refund"
        case billDue = "Bill Due"
        case paymentConfirmation = "Payment Confirmation"
        case priceDropAlert = "Price Drop Alert"
        case promotionalOffer = "Promotional Offer"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .orderConfirmation: return "bag.fill"
            case .shippingNotification: return "shippingbox.fill"
            case .deliveryConfirmation: return "checkmark.circle.fill"
            case .receipt: return "receipt.fill"
            case .subscription: return "repeat.circle.fill"
            case .subscriptionRenewal: return "arrow.clockwise.circle.fill"
            case .priceChange: return "exclamationmark.triangle.fill"
            case .refund: return "arrow.uturn.backward.circle.fill"
            case .billDue: return "calendar.badge.exclamationmark"
            case .paymentConfirmation: return "checkmark.seal.fill"
            case .priceDropAlert: return "arrow.down.circle.fill"
            case .promotionalOffer: return "tag.fill"
            case .unknown: return "envelope.fill"
            }
        }
    }

    struct ExtractedData: Codable {
        var merchantName: String?
        var orderNumber: String?
        var totalAmount: Double?
        var subtotal: Double?
        var tax: Double?
        var shipping: Double?
        var items: [ExtractedItem]?
        var trackingNumber: String?
        var carrier: String?
        var estimatedDelivery: Date?
        var subscriptionName: String?
        var subscriptionPrice: Double?
        var nextBillingDate: Date?
        var previousPrice: Double?
        var newPrice: Double?
        var dueDate: Date?
        var refundAmount: Double?
    }

    struct ExtractedItem: Identifiable, Codable {
        let id: String
        let name: String
        let quantity: Int
        let price: Double
        let originalPrice: Double?
        let sku: String?
        let imageUrl: String?
    }
}

struct DetectedSubscription: Identifiable, Codable {
    let id: String
    var name: String
    var merchant: String
    var price: Double
    var billingFrequency: BillingFrequency
    var nextBillingDate: Date?
    var startDate: Date
    var category: String
    var detectedFromEmails: [String] // Email IDs
    var priceHistory: [PriceHistoryEntry]
    var isActive: Bool
    var cancelUrl: String?

    enum BillingFrequency: String, Codable, CaseIterable {
        case weekly
        case monthly
        case quarterly
        case annually

        var monthlyEquivalent: Double {
            switch self {
            case .weekly: return 4.33
            case .monthly: return 1.0
            case .quarterly: return 0.33
            case .annually: return 0.083
            }
        }
    }

    struct PriceHistoryEntry: Codable {
        let date: Date
        let price: Double
    }

    var monthlyPrice: Double {
        return price * billingFrequency.monthlyEquivalent
    }

    var annualCost: Double {
        return monthlyPrice * 12
    }
}

struct EmailOrder: Identifiable, Codable {
    let id: String
    let emailId: String
    let merchantName: String
    let orderNumber: String
    let orderDate: Date
    var items: [ParsedEmail.ExtractedItem]
    var totalAmount: Double
    var status: OrderStatus
    var trackingInfo: TrackingInfo?
    var deliveredDate: Date?
    var returnDeadline: Date?

    enum OrderStatus: String, Codable {
        case ordered
        case shipped
        case outForDelivery
        case delivered
        case returned
        case refunded
    }

    struct TrackingInfo: Codable {
        let carrier: String
        let trackingNumber: String
        let estimatedDelivery: Date?
        let lastUpdate: String?
    }
}

struct PriceChangeAlert: Identifiable, Codable {
    let id: String
    let subscriptionId: String
    let subscriptionName: String
    let merchantName: String
    let previousPrice: Double
    let newPrice: Double
    let effectiveDate: Date
    let percentageChange: Double
    let detectedDate: Date
    var acknowledged: Bool
    var action: PriceChangeAction?

    enum PriceChangeAction: String, Codable {
        case accepted
        case canceled
        case downgraded
        case negotiated
    }

    var isIncrease: Bool {
        return newPrice > previousPrice
    }
}

struct BillReminder: Identifiable, Codable {
    let id: String
    let merchantName: String
    let amount: Double
    let dueDate: Date
    let category: String
    let isRecurring: Bool
    let emailId: String
    var isPaid: Bool
    var reminderSent: Bool

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var isOverdue: Bool {
        return dueDate < Date() && !isPaid
    }
}

// MARK: - Email Parsing Rules

struct EmailParsingRule: Codable {
    let merchantDomain: String
    let senderPatterns: [String]
    let subjectPatterns: [String]
    let bodyPatterns: [PatternExtraction]
    let emailType: ParsedEmail.EmailType

    struct PatternExtraction: Codable {
        let field: String
        let pattern: String
        let groupIndex: Int
    }
}

// MARK: - Email Intelligence Manager

class EmailIntelligenceManager: ObservableObject {
    static let shared = EmailIntelligenceManager()

    // MARK: - Published Properties
    @Published var parsedEmails: [ParsedEmail] = []
    @Published var detectedSubscriptions: [DetectedSubscription] = []
    @Published var orders: [EmailOrder] = []
    @Published var priceChangeAlerts: [PriceChangeAlert] = []
    @Published var billReminders: [BillReminder] = []

    @Published var totalMonthlySubscriptions: Double = 0
    @Published var pendingDeliveries: Int = 0
    @Published var upcomingBills: Int = 0
    @Published var recentPriceChanges: Int = 0

    @Published var isConnected: Bool = false
    @Published var lastSyncDate: Date?
    @Published var emailProvider: EmailProvider?

    // MARK: - Email Providers
    enum EmailProvider: String, Codable, CaseIterable {
        case gmail
        case outlook
        case icloud
        case yahoo
        case other

        var displayName: String {
            switch self {
            case .gmail: return "Gmail"
            case .outlook: return "Outlook"
            case .icloud: return "iCloud"
            case .yahoo: return "Yahoo"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .gmail: return "envelope.fill"
            case .outlook: return "envelope.badge.fill"
            case .icloud: return "icloud.fill"
            case .yahoo: return "envelope.fill"
            case .other: return "envelope.open.fill"
            }
        }
    }

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let parsedEmailsKey = "emailIntel_parsedEmails"
    private let subscriptionsKey = "emailIntel_subscriptions"
    private let ordersKey = "emailIntel_orders"
    private let priceChangesKey = "emailIntel_priceChanges"
    private let billsKey = "emailIntel_bills"
    private let settingsKey = "emailIntel_settings"

    // Known merchant patterns
    private let merchantPatterns: [String: EmailParsingRule] = [
        "amazon.com": EmailParsingRule(
            merchantDomain: "amazon.com",
            senderPatterns: ["auto-confirm@amazon", "ship-confirm@amazon", "order-update@amazon"],
            subjectPatterns: ["Your Amazon.com order", "Shipped:", "Delivered:"],
            bodyPatterns: [
                EmailParsingRule.PatternExtraction(field: "orderNumber", pattern: "Order #([0-9-]+)", groupIndex: 1),
                EmailParsingRule.PatternExtraction(field: "total", pattern: "Order Total:\\s*\\$([0-9.,]+)", groupIndex: 1)
            ],
            emailType: .orderConfirmation
        ),
        "apple.com": EmailParsingRule(
            merchantDomain: "apple.com",
            senderPatterns: ["no_reply@email.apple.com", "noreply@apple.com"],
            subjectPatterns: ["Your receipt from Apple", "Your subscription was renewed"],
            bodyPatterns: [
                EmailParsingRule.PatternExtraction(field: "total", pattern: "TOTAL\\s*\\$([0-9.,]+)", groupIndex: 1)
            ],
            emailType: .receipt
        ),
        "netflix.com": EmailParsingRule(
            merchantDomain: "netflix.com",
            senderPatterns: ["info@mailer.netflix.com"],
            subjectPatterns: ["Your Netflix membership", "Price change"],
            bodyPatterns: [
                EmailParsingRule.PatternExtraction(field: "subscriptionPrice", pattern: "\\$([0-9.]+)/month", groupIndex: 1)
            ],
            emailType: .subscription
        ),
        "spotify.com": EmailParsingRule(
            merchantDomain: "spotify.com",
            senderPatterns: ["no-reply@spotify.com"],
            subjectPatterns: ["Your Spotify receipt", "Thanks for subscribing"],
            bodyPatterns: [
                EmailParsingRule.PatternExtraction(field: "subscriptionPrice", pattern: "\\$([0-9.]+)", groupIndex: 1)
            ],
            emailType: .subscription
        )
    ]

    // MARK: - Initialization

    init() {
        loadData()
        calculateSummaryStats()
    }

    // MARK: - Email Connection

    func connectEmailProvider(_ provider: EmailProvider, credentials: [String: String]) async throws {
        // In a real implementation, this would:
        // 1. OAuth flow for Gmail/Outlook
        // 2. IMAP connection for others
        // 3. Store tokens securely in Keychain

        emailProvider = provider
        isConnected = true
        saveSettings()

        // Start initial sync
        await syncEmails()
    }

    func disconnectEmail() {
        emailProvider = nil
        isConnected = false
        saveSettings()
    }

    // MARK: - Email Sync

    func syncEmails() async {
        guard isConnected else { return }

        // In a real implementation, this would:
        // 1. Connect to email provider API
        // 2. Search for financial emails
        // 3. Parse and extract data

        // For now, simulate processing
        lastSyncDate = Date()
        saveSettings()
    }

    // MARK: - Email Parsing

    func parseEmail(sender: String, subject: String, body: String, receivedDate: Date) -> ParsedEmail? {
        let emailId = UUID().uuidString

        // Determine email type
        let emailType = classifyEmail(sender: sender, subject: subject, body: body)

        // Extract data based on type
        let extractedData = extractData(from: body, sender: sender, subject: subject, type: emailType)

        let confidence = calculateConfidence(extractedData: extractedData, type: emailType)

        guard confidence > 0.5 else { return nil }

        let parsedEmail = ParsedEmail(
            id: UUID().uuidString,
            emailId: emailId,
            sender: sender,
            subject: subject,
            receivedDate: receivedDate,
            type: emailType,
            extractedData: extractedData,
            confidence: confidence,
            processed: false,
            linkedTransactionId: nil
        )

        return parsedEmail
    }

    func processEmail(_ email: ParsedEmail) {
        var processedEmail = email

        switch email.type {
        case .orderConfirmation:
            processOrderConfirmation(email)
        case .shippingNotification:
            processShippingNotification(email)
        case .deliveryConfirmation:
            processDeliveryConfirmation(email)
        case .receipt:
            processReceipt(email)
        case .subscription, .subscriptionRenewal:
            processSubscription(email)
        case .priceChange:
            processPriceChange(email)
        case .billDue:
            processBillReminder(email)
        case .refund:
            processRefund(email)
        default:
            break
        }

        processedEmail = ParsedEmail(
            id: email.id,
            emailId: email.emailId,
            sender: email.sender,
            subject: email.subject,
            receivedDate: email.receivedDate,
            type: email.type,
            extractedData: email.extractedData,
            confidence: email.confidence,
            processed: true,
            linkedTransactionId: email.linkedTransactionId
        )

        parsedEmails.insert(processedEmail, at: 0)
        saveParsedEmails()
        calculateSummaryStats()
    }

    private func classifyEmail(sender: String, subject: String, body: String) -> ParsedEmail.EmailType {
        let lowercaseSender = sender.lowercased()
        let lowercaseSubject = subject.lowercased()
        let lowercaseBody = body.lowercased()

        // Order confirmation patterns
        if lowercaseSubject.contains("order confirm") ||
           lowercaseSubject.contains("your order") ||
           lowercaseSubject.contains("order #") {
            return .orderConfirmation
        }

        // Shipping patterns
        if lowercaseSubject.contains("shipped") ||
           lowercaseSubject.contains("shipping confirm") ||
           lowercaseSubject.contains("on its way") ||
           lowercaseSubject.contains("tracking") {
            return .shippingNotification
        }

        // Delivery patterns
        if lowercaseSubject.contains("delivered") ||
           lowercaseSubject.contains("delivery confirm") {
            return .deliveryConfirmation
        }

        // Receipt patterns
        if lowercaseSubject.contains("receipt") ||
           lowercaseSubject.contains("thank you for your purchase") ||
           lowercaseSubject.contains("payment received") {
            return .receipt
        }

        // Subscription patterns
        if lowercaseSubject.contains("subscription") ||
           lowercaseSubject.contains("membership") ||
           lowercaseSubject.contains("renewal") ||
           lowercaseSubject.contains("monthly charge") ||
           lowercaseSubject.contains("recurring payment") {
            if lowercaseSubject.contains("renew") {
                return .subscriptionRenewal
            }
            return .subscription
        }

        // Price change patterns
        if lowercaseSubject.contains("price change") ||
           lowercaseSubject.contains("price increase") ||
           lowercaseSubject.contains("rate change") ||
           lowercaseSubject.contains("new price") {
            return .priceChange
        }

        // Bill patterns
        if lowercaseSubject.contains("bill") ||
           lowercaseSubject.contains("invoice") ||
           lowercaseSubject.contains("statement") ||
           lowercaseSubject.contains("payment due") ||
           lowercaseSubject.contains("amount due") {
            return .billDue
        }

        // Refund patterns
        if lowercaseSubject.contains("refund") ||
           lowercaseSubject.contains("credit applied") ||
           lowercaseSubject.contains("money back") {
            return .refund
        }

        // Price drop alert
        if lowercaseSubject.contains("price drop") ||
           lowercaseSubject.contains("price alert") ||
           lowercaseSubject.contains("back in stock") {
            return .priceDropAlert
        }

        // Promotional
        if lowercaseSubject.contains("% off") ||
           lowercaseSubject.contains("sale") ||
           lowercaseSubject.contains("deal") ||
           lowercaseSubject.contains("coupon") ||
           lowercaseSubject.contains("discount") {
            return .promotionalOffer
        }

        return .unknown
    }

    private func extractData(from body: String, sender: String, subject: String, type: ParsedEmail.EmailType) -> ParsedEmail.ExtractedData {
        var data = ParsedEmail.ExtractedData()

        // Extract merchant name from sender
        data.merchantName = extractMerchantName(from: sender)

        // Extract order number
        if let orderNumber = extractPattern(from: body, pattern: "(?:order|order #|order number|confirmation #)[:\\s]*([A-Z0-9-]+)", groupIndex: 1) {
            data.orderNumber = orderNumber
        }

        // Extract total amount
        if let total = extractAmount(from: body, patterns: [
            "(?:total|order total|grand total|amount)[:\\s]*\\$([0-9,]+\\.?[0-9]*)",
            "\\$([0-9,]+\\.?[0-9]*)\\s*(?:total|charged)"
        ]) {
            data.totalAmount = total
        }

        // Extract tracking number
        if let tracking = extractPattern(from: body, pattern: "(?:tracking|tracking #|tracking number)[:\\s]*([A-Z0-9]+)", groupIndex: 1) {
            data.trackingNumber = tracking
        }

        // Extract carrier
        let carriers = ["UPS", "FedEx", "USPS", "DHL", "Amazon Logistics"]
        for carrier in carriers {
            if body.contains(carrier) {
                data.carrier = carrier
                break
            }
        }

        // Extract subscription price
        if type == .subscription || type == .subscriptionRenewal {
            if let price = extractAmount(from: body, patterns: [
                "\\$([0-9.]+)(?:/month|/mo|monthly)",
                "\\$([0-9.]+)(?:/year|/yr|annually)",
                "(?:charged|billing)\\s*\\$([0-9.]+)"
            ]) {
                data.subscriptionPrice = price
            }

            data.subscriptionName = extractSubscriptionName(from: subject, sender: sender)
        }

        // Extract due date for bills
        if type == .billDue {
            data.dueDate = extractDate(from: body)
        }

        // Extract price change info
        if type == .priceChange {
            if let previous = extractAmount(from: body, patterns: ["(?:current|old|previous)\\s*(?:price)?[:\\s]*\\$([0-9.]+)"]) {
                data.previousPrice = previous
            }
            if let newPrice = extractAmount(from: body, patterns: ["(?:new|updated)\\s*(?:price)?[:\\s]*\\$([0-9.]+)"]) {
                data.newPrice = newPrice
            }
        }

        // Extract items if present
        data.items = extractItems(from: body)

        return data
    }

    private func extractMerchantName(from sender: String) -> String {
        // Extract domain from email
        if let atIndex = sender.firstIndex(of: "@") {
            let domain = String(sender[sender.index(after: atIndex)...])
            let components = domain.split(separator: ".")
            if components.count >= 2 {
                return String(components[0]).capitalized
            }
        }
        return sender
    }

    private func extractPattern(from text: String, pattern: String, groupIndex: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if groupIndex < match.numberOfRanges,
               let groupRange = Range(match.range(at: groupIndex), in: text) {
                return String(text[groupRange])
            }
        }
        return nil
    }

    private func extractAmount(from text: String, patterns: [String]) -> Double? {
        for pattern in patterns {
            if let amountString = extractPattern(from: text, pattern: pattern, groupIndex: 1) {
                let cleanedString = amountString.replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleanedString) {
                    return amount
                }
            }
        }
        return nil
    }

    private func extractDate(from text: String) -> Date? {
        let patterns = [
            "(?:due|by|before)[:\\s]*(\\w+ \\d+,? \\d{4})",
            "(\\d{1,2}/\\d{1,2}/\\d{2,4})",
            "(\\w+ \\d{1,2},? \\d{4})"
        ]

        for pattern in patterns {
            if let dateString = extractPattern(from: text, pattern: pattern, groupIndex: 1) {
                let formatters: [DateFormatter] = {
                    let formats = ["MMMM d, yyyy", "MMM d, yyyy", "M/d/yyyy", "MM/dd/yyyy", "M/d/yy"]
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

    private func extractSubscriptionName(from subject: String, sender: String) -> String {
        let knownServices = [
            "Netflix", "Spotify", "Apple Music", "Apple TV+", "Disney+", "Hulu",
            "HBO Max", "Amazon Prime", "YouTube Premium", "Adobe", "Microsoft 365",
            "Dropbox", "iCloud", "Google One", "Audible", "Kindle Unlimited"
        ]

        for service in knownServices {
            if subject.lowercased().contains(service.lowercased()) ||
               sender.lowercased().contains(service.lowercased()) {
                return service
            }
        }

        return extractMerchantName(from: sender)
    }

    private func extractItems(from body: String) -> [ParsedEmail.ExtractedItem]? {
        // Simplified item extraction - in production would use more sophisticated parsing
        var items: [ParsedEmail.ExtractedItem] = []

        // Pattern: Item name followed by quantity and price
        let pattern = "([\\w\\s]+)\\s+(?:x\\s*)?(\\d+)\\s+\\$([0-9.]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(body.startIndex..., in: body)
        let matches = regex.matches(in: body, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges >= 4,
                  let nameRange = Range(match.range(at: 1), in: body),
                  let qtyRange = Range(match.range(at: 2), in: body),
                  let priceRange = Range(match.range(at: 3), in: body),
                  let qty = Int(body[qtyRange]),
                  let price = Double(body[priceRange]) else {
                continue
            }

            items.append(ParsedEmail.ExtractedItem(
                id: UUID().uuidString,
                name: String(body[nameRange]).trimmingCharacters(in: .whitespaces),
                quantity: qty,
                price: price,
                originalPrice: nil,
                sku: nil,
                imageUrl: nil
            ))
        }

        return items.isEmpty ? nil : items
    }

    private func calculateConfidence(extractedData: ParsedEmail.ExtractedData, type: ParsedEmail.EmailType) -> Double {
        var confidence: Double = 0.5

        if extractedData.merchantName != nil { confidence += 0.1 }
        if extractedData.totalAmount != nil { confidence += 0.2 }
        if extractedData.orderNumber != nil { confidence += 0.1 }

        switch type {
        case .subscription, .subscriptionRenewal:
            if extractedData.subscriptionPrice != nil { confidence += 0.2 }
        case .shippingNotification:
            if extractedData.trackingNumber != nil { confidence += 0.2 }
        case .billDue:
            if extractedData.dueDate != nil { confidence += 0.2 }
        case .priceChange:
            if extractedData.previousPrice != nil && extractedData.newPrice != nil { confidence += 0.2 }
        default:
            break
        }

        return min(confidence, 1.0)
    }

    // MARK: - Processing Functions

    private func processOrderConfirmation(_ email: ParsedEmail) {
        guard let merchantName = email.extractedData.merchantName else { return }

        let order = EmailOrder(
            id: UUID().uuidString,
            emailId: email.emailId,
            merchantName: merchantName,
            orderNumber: email.extractedData.orderNumber ?? "Unknown",
            orderDate: email.receivedDate,
            items: email.extractedData.items ?? [],
            totalAmount: email.extractedData.totalAmount ?? 0,
            status: .ordered,
            trackingInfo: nil,
            deliveredDate: nil,
            returnDeadline: Calendar.current.date(byAdding: .day, value: 30, to: email.receivedDate)
        )

        orders.insert(order, at: 0)
        saveOrders()
    }

    private func processShippingNotification(_ email: ParsedEmail) {
        if let orderNumber = email.extractedData.orderNumber,
           let index = orders.firstIndex(where: { $0.orderNumber == orderNumber }) {
            var order = orders[index]
            order = EmailOrder(
                id: order.id,
                emailId: order.emailId,
                merchantName: order.merchantName,
                orderNumber: order.orderNumber,
                orderDate: order.orderDate,
                items: order.items,
                totalAmount: order.totalAmount,
                status: .shipped,
                trackingInfo: email.extractedData.trackingNumber != nil ? EmailOrder.TrackingInfo(
                    carrier: email.extractedData.carrier ?? "Unknown",
                    trackingNumber: email.extractedData.trackingNumber!,
                    estimatedDelivery: email.extractedData.estimatedDelivery,
                    lastUpdate: nil
                ) : nil,
                deliveredDate: nil,
                returnDeadline: order.returnDeadline
            )
            orders[index] = order
            saveOrders()
        }
    }

    private func processDeliveryConfirmation(_ email: ParsedEmail) {
        if let orderNumber = email.extractedData.orderNumber,
           let index = orders.firstIndex(where: { $0.orderNumber == orderNumber }) {
            var order = orders[index]
            order = EmailOrder(
                id: order.id,
                emailId: order.emailId,
                merchantName: order.merchantName,
                orderNumber: order.orderNumber,
                orderDate: order.orderDate,
                items: order.items,
                totalAmount: order.totalAmount,
                status: .delivered,
                trackingInfo: order.trackingInfo,
                deliveredDate: email.receivedDate,
                returnDeadline: order.returnDeadline
            )
            orders[index] = order
            saveOrders()
        }
    }

    private func processReceipt(_ email: ParsedEmail) {
        // Receipts are tracked separately - could be linked to transactions
    }

    private func processSubscription(_ email: ParsedEmail) {
        guard let name = email.extractedData.subscriptionName,
              let price = email.extractedData.subscriptionPrice else { return }

        let merchantName = email.extractedData.merchantName ?? name

        if let existingIndex = detectedSubscriptions.firstIndex(where: {
            $0.name.lowercased() == name.lowercased() ||
            $0.merchant.lowercased() == merchantName.lowercased()
        }) {
            // Update existing subscription
            var subscription = detectedSubscriptions[existingIndex]
            if price != subscription.price {
                subscription.priceHistory.append(DetectedSubscription.PriceHistoryEntry(
                    date: email.receivedDate,
                    price: price
                ))
            }
            subscription.price = price
            subscription.nextBillingDate = Calendar.current.date(byAdding: .month, value: 1, to: email.receivedDate)
            subscription.detectedFromEmails.append(email.emailId)
            detectedSubscriptions[existingIndex] = subscription
        } else {
            // New subscription
            let subscription = DetectedSubscription(
                id: UUID().uuidString,
                name: name,
                merchant: merchantName,
                price: price,
                billingFrequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .month, value: 1, to: email.receivedDate),
                startDate: email.receivedDate,
                category: categorizeSubscription(name),
                detectedFromEmails: [email.emailId],
                priceHistory: [DetectedSubscription.PriceHistoryEntry(date: email.receivedDate, price: price)],
                isActive: true,
                cancelUrl: nil
            )
            detectedSubscriptions.append(subscription)
        }

        saveSubscriptions()
    }

    private func processPriceChange(_ email: ParsedEmail) {
        guard let previousPrice = email.extractedData.previousPrice,
              let newPrice = email.extractedData.newPrice,
              let subscriptionName = email.extractedData.subscriptionName else { return }

        // Find matching subscription
        let subscriptionId = detectedSubscriptions.first { $0.name.lowercased() == subscriptionName.lowercased() }?.id ?? UUID().uuidString

        let alert = PriceChangeAlert(
            id: UUID().uuidString,
            subscriptionId: subscriptionId,
            subscriptionName: subscriptionName,
            merchantName: email.extractedData.merchantName ?? subscriptionName,
            previousPrice: previousPrice,
            newPrice: newPrice,
            effectiveDate: email.extractedData.dueDate ?? Calendar.current.date(byAdding: .month, value: 1, to: email.receivedDate) ?? email.receivedDate,
            percentageChange: ((newPrice - previousPrice) / previousPrice) * 100,
            detectedDate: Date(),
            acknowledged: false,
            action: nil
        )

        priceChangeAlerts.insert(alert, at: 0)
        savePriceChanges()

        // Update subscription if exists
        if let index = detectedSubscriptions.firstIndex(where: { $0.id == subscriptionId }) {
            detectedSubscriptions[index].price = newPrice
            detectedSubscriptions[index].priceHistory.append(
                DetectedSubscription.PriceHistoryEntry(date: Date(), price: newPrice)
            )
            saveSubscriptions()
        }
    }

    private func processBillReminder(_ email: ParsedEmail) {
        guard let merchantName = email.extractedData.merchantName else { return }

        let bill = BillReminder(
            id: UUID().uuidString,
            merchantName: merchantName,
            amount: email.extractedData.totalAmount ?? 0,
            dueDate: email.extractedData.dueDate ?? Calendar.current.date(byAdding: .day, value: 14, to: email.receivedDate) ?? email.receivedDate,
            category: "Bills",
            isRecurring: true,
            emailId: email.emailId,
            isPaid: false,
            reminderSent: false
        )

        billReminders.insert(bill, at: 0)
        saveBills()
    }

    private func processRefund(_ email: ParsedEmail) {
        if let orderNumber = email.extractedData.orderNumber,
           let index = orders.firstIndex(where: { $0.orderNumber == orderNumber }) {
            var order = orders[index]
            order = EmailOrder(
                id: order.id,
                emailId: order.emailId,
                merchantName: order.merchantName,
                orderNumber: order.orderNumber,
                orderDate: order.orderDate,
                items: order.items,
                totalAmount: order.totalAmount,
                status: .refunded,
                trackingInfo: order.trackingInfo,
                deliveredDate: order.deliveredDate,
                returnDeadline: order.returnDeadline
            )
            orders[index] = order
            saveOrders()
        }
    }

    private func categorizeSubscription(_ name: String) -> String {
        let streaming = ["Netflix", "Hulu", "Disney+", "HBO", "Paramount", "Peacock", "Apple TV"]
        let music = ["Spotify", "Apple Music", "Amazon Music", "YouTube Music", "Tidal", "Pandora"]
        let productivity = ["Microsoft 365", "Adobe", "Notion", "Evernote", "Todoist"]
        let storage = ["iCloud", "Google One", "Dropbox", "OneDrive"]
        let gaming = ["Xbox", "PlayStation", "Nintendo", "Game Pass"]
        let news = ["New York Times", "Washington Post", "WSJ", "The Athletic"]

        let lowercaseName = name.lowercased()

        for service in streaming where lowercaseName.contains(service.lowercased()) { return "Streaming" }
        for service in music where lowercaseName.contains(service.lowercased()) { return "Music" }
        for service in productivity where lowercaseName.contains(service.lowercased()) { return "Productivity" }
        for service in storage where lowercaseName.contains(service.lowercased()) { return "Storage" }
        for service in gaming where lowercaseName.contains(service.lowercased()) { return "Gaming" }
        for service in news where lowercaseName.contains(service.lowercased()) { return "News" }

        return "Other"
    }

    // MARK: - Summary Statistics

    private func calculateSummaryStats() {
        totalMonthlySubscriptions = detectedSubscriptions
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.monthlyPrice }

        pendingDeliveries = orders
            .filter { $0.status == .shipped || $0.status == .ordered }
            .count

        upcomingBills = billReminders
            .filter { !$0.isPaid && $0.daysUntilDue <= 7 }
            .count

        recentPriceChanges = priceChangeAlerts
            .filter { !$0.acknowledged }
            .count
    }

    // MARK: - Manual Import

    func importGoogleTakeoutPurchases(data: Data) {
        // Parse Google Takeout purchase history JSON
        // In production, this would handle the specific format
    }

    func importForwardedEmail(content: String, sender: String, subject: String) {
        if let parsed = parseEmail(sender: sender, subject: subject, body: content, receivedDate: Date()) {
            processEmail(parsed)
        }
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: parsedEmailsKey),
           let emails = try? JSONDecoder().decode([ParsedEmail].self, from: data) {
            parsedEmails = emails
        }

        if let data = userDefaults.data(forKey: subscriptionsKey),
           let subs = try? JSONDecoder().decode([DetectedSubscription].self, from: data) {
            detectedSubscriptions = subs
        }

        if let data = userDefaults.data(forKey: ordersKey),
           let savedOrders = try? JSONDecoder().decode([EmailOrder].self, from: data) {
            orders = savedOrders
        }

        if let data = userDefaults.data(forKey: priceChangesKey),
           let changes = try? JSONDecoder().decode([PriceChangeAlert].self, from: data) {
            priceChangeAlerts = changes
        }

        if let data = userDefaults.data(forKey: billsKey),
           let bills = try? JSONDecoder().decode([BillReminder].self, from: data) {
            billReminders = bills
        }

        if let data = userDefaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode([String: String].self, from: data) {
            if let providerString = settings["provider"],
               let provider = EmailProvider(rawValue: providerString) {
                emailProvider = provider
            }
            isConnected = settings["connected"] == "true"
            if let lastSync = settings["lastSync"], let interval = Double(lastSync) {
                lastSyncDate = Date(timeIntervalSince1970: interval)
            }
        }
    }

    private func saveParsedEmails() {
        if let data = try? JSONEncoder().encode(parsedEmails) {
            userDefaults.set(data, forKey: parsedEmailsKey)
        }
    }

    private func saveSubscriptions() {
        if let data = try? JSONEncoder().encode(detectedSubscriptions) {
            userDefaults.set(data, forKey: subscriptionsKey)
        }
    }

    private func saveOrders() {
        if let data = try? JSONEncoder().encode(orders) {
            userDefaults.set(data, forKey: ordersKey)
        }
    }

    private func savePriceChanges() {
        if let data = try? JSONEncoder().encode(priceChangeAlerts) {
            userDefaults.set(data, forKey: priceChangesKey)
        }
    }

    private func saveBills() {
        if let data = try? JSONEncoder().encode(billReminders) {
            userDefaults.set(data, forKey: billsKey)
        }
    }

    private func saveSettings() {
        var settings: [String: String] = [:]
        settings["provider"] = emailProvider?.rawValue
        settings["connected"] = isConnected ? "true" : "false"
        settings["lastSync"] = lastSyncDate.map { String($0.timeIntervalSince1970) }

        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
}
