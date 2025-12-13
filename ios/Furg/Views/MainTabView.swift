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
            Text("Tools Hub (TODO)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
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
