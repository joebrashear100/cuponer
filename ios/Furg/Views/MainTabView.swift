//
//  MainTabView.swift
//  Furg
//
//  Main tab bar container
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(0)

            BalanceView()
                .tabItem {
                    Label("Balance", systemImage: "dollarsign.circle.fill")
                }
                .tag(1)

            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "heart.fill")
                }
                .tag(2)

            PurchasePlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.orange)
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
}
