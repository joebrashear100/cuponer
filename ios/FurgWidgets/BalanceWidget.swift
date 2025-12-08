//
//  BalanceWidget.swift
//  FurgWidgets
//
//  Shows total balance across all accounts
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct BalanceEntry: TimelineEntry {
    let date: Date
    let totalBalance: Double
    let change: Double
    let changePercent: Double
    let accountCount: Int
    let lastUpdated: Date
    let isPreview: Bool

    static var placeholder: BalanceEntry {
        BalanceEntry(
            date: Date(),
            totalBalance: 24567.89,
            change: 1234.56,
            changePercent: 5.3,
            accountCount: 4,
            lastUpdated: Date(),
            isPreview: true
        )
    }
}

// MARK: - Timeline Provider

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        // Fetch from shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.com.furg.app")

        let totalBalance = sharedDefaults?.double(forKey: "widget_total_balance") ?? 24567.89
        let change = sharedDefaults?.double(forKey: "widget_balance_change") ?? 1234.56
        let changePercent = sharedDefaults?.double(forKey: "widget_balance_change_percent") ?? 5.3
        let accountCount = sharedDefaults?.integer(forKey: "widget_account_count") ?? 4
        let lastUpdated = sharedDefaults?.object(forKey: "widget_last_updated") as? Date ?? Date()

        let entry = BalanceEntry(
            date: Date(),
            totalBalance: totalBalance,
            change: change,
            changePercent: changePercent,
            accountCount: accountCount,
            lastUpdated: lastUpdated,
            isPreview: false
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct BalanceWidgetEntryView: View {
    var entry: BalanceEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallBalanceView(entry: entry)
        case .systemMedium:
            MediumBalanceView(entry: entry)
        case .systemLarge:
            LargeBalanceView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularBalanceView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularBalanceView(entry: entry)
        case .accessoryInline:
            AccessoryInlineBalanceView(entry: entry)
        @unknown default:
            SmallBalanceView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallBalanceView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WidgetColors.mint)

                Spacer()

                Image(systemName: entry.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(entry.change >= 0 ? WidgetColors.success : WidgetColors.danger)
            }

            Spacer()

            Text("Total Balance")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            Text(formatCurrency(entry.totalBalance))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text("\(entry.change >= 0 ? "+" : "")\(formatCurrency(entry.change))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(entry.change >= 0 ? WidgetColors.success : WidgetColors.danger)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Medium Widget

struct MediumBalanceView: View {
    let entry: BalanceEntry

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WidgetColors.mint)

                    Text("Total Balance")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatCurrency(entry.totalBalance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: entry.change >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(entry.change >= 0 ? WidgetColors.success : WidgetColors.danger)

                    Text("\(entry.change >= 0 ? "+" : "")\(formatCurrency(entry.change)) this month")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(entry.change >= 0 ? WidgetColors.success : WidgetColors.danger)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                // Account count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.accountCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetColors.mint)

                    Text("Accounts")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Last updated
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Updated")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)

                    Text(entry.lastUpdated, style: .relative)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Large Widget

struct LargeBalanceView: View {
    let entry: BalanceEntry

    // Demo account breakdown
    let accounts: [(name: String, balance: Double, icon: String, color: Color)] = [
        ("Checking", 8234.56, "building.columns.fill", .blue),
        ("Savings", 12890.45, "banknote.fill", .green),
        ("Investment", 3442.88, "chart.line.uptrend.xyaxis", .purple),
        ("Credit Card", -1200.00, "creditcard.fill", .orange)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(WidgetColors.mint)

                        Text("Total Balance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text(formatCurrency(entry.totalBalance))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: entry.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))

                        Text("\(entry.change >= 0 ? "+" : "")\(formatCurrency(entry.change))")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(entry.change >= 0 ? WidgetColors.success : WidgetColors.danger)

                    Text("\(String(format: "%.1f", entry.changePercent))% this month")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Account breakdown
            VStack(spacing: 10) {
                ForEach(accounts, id: \.name) { account in
                    HStack(spacing: 12) {
                        Image(systemName: account.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(account.color)
                            .frame(width: 28, height: 28)
                            .background(account.color.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(account.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(formatCurrency(account.balance))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(account.balance < 0 ? WidgetColors.danger : .primary)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("Last updated \(entry.lastUpdated, style: .relative)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("Tap to view details")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetColors.mint)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularBalanceView: View {
    let entry: BalanceEntry

    var body: some View {
        Gauge(value: min(entry.changePercent, 100) / 100) {
            Image(systemName: "dollarsign")
        } currentValueLabel: {
            Text(formatCompact(entry.totalBalance))
                .font(.system(size: 10, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularBalanceView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                Text("Balance")
                    .font(.headline)
            }

            Text(formatCurrency(entry.totalBalance))
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text("\(entry.change >= 0 ? "+" : "")\(formatCompact(entry.change)) this month")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessoryInlineBalanceView: View {
    let entry: BalanceEntry

    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
            Text(formatCurrency(entry.totalBalance))
        }
    }
}

// MARK: - Widget Definition

struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceProvider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Balance")
        .description("View your total balance at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Helpers

private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
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
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}

#Preview(as: .systemMedium) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}

#Preview(as: .systemLarge) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}
