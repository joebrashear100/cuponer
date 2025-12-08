//
//  SpendingWidget.swift
//  FurgWidgets
//
//  Shows spending progress against budget
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SpendingEntry: TimelineEntry {
    let date: Date
    let spent: Double
    let budget: Double
    let dayOfMonth: Int
    let daysInMonth: Int
    let topCategories: [(name: String, amount: Double, color: Color)]
    let isPreview: Bool

    var remaining: Double {
        max(0, budget - spent)
    }

    var percentUsed: Double {
        guard budget > 0 else { return 0 }
        return min((spent / budget) * 100, 100)
    }

    var idealSpent: Double {
        budget * Double(dayOfMonth) / Double(daysInMonth)
    }

    var isOverPace: Bool {
        spent > idealSpent
    }

    static var placeholder: SpendingEntry {
        SpendingEntry(
            date: Date(),
            spent: 2340.50,
            budget: 4000.00,
            dayOfMonth: 15,
            daysInMonth: 30,
            topCategories: [
                ("Food & Dining", 680.45, .orange),
                ("Shopping", 520.30, .blue),
                ("Entertainment", 340.20, .purple)
            ],
            isPreview: true
        )
    }
}

// MARK: - Timeline Provider

struct SpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendingEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.furg.app")

        let spent = sharedDefaults?.double(forKey: "widget_monthly_spent") ?? 2340.50
        let budget = sharedDefaults?.double(forKey: "widget_monthly_budget") ?? 4000.00

        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        let entry = SpendingEntry(
            date: now,
            spent: spent,
            budget: budget,
            dayOfMonth: dayOfMonth,
            daysInMonth: daysInMonth,
            topCategories: [
                ("Food & Dining", 680.45, .orange),
                ("Shopping", 520.30, .blue),
                ("Entertainment", 340.20, .purple)
            ],
            isPreview: false
        )

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct SpendingWidgetEntryView: View {
    var entry: SpendingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallSpendingView(entry: entry)
        case .systemMedium:
            MediumSpendingView(entry: entry)
        case .systemLarge:
            LargeSpendingView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularSpendingView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularSpendingView(entry: entry)
        case .accessoryInline:
            AccessoryInlineSpendingView(entry: entry)
        @unknown default:
            SmallSpendingView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallSpendingView: View {
    let entry: SpendingEntry

    private var statusColor: Color {
        if entry.percentUsed > 100 {
            return WidgetColors.danger
        } else if entry.isOverPace {
            return WidgetColors.warning
        }
        return WidgetColors.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WidgetColors.mint)

                Spacer()

                Text("\(Int(entry.percentUsed))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(statusColor)
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: entry.percentUsed / 100)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(formatCompact(entry.remaining))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("left")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)
            .frame(maxWidth: .infinity)

            Spacer()

            Text("of \(formatCurrency(entry.budget))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Medium Widget

struct MediumSpendingView: View {
    let entry: SpendingEntry

    private var statusColor: Color {
        if entry.percentUsed > 100 {
            return WidgetColors.danger
        } else if entry.isOverPace {
            return WidgetColors.warning
        }
        return WidgetColors.success
    }

    private var statusText: String {
        if entry.percentUsed > 100 {
            return "Over budget"
        } else if entry.isOverPace {
            return "Over pace"
        }
        return "On track"
    }

    var body: some View {
        HStack(spacing: 20) {
            // Left side - Progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WidgetColors.mint)

                    Text("Monthly Spending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(formatCurrency(entry.spent))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // Ideal pace marker
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: 14)
                            .offset(x: geometry.size.width * (entry.idealSpent / entry.budget) - 1)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor)
                            .frame(width: geometry.size.width * min(entry.percentUsed / 100, 1), height: 8)
                    }
                }
                .frame(height: 14)

                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(statusColor)

                    Spacer()

                    Text("\(formatCurrency(entry.remaining)) left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Right side - Daily stats
            VStack(alignment: .trailing, spacing: 8) {
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Daily budget")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)

                    let dailyBudget = entry.remaining / Double(entry.daysInMonth - entry.dayOfMonth + 1)
                    Text(formatCurrency(dailyBudget))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetColors.mint)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Day \(entry.dayOfMonth) of \(entry.daysInMonth)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Large Widget

struct LargeSpendingView: View {
    let entry: SpendingEntry

    private var statusColor: Color {
        if entry.percentUsed > 100 {
            return WidgetColors.danger
        } else if entry.isOverPace {
            return WidgetColors.warning
        }
        return WidgetColors.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(WidgetColors.mint)

                        Text("Monthly Spending")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text(formatCurrency(entry.spent))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: min(entry.percentUsed / 100, 1))
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.percentUsed))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(width: 70, height: 70)
            }

            // Budget bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)

                        // Ideal pace marker
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 2, height: 18)
                            .offset(x: geometry.size.width * (entry.idealSpent / entry.budget) - 1)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor)
                            .frame(width: geometry.size.width * min(entry.percentUsed / 100, 1), height: 12)
                    }
                }
                .frame(height: 18)

                HStack {
                    Text("\(formatCurrency(entry.remaining)) remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("Budget: \(formatCurrency(entry.budget))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Top categories
            Text("Top Categories")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(entry.topCategories, id: \.name) { category in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(category.color)
                        .frame(width: 4, height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)

                        // Category progress
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(category.color.opacity(0.3))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(category.color)
                                        .frame(width: geo.size.width * (category.amount / entry.spent))
                                }
                        }
                        .frame(height: 4)
                    }

                    Spacer()

                    Text(formatCurrency(category.amount))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            // Daily recommendation
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetColors.warning)

                let dailyBudget = entry.remaining / Double(max(1, entry.daysInMonth - entry.dayOfMonth + 1))
                Text("Try to spend less than \(formatCurrency(dailyBudget))/day")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularSpendingView: View {
    let entry: SpendingEntry

    var body: some View {
        Gauge(value: min(entry.percentUsed, 100) / 100) {
            Image(systemName: "chart.pie")
        } currentValueLabel: {
            Text("\(Int(entry.percentUsed))%")
                .font(.system(size: 12, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularSpendingView: View {
    let entry: SpendingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "chart.pie.fill")
                Text("Spending")
                    .font(.headline)
            }

            Text("\(formatCurrency(entry.spent)) of \(formatCurrency(entry.budget))")
                .font(.system(size: 14, weight: .bold, design: .rounded))

            ProgressView(value: min(entry.percentUsed / 100, 1))
        }
    }
}

struct AccessoryInlineSpendingView: View {
    let entry: SpendingEntry

    var body: some View {
        HStack {
            Image(systemName: "chart.pie.fill")
            Text("\(formatCurrency(entry.remaining)) left")
        }
    }
}

// MARK: - Widget Definition

struct SpendingWidget: Widget {
    let kind: String = "SpendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingProvider()) { entry in
            SpendingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Spending")
        .description("Track your monthly spending progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Helpers

private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

private func formatCompact(_ amount: Double) -> String {
    let absAmount = abs(amount)
    let sign = amount < 0 ? "-" : ""
    if absAmount >= 1_000_000 {
        return "\(sign)$\(String(format: "%.1fM", absAmount / 1_000_000))"
    } else if absAmount >= 1000 {
        return "\(sign)$\(String(format: "%.1fK", absAmount / 1000))"
    }
    return "\(sign)$\(Int(absAmount))"
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SpendingWidget()
} timeline: {
    SpendingEntry.placeholder
}

#Preview(as: .systemMedium) {
    SpendingWidget()
} timeline: {
    SpendingEntry.placeholder
}

#Preview(as: .systemLarge) {
    SpendingWidget()
} timeline: {
    SpendingEntry.placeholder
}
