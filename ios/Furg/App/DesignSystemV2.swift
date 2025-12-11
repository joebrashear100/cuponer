//
//  DesignSystemV2.swift
//  Furg
//
//  "Midnight Emerald" Design System
//  Research-backed color psychology for finance apps:
//  - Deep blues convey trust & stability (42% associate blue with reliability)
//  - Emerald green signals growth & prosperity (23% higher satisfaction)
//  - Warm coral for engagement & CTAs (24% higher click-through)
//  - Purple accents suggest premium/wealth
//
//  Inspired by: Monzo's coral warmth, Robinhood's clean data,
//  Cash App's bold personality, Revolut's sophisticated dark theme
//

import SwiftUI

// MARK: - Color Palette V2 - "Midnight Emerald"

extension Color {
    // Primary Background - Deep midnight blue (trust & stability)
    // Research: 69% of users feel more secure with darker shades
    static let v2Background = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let v2BackgroundSecondary = Color(red: 0.06, green: 0.07, blue: 0.12)
    static let v2CardBackground = Color(red: 0.08, green: 0.09, blue: 0.15)
    static let v2CardBackgroundElevated = Color(red: 0.10, green: 0.11, blue: 0.18)

    // Primary Accent - Emerald (growth, prosperity, security)
    // Research: 73% feel more secure with green in finances, 20% higher retention
    static let v2Primary = Color(red: 0.18, green: 0.80, blue: 0.58)          // Main emerald
    static let v2PrimaryLight = Color(red: 0.30, green: 0.90, blue: 0.70)     // Highlight
    static let v2PrimaryDark = Color(red: 0.12, green: 0.60, blue: 0.45)      // Pressed state

    // Secondary Accent - Warm Coral (engagement, action, personality)
    // Inspired by Monzo's success - warm, human, memorable
    static let v2Accent = Color(red: 1.0, green: 0.45, blue: 0.40)            // Coral
    static let v2AccentLight = Color(red: 1.0, green: 0.55, blue: 0.50)

    // Semantic Colors
    static let v2Success = Color(red: 0.20, green: 0.85, blue: 0.55)          // Positive/gains
    static let v2Warning = Color(red: 1.0, green: 0.78, blue: 0.28)           // Caution/alerts
    static let v2Danger = Color(red: 1.0, green: 0.38, blue: 0.38)            // Negative/losses
    static let v2Info = Color(red: 0.40, green: 0.70, blue: 1.0)              // Information

    // Premium/Wealth Purple (27% perceive purple brands as premium)
    static let v2Premium = Color(red: 0.58, green: 0.44, blue: 0.98)
    static let v2PremiumLight = Color(red: 0.70, green: 0.58, blue: 1.0)

    // Text Colors - High contrast for accessibility
    static let v2TextPrimary = Color.white
    static let v2TextSecondary = Color.white.opacity(0.65)
    static let v2TextTertiary = Color.white.opacity(0.40)
    static let v2TextInverse = Color(red: 0.04, green: 0.05, blue: 0.09)

    // Category Colors - Vibrant, distinguishable palette
    static let v2CategoryFood = Color(red: 1.0, green: 0.55, blue: 0.25)      // Warm orange
    static let v2CategoryShopping = Color(red: 0.95, green: 0.38, blue: 0.58) // Rose pink
    static let v2CategoryTransport = Color(red: 0.45, green: 0.58, blue: 1.0) // Soft blue
    static let v2CategoryHome = Color(red: 0.25, green: 0.78, blue: 0.65)     // Teal
    static let v2CategoryEntertainment = Color(red: 0.70, green: 0.48, blue: 0.98) // Purple
    static let v2CategoryHealth = Color(red: 0.98, green: 0.42, blue: 0.42)   // Red
    static let v2CategoryTravel = Color(red: 0.35, green: 0.75, blue: 0.95)   // Sky blue
    static let v2CategoryBills = Color(red: 0.55, green: 0.62, blue: 0.72)    // Steel
    static let v2CategoryIncome = Color(red: 0.20, green: 0.85, blue: 0.55)   // Green
    static let v2CategoryOther = Color(red: 0.50, green: 0.55, blue: 0.65)    // Gray

    // Legacy aliases for compatibility
    static var v2Mint: Color { v2Primary }
    static var v2Lime: Color { v2Success }
    static var v2Gold: Color { v2Warning }
    static var v2Coral: Color { v2Danger }
    static var v2Purple: Color { v2Premium }
    static var v2Blue: Color { v2Info }
}

// MARK: - Gradients V2

struct V2Gradients {
    // Primary gradient - Emerald flow
    static let primary = LinearGradient(
        colors: [.v2Primary, .v2PrimaryLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Budget/spending line gradient
    static let budgetLine = LinearGradient(
        colors: [.v2Primary, .v2Success],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Accent gradient - Coral warmth (for CTAs, 24% higher engagement)
    static let accent = LinearGradient(
        colors: [.v2Accent, .v2AccentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Premium gradient - Wealth/luxury feel
    static let premium = LinearGradient(
        colors: [.v2Premium, .v2PremiumLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let positive = LinearGradient(
        colors: [.v2Success.opacity(0.8), .v2Success],
        startPoint: .bottom,
        endPoint: .top
    )

    static let negative = LinearGradient(
        colors: [.v2Danger.opacity(0.8), .v2Danger],
        startPoint: .bottom,
        endPoint: .top
    )

    // Subtle card glow effect
    static let cardGlow = RadialGradient(
        colors: [.v2Primary.opacity(0.12), .clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 250
    )

    // Hero card gradient
    static let heroCard = LinearGradient(
        colors: [
            Color.v2CardBackgroundElevated,
            Color.v2CardBackground
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Background ambient gradient
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.v2Background,
            Color.v2BackgroundSecondary.opacity(0.6),
            Color.v2Background
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Mesh-like premium background
    static let premiumBackground = RadialGradient(
        colors: [
            Color.v2Premium.opacity(0.08),
            Color.v2Background
        ],
        center: .topTrailing,
        startRadius: 0,
        endRadius: 400
    )
}

// MARK: - Typography V2

extension Font {
    // Large display numbers (like "$650 left")
    static let v2DisplayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let v2DisplayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    static let v2DisplaySmall = Font.system(size: 28, weight: .bold, design: .rounded)

    // Headers
    static let v2Title = Font.system(size: 22, weight: .bold, design: .rounded)
    static let v2Headline = Font.system(size: 17, weight: .semibold, design: .rounded)

    // Body text
    static let v2Body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let v2BodyBold = Font.system(size: 15, weight: .semibold, design: .rounded)

    // Small text
    static let v2Caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let v2CaptionSmall = Font.system(size: 11, weight: .medium, design: .rounded)

    // Numbers in charts/metrics
    static let v2MetricLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
    static let v2MetricMedium = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let v2MetricSmall = Font.system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Card Styles V2

struct V2Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20

    init(padding: CGFloat = 20, cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.v2CardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Pill/Tag Style

struct V2Pill: View {
    let text: String
    let color: Color
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(.v2Caption)
            .foregroundColor(isSelected ? .v2Background : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
    }
}

// MARK: - Under/Over Budget Badge

struct V2BudgetBadge: View {
    let amount: Double
    let isUnder: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text("$\(Int(abs(amount)))")
                .font(.v2CaptionSmall)
                .fontWeight(.bold)
            Text(isUnder ? "under" : "over")
                .font(.v2CaptionSmall)
        }
        .foregroundColor(isUnder ? .v2Background : .white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(isUnder ? Color.v2Lime : Color.v2Coral)
        )
    }
}

// MARK: - Spending Indicator Dot

struct V2SpendingDot: View {
    let spent: Double
    let budget: Double

    var ratio: Double { min(spent / budget, 1.5) }
    var color: Color {
        if ratio < 0.7 { return .v2Lime }
        else if ratio < 1.0 { return .v2Gold }
        else { return .v2Coral }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Section Header

struct V2SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.v2Headline)
                .foregroundColor(.v2TextPrimary)

            Spacer()

            if let action = action {
                Button {
                    onAction?()
                } label: {
                    Text(action)
                        .font(.v2Caption)
                        .foregroundColor(.v2Mint)
                }
            }
        }
    }
}

// MARK: - Amount Display

struct V2AmountDisplay: View {
    let amount: Double
    let label: String
    var size: Size = .large
    var showSign: Bool = false

    enum Size {
        case large, medium, small

        var font: Font {
            switch self {
            case .large: return .v2DisplayLarge
            case .medium: return .v2DisplayMedium
            case .small: return .v2DisplaySmall
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if showSign && amount != 0 {
                    Text(amount > 0 ? "+" : "")
                        .font(size.font)
                        .foregroundColor(amount > 0 ? .v2Lime : .v2Coral)
                }
                Text("$")
                    .font(.system(size: size == .large ? 28 : 20, weight: .medium, design: .rounded))
                    .foregroundColor(.v2Mint)
                Text(formatNumber(abs(amount)))
                    .font(size.font)
                    .foregroundColor(.v2TextPrimary)
            }

            Text(label)
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Transaction Row V2

struct V2TransactionRow: View {
    let icon: String
    let iconColor: Color
    let merchant: String
    let category: String
    let amount: Double
    let date: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(merchant)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)

                Text(category)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }

            Spacer()

            // Amount & Date
            VStack(alignment: .trailing, spacing: 3) {
                Text(amount > 0 ? "+$\(Int(amount))" : "-$\(Int(abs(amount)))")
                    .font(.v2BodyBold)
                    .foregroundColor(amount > 0 ? .v2Lime : .v2TextPrimary)

                Text(date)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Category Spending Row

struct V2CategoryRow: View {
    let name: String
    let icon: String
    let color: Color
    let spent: Double
    let budget: Double

    var progress: Double { min(spent / budget, 1.0) }
    var isOver: Bool { spent > budget }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }

                // Name
                Text(name)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(spent))")
                        .font(.v2BodyBold)
                        .foregroundColor(isOver ? .v2Coral : .v2TextPrimary)

                    Text("of $\(Int(budget))")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOver ? Color.v2Coral : color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.v2Background.ignoresSafeArea()

        VStack(spacing: 20) {
            V2AmountDisplay(amount: 650, label: "left to spend")

            V2BudgetBadge(amount: 12, isUnder: true)

            V2Card {
                V2CategoryRow(
                    name: "Food & Dining",
                    icon: "fork.knife",
                    color: .v2CategoryFood,
                    spent: 253.16,
                    budget: 400
                )
            }

            V2Card {
                V2TransactionRow(
                    icon: "car.fill",
                    iconColor: .v2CategoryTransport,
                    merchant: "Lyft",
                    category: "Transportation",
                    amount: -34.25,
                    date: "Today"
                )
            }
        }
        .padding()
    }
}
