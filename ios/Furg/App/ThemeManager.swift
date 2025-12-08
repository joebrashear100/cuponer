//
//  ThemeManager.swift
//  Furg
//
//  Centralized theme management with dark mode polish
//

import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("app_theme") var appTheme: AppTheme = .system
    @AppStorage("haptics_enabled") var hapticsEnabled = true
    @AppStorage("reduce_motion") var reduceMotion = false
    @AppStorage("high_contrast") var highContrast = false

    @Published var currentScheme: ColorScheme = .dark

    private init() {}

    func updateColorScheme(_ scheme: ColorScheme?) {
        switch appTheme {
        case .system:
            currentScheme = scheme ?? .dark
        case .dark:
            currentScheme = .dark
        case .light:
            currentScheme = .light
        }
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

enum AppTheme: String, CaseIterable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

// MARK: - Enhanced Color Extensions

extension Color {
    // Adaptive colors that work well in both modes but optimized for dark
    static func adaptiveBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .furgCharcoal : .furgCream
    }

    static func adaptiveCardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .furgSlate : .furgMist
    }

    static func adaptiveText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .furgCharcoal
    }

    static func adaptiveSecondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.6) : .furgCharcoal.opacity(0.6)
    }

    static func adaptiveTertiaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.4) : .furgCharcoal.opacity(0.4)
    }

    static func adaptiveBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1)
    }
}

// MARK: - Dark Mode View Modifiers

struct DarkModeCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16
    var elevation: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.adaptiveCardBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.adaptiveBorder(colorScheme), lineWidth: 0.5)
            )
            .shadow(
                color: elevation ? Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1) : .clear,
                radius: elevation ? 10 : 0,
                y: elevation ? 4 : 0
            )
    }
}

struct EnhancedSheetBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.furgCharcoal)
            .preferredColorScheme(.dark) // Force dark mode for sheets
    }
}

struct AnimatedEntrance: ViewModifier {
    @State private var appeared = false
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : (appeared ? 0 : 20))
            .opacity(appeared ? 1 : 0)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.spring(response: 0.6).delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func darkModeCard(cornerRadius: CGFloat = 16, elevation: Bool = true) -> some View {
        modifier(DarkModeCard(cornerRadius: cornerRadius, elevation: elevation))
    }

    func enhancedSheetBackground() -> some View {
        modifier(EnhancedSheetBackground())
    }

    func animatedEntrance(delay: Double = 0, reduceMotion: Bool = false) -> some View {
        modifier(AnimatedEntrance(delay: delay, reduceMotion: reduceMotion))
    }

    func furgSheet() -> some View {
        self
            .presentationBackground(Color.furgCharcoal)
            .presentationDragIndicator(.visible)
    }
}

// MARK: - Enhanced Backgrounds

struct AdaptiveBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                FurgGradients.mainBackground
            } else {
                LinearGradient(
                    colors: [.furgCream, .furgMist],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct EnhancedMeshBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            if colorScheme == .dark {
                FurgGradients.mainBackground
            } else {
                LinearGradient(
                    colors: [.furgCream, .furgMist.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // Floating orbs (only in dark mode or non-reduced motion)
            if colorScheme == .dark {
                GlowingOrb(color: .furgMint.opacity(0.4), size: 300)
                    .offset(x: animate ? -50 : -100, y: animate ? -100 : -50)
                    .animation(
                        .easeInOut(duration: 8).repeatForever(autoreverses: true),
                        value: animate
                    )

                GlowingOrb(color: .furgSeafoam.opacity(0.3), size: 250)
                    .offset(x: animate ? 150 : 100, y: animate ? 200 : 250)
                    .animation(
                        .easeInOut(duration: 10).repeatForever(autoreverses: true),
                        value: animate
                    )

                GlowingOrb(color: .furgPistachio.opacity(0.2), size: 200)
                    .offset(x: animate ? -100 : -150, y: animate ? 400 : 350)
                    .animation(
                        .easeInOut(duration: 12).repeatForever(autoreverses: true),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}

// MARK: - Navigation Bar Appearance

struct DarkNavigationBarModifier: ViewModifier {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func darkNavigationBar() -> some View {
        modifier(DarkNavigationBarModifier())
    }
}

// MARK: - Tab Bar Appearance

struct DarkTabBarModifier: ViewModifier {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.furgCharcoal.opacity(0.95))

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.furgMint)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.furgMint)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func darkTabBar() -> some View {
        modifier(DarkTabBarModifier())
    }
}

// MARK: - Preview Helpers

struct ThemePreview<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dark mode preview
            content
                .preferredColorScheme(.dark)
                .frame(maxHeight: .infinity)

            Divider()

            // Light mode preview (though app is dark-focused)
            content
                .preferredColorScheme(.light)
                .frame(maxHeight: .infinity)
        }
    }
}
