//
//  WidgetColors.swift
//  FurgWidgets
//
//  Shared colors for widgets matching the main app design system
//

import SwiftUI

enum WidgetColors {
    // Primary colors
    static let mint = Color(red: 0.6, green: 0.95, blue: 0.85)
    static let seafoam = Color(red: 0.5, green: 0.9, blue: 0.8)
    static let sage = Color(red: 0.68, green: 0.88, blue: 0.76)

    // Semantic colors
    static let success = Color(red: 0.4, green: 0.85, blue: 0.6)
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.4)
    static let danger = Color(red: 1.0, green: 0.5, blue: 0.5)
    static let info = Color(red: 0.5, green: 0.8, blue: 1.0)

    // Background
    static let background = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.1, blue: 0.14),
            Color(red: 0.12, green: 0.16, blue: 0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Card background
    static let cardBackground = Color.white.opacity(0.08)
}
