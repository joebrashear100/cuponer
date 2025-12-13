//
//  MainTabView.swift
//  Furg
//
//  Gesture-based navigation with pill indicator
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationState = NavigationState()
    @EnvironmentObject var financeManager: FinanceManager

    var body: some View {
        ZStack {
            // Background
            CopilotBackground()

            // Main content area
            VStack(spacing: 0) {
                // Top bar with FURG logo and actions
                HStack(spacing: 16) {
                    Text("FURG")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.furgMint)

                    Spacer()

                    // Refresh Button
                    Button(action: handleRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }

                    // Notifications
                    Button(action: handleNotifications) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 44, height: 44)

                            Circle()
                                .fill(Color.chartSpending)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: 10)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.95))

                // View content with gesture navigation
                selectedViewContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { gesture in
                                if gesture.translation.width > 0 {
                                    // Swipe right = previous
                                    navigationState.swipeToPrevious()
                                } else if gesture.translation.width < 0 {
                                    // Swipe left = next
                                    navigationState.swipeToNext()
                                }
                            }
                    )
            }

            // Floating pill (bottom left) and FAB (bottom right)
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    // Bottom left floating pill
                    BottomPill(navigationState: navigationState)
                        .padding(.leading, 20)
                        .padding(.bottom, 20)

                    Spacer()

                    // Bottom right FAB
                    FloatingActionButton()
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var selectedViewContent: some View {
        switch navigationState.currentView {
        case .dashboard:
            BalanceView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        case .chat:
            ChatView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        case .activity:
            TransactionsListView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        case .accounts:
            AccountsView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        case .tools:
            // TODO: ToolsHubView is fully implemented in Furg/Views/ToolsHubView.swift
            // Once pbxproj file references are manually added through Xcode, uncomment:
            // ToolsHubView()
            //     .transition(.asymmetric(
            //         insertion: .move(edge: .trailing),
            //         removal: .move(edge: .leading)
            //     ))
            //     .environmentObject(navigationState)
            PremiumToolsPlaceholder()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .environmentObject(navigationState)
        case .settings:
            SettingsView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        }
    }

    private func handleRefresh() {
        // TODO: Implement refresh logic
        print("Refresh tapped")
    }

    private func handleNotifications() {
        // TODO: Navigate to notifications view
        print("Notifications tapped")
    }
}

// MARK: - Premium Tools Placeholder
// Temporary display for Tools Hub (ToolsHubView.swift is fully implemented)
struct PremiumToolsPlaceholder: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Premium Tools")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    Text("ToolsHubView.swift is fully implemented with:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        FeatureItem(title: "Debt Payoff", icon: "chart.line.downtrend.xyaxis", color: Color(red: 0.95, green: 0.4, blue: 0.4))
                        FeatureItem(title: "Card Optimizer", icon: "creditcard.fill", color: Color(red: 0.6, green: 0.4, blue: 0.9))
                        FeatureItem(title: "Investments", icon: "chart.pie.fill", color: Color(red: 0.7, green: 0.4, blue: 0.9))
                        FeatureItem(title: "Merchant Intel", icon: "building.2.fill", color: Color(red: 0.4, green: 0.8, blue: 0.9))
                        FeatureItem(title: "Life Integration", icon: "heart.text.square.fill", color: Color(red: 0.9, green: 0.4, blue: 0.7))
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 100)
                }
            }
        }
    }
}

struct FeatureItem: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text("Feature implemented and ready")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
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
}
