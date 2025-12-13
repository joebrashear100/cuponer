//
//  MainTabView.swift
//  Furg
//
//  Modern glassmorphism tab navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Namespace private var tabAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            AnimatedMeshBackground()

            // Content
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                case 1:
                    ChatView()
                case 2:
                    DealsView()
                case 3:
                    TransactionsListView()
                case 4:
                    SettingsView()
                default:
                    DashboardView()
                }
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, namespace: tabAnimation)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var namespace: Namespace.ID

    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("message.fill", "Chat"),
        ("tag.fill", "Deals"),
        ("list.bullet.rectangle", "Activity"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                TabBarButton(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    isSelected: selectedTab == index,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack {
                // Blur background
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.furgCharcoal.opacity(0.8),
                        Color.furgCharcoal.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Top border glow
                VStack {
                    LinearGradient(
                        colors: [Color.furgMint.opacity(0.3), Color.furgMint.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 1)
                    Spacer()
                }
            }
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
        .padding(.horizontal, 12)
        .padding(.bottom, -20)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.furgMint.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .matchedGeometryEffect(id: "tabBackground", in: namespace)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .furgMint : .white.opacity(0.4))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(width: 48, height: 48)

                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .furgMint : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccessibleTabButtonStyle(isSelected: isSelected))
        // Accessibility
        .accessibilityLabel(label)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(label)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
        .accessibilityRemoveTraits(isSelected ? [] : [.isSelected])
    }
}

// MARK: - Accessible Button Style
/// Custom button style that provides visual feedback while maintaining accessibility
private struct AccessibleTabButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(APIClient())
        .environmentObject(ChatManager())
        .environmentObject(FinanceManager())
        .environmentObject(PlaidManager())
        .environmentObject(WishlistManager())
        .environmentObject(GoalsManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(DealsManager())
}
