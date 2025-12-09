//
//  MainTabView.swift
//  Furg
//
//  Side drawer navigation with floating action button
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationState = NavigationState()
    @EnvironmentObject var financeManager: FinanceManager

    var body: some View {
        ZStack {
            // Background
            CopilotBackground()

            // Main Content with Top Bar
            VStack(spacing: 0) {
                TopNavigationBar(
                    navigationState: navigationState,
                    onRefresh: handleRefresh,
                    onNotifications: handleNotifications
                )

                // Selected View Content
                selectedViewContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Side Drawer (slides from left)
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    SideDrawer(navigationState: navigationState, financeManager: financeManager)
                        .offset(x: navigationState.isDrawerOpen ? 0 : -280)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Dimmed overlay when drawer is open
                if navigationState.isDrawerOpen {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            navigationState.toggleDrawer()
                        }
                }
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
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // Swipe from left edge to open drawer
                    if gesture.startLocation.x < 50 && gesture.translation.width > 100 {
                        navigationState.toggleDrawer()
                    }
                    // Swipe right to close drawer
                    else if navigationState.isDrawerOpen && gesture.translation.width < -100 {
                        navigationState.toggleDrawer()
                    }
                }
        )
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var selectedViewContent: some View {
        switch navigationState.selectedView {
        case .dashboard:
            BalanceView()
        case .chat:
            ChatView()
        case .activity:
            TransactionsListView()
        case .accounts:
            AccountsView()
        case .settings:
            SettingsView()
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
