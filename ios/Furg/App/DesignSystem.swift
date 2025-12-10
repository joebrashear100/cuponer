//
//  DesignSystem.swift
//  Furg
//
//  Modern glassmorphism design system with pastel green palette
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary pastel greens
    static let furgMint = Color(red: 0.6, green: 0.95, blue: 0.85)           // #99F2D9 - Main accent
    static let furgSage = Color(red: 0.68, green: 0.88, blue: 0.76)          // #AEE1C2 - Secondary
    static let furgSeafoam = Color(red: 0.5, green: 0.9, blue: 0.8)          // #80E6CC - Vibrant accent
    static let furgPistachio = Color(red: 0.75, green: 0.93, blue: 0.73)     // #BFEDBA - Light accent

    // Supporting colors
    static let furgCream = Color(red: 0.98, green: 1.0, blue: 0.96)          // #FAFFF5 - Light background
    static let furgCharcoal = Color(red: 0.12, green: 0.14, blue: 0.16)      // #1F2429 - Dark background
    static let furgSlate = Color(red: 0.18, green: 0.22, blue: 0.26)         // #2E3842 - Cards dark
    static let furgMist = Color(red: 0.94, green: 0.97, blue: 0.95)          // #F0F8F2 - Light cards

    // Semantic colors
    static let furgSuccess = Color(red: 0.4, green: 0.85, blue: 0.6)         // #66D999
    static let furgWarning = Color(red: 1.0, green: 0.8, blue: 0.4)          // #FFCC66
    static let furgDanger = Color(red: 1.0, green: 0.5, blue: 0.5)           // #FF8080
    static let furgError = Color.furgDanger                                   // Alias for danger/error
    static let furgInfo = Color(red: 0.5, green: 0.8, blue: 1.0)             // #80CCFF
    static let furgAccent = Color.furgMint                                    // Alias for accent color

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
    static let chartIncome = Color(red: 0.4, green: 0.85, blue: 0.6)         // Green - money in
    static let chartSpending = Color(red: 1.0, green: 0.5, blue: 0.5)        // Red - money out
    static let chartNetPositive = Color(red: 0.4, green: 0.75, blue: 1.0)    // Blue - positive net
    static let chartNetNegative = Color(red: 1.0, green: 0.55, blue: 0.55)   // Light red - negative net
    static let chartIdealLine = Color.white.opacity(0.4)                      // Dashed ideal line
    static let chartActualLine = Color.furgMint                               // Actual spending line

    // Chart category colors for pie/bar charts
    static let chartCategory1 = Color(red: 0.6, green: 0.95, blue: 0.85)     // Mint
    static let chartCategory2 = Color(red: 0.5, green: 0.75, blue: 1.0)      // Blue
    static let chartCategory3 = Color(red: 1.0, green: 0.7, blue: 0.5)       // Peach
    static let chartCategory4 = Color(red: 0.85, green: 0.65, blue: 0.95)    // Purple
    static let chartCategory5 = Color(red: 1.0, green: 0.85, blue: 0.5)      // Yellow
    static let chartCategory6 = Color(red: 0.6, green: 0.85, blue: 0.7)      // Seafoam

    // MARK: - Financial Indicator Colors

    /// Positive change indicator (e.g., balance increase)
    static let positiveChange = Color(red: 0.4, green: 0.85, blue: 0.6)
    /// Negative change indicator (e.g., balance decrease)
    static let negativeChange = Color(red: 1.0, green: 0.5, blue: 0.5)
    /// Unreviewed transaction indicator (light blue dot)
    static let unreviewedBadge = Color(red: 0.5, green: 0.7, blue: 1.0).opacity(0.7)

    // Glass colors
    static let glassWhite = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.25)
    static let glassDark = Color.black.opacity(0.2)

    // Background aliases
    static let furgDarkBg = Color.furgCharcoal
}

// MARK: - Gradients

struct FurgGradients {
    // Main background gradient
    static let mainBackground = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.1, blue: 0.14),    // Deep dark
            Color(red: 0.12, green: 0.16, blue: 0.2),    // Slightly lighter
            Color(red: 0.1, green: 0.18, blue: 0.2)      // Hint of teal
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Accent gradient
    static let mintGradient = LinearGradient(
        colors: [Color.furgMint, Color.furgSeafoam],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Glass gradient
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Mesh-like background
    static let meshBackground = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.08, blue: 0.12),
            Color(red: 0.1, green: 0.14, blue: 0.18),
            Color(red: 0.08, green: 0.12, blue: 0.16)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var opacity: Double = 0.12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
                        LinearGradient(
                            colors: [Color.furgMint, Color.furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(isAccent ? 0.3 : 0.15), lineWidth: 1)
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
    var color: Color = .furgMint
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

// GlassCard as a container view (not just modifier)
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    init(cornerRadius: CGFloat = 16, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.12))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct AccentBadge: View {
    let text: String
    var color: Color = .furgMint

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.furgCharcoal)
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
                    .foregroundColor(.furgMint)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(trend)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(trendUp ? .furgSuccess : .furgDanger)
                }
            }

            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(.white)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
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
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(selectedIndex == index ? .furgCharcoal : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedIndex == index {
                                    Capsule().fill(Color.furgMint)
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

// MARK: - Text Styles

extension Font {
    static let furgLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let furgTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let furgTitle2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let furgHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let furgBody = Font.system(size: 17, weight: .regular, design: .rounded)
    static let furgCaption = Font.system(size: 12, weight: .medium, design: .rounded)
}

// MARK: - Animated Background

struct AnimatedMeshBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            FurgGradients.mainBackground

            // Floating orbs
            GlowingOrb(color: .furgMint, size: 300)
                .offset(x: animate ? -50 : -100, y: animate ? -100 : -50)
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: animate
                )

            GlowingOrb(color: .furgSeafoam, size: 250)
                .offset(x: animate ? 150 : 100, y: animate ? 200 : 250)
                .animation(
                    .easeInOut(duration: 10).repeatForever(autoreverses: true),
                    value: animate
                )

            GlowingOrb(color: .furgPistachio.opacity(0.5), size: 200)
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
    var gradientColors: [Color] = [.furgMint, .furgSeafoam]

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

/// Clean dark gradient background - replaces AnimatedMeshBackground
struct CopilotBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.08),
                Color(red: 0.08, green: 0.08, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Clean card component with subtle border - replaces GlassCard and FloatingCard
struct CopilotCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 20

    init(cornerRadius: CGFloat = 16, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

/// View modifier extension for copilotCard
extension View {
    func copilotCard(cornerRadius: CGFloat = 16, padding: CGFloat = 20, opacity: CGFloat = 0.03) -> some View {
        self.padding(padding)
            .background(Color.white.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
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

/// Primary button style for Copilot aesthetic
struct CopilotPrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.chartIncome, Color(red: 0.35, green: 0.75, blue: 0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
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

// MARK: - Navigation State & Drawer Components

/// Manages global navigation state for gesture-based home hub navigation
@MainActor
class NavigationState: ObservableObject {
    @Published var currentView: AppView = .hub
    @Published var isHomeHub: Bool = true

    enum AppView: String, CaseIterable, Identifiable {
        case hub = "Home"
        case dashboard = "Dashboard"
        case chat = "Chat"
        case activity = "Activity"
        case accounts = "Accounts"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .hub: return "house.fill"
            case .dashboard: return "chart.bar.fill"
            case .chat: return "message.fill"
            case .activity: return "list.bullet.rectangle"
            case .accounts: return "creditcard.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .hub: return .furgMint
            case .dashboard: return Color(red: 0.45, green: 0.85, blue: 0.65)
            case .chat: return Color(red: 0.35, green: 0.75, blue: 0.95)
            case .activity: return Color(red: 0.95, green: 0.65, blue: 0.35)
            case .accounts: return Color(red: 0.75, green: 0.55, blue: 0.95)
            case .settings: return Color(red: 0.55, green: 0.65, blue: 0.75)
            }
        }

        var description: String {
            switch self {
            case .hub: return "Your financial overview"
            case .dashboard: return "Balance & insights"
            case .chat: return "AI financial assistant"
            case .activity: return "Transactions & spending"
            case .accounts: return "All your accounts"
            case .settings: return "App preferences"
            }
        }
    }

    func navigateTo(_ view: AppView) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentView = view
            isHomeHub = (view == .hub)
        }
    }

    func navigateToHub() {
        navigateTo(.hub)
    }

    func swipeToNext() {
        let views = AppView.allCases.filter { $0 != .hub }
        guard let currentIndex = views.firstIndex(of: currentView) else { return }
        let nextIndex = (currentIndex + 1) % views.count
        navigateTo(views[nextIndex])
    }

    func swipeToPrevious() {
        let views = AppView.allCases.filter { $0 != .hub }
        guard let currentIndex = views.firstIndex(of: currentView) else { return }
        let previousIndex = currentIndex == 0 ? views.count - 1 : currentIndex - 1
        navigateTo(views[previousIndex])
    }
}

/// Home hub with visual cards for navigation
struct HomeHubView: View {
    @ObservedObject var navigationState: NavigationState
    @ObservedObject var financeManager: FinanceManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Greeting and balance summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Afternoon")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))

                        Text("Joe")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Balance")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))

                        Text("$4,250")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.furgMint)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Navigation cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(NavigationState.AppView.allCases.filter { $0 != .hub }) { view in
                        HubNavigationCard(
                            view: view,
                            action: { navigationState.navigateTo(view) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for FAB
            }
        }
    }
}

/// Large visual card for hub navigation
struct HubNavigationCard: View {
    let view: NavigationState.AppView
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                view.color.opacity(0.8),
                                view.color.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: view.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: view.color.opacity(0.3), radius: 8, y: 4)

                // Title
                Text(view.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                // Description
                Text(view.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding(20)
            .copilotCard(cornerRadius: 20, padding: 0)
        }
        .buttonStyle(HubCardButtonStyle())
    }
}

/// Button style with scale animation
struct HubCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Expandable floating action button with menu items
struct FloatingActionButton: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                FABMenuItem(
                    icon: "plus.circle.fill",
                    label: "Add Transaction",
                    color: .chartIncome
                ) {
                    // TODO: Show add transaction sheet
                    isExpanded = false
                }

                FABMenuItem(
                    icon: "message.fill",
                    label: "Ask AI",
                    color: .chartCategory2
                ) {
                    // TODO: Navigate to chat and focus input
                    isExpanded = false
                }
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
                    .background(
                        LinearGradient(
                            colors: [.chartIncome, Color(red: 0.35, green: 0.75, blue: 0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)
            }
            .rotationEffect(.degrees(isExpanded ? 45 : 0))
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
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)

                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}

/// Ultra-minimal top bar without hamburger menu
struct MinimalTopBar: View {
    @ObservedObject var navigationState: NavigationState
    let onRefresh: () -> Void
    let onNotifications: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Logo (tappable to return home)
            Button {
                navigationState.navigateToHub()
            } label: {
                Text("FURG")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.furgMint)
            }

            // Current view title (only show when not on hub)
            if !navigationState.isHomeHub {
                Text(navigationState.currentView.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity)
            }

            Spacer()

            // Refresh Button
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
            }

            // Notifications
            Button(action: onNotifications) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 44, height: 44)

                    // Notification badge
                    Circle()
                        .fill(Color.chartSpending)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: 10)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.95)
        )
    }
}
