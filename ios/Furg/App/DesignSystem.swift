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
    static let furgInfo = Color(red: 0.5, green: 0.8, blue: 1.0)             // #80CCFF

    // Glass colors
    static let glassWhite = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.25)
    static let glassDark = Color.black.opacity(0.2)
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

struct GlassCard: ViewModifier {
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
        modifier(GlassCard(cornerRadius: cornerRadius, opacity: opacity))
    }

    func glassButton(isAccent: Bool = false) -> some View {
        modifier(GlassButton(isAccent: isAccent))
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

struct PillTabBar: View {
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
