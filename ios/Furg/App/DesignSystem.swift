//
//  DesignSystem.swift
//  Furg
//
//  FURG Design System - Cyber-Premium Dark Mode
//  True Black backgrounds with Electric Indigo accents
//

import SwiftUI

// MARK: - FURG Color Palette

extension Color {
    // MARK: Primary Colors
    /// True Black - Main app background. Maximizes OLED contrast.
    static let furgTrueBlack = Color(red: 0, green: 0, blue: 0)              // #000000
    /// Off-Black - Secondary backgrounds, cards, and sheets.
    static let furgOffBlack = Color(red: 0.071, green: 0.071, blue: 0.071)   // #121212
    /// Electric Indigo - Primary Brand Color. Buttons, active states, focus.
    static let furgIndigo = Color(red: 0.369, green: 0.361, blue: 0.902)     // #5E5CE6
    /// Cyber Violet - Secondary accent. Used in gradients with Indigo.
    static let furgViolet = Color(red: 0.749, green: 0.353, blue: 0.949)     // #BF5AF2

    // MARK: Semantic Colors
    /// Neon Green - Income, positive trends, success states.
    static let furgNeonGreen = Color(red: 0.196, green: 0.843, blue: 0.294)  // #32D74B
    /// Neon Red - Expenses, debt, error states.
    static let furgNeonRed = Color(red: 1.0, green: 0.271, blue: 0.227)      // #FF453A
    /// Neon Amber - Warnings, cautions.
    static let furgNeonAmber = Color(red: 1.0, green: 0.839, blue: 0.039)    // #FFD60A

    // MARK: Text Colors
    /// Primary Label - High emphasis text
    static let furgPrimaryLabel = Color.white
    /// Secondary Label - Subtitles, captions
    static let furgSecondaryLabel = Color.white.opacity(0.6)
    /// Tertiary Label - Placeholders, disabled text
    static let furgTertiaryLabel = Color.white.opacity(0.3)

    // MARK: Legacy Aliases (for backward compatibility)
    static let furgMint = furgIndigo                                          // Map to new primary
    static let furgSage = furgViolet                                          // Map to new secondary
    static let furgSeafoam = furgIndigo.opacity(0.8)                          // Lighter indigo
    static let furgPistachio = furgViolet.opacity(0.7)                        // Lighter violet
    static let furgCream = Color(red: 0.98, green: 1.0, blue: 0.96)          // Keep for light mode
    static let furgCharcoal = furgOffBlack                                    // Map to Off-Black
    static let furgSlate = Color(red: 0.1, green: 0.1, blue: 0.12)           // Slightly lighter than Off-Black
    static let furgMist = Color(red: 0.94, green: 0.97, blue: 0.95)          // Keep for light mode

    // Semantic color aliases
    static let furgSuccess = furgNeonGreen
    static let furgWarning = furgNeonAmber
    static let furgDanger = furgNeonRed
    static let furgError = furgNeonRed
    static let furgInfo = furgIndigo
    static let furgAccent = furgIndigo

    // MARK: - Budget Status Colors (Copilot-inspired)
    // These colors indicate spending pace relative to budget

    /// On track - spending is at or below expected pace
    static let budgetOnTrack = Color(red: 0.4, green: 0.85, blue: 0.6)       // Green
    /// Slightly over pace - spending is moderately above expected
    static let budgetSlightlyOver = Color(red: 1.0, green: 0.7, blue: 0.3)   // Light orange
    /// Significantly over pace - spending is well above expected
    static let budgetOverPace = Color(red: 1.0, green: 0.55, blue: 0.2)      // Orange
    /// Over budget - exceeded total budget
    static let budgetExceeded = Color(red: 1.0, green: 0.4, blue: 0.4)       // Red

    // MARK: - Chart Colors

    /// Chart semantic colors for consistent data visualization
    static let chartIncome = furgNeonGreen                                    // Green - money in
    static let chartSpending = furgNeonRed                                    // Red - money out
    static let chartNetPositive = furgIndigo                                  // Indigo - positive net
    static let chartNetNegative = furgNeonRed.opacity(0.8)                    // Light red - negative net
    static let chartIdealLine = Color.white.opacity(0.4)                      // Dashed ideal line
    static let chartActualLine = furgIndigo                                   // Actual spending line

    // Chart category colors for pie/bar charts (using FURG palette)
    static let chartCategory1 = furgIndigo                                    // Electric Indigo
    static let chartCategory2 = furgViolet                                    // Cyber Violet
    static let chartCategory3 = furgNeonGreen                                 // Neon Green
    static let chartCategory4 = furgNeonAmber                                 // Neon Amber
    static let chartCategory5 = Color(red: 0.4, green: 0.85, blue: 0.95)      // Cyan
    static let chartCategory6 = Color(red: 0.95, green: 0.45, blue: 0.65)     // Pink

    // MARK: - Financial Indicator Colors

    /// Positive change indicator (e.g., balance increase)
    static let positiveChange = furgNeonGreen
    /// Negative change indicator (e.g., balance decrease)
    static let negativeChange = furgNeonRed
    /// Unreviewed transaction indicator
    static let unreviewedBadge = furgIndigo.opacity(0.7)

    // Glass colors (updated for Indigo accent)
    static let glassWhite = Color.white.opacity(0.15)
    static let glassBorder = furgIndigo.opacity(0.3)
    static let glassDark = Color.black.opacity(0.2)

    // Background aliases
    static let furgDarkBg = furgTrueBlack
}

// MARK: - Gradients

struct FurgGradients {
    // MARK: Primary Gradients

    /// Main background - True Black for OLED
    static let mainBackground = LinearGradient(
        colors: [Color.furgTrueBlack, Color.furgTrueBlack],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Primary accent gradient - Electric Indigo to Cyber Violet
    static let indigoVioletGradient = LinearGradient(
        colors: [Color.furgIndigo, Color.furgViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent gradient (alias for backward compatibility)
    static let mintGradient = indigoVioletGradient

    /// Card border gradient - Indigo to transparent
    static let cardBorderGradient = LinearGradient(
        colors: [Color.furgIndigo.opacity(0.6), Color.furgIndigo.opacity(0.1), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Glass gradient for glassmorphism effects
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Balance Hero glow gradient
    static let balanceGlow = RadialGradient(
        colors: [Color.furgIndigo.opacity(0.4), Color.furgIndigo.opacity(0.1), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )

    /// Mesh-like background with subtle Indigo tint
    static let meshBackground = LinearGradient(
        colors: [
            Color.furgTrueBlack,
            Color(red: 0.02, green: 0.02, blue: 0.04),
            Color.furgTrueBlack
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// FAB gradient - Electric Indigo to Cyber Violet
    static let fabGradient = LinearGradient(
        colors: [Color.furgIndigo, Color.furgViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glass Card Modifier (FURG Design System)
// Background: .regularMaterial (Blur) over Off-Black
// Border: 1px Gradient Stroke (Indigo -> Transparent)
// Shadow: Soft black drop shadow (y: 5, radius: 10)
// Corner Radius: 24pt

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var opacity: Double = 0.12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.furgOffBlack)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.regularMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.furgIndigo.opacity(0.6),
                                Color.furgIndigo.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct GlassButton: ViewModifier {
    var isAccent: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isAccent {
                        FurgGradients.indigoVioletGradient
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isAccent ? Color.furgIndigo.opacity(0.5) : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 24, opacity: Double = 0.12) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, opacity: opacity))
    }

    func glassButton(isAccent: Bool = false) -> some View {
        modifier(GlassButton(isAccent: isAccent))
    }

    func primaryButton() -> some View {
        modifier(GlassButton(isAccent: true))
    }

    func furgBackground() -> some View {
        self.background(FurgGradients.mainBackground.ignoresSafeArea())
    }
}

// MARK: - Custom Components

struct GlowingOrb: View {
    var color: Color = .furgIndigo
    var size: CGFloat = 200

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.6),
                        color.opacity(0.2),
                        color.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 40)
    }
}

struct FloatingCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .glassCard()
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// GlassCard as a container view (FURG Design System)
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 16

    init(cornerRadius: CGFloat = 24, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.furgOffBlack)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.regularMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.furgIndigo.opacity(0.6),
                                Color.furgIndigo.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct AccentBadge: View {
    let text: String
    var color: Color = .furgIndigo

    var body: some View {
        Text(text)
            .font(.furgCaption)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var trend: String? = nil
    var trendUp: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.furgIndigo)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(trend)
                            .font(.furgCaption)
                    }
                    .foregroundColor(trendUp ? .furgNeonGreen : .furgNeonRed)
                }
            }

            Text(value)
                .font(.furgTitle)
                .foregroundColor(.furgPrimaryLabel)

            Text(title)
                .font(.furgSubheadline)
                .foregroundColor(.furgSecondaryLabel)
        }
        .padding(20)
        .glassCard(cornerRadius: 24)
    }
}

struct LegacyPillTabBar: View {
    @Binding var selectedIndex: Int
    let tabs: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = index
                    }
                } label: {
                    Text(tabs[index])
                        .font(.furgSubheadline)
                        .foregroundColor(selectedIndex == index ? .white : .furgSecondaryLabel)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedIndex == index {
                                    Capsule().fill(Color.furgIndigo)
                                } else {
                                    Capsule().fill(Color.white.opacity(0.08))
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }
}

// MARK: - Typography (SF Pro Rounded)
// FURG uses SF Pro Rounded for a softer, modern feel that contrasts with sharp financial data

extension Font {
    // MARK: Display & Titles
    /// Large Title - Rounded, Bold. Used for Balance amounts.
    static let furgLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    /// Title - Rounded, Bold. Primary headers.
    static let furgTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    /// Title 2 - Rounded, Semibold. Secondary headers.
    static let furgTitle2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    /// Headline - Rounded, Semibold. Section headers.
    static let furgHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)

    // MARK: Body & Captions
    /// Body - Rounded, Medium. Standard text.
    static let furgBody = Font.system(size: 17, weight: .medium, design: .rounded)
    /// Body Regular - Rounded, Regular weight.
    static let furgBodyRegular = Font.system(size: 17, weight: .regular, design: .rounded)
    /// Subheadline - Rounded, Medium.
    static let furgSubheadline = Font.system(size: 15, weight: .medium, design: .rounded)
    /// Caption - Rounded, Medium.
    static let furgCaption = Font.system(size: 12, weight: .medium, design: .rounded)
    /// Caption 2 - Rounded, Regular. Smaller captions.
    static let furgCaption2 = Font.system(size: 11, weight: .regular, design: .rounded)

    // MARK: Numeric (Monospaced for alignment)
    /// Monospaced numbers for transaction lists and aligned data
    static let furgMonoLarge = Font.system(size: 34, weight: .bold, design: .monospaced)
    static let furgMonoMedium = Font.system(size: 20, weight: .semibold, design: .monospaced)
    static let furgMonoSmall = Font.system(size: 14, weight: .medium, design: .monospaced)

    // MARK: Balance Display
    /// Extra large for hero balance amounts
    static let furgBalanceHero = Font.system(size: 42, weight: .bold, design: .rounded)
    /// Currency symbol size
    static let furgCurrencySymbol = Font.system(size: 24, weight: .medium, design: .rounded)
}

// MARK: - Animated Background

struct AnimatedMeshBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // True Black background for OLED
            Color.furgTrueBlack

            // Floating orbs with Indigo/Violet glow
            GlowingOrb(color: .furgIndigo, size: 300)
                .offset(x: animate ? -50 : -100, y: animate ? -100 : -50)
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: animate
                )

            GlowingOrb(color: .furgViolet, size: 250)
                .offset(x: animate ? 150 : 100, y: animate ? 200 : 250)
                .animation(
                    .easeInOut(duration: 10).repeatForever(autoreverses: true),
                    value: animate
                )

            GlowingOrb(color: .furgIndigo.opacity(0.5), size: 200)
                .offset(x: animate ? -100 : -150, y: animate ? 400 : 350)
                .animation(
                    .easeInOut(duration: 12).repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}

// MARK: - Budget Status Utilities

struct BudgetStatus {
    /// Calculate the budget status color based on spending pace
    /// - Parameters:
    ///   - spent: Amount spent so far
    ///   - budget: Total budget for the period
    ///   - dayOfMonth: Current day of the month
    ///   - daysInMonth: Total days in the month
    /// - Returns: Appropriate color for the budget status
    static func color(spent: Double, budget: Double, dayOfMonth: Int, daysInMonth: Int) -> Color {
        guard budget > 0 else { return .budgetOnTrack }

        let spentRatio = spent / budget
        let idealRatio = Double(dayOfMonth) / Double(daysInMonth)
        let difference = spentRatio - idealRatio

        if spentRatio > 1.0 {
            return .budgetExceeded        // Over budget
        }
        if difference > 0.2 {
            return .budgetOverPace        // Significantly over pace
        }
        if difference > 0 {
            return .budgetSlightlyOver    // Slightly over pace
        }
        return .budgetOnTrack             // On track
    }

    /// Calculate the ideal spending amount for the current day
    static func idealSpending(budget: Double, dayOfMonth: Int, daysInMonth: Int) -> Double {
        return budget * Double(dayOfMonth) / Double(daysInMonth)
    }

    /// Calculate remaining budget
    static func remaining(spent: Double, budget: Double) -> Double {
        return max(0, budget - spent)
    }

    /// Get status text description
    static func statusText(spent: Double, budget: Double, dayOfMonth: Int, daysInMonth: Int) -> String {
        guard budget > 0 else { return "No budget set" }

        let spentRatio = spent / budget
        let idealRatio = Double(dayOfMonth) / Double(daysInMonth)

        if spentRatio > 1.0 {
            return "Over budget"
        }
        if spentRatio > idealRatio + 0.15 {
            return "Over pace"
        }
        if spentRatio > idealRatio {
            return "Slightly over"
        }
        if spentRatio < idealRatio - 0.15 {
            return "Under budget"
        }
        return "On track"
    }
}

// MARK: - Chart Category Colors

struct ChartColors {
    /// Get color for a category index (cycles through available colors)
    static func forCategory(index: Int) -> Color {
        let colors: [Color] = [
            .chartCategory1,
            .chartCategory2,
            .chartCategory3,
            .chartCategory4,
            .chartCategory5,
            .chartCategory6
        ]
        return colors[index % colors.count]
    }

    /// Common category colors
    static let categoryColors: [String: Color] = [
        "Food & Dining": Color.chartCategory1,
        "Groceries": Color.chartCategory1,
        "Shopping": Color.chartCategory2,
        "Entertainment": Color.chartCategory3,
        "Transportation": Color.chartCategory4,
        "Bills & Utilities": Color.chartCategory5,
        "Health": Color.chartCategory6,
        "Travel": Color(red: 0.5, green: 0.85, blue: 0.95),
        "Personal": Color(red: 0.95, green: 0.7, blue: 0.75),
        "Other": Color.gray.opacity(0.7)
    ]

    /// Get color for a named category
    static func forCategory(name: String) -> Color {
        return categoryColors[name] ?? .gray.opacity(0.7)
    }
}

// MARK: - Trend Badge View

struct TrendBadge: View {
    let value: Double
    let suffix: String

    init(_ value: Double, suffix: String = "") {
        self.value = value
        self.suffix = suffix
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2.weight(.bold))

            Text(String(format: "%.1f%@", abs(value), suffix))
                .font(.caption.weight(.medium))
        }
        .foregroundColor(value >= 0 ? .positiveChange : .negativeChange)
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    var gradientColors: [Color] = [.furgIndigo, .furgViolet]

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Spending Pace Indicator

struct SpendingPaceIndicator: View {
    let spent: Double
    let budget: Double
    let dayOfMonth: Int
    let daysInMonth: Int

    private var statusColor: Color {
        BudgetStatus.color(spent: spent, budget: budget, dayOfMonth: dayOfMonth, daysInMonth: daysInMonth)
    }

    private var statusText: String {
        BudgetStatus.statusText(spent: spent, budget: budget, dayOfMonth: dayOfMonth, daysInMonth: daysInMonth)
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Copilot Money Aesthetic Components

/// Clean True Black background - FURG Design System
struct CopilotBackground: View {
    var body: some View {
        Color.furgTrueBlack
            .ignoresSafeArea()
    }
}

/// Clean card component with Indigo gradient border - FURG Design System
struct CopilotCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20

    init(cornerRadius: CGFloat = 24, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.furgOffBlack)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.furgIndigo.opacity(0.5), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

/// View modifier extension for copilotCard - FURG Design System
extension View {
    func copilotCard(cornerRadius: CGFloat = 24, padding: CGFloat = 20, opacity: CGFloat = 0.03) -> some View {
        self.padding(padding)
            .background(Color.furgOffBlack)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.furgIndigo.opacity(0.5), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

/// Directional change indicator with green/red semantic colors
struct ChangeIndicator: View {
    let value: Double
    let isPositive: Bool  // true = increase is good (income, assets), false = increase is bad (expenses, debt)
    let suffix: String

    init(value: Double, isPositive: Bool = true, suffix: String = "") {
        self.value = value
        self.isPositive = isPositive
        self.suffix = suffix
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: value >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 14, weight: .bold))

            Text("$\(Int(abs(value))) \(suffix)")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(determineColor())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(determineColor().opacity(0.15))
        .clipShape(Capsule())
    }

    private func determineColor() -> Color {
        if isPositive {
            // For positive context: up = green (good), down = red (bad)
            return value >= 0 ? .chartIncome : .chartSpending
        } else {
            // For negative context: up = red (bad), down = green (good)
            return value >= 0 ? .chartSpending : .chartIncome
        }
    }
}

/// Chart styling utilities for consistent Copilot-style charts
struct CopilotChartStyles {
    /// Line mark style with gradient
    static func lineMarkStyle(color: Color = .chartIncome) -> some ShapeStyle {
        LinearGradient(
            colors: [color.opacity(0.8), color.opacity(0.5)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Area mark style with gradient fade
    static func areaMarkStyle(color: Color = .chartIncome) -> some ShapeStyle {
        LinearGradient(
            colors: [color.opacity(0.3), color.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Standard axis label font
    static var axisLabelFont: Font { .system(size: 11) }

    /// Standard axis label color
    static var axisLabelColor: Color { .white.opacity(0.4) }
}

/// Primary button style - FURG Design System (Indigo to Violet gradient)
struct CopilotPrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.furgHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FurgGradients.indigoVioletGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.furgIndigo.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

/// Secondary button style for Copilot aesthetic
struct CopilotSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }
}

extension View {
    func copilotPrimaryButton() -> some View {
        modifier(CopilotPrimaryButton())
    }

    func copilotSecondaryButton() -> some View {
        modifier(CopilotSecondaryButton())
    }
}

// MARK: - Balance Hero Component (FURG Design System)
// The centerpiece of the Dashboard with subtle Indigo glow behind the card

struct BalanceHeroCard: View {
    let balance: Double
    let change: Double
    let changePercentage: Double
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                // Subtle Indigo glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.furgIndigo.opacity(0.3), Color.furgIndigo.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .offset(y: -50)

                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("NET WORTH")
                            .font(.furgCaption)
                            .foregroundColor(.furgTertiaryLabel)
                            .tracking(1.5)

                        Spacer()

                        // Change indicator
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text(String(format: "%@$%.0f", change >= 0 ? "+" : "", abs(change)))
                                .font(.furgCaption)
                        }
                        .foregroundColor(change >= 0 ? .furgNeonGreen : .furgNeonRed)
                    }

                    // Balance amount
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.furgCurrencySymbol)
                            .foregroundColor(.furgIndigo)

                        Text(formatBalance(balance))
                            .font(.furgBalanceHero)
                            .foregroundColor(.furgPrimaryLabel)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgTertiaryLabel)
                    }

                    // Sparkline placeholder
                    BalanceSparkline()
                        .frame(height: 40)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.furgOffBlack)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.furgIndigo.opacity(0.6), Color.furgIndigo.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .buttonStyle(.plain)
    }

    private func formatBalance(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

/// Sparkline chart with Indigo gradient tint
struct BalanceSparkline: View {
    var body: some View {
        GeometryReader { geometry in
            let data: [Double] = [280000, 282500, 285000, 283000, 290000, 288000, 292000, 295000, 293000, 296000, 294000, 298264]
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 1
            let range = maxValue - minValue

            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width
                    let y = (1 - CGFloat((value - minValue) / range)) * geometry.size.height

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.furgIndigo, .furgViolet],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )

            // Area fill
            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width
                    let y = (1 - CGFloat((value - minValue) / range)) * geometry.size.height

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color.furgIndigo.opacity(0.3), Color.furgIndigo.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Navigation State & Drawer Components

/// Manages global navigation state for gesture-based navigation with pill indicator
@MainActor
class NavigationState: ObservableObject {
    @Published var currentView: AppView = .dashboard

    enum AppView: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case chat = "Chat"
        case activity = "Activity"
        case accounts = "Accounts"
        case tools = "Tools"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .chat: return "message.fill"
            case .activity: return "list.bullet.rectangle"
            case .accounts: return "creditcard.fill"
            case .tools: return "square.grid.2x2.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return Color.furgIndigo
            case .chat: return Color.furgViolet
            case .activity: return Color.furgNeonAmber
            case .accounts: return Color.furgViolet
            case .tools: return Color.furgIndigo
            case .settings: return Color.furgSecondaryLabel
            }
        }
    }

    func navigateTo(_ view: AppView) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentView = view
        }
    }

    func swipeToNext() {
        let views = AppView.allCases
        guard let currentIndex = views.firstIndex(of: currentView) else { return }
        let nextIndex = (currentIndex + 1) % views.count
        navigateTo(views[nextIndex])
    }

    func swipeToPrevious() {
        let views = AppView.allCases
        guard let currentIndex = views.firstIndex(of: currentView) else { return }
        let previousIndex = currentIndex == 0 ? views.count - 1 : currentIndex - 1
        navigateTo(views[previousIndex])
    }
}

/// Bottom left floating pill with animated view name (shows name, fades to dot after 1 second)
/// Tap to open navigation menu with all screens
struct BottomPill: View {
    @ObservedObject var navigationState: NavigationState
    @State private var displayedView: NavigationState.AppView?
    @State private var showViewName = true
    @State private var hideTimer: Timer?
    @State private var showMenu = false

    var body: some View {
        Menu {
            ForEach(NavigationState.AppView.allCases, id: \.self) { view in
                Button {
                    navigationState.navigateTo(view)
                    showMenu = false
                } label: {
                    Label(view.rawValue, systemImage: view.icon)
                }
            }
        } label: {
            // Animated floating pill - shows name or dot
            ZStack {
                // Background capsule
                Capsule()
                    .fill(currentColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(currentColor.opacity(0.4), lineWidth: 1)
                    )

                // Content - either full pill with name or just a dot
                if showViewName {
                    HStack(spacing: 8) {
                        Image(systemName: displayedView?.icon ?? navigationState.currentView.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text((displayedView ?? navigationState.currentView).rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 8, height: 8)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(height: 40)
            .frame(maxWidth: 70)
            .shadow(color: currentColor.opacity(0.3), radius: 8, y: 4)
        }
        .onChange(of: navigationState.currentView) { newView in
            // Update displayed view immediately on navigation change
            displayedView = newView
            showViewName = true
            resetTimer()
        }
        .onAppear {
            displayedView = navigationState.currentView
            startTimer()
        }
        .onDisappear {
            hideTimer?.invalidate()
        }
    }

    private var currentColor: Color {
        (displayedView ?? navigationState.currentView).color
    }

    private func startTimer() {
        hideTimer?.invalidate()
        showViewName = true

        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showViewName = false
            }
        }
    }

    private func resetTimer() {
        hideTimer?.invalidate()
        showViewName = true

        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showViewName = false
            }
        }
    }
}

/// Carousel navigation header with animated floating pill (shows name, fades to dot after 1 second)
struct CarouselNavigationHeader: View {
    @ObservedObject var navigationState: NavigationState
    @State private var displayedView: NavigationState.AppView?
    @State private var showViewName = true
    @State private var hideTimer: Timer?

    var body: some View {
        HStack {
            Spacer()

            // Animated floating pill - shows name or dot
            ZStack {
                // Background capsule
                Capsule()
                    .fill(currentColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(currentColor.opacity(0.4), lineWidth: 1)
                    )

                // Content - either full pill with name or just a dot
                if showViewName {
                    HStack(spacing: 8) {
                        Image(systemName: displayedView?.icon ?? navigationState.currentView.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text((displayedView ?? navigationState.currentView).rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 8, height: 8)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(height: 40)
            .frame(maxWidth: 70)
            .shadow(color: currentColor.opacity(0.3), radius: 8, y: 4)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: navigationState.currentView) { newView in
            // Update displayed view immediately on navigation change
            displayedView = newView
            showViewName = true
            resetTimer()
        }
        .onAppear {
            displayedView = navigationState.currentView
            startTimer()
        }
        .onDisappear {
            hideTimer?.invalidate()
        }
    }

    private var currentColor: Color {
        (displayedView ?? navigationState.currentView).color
    }

    private func startTimer() {
        hideTimer?.invalidate()
        showViewName = true

        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showViewName = false
            }
        }
    }

    private func resetTimer() {
        hideTimer?.invalidate()
        showViewName = true

        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showViewName = false
            }
        }
    }
}

/// Legacy bottom pill navigation (deprecated, use CarouselNavigationHeader instead)
struct PillNavigation: View {
    @ObservedObject var navigationState: NavigationState

    var body: some View {
        HStack(spacing: 12) {
            // Left arrow button
            Button {
                navigationState.swipeToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            // Current view pill
            HStack(spacing: 8) {
                Image(systemName: navigationState.currentView.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(navigationState.currentView.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(Double(index) * 0.3 + 0.2))
                            .frame(height: 2)
                    }
                }
                .frame(width: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(navigationState.currentView.color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(navigationState.currentView.color.opacity(0.4), lineWidth: 1)
                    )
            )

            // Right arrow button
            Button {
                navigationState.swipeToNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Expandable floating action button - FURG Design System
/// Shape: 60pt Circle, Fill: Linear Gradient (Indigo -> Violet)
struct FloatingActionButton: View {
    @State private var isExpanded = false
    @State private var showReceiptScan = false
    @State private var showQuickDebtPayment = false
    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                VStack(spacing: 10) {
                    FABMenuItem(
                        icon: "plus.circle.fill",
                        label: "Add Transaction",
                        color: .furgIndigo
                    ) {
                        // TODO: Show add transaction sheet
                        isExpanded = false
                    }

                    FABMenuItem(
                        icon: "message.fill",
                        label: "Ask AI",
                        color: .furgViolet
                    ) {
                        navigationState.navigateTo(.chat)
                        isExpanded = false
                    }

                    FABMenuItem(
                        icon: "doc.text.viewfinder",
                        label: "Scan Receipt",
                        color: .furgIndigo
                    ) {
                        showReceiptScan = true
                        isExpanded = false
                    }

                    FABMenuItem(
                        icon: "creditcard.fill",
                        label: "Pay Debt",
                        color: .furgNeonRed
                    ) {
                        showQuickDebtPayment = true
                        isExpanded = false
                    }

                    FABMenuItem(
                        icon: "tag.fill",
                        label: "Deals",
                        color: .furgViolet
                    ) {
                        navigationState.navigateTo(.tools)
                        isExpanded = false
                    }
                }
                .padding(12)
                .background(Color.furgOffBlack)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.furgIndigo.opacity(0.3), lineWidth: 1)
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(FurgGradients.indigoVioletGradient)
                    .clipShape(Circle())
                    .shadow(color: Color.furgIndigo.opacity(0.5), radius: 12, y: 6)
            }
            .rotationEffect(.degrees(isExpanded ? 45 : 0))
        }
        .sheet(isPresented: $showReceiptScan) {
            ZStack {
                Color.furgTrueBlack.ignoresSafeArea()
                VStack {
                    HStack {
                        Button("Close") {
                            showReceiptScan = false
                        }
                        .foregroundColor(.furgIndigo)
                        Spacer()
                    }
                    .padding()

                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.furgIndigo)

                        Text("Receipt Scan")
                            .font(.furgTitle2)
                            .foregroundColor(.furgPrimaryLabel)

                        Text("Coming Soon")
                            .font(.furgBody)
                            .foregroundColor(.furgSecondaryLabel)
                    }

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showQuickDebtPayment) {
            QuickDebtPaymentSheet()
        }
    }
}

/// Individual menu item in the FAB menu
struct FABMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with colored background
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: color.opacity(0.4), radius: 6, y: 2)

                // Label with better styling
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}

// MARK: - Quick Debt Payment Sheet
struct QuickDebtPaymentSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDebtIndex = 0
    @State private var paymentAmount = ""
    @State private var paymentMethod = "Balance Transfer"
    @State private var isSubmitting = false
    @State private var showSuccessMessage = false

    // Temporary sample debts - will be wired to DebtPayoffManager in Phase 3.2
    let sampleDebts = [
        (id: UUID(), name: "Credit Card - Chase", balance: 4250.0, rate: 0.18),
        (id: UUID(), name: "Student Loan - Federal", balance: 18500.0, rate: 0.05),
        (id: UUID(), name: "Auto Loan - Honda", balance: 12000.0, rate: 0.06),
        (id: UUID(), name: "Personal Loan - SoFi", balance: 3750.0, rate: 0.08),
    ]

    var body: some View {
        ZStack {
            Color.furgCharcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Quick Debt Payment")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.furgMint)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.95))
                .overlay(
                    VStack(spacing: 0) {
                        Spacer()
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Select Debt Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Debt")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(0..<sampleDebts.count, id: \.self) { index in
                                    let debt = sampleDebts[index]
                                    DebtSelectionRow(
                                        isSelected: selectedDebtIndex == index,
                                        debtName: debt.name,
                                        debtBalance: String(format: "$%.0f", debt.balance),
                                        interestType: String(format: "%.1f%%", debt.rate * 100)
                                    ) {
                                        selectedDebtIndex = index
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Payment Amount Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Amount")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                Text("$")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.furgMint)

                                TextField("0.00", text: $paymentAmount)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)

                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }

                        // Payment Method Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Method")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            HStack(spacing: 8) {
                                ForEach(["Balance Transfer", "Check", "ACH"], id: \.self) { method in
                                    Button {
                                        paymentMethod = method
                                    } label: {
                                        Text(method)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(paymentMethod == method ? .white : .white.opacity(0.6))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                paymentMethod == method
                                                    ? Color.furgMint.opacity(0.2)
                                                    : Color.white.opacity(0.03)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        paymentMethod == method ? Color.furgMint.opacity(0.4) : Color.white.opacity(0.1),
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Payment Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            VStack(spacing: 10) {
                                HStack {
                                    Text("Debt:")
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text(sampleDebts[selectedDebtIndex].name)
                                        .foregroundColor(.white)
                                        .font(.system(size: 13, weight: .medium))
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                HStack {
                                    Text("Amount:")
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text("$\(paymentAmount.isEmpty ? "0.00" : paymentAmount)")
                                        .foregroundColor(.furgMint)
                                        .font(.system(size: 13, weight: .semibold))
                                }

                                HStack {
                                    Text("Method:")
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text(paymentMethod)
                                        .foregroundColor(.white)
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }

                        // Submit Button
                        VStack(spacing: 12) {
                            Button {
                                isSubmitting = true
                                // TODO: Wire to DebtPayoffManager.recordPayment in Phase 3.2
                                showSuccessMessage = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: showSuccessMessage ? "checkmark.circle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(showSuccessMessage ? "Payment Recorded!" : "Record Payment")
                                        .font(.system(size: 16, weight: .semibold))

                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: showSuccessMessage ? [Color.furgMint.opacity(0.6), Color.furgMint.opacity(0.4)] : [.furgMint, Color(red: 0.3, green: 0.85, blue: 0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.furgMint.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(paymentAmount.isEmpty || Double(paymentAmount) ?? 0 <= 0 || isSubmitting)
                            .opacity((paymentAmount.isEmpty || Double(paymentAmount) ?? 0 <= 0 || isSubmitting) ? 0.5 : 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

// MARK: - Debt Selection Row
struct DebtSelectionRow: View {
    let isSelected: Bool
    let debtName: String
    let debtBalance: String
    let interestType: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.furgMint : Color.white.opacity(0.1))
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.furgCharcoal)
                    }
                }

                // Debt info
                VStack(alignment: .leading, spacing: 4) {
                    Text(debtName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Text(debtBalance)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))

                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        Text(interestType)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.furgMint.opacity(0.15) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.furgMint.opacity(0.4) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Balance Trend Waterfall Chart (Proper Implementation)
struct BalanceTrendWaterfallChart: View {
    @State private var selectedRange: WaterfallTimeRange = .month
    let data: [(category: String, amount: Double, color: Color)]

    enum WaterfallTimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }

    private let startingBalance: Double = 12000.0

    var endingBalance: Double {
        startingBalance - data.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Time range selector
            HStack(spacing: 12) {
                ForEach(WaterfallTimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedRange == range ? .white : .white.opacity(0.4))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedRange == range
                                ? Color.furgMint.opacity(0.2)
                                : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }

            // Waterfall chart using custom Canvas
            WaterfallChartCanvas(
                startingBalance: startingBalance,
                expenses: data,
                endingBalance: endingBalance
            )
            .frame(height: 280)

            // Balance summary
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starting Balance")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "$%.2f", startingBalance))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Total Spent")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "-$%.2f", data.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.chartSpending)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ending Balance")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "$%.2f", endingBalance))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.chartIncome)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Legend
            VStack(alignment: .leading, spacing: 10) {
                Text("Spending by Category")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(data, id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)

                                Text(String(format: "-$%.0f", item.amount))
                                    .font(.system(size: 10))
                                    .foregroundColor(item.color)
                            }

                            Spacer()
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Waterfall Chart Canvas
struct WaterfallChartCanvas: View {
    let startingBalance: Double
    let expenses: [(category: String, amount: Double, color: Color)]
    let endingBalance: Double

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 16
            let chartWidth = size.width - (padding * 2)
            let chartHeight = size.height - 60
            let maxBalance = startingBalance

            // Number of bars (start + expenses + end)
            let barCount = CGFloat(expenses.count + 2)
            let barSpacing: CGFloat = 8
            let totalSpacing = barSpacing * (barCount - 1)
            let barWidth = (chartWidth - totalSpacing) / barCount

            // Background
            let bgPath = Path(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: 12)
            context.fill(bgPath, with: .color(Color.white.opacity(0.02)))

            var currentBalance = startingBalance
            var previousBarX: CGFloat = 0
            var previousBarTopY: CGFloat = 0

            // Calculate all bars
            var barInfo: [(x: CGFloat, height: CGFloat, balance: Double, label: String, color: Color, isStart: Bool)] = []

            for (index) in 0...expenses.count {
                let barX = padding + CGFloat(index) * (barWidth + barSpacing)
                let barHeight: CGFloat
                let label: String
                let color: Color
                let isStart: Bool

                if index == 0 {
                    // Starting balance
                    barHeight = (startingBalance / maxBalance) * chartHeight
                    label = "Start"
                    color = Color(red: 0.55, green: 0.65, blue: 0.75)
                    isStart = true
                } else if index == expenses.count {
                    // Ending balance
                    barHeight = (endingBalance / maxBalance) * chartHeight
                    label = "End"
                    color = Color(red: 0.45, green: 0.85, blue: 0.65)
                    isStart = true
                } else {
                    // Expense bar
                    let expense = expenses[index - 1]
                    currentBalance -= expense.amount
                    barHeight = (currentBalance / maxBalance) * chartHeight
                    label = expense.category
                    color = expense.color
                    isStart = false
                }

                barInfo.append((x: barX, height: barHeight, balance: currentBalance, label: label, color: color, isStart: isStart))
            }

            // Draw bars and connectors
            for (index, info) in barInfo.enumerated() {
                let barY = padding + chartHeight - info.height
                let barRect = Path(roundedRect: CGRect(x: info.x, y: barY, width: barWidth, height: info.height), cornerRadius: 4)
                context.fill(barRect, with: .color(info.color))

                // Draw connector line to next bar
                if index < barInfo.count - 1 {
                    let nextInfo = barInfo[index + 1]
                    let currentBarTopY = padding + chartHeight - info.height
                    let nextBarTopY = padding + chartHeight - nextInfo.height

                    // Horizontal connector line at the current bar's top
                    var connectorPath = Path()
                    connectorPath.move(to: CGPoint(x: info.x + barWidth, y: currentBarTopY))
                    connectorPath.addLine(to: CGPoint(x: nextInfo.x, y: currentBarTopY))

                    context.stroke(connectorPath, with: .color(info.color.opacity(0.4)), lineWidth: 1)

                    // Vertical connector if there's a gap (step down)
                    if currentBarTopY != nextBarTopY {
                        var verticalPath = Path()
                        verticalPath.move(to: CGPoint(x: nextInfo.x, y: currentBarTopY))
                        verticalPath.addLine(to: CGPoint(x: nextInfo.x, y: nextBarTopY))
                        context.stroke(verticalPath, with: .color(info.color.opacity(0.4)), lineWidth: 1)
                    }
                }
            }
        }
    }
}

// MARK: - Waterfall Bar Component
struct WaterfallBar: View {
    let label: String
    let amount: Double
    let height: CGFloat
    let color: Color
    let isConnector: Bool
    var isPositive: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            // Value label
            Text(String(format: "$%.0f", abs(amount)))
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)

            Spacer()

            // Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(height: height)
                .shadow(color: color.opacity(0.3), radius: 4, y: 2)

            // Connector line (for intermediate bars)
            if isConnector {
                VStack(spacing: 0) {
                    Divider()
                        .frame(height: 1)
                        .background(color.opacity(0.3))
                }
                .frame(height: 8)
            }

            // Category label
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Spending Heatmap Calendar
struct SpendingHeatmapCalendar: View {
    let monthData: [Int: Double] // day -> spending amount
    @State private var selectedDay: Int?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 16) {
            // Day labels
            HStack {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...31, id: \.self) { day in
                    let amount = monthData[day] ?? 0
                    let intensity = amount / 500 // Normalize to 500 as max
                    let color = getHeatmapColor(intensity: min(intensity, 1.0))

                    VStack(spacing: 4) {
                        Text("\(day)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        selectedDay == day
                            ? RoundedRectangle(cornerRadius: 8).stroke(Color.furgMint, lineWidth: 2)
                            : nil
                    )
                    .onTapGesture {
                        selectedDay = day
                    }
                }
            }

            // Legend and info
            if let selectedDay = selectedDay, let amount = monthData[selectedDay] {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(selectedDay)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Spending: $\(String(format: "%.2f", amount))")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    let intensity = amount / 500
                    if intensity > 0.7 {
                        Label("High spending", systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.furgWarning)
                    } else if intensity > 0.4 {
                        Label("Moderate", systemImage: "circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.furgSeafoam)
                    } else {
                        Label("Low spending", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.chartIncome)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity)
            }
        }
    }

    private func getHeatmapColor(intensity: Double) -> Color {
        if intensity < 0.2 {
            return Color.chartIncome.opacity(0.3) // Light green - low spending
        } else if intensity < 0.4 {
            return Color.chartIncome.opacity(0.6)
        } else if intensity < 0.6 {
            return Color.furgSeafoam.opacity(0.6)
        } else if intensity < 0.8 {
            return Color.furgWarning.opacity(0.6)
        } else {
            return Color.furgDanger.opacity(0.7) // Dark red - high spending
        }
    }
}

