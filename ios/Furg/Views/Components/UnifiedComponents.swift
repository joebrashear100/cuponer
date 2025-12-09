//
//  UnifiedComponents.swift
//  Furg
//
//  Unified, reusable UI components for consistent design across the app
//

import SwiftUI

// MARK: - Card Styles

/// Standard card with glass morphism effect
struct FurgCard<Content: View>: View {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let showBorder: Bool
    let borderColor: Color
    let content: Content

    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        showBorder: Bool = true,
        borderColor: Color = .white.opacity(0.1),
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(showBorder ? borderColor : .clear, lineWidth: 0.5)
                    )
            )
    }
}

/// Highlighted card with accent border
struct FurgAccentCard<Content: View>: View {
    let accentColor: Color
    let padding: CGFloat
    let content: Content

    init(
        accentColor: Color = .furgMint,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.accentColor = accentColor
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.4), accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Section Headers

struct FurgSectionHeader: View {
    let title: String
    let icon: String?
    let iconColor: Color
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        _ title: String,
        icon: String? = nil,
        iconColor: Color = .furgMint,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

// MARK: - Buttons

/// Primary action button with gradient
struct FurgPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.furgCharcoal)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.furgCharcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.furgMint, .furgSeafoam],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading || isDisabled)
        .opacity(isLoading || isDisabled ? 0.6 : 1)
    }
}

/// Secondary button with outline
struct FurgSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.furgMint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.furgMint.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.furgMint.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// Icon button with circular background
struct FurgIconButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    init(_ icon: String, color: Color = .furgMint, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.15))
                .clipShape(Circle())
        }
    }
}

// MARK: - Input Fields

struct FurgTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let keyboardType: UIKeyboardType

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.keyboardType = keyboardType
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 24)
            }

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct FurgAmountInput: View {
    @Binding var amount: String
    let prefix: String
    let placeholder: String

    init(_ amount: Binding<String>, prefix: String = "$", placeholder: String = "0") {
        self._amount = amount
        self.prefix = prefix
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(prefix)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(.furgMint)

            TextField(placeholder, text: $amount)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - List Rows

struct FurgListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        let content = HStack(spacing: 14) {
            leading

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            trailing
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )

        if let action = action {
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Progress Indicators

struct FurgProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    let showLabel: Bool

    init(
        progress: Double,
        color: Color = .furgMint,
        height: CGFloat = 8,
        showLabel: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.height = height
        self.showLabel = showLabel
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: height)
                }
            }
            .frame(height: height)

            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
            }
        }
    }
}

struct FurgCircularProgress: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let label: String?

    init(
        progress: Double,
        color: Color = .furgMint,
        size: CGFloat = 80,
        lineWidth: CGFloat = 8,
        label: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.label = label
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let label = label {
                    Text(label)
                        .font(.system(size: size * 0.1))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Badges & Tags

struct FurgBadge: View {
    let text: String
    let color: Color
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 9
            case .medium: return 11
            case .large: return 13
            }
        }

        var padding: (h: CGFloat, v: CGFloat) {
            switch self {
            case .small: return (6, 3)
            case .medium: return (10, 5)
            case .large: return (14, 7)
            }
        }
    }

    init(_ text: String, color: Color = .furgMint, size: BadgeSize = .medium) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, size.padding.h)
            .padding(.vertical, size.padding.v)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct FurgStatusIndicator: View {
    let status: Status
    let showLabel: Bool

    enum Status {
        case success, warning, error, info, pending

        var color: Color {
            switch self {
            case .success: return .furgSuccess
            case .warning: return .furgWarning
            case .error: return .furgDanger
            case .info: return .furgInfo
            case .pending: return .white.opacity(0.5)
            }
        }

        var label: String {
            switch self {
            case .success: return "Success"
            case .warning: return "Warning"
            case .error: return "Error"
            case .info: return "Info"
            case .pending: return "Pending"
            }
        }
    }

    init(_ status: Status, showLabel: Bool = true) {
        self.status = status
        self.showLabel = showLabel
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            if showLabel {
                Text(status.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(status.color)
            }
        }
    }
}

// MARK: - Empty States

struct FurgEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            if let actionLabel = actionLabel, let action = action {
                FurgSecondaryButton(actionLabel, action: action)
                    .frame(width: 160)
            }
        }
        .padding(40)
    }
}

// MARK: - Dividers

struct FurgDivider: View {
    let opacity: Double

    init(opacity: Double = 0.1) {
        self.opacity = opacity
    }

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(opacity))
            .frame(height: 1)
    }
}

// MARK: - Category Icons

struct FurgCategoryIcon: View {
    let category: String
    let size: CGFloat

    init(_ category: String, size: CGFloat = 40) {
        self.category = category
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(categoryColor.opacity(0.2))
                .frame(width: size, height: size)

            Image(systemName: categoryIcon)
                .font(.system(size: size * 0.4))
                .foregroundColor(categoryColor)
        }
    }

    private var categoryIcon: String {
        switch category.lowercased() {
        case "food", "dining", "restaurants", "food & dining": return "fork.knife"
        case "shopping": return "bag.fill"
        case "transportation", "travel": return "car.fill"
        case "entertainment": return "film.fill"
        case "utilities": return "bolt.fill"
        case "health", "healthcare": return "heart.fill"
        case "groceries": return "cart.fill"
        case "subscriptions": return "repeat.circle.fill"
        case "income": return "arrow.down.circle.fill"
        default: return "dollarsign.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch category.lowercased() {
        case "food", "dining", "restaurants", "food & dining": return .orange
        case "shopping": return .pink
        case "transportation", "travel": return .blue
        case "entertainment": return .purple
        case "utilities": return .yellow
        case "health", "healthcare": return .red
        case "groceries": return .green
        case "subscriptions": return .indigo
        case "income": return .furgSuccess
        default: return .furgMint
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply standard animation for view entrance
    func furgEntrance(delay: Double = 0, animate: Bool) -> some View {
        self
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(delay), value: animate)
    }

    /// Apply standard card background
    func furgCardStyle(padding: CGFloat = 20, cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }

    /// Apply sheet presentation style
    func furgSheetStyle() -> some View {
        self
            .presentationBackground(Color.furgCharcoal)
            .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.furgCharcoal.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                FurgCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("This is a standard card component")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                FurgSectionHeader("Section Title", icon: "star.fill", actionLabel: "See All") {}

                FurgPrimaryButton("Primary Action", icon: "plus") {}

                FurgSecondaryButton("Secondary Action", icon: "arrow.right") {}

                FurgProgressBar(progress: 0.7, showLabel: true)

                HStack {
                    FurgCircularProgress(progress: 0.65, label: "complete")
                    Spacer()
                    FurgBadge("NEW", color: .furgSuccess)
                    FurgStatusIndicator(.success)
                }

                FurgCategoryIcon("Food & Dining")
            }
            .padding(20)
        }
    }
}
