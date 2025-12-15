//
//  DesignSystemV2.swift
//  Furg
//
//  "Midnight Emerald" design system - research-backed color psychology for finance apps
//  - 73% feel secure with green in finances
//  - 24% higher CTAs engagement with coral accents
//  - 20% higher retention with emerald primary
//

import SwiftUI

// MARK: - V2 Color Palette

extension Color {
    // Background Colors - Deep midnight blue
    static let v2Background = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let v2BackgroundSecondary = Color(red: 0.06, green: 0.07, blue: 0.12)
    static let v2CardBackground = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let v2CardBackgroundElevated = Color(red: 0.10, green: 0.11, blue: 0.16)

    // Primary Accent: Emerald - 73% security confidence
    static let v2Primary = Color(red: 0.18, green: 0.80, blue: 0.58)
    static let v2PrimaryLight = Color(red: 0.25, green: 0.88, blue: 0.65)
    static let v2PrimaryDark = Color(red: 0.12, green: 0.65, blue: 0.48)

    // Secondary Accent: Coral - 24% higher CTAs (Monzo-inspired)
    static let v2Accent = Color(red: 1.0, green: 0.45, blue: 0.40)
    static let v2AccentLight = Color(red: 1.0, green: 0.55, blue: 0.50)
    static let v2AccentDark = Color(red: 0.85, green: 0.35, blue: 0.30)

    // Semantic Colors
    static let v2Success = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let v2Warning = Color(red: 1.0, green: 0.75, blue: 0.30)
    static let v2Danger = Color(red: 1.0, green: 0.45, blue: 0.45)
    static let v2Info = Color(red: 0.40, green: 0.70, blue: 1.0)

    // Premium Purple - 27% wealth perception
    static let v2Premium = Color(red: 0.65, green: 0.45, blue: 0.95)
    static let v2PremiumLight = Color(red: 0.75, green: 0.55, blue: 1.0)

    // Text Colors
    static let v2TextPrimary = Color.white
    static let v2TextSecondary = Color.white.opacity(0.65)
    static let v2TextTertiary = Color.white.opacity(0.40)
    static let v2TextInverse = Color(red: 0.08, green: 0.09, blue: 0.12)

    // Category Colors (for spending visualization)
    static let v2CategoryFood = Color(red: 1.0, green: 0.65, blue: 0.40)
    static let v2CategoryShopping = Color(red: 0.95, green: 0.55, blue: 0.70)
    static let v2CategoryTransport = Color(red: 0.50, green: 0.70, blue: 0.95)
    static let v2CategoryHome = Color(red: 0.40, green: 0.80, blue: 0.75)
    static let v2CategoryEntertainment = Color(red: 0.70, green: 0.55, blue: 0.95)
    static let v2CategoryHealth = Color(red: 0.95, green: 0.50, blue: 0.50)
    static let v2CategoryTravel = Color(red: 0.50, green: 0.85, blue: 1.0)
    static let v2CategoryBills = Color(red: 0.55, green: 0.60, blue: 0.70)
    static let v2CategoryIncome = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let v2CategoryOther = Color(red: 0.55, green: 0.55, blue: 0.60)

    // Additional UI colors
    static let v2Lime = Color(red: 0.70, green: 0.95, blue: 0.40)
    static let v2Teal = Color(red: 0.30, green: 0.85, blue: 0.80)
    static let v2Gold = Color(red: 1.0, green: 0.85, blue: 0.40)
}

// MARK: - V2 Gradients

struct V2Gradients {
    // Primary emerald gradient
    static let primary = LinearGradient(
        colors: [Color.v2Primary, Color.v2PrimaryLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Accent coral gradient - 24% higher engagement
    static let accent = LinearGradient(
        colors: [Color.v2Accent, Color.v2AccentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Budget progress gradient
    static let budget = LinearGradient(
        colors: [Color.v2Primary, Color.v2Success],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Premium gradient
    static let premium = LinearGradient(
        colors: [Color.v2Premium, Color.v2PremiumLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Background gradient
    static let background = LinearGradient(
        colors: [Color.v2Background, Color.v2BackgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    // Card gradient
    static let card = LinearGradient(
        colors: [Color.v2CardBackground, Color.v2CardBackgroundElevated],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - V2 Typography

extension Font {
    // Headlines
    static let v2LargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let v2Title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let v2Title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let v2Headline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let v2Subtitle = Font.system(size: 16, weight: .semibold, design: .rounded)

    // Body
    static let v2Body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let v2BodyMedium = Font.system(size: 16, weight: .medium, design: .rounded)

    // Small
    static let v2Caption = Font.system(size: 14, weight: .regular, design: .rounded)
    static let v2CaptionMedium = Font.system(size: 14, weight: .medium, design: .rounded)
    static let v2Footnote = Font.system(size: 12, weight: .regular, design: .rounded)
    static let v2FootnoteMedium = Font.system(size: 12, weight: .medium, design: .rounded)

    // Numbers (for financial data)
    static let v2Amount = Font.system(size: 32, weight: .bold, design: .rounded)
    static let v2AmountSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
}

// MARK: - V2 Card Component

struct V2Card<Content: View>: View {
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
            .background(Color.v2CardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - V2 View Modifiers

extension View {
    func v2Card(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .background(Color.v2CardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    func v2Background() -> some View {
        self.background(Color.v2Background.ignoresSafeArea())
    }

    func v2PrimaryButton() -> some View {
        self.font(.v2BodyMedium)
            .foregroundColor(.v2TextInverse)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(V2Gradients.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func v2SecondaryButton() -> some View {
        self.font(.v2BodyMedium)
            .foregroundColor(.v2TextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - V2 Pill Component

struct V2Pill: View {
    let text: String
    var color: Color = .v2Primary
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(.v2CaptionMedium)
            .foregroundColor(isSelected ? .v2TextInverse : .v2TextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.white.opacity(0.08))
            .clipShape(Capsule())
    }
}

// MARK: - V2 Section Header

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

            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.v2CaptionMedium)
                        .foregroundColor(.v2Primary)
                }
            }
        }
    }
}

// MARK: - V2 Amount Display

struct V2AmountDisplay: View {
    let amount: Double
    var prefix: String = "$"
    var showSign: Bool = false
    var size: AmountSize = .large

    enum AmountSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return .v2AmountSmall
            case .medium: return .v2Title
            case .large: return .v2Amount
            }
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if showSign && amount != 0 {
                Text(amount > 0 ? "+" : "-")
                    .font(size.font)
                    .foregroundColor(amount > 0 ? .v2Success : .v2Danger)
            }

            Text(prefix)
                .font(size.font)
                .foregroundColor(.v2TextSecondary)

            Text(String(format: "%.2f", abs(amount)))
                .font(size.font)
                .foregroundColor(.v2TextPrimary)
        }
    }
}

// MARK: - V2 Transaction Row

struct V2TransactionRow: View {
    let merchant: String
    let category: String
    let amount: Double
    let date: Date
    var icon: String = "cart.fill"
    var iconColor: Color = .v2Primary

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(merchant)
                    .font(.v2BodyMedium)
                    .foregroundColor(.v2TextPrimary)

                Text(category)
                    .font(.v2Footnote)
                    .foregroundColor(.v2TextTertiary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "-$%.2f", abs(amount)))
                    .font(.v2BodyMedium)
                    .foregroundColor(.v2TextPrimary)

                Text(date, style: .date)
                    .font(.v2Footnote)
                    .foregroundColor(.v2TextTertiary)
            }
        }
        .padding(12)
        .background(Color.v2CardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - V2 Category Row

struct V2CategoryRow: View {
    let name: String
    let amount: Double
    let budget: Double
    var color: Color = .v2Primary

    var progress: Double {
        guard budget > 0 else { return 0 }
        return min(amount / budget, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.v2BodyMedium)
                    .foregroundColor(.v2TextPrimary)

                Spacer()

                Text(String(format: "$%.0f / $%.0f", amount, budget))
                    .font(.v2Caption)
                    .foregroundColor(.v2TextSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress > 0.9 ? Color.v2Danger : color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(Color.v2CardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - V2 Navigation State

@MainActor
class V2NavigationState: ObservableObject {
    @Published var currentPage: V2Page = .dashboard

    enum V2Page: Int, CaseIterable {
        case dashboard = 0
        case spending = 1
        case accounts = 2

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .spending: return "Spending"
            case .accounts: return "Accounts"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .spending: return "creditcard.fill"
            case .accounts: return "building.columns.fill"
            }
        }
    }

    func navigateTo(_ page: V2Page) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentPage = page
        }
    }

    func swipeToNext() {
        let pages = V2Page.allCases
        let currentIndex = currentPage.rawValue
        let nextIndex = min(currentIndex + 1, pages.count - 1)
        navigateTo(pages[nextIndex])
    }

    func swipeToPrevious() {
        let pages = V2Page.allCases
        let currentIndex = currentPage.rawValue
        let previousIndex = max(currentIndex - 1, 0)
        navigateTo(pages[previousIndex])
    }
}

// MARK: - V2 Page Indicator

struct V2PageIndicator: View {
    @ObservedObject var navigationState: V2NavigationState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(V2NavigationState.V2Page.allCases, id: \.rawValue) { page in
                Circle()
                    .fill(navigationState.currentPage == page ? Color.v2Primary : Color.white.opacity(0.3))
                    .frame(width: navigationState.currentPage == page ? 8 : 6, height: navigationState.currentPage == page ? 8 : 6)
                    .animation(.spring(response: 0.3), value: navigationState.currentPage)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}
