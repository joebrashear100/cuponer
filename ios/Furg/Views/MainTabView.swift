//
//  MainTabView.swift
//  Furg
//
//  Gesture-based home hub navigation with minimal top bar
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
                // Minimal top bar
                MinimalTopBar(
                    navigationState: navigationState,
                    onRefresh: handleRefresh,
                    onNotifications: handleNotifications
                )

                // View content with gesture navigation
                selectedViewContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { gesture in
                                // Only enable swipes when not on hub
                                guard !navigationState.isHomeHub else { return }

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

            // Floating Action Button (bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
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
        case .hub:
            HomeHubView(navigationState: navigationState, financeManager: financeManager)
                .transition(.opacity)
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
