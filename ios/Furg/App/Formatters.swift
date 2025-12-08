//
//  Formatters.swift
//  Furg
//
//  Shared formatting utilities for consistent data presentation across the app
//

import Foundation
import SwiftUI

// MARK: - Currency Formatting

struct CurrencyFormatter {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let compactCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Format a value as currency (e.g., $1,234.56)
    static func format(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    /// Format a value as compact currency without cents (e.g., $1,235)
    static func formatCompact(_ value: Double) -> String {
        return compactCurrencyFormatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    /// Format a value with abbreviated suffix for large numbers (e.g., $1.2K, $1.5M)
    static func formatAbbreviated(_ value: Double) -> String {
        if abs(value) >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        }
        return format(value)
    }

    /// Format as signed currency showing + or - (e.g., +$50.00, -$25.00)
    static func formatSigned(_ value: Double) -> String {
        let formatted = format(abs(value))
        return value >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
}

// MARK: - Percentage Formatting

struct PercentageFormatter {
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.multiplier = 1
        return formatter
    }()

    /// Format a percentage value (e.g., 75.5%)
    static func format(_ value: Double) -> String {
        return percentFormatter.string(from: NSNumber(value: value / 100)) ?? "\(value)%"
    }

    /// Format as whole percentage (e.g., 75%)
    static func formatWhole(_ value: Double) -> String {
        return "\(Int(value.rounded()))%"
    }

    /// Format as signed percentage showing + or - (e.g., +5.25%, -3.50%)
    static func formatSigned(_ value: Double, decimals: Int = 2) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.\(decimals)f", value))%"
    }

    /// Format with explicit decimal places
    static func format(_ value: Double, decimals: Int) -> String {
        return String(format: "%.\(decimals)f%%", value)
    }
}

// MARK: - Time Formatting

struct TimeFormatter {
    /// Format duration in hours and minutes (e.g., "2h 30m")
    static func formatHoursMinutes(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60

        if h == 0 {
            return "\(m)m"
        } else if m == 0 {
            return "\(h)h"
        }
        return "\(h)h \(m)m"
    }

    /// Format duration in work time format (e.g., "2.5 hours of work")
    static func formatWorkTime(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60)) min of work"
        } else if hours == 1 {
            return "1 hour of work"
        }
        return String(format: "%.1f hours of work", hours)
    }

    /// Format time interval as mm:ss (e.g., "5:30")
    static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format time interval as human readable (e.g., "2m 30s")
    static func formatDurationReadable(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Date Formatting

struct DateFormatters {
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Format as short date (e.g., "12/8/24")
    static func shortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }

    /// Format as medium date (e.g., "Dec 8, 2024")
    static func mediumDate(_ date: Date) -> String {
        return mediumDateFormatter.string(from: date)
    }

    /// Format as relative time (e.g., "2 hr ago")
    static func relative(_ date: Date) -> String {
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format as month and year (e.g., "December 2024")
    static func monthYear(_ date: Date) -> String {
        return monthYearFormatter.string(from: date)
    }

    /// Format as day and month (e.g., "Dec 8")
    static func dayMonth(_ date: Date) -> String {
        return dayMonthFormatter.string(from: date)
    }
}

// MARK: - Convenience Extensions

extension Double {
    /// Format as currency
    var asCurrency: String {
        CurrencyFormatter.format(self)
    }

    /// Format as compact currency
    var asCompactCurrency: String {
        CurrencyFormatter.formatCompact(self)
    }

    /// Format as percentage
    var asPercent: String {
        PercentageFormatter.format(self)
    }

    /// Format as work hours
    var asWorkHours: String {
        TimeFormatter.formatWorkTime(self)
    }
}

extension Date {
    /// Format as short date
    var shortFormatted: String {
        DateFormatters.shortDate(self)
    }

    /// Format as relative time
    var relativeFormatted: String {
        DateFormatters.relative(self)
    }
}

// MARK: - Affordability Color Utilities

struct AffordabilityColors {
    /// Get color for affordability impact level string
    static func color(for level: String) -> Color {
        switch level.lowercased() {
        case "easily_affordable", "easily affordable", "negligible":
            return .green
        case "affordable", "minor":
            return Color.green.opacity(0.8)
        case "consider_carefully", "consider carefully", "moderate":
            return .yellow
        case "stretch", "significant":
            return .orange
        case "not_recommended", "not recommended", "major":
            return .red
        default:
            return .gray
        }
    }

    /// Get icon for affordability impact level string
    static func icon(for level: String) -> String {
        switch level.lowercased() {
        case "easily_affordable", "easily affordable", "negligible":
            return "checkmark.circle.fill"
        case "affordable", "minor":
            return "checkmark.circle"
        case "consider_carefully", "consider carefully", "moderate":
            return "exclamationmark.circle"
        case "stretch", "significant":
            return "exclamationmark.triangle"
        case "not_recommended", "not recommended", "major":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle"
        }
    }

    /// Format impact level for display
    static func displayText(for level: String) -> String {
        switch level.lowercased() {
        case "easily_affordable", "negligible":
            return "Easily Affordable"
        case "affordable", "minor":
            return "Affordable"
        case "consider_carefully", "moderate":
            return "Consider Carefully"
        case "stretch", "significant":
            return "A Stretch"
        case "not_recommended", "major":
            return "Not Recommended"
        default:
            return level.capitalized
        }
    }
}

// MARK: - Category Colors

struct CategoryColors {
    private static let categoryColorMap: [String: Color] = [
        "Electronics": .blue,
        "Gaming": .purple,
        "Home": .orange,
        "Kitchen": .yellow,
        "Clothing": .pink,
        "Outdoor": .green,
        "Food & Dining": Color(red: 0.6, green: 0.95, blue: 0.85),
        "Groceries": Color(red: 0.6, green: 0.95, blue: 0.85),
        "Shopping": Color(red: 0.5, green: 0.75, blue: 1.0),
        "Entertainment": Color(red: 1.0, green: 0.7, blue: 0.5),
        "Transportation": Color(red: 0.85, green: 0.65, blue: 0.95),
        "Bills & Utilities": Color(red: 1.0, green: 0.85, blue: 0.5),
        "Health": Color(red: 0.6, green: 0.85, blue: 0.7),
        "Travel": Color(red: 0.5, green: 0.85, blue: 0.95),
        "Personal": Color(red: 0.95, green: 0.7, blue: 0.75),
        "Unknown": .gray
    ]

    /// Get color for a category name
    static func color(for category: String) -> Color {
        return categoryColorMap[category] ?? .gray.opacity(0.7)
    }

    /// Get color for category at index (cycles through colors)
    static func color(at index: Int) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Merchant Category Colors

struct MerchantCategoryColors {
    /// Get color for merchant category
    static func color(for category: String) -> Color {
        switch category.lowercased() {
        case "grocery", "groceries":
            return .green
        case "electronics":
            return .blue
        case "department":
            return .purple
        case "pharmacy":
            return .red
        case "home goods", "homegoods":
            return .orange
        case "clothing", "apparel":
            return .pink
        case "restaurant", "dining":
            return .orange
        case "gas", "fuel":
            return .yellow
        case "warehouse":
            return .indigo
        default:
            return .gray
        }
    }
}
