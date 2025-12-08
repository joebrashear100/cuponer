//
//  SpendingPredictionManager.swift
//  Furg
//
//  AI-powered spending predictions based on seasonal patterns and holidays
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct SpendingPrediction: Identifiable {
    let id = UUID()
    let period: PredictionPeriod
    let predictedAmount: Double
    let historicalAverage: Double
    let variance: Double // How much above/below average
    let confidence: Double
    let factors: [PredictionFactor]
    let recommendations: [String]
}

enum PredictionPeriod: String, CaseIterable {
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
    case thisMonth = "This Month"
    case nextMonth = "Next Month"

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .nextWeek:
            let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let start = calendar.date(byAdding: .day, value: 7, to: thisWeekStart)!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .nextMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: 1, to: thisMonthStart)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        }
    }
}

struct PredictionFactor: Identifiable {
    let id = UUID()
    let name: String
    let impact: Double // Positive = increases spending, negative = decreases
    let icon: String
    let description: String
}

struct SeasonalPattern: Codable {
    let month: Int
    let dayOfWeek: Int?
    let multiplier: Double
    let category: String?
    let description: String
}

struct UpcomingEvent: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let expectedImpact: Double
    let category: String
    let icon: String
    let description: String
    let isUserDefined: Bool
}

struct CategoryPrediction: Identifiable {
    let id = UUID()
    let category: String
    let predictedAmount: Double
    let trend: SpendingTrend
    let factors: [String]
}

enum SpendingTrend: String {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .increasing: return .furgWarning
        case .decreasing: return .furgSuccess
        case .stable: return .furgMint
        }
    }
}

// MARK: - Spending Prediction Manager

class SpendingPredictionManager: ObservableObject {
    static let shared = SpendingPredictionManager()

    @Published var currentPredictions: [SpendingPrediction] = []
    @Published var categoryPredictions: [CategoryPrediction] = []
    @Published var upcomingEvents: [UpcomingEvent] = []
    @Published var seasonalAlerts: [String] = []

    private var historicalData: [Date: Double] = [:]
    private var cancellables = Set<AnyCancellable>()

    // Holiday and seasonal spending multipliers
    private let holidayMultipliers: [String: (month: Int, day: Int?, multiplier: Double, description: String)] = [
        "New Year": (1, 1, 1.3, "New Year celebrations and sales"),
        "Valentine's Day": (2, 14, 1.4, "Valentine's gifts and dining"),
        "St. Patrick's Day": (3, 17, 1.15, "St. Patrick's Day festivities"),
        "Easter": (4, nil, 1.2, "Easter shopping and family gatherings"),
        "Memorial Day": (5, nil, 1.25, "Memorial Day sales and travel"),
        "Fourth of July": (7, 4, 1.3, "Independence Day celebrations"),
        "Labor Day": (9, nil, 1.2, "Labor Day sales and travel"),
        "Halloween": (10, 31, 1.35, "Halloween costumes and candy"),
        "Thanksgiving": (11, nil, 1.5, "Thanksgiving food and travel"),
        "Black Friday": (11, nil, 2.0, "Black Friday shopping"),
        "Cyber Monday": (12, nil, 1.8, "Cyber Monday deals"),
        "Christmas": (12, 25, 2.2, "Christmas gifts and celebrations"),
        "New Year's Eve": (12, 31, 1.4, "New Year's Eve parties")
    ]

    // Category-specific seasonal patterns
    private let categorySeasonalPatterns: [String: [(months: [Int], multiplier: Double, reason: String)]] = [
        "Travel": [
            ([6, 7, 8], 1.5, "Summer vacation season"),
            ([12], 1.4, "Holiday travel"),
            ([3], 1.3, "Spring break travel")
        ],
        "Utilities": [
            ([1, 2, 12], 1.3, "Winter heating costs"),
            ([7, 8], 1.25, "Summer cooling costs")
        ],
        "Food & Dining": [
            ([11, 12], 1.4, "Holiday dining and entertaining"),
            ([5], 1.2, "Mother's Day dining")
        ],
        "Shopping": [
            ([11, 12], 1.8, "Holiday shopping season"),
            ([8], 1.3, "Back-to-school shopping"),
            ([1], 0.8, "Post-holiday spending reduction")
        ],
        "Entertainment": [
            ([6, 7, 8], 1.3, "Summer activities"),
            ([12], 1.2, "Holiday events")
        ],
        "Health & Medical": [
            ([1], 1.4, "New year health resolutions"),
            ([9], 1.2, "Back-to-school checkups")
        ]
    ]

    init() {
        loadHistoricalData()
        generatePredictions()
        identifyUpcomingEvents()
    }

    // MARK: - Prediction Generation

    func generatePredictions() {
        currentPredictions = PredictionPeriod.allCases.map { period in
            generatePrediction(for: period)
        }

        generateCategoryPredictions()
        generateSeasonalAlerts()
    }

    private func generatePrediction(for period: PredictionPeriod) -> SpendingPrediction {
        let baseAmount = getBaselineSpending(for: period)
        var factors: [PredictionFactor] = []
        var totalMultiplier = 1.0

        let dateRange = period.dateRange
        let calendar = Calendar.current

        // Check for holidays in this period
        for (holiday, info) in holidayMultipliers {
            if isHolidayInRange(month: info.month, day: info.day, range: dateRange) {
                let impact = (info.multiplier - 1.0) * baseAmount
                factors.append(PredictionFactor(
                    name: holiday,
                    impact: impact,
                    icon: "gift.fill",
                    description: info.description
                ))
                totalMultiplier *= info.multiplier
            }
        }

        // Day of week patterns
        let weekendDays = countWeekendDays(in: dateRange)
        if weekendDays > 0 {
            let weekendImpact = Double(weekendDays) * 50 // Avg $50 extra per weekend day
            factors.append(PredictionFactor(
                name: "Weekend Spending",
                impact: weekendImpact,
                icon: "calendar",
                description: "\(weekendDays) weekend days in this period"
            ))
        }

        // Payday effect
        let paydays = getPaydaysInRange(dateRange)
        if !paydays.isEmpty {
            let paydayImpact = Double(paydays.count) * 100 // Avg $100 extra around payday
            factors.append(PredictionFactor(
                name: "Payday Effect",
                impact: paydayImpact,
                icon: "dollarsign.circle.fill",
                description: "\(paydays.count) payday(s) in this period"
            ))
        }

        // Seasonal adjustment
        let month = calendar.component(.month, from: dateRange.start)
        let seasonalMultiplier = getSeasonalMultiplier(for: month)
        if abs(seasonalMultiplier - 1.0) > 0.05 {
            let seasonalImpact = (seasonalMultiplier - 1.0) * baseAmount
            factors.append(PredictionFactor(
                name: "Seasonal Pattern",
                impact: seasonalImpact,
                icon: "leaf.fill",
                description: getSeasonDescription(for: month)
            ))
            totalMultiplier *= seasonalMultiplier
        }

        // Calculate final prediction
        let factorSum = factors.reduce(0) { $0 + $1.impact }
        let predictedAmount = baseAmount * totalMultiplier + factorSum * 0.5 // Dampen factor impact

        // Generate recommendations
        let recommendations = generateRecommendations(
            predicted: predictedAmount,
            baseline: baseAmount,
            factors: factors
        )

        // Calculate confidence based on historical data availability
        let confidence = min(0.85, 0.5 + Double(historicalData.count) * 0.01)

        return SpendingPrediction(
            period: period,
            predictedAmount: predictedAmount,
            historicalAverage: baseAmount,
            variance: (predictedAmount - baseAmount) / baseAmount * 100,
            confidence: confidence,
            factors: factors,
            recommendations: recommendations
        )
    }

    private func generateCategoryPredictions() {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())

        let categories = ["Food & Dining", "Shopping", "Transportation", "Entertainment", "Utilities", "Travel", "Health & Medical"]

        categoryPredictions = categories.compactMap { category in
            let baseAmount = getCategoryBaseline(category)
            var multiplier = 1.0
            var factors: [String] = []

            // Apply category-specific seasonal patterns
            if let patterns = categorySeasonalPatterns[category] {
                for pattern in patterns {
                    if pattern.months.contains(currentMonth) {
                        multiplier *= pattern.multiplier
                        factors.append(pattern.reason)
                    }
                }
            }

            let predictedAmount = baseAmount * multiplier
            let trend: SpendingTrend = multiplier > 1.1 ? .increasing : (multiplier < 0.9 ? .decreasing : .stable)

            return CategoryPrediction(
                category: category,
                predictedAmount: predictedAmount,
                trend: trend,
                factors: factors
            )
        }
    }

    private func generateSeasonalAlerts() {
        var alerts: [String] = []
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentDay = calendar.component(.day, from: now)

        // Check for upcoming holidays in next 14 days
        for (holiday, info) in holidayMultipliers {
            if info.month == currentMonth || (info.month == currentMonth + 1 && currentDay > 15) {
                if let day = info.day {
                    let daysUntil = calculateDaysUntilHoliday(month: info.month, day: day)
                    if daysUntil > 0 && daysUntil <= 14 {
                        let increase = Int((info.multiplier - 1.0) * 100)
                        alerts.append("⚠️ \(holiday) is in \(daysUntil) days. Expect ~\(increase)% higher spending.")
                    }
                }
            }
        }

        // Back-to-school alert
        if currentMonth == 8 && currentDay < 20 {
            alerts.append("📚 Back-to-school season! Shopping typically increases 30%.")
        }

        // End of month bill reminder
        if currentDay >= 25 {
            alerts.append("📅 End of month approaching. Bills and subscriptions will renew soon.")
        }

        // Tax season
        if currentMonth >= 3 && currentMonth <= 4 {
            alerts.append("💰 Tax season! Consider setting aside money for potential payments.")
        }

        seasonalAlerts = alerts
    }

    // MARK: - Upcoming Events

    func identifyUpcomingEvents() {
        var events: [UpcomingEvent] = []
        let calendar = Calendar.current
        let now = Date()

        // Add holidays in the next 60 days
        for (holiday, info) in holidayMultipliers {
            if let eventDate = getNextOccurrence(month: info.month, day: info.day) {
                let daysUntil = calendar.dateComponents([.day], from: now, to: eventDate).day ?? 0
                if daysUntil >= 0 && daysUntil <= 60 {
                    events.append(UpcomingEvent(
                        name: holiday,
                        date: eventDate,
                        expectedImpact: (info.multiplier - 1.0) * getBaselineSpending(for: .thisWeek),
                        category: "Holiday",
                        icon: getHolidayIcon(holiday),
                        description: info.description,
                        isUserDefined: false
                    ))
                }
            }
        }

        // Add recurring bills (demo)
        let billEvents = [
            ("Rent Due", 1, 1500.0, "house.fill"),
            ("Car Insurance", 15, 150.0, "car.fill"),
            ("Phone Bill", 20, 85.0, "phone.fill")
        ]

        for (name, day, amount, icon) in billEvents {
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = day
            if let date = calendar.date(from: components), date >= now {
                events.append(UpcomingEvent(
                    name: name,
                    date: date,
                    expectedImpact: amount,
                    category: "Bills",
                    icon: icon,
                    description: "Recurring monthly expense",
                    isUserDefined: false
                ))
            }
        }

        upcomingEvents = events.sorted { $0.date < $1.date }
    }

    func addCustomEvent(name: String, date: Date, expectedImpact: Double, category: String) {
        let event = UpcomingEvent(
            name: name,
            date: date,
            expectedImpact: expectedImpact,
            category: category,
            icon: "calendar.badge.plus",
            description: "User-defined event",
            isUserDefined: true
        )

        upcomingEvents.append(event)
        upcomingEvents.sort { $0.date < $1.date }
    }

    // MARK: - Helper Functions

    private func getBaselineSpending(for period: PredictionPeriod) -> Double {
        // In a real app, this would analyze historical data
        switch period {
        case .thisWeek, .nextWeek:
            return 450.0 // Average weekly spending
        case .thisMonth, .nextMonth:
            return 1950.0 // Average monthly spending
        }
    }

    private func getCategoryBaseline(_ category: String) -> Double {
        // Demo baselines
        let baselines: [String: Double] = [
            "Food & Dining": 450,
            "Shopping": 300,
            "Transportation": 200,
            "Entertainment": 150,
            "Utilities": 250,
            "Travel": 100,
            "Health & Medical": 100
        ]
        return baselines[category] ?? 100
    }

    private func isHolidayInRange(month: Int, day: Int?, range: (Date, Date)) -> Bool {
        let calendar = Calendar.current
        let rangeMonth = calendar.component(.month, from: range.start)
        let rangeEndMonth = calendar.component(.month, from: range.end)

        if month >= rangeMonth && month <= rangeEndMonth {
            if let specificDay = day {
                let rangeDay = calendar.component(.day, from: range.start)
                let rangeEndDay = calendar.component(.day, from: range.end)
                return specificDay >= rangeDay && specificDay <= rangeEndDay
            }
            return true
        }
        return false
    }

    private func countWeekendDays(in range: (Date, Date)) -> Int {
        var count = 0
        var current = range.start
        let calendar = Calendar.current

        while current <= range.end {
            let weekday = calendar.component(.weekday, from: current)
            if weekday == 1 || weekday == 7 {
                count += 1
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return count
    }

    private func getPaydaysInRange(_ range: (Date, Date)) -> [Date] {
        return IncomeManager.shared.upcomingPaydays
            .filter { $0.predictedDate >= range.0 && $0.predictedDate <= range.1 }
            .map { $0.predictedDate }
    }

    private func getSeasonalMultiplier(for month: Int) -> Double {
        let multipliers: [Int: Double] = [
            1: 0.85,  // January - post-holiday reduction
            2: 0.95,
            3: 1.0,
            4: 1.05,
            5: 1.1,   // Spring activities
            6: 1.15,  // Summer starts
            7: 1.2,
            8: 1.25,  // Back to school
            9: 1.1,
            10: 1.15,
            11: 1.5,  // Holiday shopping starts
            12: 1.7   // Peak holiday
        ]
        return multipliers[month] ?? 1.0
    }

    private func getSeasonDescription(for month: Int) -> String {
        switch month {
        case 1: return "Post-holiday spending typically decreases"
        case 2...4: return "Spring season with moderate spending"
        case 5...8: return "Summer activities and vacation season"
        case 9, 10: return "Fall season with back-to-school impact"
        case 11, 12: return "Holiday shopping season"
        default: return "Seasonal patterns apply"
        }
    }

    private func calculateDaysUntilHoliday(month: Int, day: Int) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year], from: now)
        components.month = month
        components.day = day

        guard let holidayDate = calendar.date(from: components) else { return -1 }

        var targetDate = holidayDate
        if holidayDate < now {
            components.year! += 1
            targetDate = calendar.date(from: components) ?? holidayDate
        }

        return calendar.dateComponents([.day], from: now, to: targetDate).day ?? -1
    }

    private func getNextOccurrence(month: Int, day: Int?) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year], from: now)
        components.month = month
        components.day = day ?? 15 // Default to middle of month

        guard var date = calendar.date(from: components) else { return nil }

        if date < now {
            components.year! += 1
            date = calendar.date(from: components) ?? date
        }

        return date
    }

    private func getHolidayIcon(_ holiday: String) -> String {
        let icons: [String: String] = [
            "New Year": "sparkles",
            "Valentine's Day": "heart.fill",
            "Easter": "hare.fill",
            "Fourth of July": "star.fill",
            "Halloween": "moon.fill",
            "Thanksgiving": "leaf.fill",
            "Black Friday": "bag.fill",
            "Christmas": "gift.fill"
        ]
        return icons[holiday] ?? "calendar"
    }

    private func generateRecommendations(predicted: Double, baseline: Double, factors: [PredictionFactor]) -> [String] {
        var recommendations: [String] = []

        let percentIncrease = (predicted - baseline) / baseline * 100

        if percentIncrease > 30 {
            recommendations.append("📊 Significant spending increase expected. Consider setting a stricter budget.")
        }

        if factors.contains(where: { $0.name.contains("Holiday") || $0.name.contains("Black Friday") }) {
            recommendations.append("🎁 Holiday period ahead! Make a shopping list to avoid impulse purchases.")
        }

        if factors.contains(where: { $0.name == "Payday Effect" }) {
            recommendations.append("💰 Payday coming up. Remember to prioritize savings before discretionary spending.")
        }

        if predicted > baseline * 1.5 {
            recommendations.append("⚠️ Consider postponing non-essential purchases to a lower-spending period.")
        }

        if recommendations.isEmpty {
            recommendations.append("✅ Spending looks normal for this period. Keep up the good habits!")
        }

        return recommendations
    }

    private func loadHistoricalData() {
        // In a real app, this would load from transaction history
        // For demo, generate some historical data points
        let calendar = Calendar.current
        for i in 0..<90 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let baseAmount = Double.random(in: 50...200)
                let weekday = calendar.component(.weekday, from: date)
                let multiplier = (weekday == 1 || weekday == 7) ? 1.3 : 1.0
                historicalData[date] = baseAmount * multiplier
            }
        }
    }
}
