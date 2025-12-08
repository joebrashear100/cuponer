//
//  GoalsWidget.swift
//  FurgWidgets
//
//  Shows savings goals progress
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct GoalsEntry: TimelineEntry {
    let date: Date
    let goals: [WidgetGoal]
    let totalProgress: Double
    let isPreview: Bool

    static var placeholder: GoalsEntry {
        GoalsEntry(
            date: Date(),
            goals: [
                WidgetGoal(name: "Emergency Fund", current: 8500, target: 10000, icon: "cross.case.fill", color: .red, daysRemaining: 45),
                WidgetGoal(name: "Vacation", current: 2340, target: 5000, icon: "airplane", color: .orange, daysRemaining: 120),
                WidgetGoal(name: "New Car", current: 12000, target: 25000, icon: "car.fill", color: .purple, daysRemaining: 365)
            ],
            totalProgress: 0.58,
            isPreview: true
        )
    }
}

struct WidgetGoal: Identifiable {
    let id = UUID()
    let name: String
    let current: Double
    let target: Double
    let icon: String
    let color: Color
    let daysRemaining: Int?

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var percentComplete: Int {
        Int(progress * 100)
    }
}

// MARK: - Timeline Provider

struct GoalsProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalsEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalsEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalsEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.furg.app")

        // In a real app, we'd decode goals from shared defaults
        // For now, using demo data
        var goals: [WidgetGoal] = []

        if let goalsData = sharedDefaults?.data(forKey: "widget_goals"),
           let decoded = try? JSONDecoder().decode([WidgetGoalData].self, from: goalsData) {
            goals = decoded.map { data in
                WidgetGoal(
                    name: data.name,
                    current: data.current,
                    target: data.target,
                    icon: data.icon,
                    color: colorFromString(data.color),
                    daysRemaining: data.daysRemaining
                )
            }
        } else {
            // Demo data
            goals = [
                WidgetGoal(name: "Emergency Fund", current: 8500, target: 10000, icon: "cross.case.fill", color: .red, daysRemaining: 45),
                WidgetGoal(name: "Vacation", current: 2340, target: 5000, icon: "airplane", color: .orange, daysRemaining: 120),
                WidgetGoal(name: "New Car", current: 12000, target: 25000, icon: "car.fill", color: .purple, daysRemaining: 365)
            ]
        }

        let totalCurrent = goals.reduce(0) { $0 + $1.current }
        let totalTarget = goals.reduce(0) { $0 + $1.target }
        let totalProgress = totalTarget > 0 ? totalCurrent / totalTarget : 0

        let entry = GoalsEntry(
            date: Date(),
            goals: goals,
            totalProgress: totalProgress,
            isPreview: false
        )

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// Data structure for encoding/decoding
struct WidgetGoalData: Codable {
    let name: String
    let current: Double
    let target: Double
    let icon: String
    let color: String
    let daysRemaining: Int?
}

private func colorFromString(_ string: String) -> Color {
    switch string.lowercased() {
    case "red": return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green": return .green
    case "blue": return .blue
    case "purple": return .purple
    case "pink": return .pink
    case "mint": return WidgetColors.mint
    default: return WidgetColors.mint
    }
}

// MARK: - Widget Views

struct GoalsWidgetEntryView: View {
    var entry: GoalsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallGoalsView(entry: entry)
        case .systemMedium:
            MediumGoalsView(entry: entry)
        case .systemLarge:
            LargeGoalsView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularGoalsView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularGoalsView(entry: entry)
        case .accessoryInline:
            AccessoryInlineGoalsView(entry: entry)
        @unknown default:
            SmallGoalsView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallGoalsView: View {
    let entry: GoalsEntry

    var topGoal: WidgetGoal? {
        entry.goals.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WidgetColors.mint)

                Spacer()

                Text("\(entry.goals.count) Goals")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let goal = topGoal {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: goal.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(goal.color)

                        Text(goal.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(goal.color)
                                .frame(width: geometry.size.width * goal.progress)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(goal.percentComplete)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(formatCompact(goal.target - goal.current))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        + Text(" left")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Medium Widget

struct MediumGoalsView: View {
    let entry: GoalsEntry

    var body: some View {
        HStack(spacing: 16) {
            // Overall progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WidgetColors.mint)

                    Text("Goals")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Big progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: entry.totalProgress)
                        .stroke(
                            AngularGradient(
                                colors: [WidgetColors.mint, WidgetColors.seafoam],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(entry.totalProgress * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("overall")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                Spacer()
            }

            // Goals list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.goals.prefix(3)) { goal in
                    HStack(spacing: 10) {
                        Image(systemName: goal.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(goal.color)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(goal.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(goal.color)
                                            .frame(width: geo.size.width * goal.progress)
                                    }
                            }
                            .frame(height: 4)
                        }

                        Text("\(goal.percentComplete)%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }

                if entry.goals.count > 3 {
                    Text("+\(entry.goals.count - 3) more")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
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

struct LargeGoalsView: View {
    let entry: GoalsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "target")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(WidgetColors.mint)

                        Text("Savings Goals")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(Int(entry.totalProgress * 100))% Overall Progress")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: entry.totalProgress)
                        .stroke(WidgetColors.mint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 50, height: 50)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Goals list
            ForEach(entry.goals) { goal in
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: goal.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(goal.color)
                            .frame(width: 36, height: 36)
                            .background(goal.color.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Goal info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("\(formatCurrency(goal.current)) of \(formatCurrency(goal.target))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Progress percentage
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(goal.percentComplete)%")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(goal.color)

                            if let days = goal.daysRemaining {
                                Text("\(days)d left")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [goal.color, goal.color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * goal.progress)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 4)
            }

            Spacer()

            // Motivation message
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetColors.mint)

                if let closestGoal = entry.goals.min(by: { ($0.target - $0.current) < ($1.target - $1.current) }) {
                    Text("\(formatCurrency(closestGoal.target - closestGoal.current)) more to complete \(closestGoal.name)!")
                        .font(.system(size: 11, weight: .medium))
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

// MARK: - Lock Screen Widgets

struct AccessoryCircularGoalsView: View {
    let entry: GoalsEntry

    var body: some View {
        Gauge(value: entry.totalProgress) {
            Image(systemName: "target")
        } currentValueLabel: {
            Text("\(Int(entry.totalProgress * 100))%")
                .font(.system(size: 12, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularGoalsView: View {
    let entry: GoalsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "target")
                Text("Goals")
                    .font(.headline)
            }

            if let goal = entry.goals.first {
                Text("\(goal.name): \(goal.percentComplete)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                ProgressView(value: goal.progress)
            }
        }
    }
}

struct AccessoryInlineGoalsView: View {
    let entry: GoalsEntry

    var body: some View {
        HStack {
            Image(systemName: "target")
            Text("\(Int(entry.totalProgress * 100))% toward goals")
        }
    }
}

// MARK: - Widget Definition

struct GoalsWidget: Widget {
    let kind: String = "GoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalsProvider()) { entry in
            GoalsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Goals")
        .description("Track your savings goals progress.")
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
    GoalsWidget()
} timeline: {
    GoalsEntry.placeholder
}

#Preview(as: .systemMedium) {
    GoalsWidget()
} timeline: {
    GoalsEntry.placeholder
}

#Preview(as: .systemLarge) {
    GoalsWidget()
} timeline: {
    GoalsEntry.placeholder
}
