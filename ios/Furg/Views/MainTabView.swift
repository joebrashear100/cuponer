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

            TransactionsView()
                .tabItem {
                    Label("Activity", systemImage: "list.bullet")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
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
}
