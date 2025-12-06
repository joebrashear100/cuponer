//
//  SpendingLimitsManager.swift
//  Furg
//
//  Service for managing category spending limits and alerts
//

import SwiftUI

// MARK: - Models

struct SpendingLimit: Identifiable, Codable {
    let id: String
    let category: String
    let limitAmount: Decimal
    let period: LimitPeriod
    let warningThreshold: Double
    var currentSpent: Decimal
    var isActive: Bool

    var remaining: Decimal {
        limitAmount - currentSpent
    }

    var percentageUsed: Double {
        guard limitAmount > 0 else { return 0 }
        return Double(truncating: (currentSpent / limitAmount) as NSDecimalNumber)
    }

    var isOverLimit: Bool {
        currentSpent >= limitAmount
    }

    var isNearLimit: Bool {
        percentageUsed >= warningThreshold && !isOverLimit
    }

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case limitAmount = "limit_amount"
        case period
        case warningThreshold = "warning_threshold"
        case currentSpent = "current_spent"
        case isActive = "is_active"
    }

    static var demo: [SpendingLimit] {
        [
            SpendingLimit(
                id: "1",
                category: "Dining",
                limitAmount: 400,
                period: .monthly,
                warningThreshold: 0.8,
                currentSpent: 287.50,
                isActive: true
            ),
            SpendingLimit(
                id: "2",
                category: "Entertainment",
                limitAmount: 200,
                period: .monthly,
                warningThreshold: 0.8,
                currentSpent: 175.00,
                isActive: true
            ),
            SpendingLimit(
                id: "3",
                category: "Shopping",
                limitAmount: 300,
                period: .monthly,
                warningThreshold: 0.75,
                currentSpent: 89.99,
                isActive: true
            ),
            SpendingLimit(
                id: "4",
                category: "Transportation",
                limitAmount: 150,
                period: .monthly,
                warningThreshold: 0.8,
                currentSpent: 162.00,
                isActive: true
            ),
            SpendingLimit(
                id: "5",
                category: "Coffee",
                limitAmount: 50,
                period: .weekly,
                warningThreshold: 0.7,
                currentSpent: 28.50,
                isActive: true
            )
        ]
    }
}

enum LimitPeriod: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}

struct SpendingAlert: Identifiable, Codable {
    let id: String
    let alertType: AlertType
    let title: String
    let message: String
    let category: String?
    let amount: Decimal?
    let createdAt: Date
    var isRead: Bool

    enum AlertType: String, Codable {
        case limitWarning = "limit_warning"
        case limitExceeded = "limit_exceeded"
        case billDue = "bill_due"
        case unusualSpending = "unusual_spending"
        case goalMilestone = "goal_milestone"
        case payday = "payday"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case alertType = "alert_type"
        case title
        case message
        case category
        case amount
        case createdAt = "created_at"
        case isRead = "is_read"
    }

    var icon: String {
        switch alertType {
        case .limitWarning: return "exclamationmark.triangle.fill"
        case .limitExceeded: return "xmark.octagon.fill"
        case .billDue: return "calendar.badge.exclamationmark"
        case .unusualSpending: return "chart.line.uptrend.xyaxis"
        case .goalMilestone: return "flag.fill"
        case .payday: return "dollarsign.circle.fill"
        }
    }

    var iconColor: Color {
        switch alertType {
        case .limitWarning: return .furgWarning
        case .limitExceeded: return .furgDanger
        case .billDue: return .furgAccent
        case .unusualSpending: return .orange
        case .goalMilestone: return .furgMint
        case .payday: return .furgSuccess
        }
    }

    static var demo: [SpendingAlert] {
        [
            SpendingAlert(
                id: "1",
                alertType: .limitExceeded,
                title: "Transportation Limit Exceeded",
                message: "You've spent $162 of your $150 monthly limit on transportation.",
                category: "Transportation",
                amount: 162,
                createdAt: Date(),
                isRead: false
            ),
            SpendingAlert(
                id: "2",
                alertType: .limitWarning,
                title: "Entertainment at 87%",
                message: "You've used $175 of your $200 entertainment budget.",
                category: "Entertainment",
                amount: 175,
                createdAt: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            SpendingAlert(
                id: "3",
                alertType: .billDue,
                title: "Rent Due in 3 Days",
                message: "Your rent payment of $1,500 is due on December 9th.",
                category: nil,
                amount: 1500,
                createdAt: Date().addingTimeInterval(-7200),
                isRead: true
            ),
            SpendingAlert(
                id: "4",
                alertType: .goalMilestone,
                title: "Goal Progress!",
                message: "You've reached 35% of your house down payment goal!",
                category: nil,
                amount: 10500,
                createdAt: Date().addingTimeInterval(-86400),
                isRead: true
            )
        ]
    }
}

// MARK: - Manager

@MainActor
class SpendingLimitsManager: ObservableObject {
    @Published var limits: [SpendingLimit] = []
    @Published var alerts: [SpendingAlert] = []
    @Published var isLoading = false
    @Published var error: String?

    var unreadAlertCount: Int {
        alerts.filter { !$0.isRead }.count
    }

    var overLimitCategories: [SpendingLimit] {
        limits.filter { $0.isOverLimit }
    }

    var nearLimitCategories: [SpendingLimit] {
        limits.filter { $0.isNearLimit }
    }

    init() {
        loadDemoData()
    }

    private func loadDemoData() {
        limits = SpendingLimit.demo
        alerts = SpendingAlert.demo
    }

    func loadLimits() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Replace with actual API call
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            limits = SpendingLimit.demo
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAlerts() async {
        // TODO: Replace with actual API call
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
            alerts = SpendingAlert.demo
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createLimit(
        category: String,
        amount: Decimal,
        period: LimitPeriod,
        warningThreshold: Double = 0.8
    ) async {
        let newLimit = SpendingLimit(
            id: UUID().uuidString,
            category: category,
            limitAmount: amount,
            period: period,
            warningThreshold: warningThreshold,
            currentSpent: 0,
            isActive: true
        )

        limits.append(newLimit)

        // TODO: API call to persist
    }

    func updateLimit(_ limit: SpendingLimit, newAmount: Decimal) async {
        if let index = limits.firstIndex(where: { $0.id == limit.id }) {
            var updated = limits[index]
            updated = SpendingLimit(
                id: updated.id,
                category: updated.category,
                limitAmount: newAmount,
                period: updated.period,
                warningThreshold: updated.warningThreshold,
                currentSpent: updated.currentSpent,
                isActive: updated.isActive
            )
            limits[index] = updated
        }

        // TODO: API call to persist
    }

    func deleteLimit(_ limit: SpendingLimit) async {
        limits.removeAll { $0.id == limit.id }

        // TODO: API call to delete
    }

    func markAlertRead(_ alert: SpendingAlert) async {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].isRead = true
        }

        // TODO: API call to update
    }

    func markAllAlertsRead() async {
        for i in alerts.indices {
            alerts[i].isRead = true
        }

        // TODO: API call to update
    }

    func checkTransaction(amount: Decimal, category: String) -> SpendingAlert? {
        guard let limit = limits.first(where: { $0.category == category && $0.isActive }) else {
            return nil
        }

        let newSpent = limit.currentSpent + amount

        if newSpent >= limit.limitAmount {
            return SpendingAlert(
                id: UUID().uuidString,
                alertType: .limitExceeded,
                title: "\(category) Limit Exceeded",
                message: "This purchase puts you over your \(limit.period.displayName.lowercased()) limit.",
                category: category,
                amount: newSpent,
                createdAt: Date(),
                isRead: false
            )
        } else if Double(truncating: (newSpent / limit.limitAmount) as NSDecimalNumber) >= limit.warningThreshold {
            return SpendingAlert(
                id: UUID().uuidString,
                alertType: .limitWarning,
                title: "\(category) Budget Warning",
                message: "You're approaching your \(limit.period.displayName.lowercased()) limit.",
                category: category,
                amount: newSpent,
                createdAt: Date(),
                isRead: false
            )
        }

        return nil
    }
}

// MARK: - Category Helpers

extension SpendingLimitsManager {
    static let availableCategories = [
        "Dining",
        "Coffee",
        "Entertainment",
        "Shopping",
        "Transportation",
        "Groceries",
        "Subscriptions",
        "Personal Care",
        "Health",
        "Travel",
        "Education",
        "Gifts",
        "Other"
    ]

    static func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "dining": return "fork.knife"
        case "coffee": return "cup.and.saucer.fill"
        case "entertainment": return "tv.fill"
        case "shopping": return "bag.fill"
        case "transportation": return "car.fill"
        case "groceries": return "cart.fill"
        case "subscriptions": return "creditcard.fill"
        case "personal care": return "sparkles"
        case "health": return "heart.fill"
        case "travel": return "airplane"
        case "education": return "book.fill"
        case "gifts": return "gift.fill"
        default: return "dollarsign.circle.fill"
        }
    }

    static func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "dining": return .orange
        case "coffee": return .brown
        case "entertainment": return .purple
        case "shopping": return .pink
        case "transportation": return .blue
        case "groceries": return .green
        case "subscriptions": return .indigo
        case "personal care": return .mint
        case "health": return .red
        case "travel": return .cyan
        case "education": return .teal
        case "gifts": return .yellow
        default: return .gray
        }
    }
}
