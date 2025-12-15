//
//  FurgAppV2.swift
//  Furg
//
//  Main container for V2 gesture-based navigation
//  - 3 pages: Dashboard, Spending, Accounts
//  - Horizontal swipe navigation
//  - 12 sheet overlays for sub-features
//  - Floating action menu
//

import SwiftUI

struct FurgAppV2: View {
    // MARK: - Navigation State
    @StateObject private var v2NavState = V2NavigationState()
    @State private var dragOffset: CGFloat = 0

    // MARK: - Sheet States (18 total)
    @State private var showChat = false
    @State private var showGoals = false
    @State private var showInsights = false
    @State private var showTransactions = false
    @State private var showSubscriptions = false
    @State private var showForecast = false
    @State private var showReceiptScanner = false
    @State private var showWishlist = false
    @State private var showFinancingCalculator = false
    @State private var showConnectBank = false
    @State private var showSpendingLimits = false
    @State private var showOffers = false
    @State private var showSettings = false
    // Premium Features
    @State private var showCardRecommendations = false
    @State private var showMerchantIntelligence = false
    @State private var showInvestmentPortfolio = false
    @State private var showLifeScenarios = false
    @State private var showCashFlow = false
    @State private var showDebtPayoff = false

    // MARK: - Floating Action Menu
    @State private var showActionMenu = false

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var goalsManager: GoalsManager
    @EnvironmentObject var plaidManager: PlaidManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.v2Background
                    .ignoresSafeArea()

                // Main Content with Swipe
                VStack(spacing: 0) {
                    // Top Bar
                    topBar

                    // Page Content
                    pageContent(geometry: geometry)

                    // Bottom Navigation
                    bottomNavigation
                }

                // Floating Action Button (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
            .gesture(swipeGesture)
        }
        // MARK: - Sheet Presentations
        .sheet(isPresented: $showChat) {
            ChatViewV2()
                .environmentObject(chatManager)
        }
        .sheet(isPresented: $showGoals) {
            GoalsV2()
                .environmentObject(goalsManager)
        }
        .sheet(isPresented: $showInsights) {
            InsightsV2()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showTransactions) {
            TransactionsV2()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showSubscriptions) {
            SubscriptionsViewV2()
        }
        .sheet(isPresented: $showForecast) {
            ForecastViewV2()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showReceiptScanner) {
            ReceiptScannerV2()
        }
        .sheet(isPresented: $showWishlist) {
            WishlistViewV2()
        }
        .sheet(isPresented: $showFinancingCalculator) {
            FinancingCalculatorV2()
        }
        .sheet(isPresented: $showConnectBank) {
            ConnectBankViewV2()
                .environmentObject(plaidManager)
        }
        .sheet(isPresented: $showSpendingLimits) {
            SpendingLimitsViewV2()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showOffers) {
            OffersViewV2()
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewV2()
                .environmentObject(authManager)
        }
        // Premium Features
        .sheet(isPresented: $showCardRecommendations) {
            CardRecommendationsView()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showMerchantIntelligence) {
            MerchantIntelligenceView()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showInvestmentPortfolio) {
            InvestmentPortfolioView()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showLifeScenarios) {
            LifeIntegrationView()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showCashFlow) {
            CashFlowView()
                .environmentObject(financeManager)
        }
        .sheet(isPresented: $showDebtPayoff) {
            DebtPayoffView()
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Logo
            Text("FURG")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.v2Primary)

            Spacer()

            // Refresh button
            Button {
                // Refresh data
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.v2TextSecondary)
            }

            // Settings button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.v2TextSecondary)
            }
            .padding(.leading, 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Page Content
    @ViewBuilder
    private func pageContent(geometry: GeometryProxy) -> some View {
        let pageWidth = geometry.size.width

        HStack(spacing: 0) {
            // Dashboard Page
            DashboardPageV2(
                onShowChat: { showChat = true },
                onShowGoals: { showGoals = true },
                onShowTransactions: { showTransactions = true }
            )
            .frame(width: pageWidth)

            // Spending Page
            SpendingPageV2(
                onShowInsights: { showInsights = true },
                onShowSpendingLimits: { showSpendingLimits = true }
            )
            .frame(width: pageWidth)

            // Accounts Page
            AccountsPageV2(
                onShowConnectBank: { showConnectBank = true }
            )
            .frame(width: pageWidth)
        }
        .offset(x: -CGFloat(v2NavState.currentPage.rawValue) * pageWidth + dragOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: v2NavState.currentPage)
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            // Dashboard tab
            tabButton(page: .dashboard)

            // Spending tab
            tabButton(page: .spending)

            // Accounts tab
            tabButton(page: .accounts)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.v2Background)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func tabButton(page: V2NavigationState.V2Page) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                v2NavState.currentPage = page
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: page.icon)
                    .font(.system(size: 22, weight: .medium))

                Text(page.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(v2NavState.currentPage == page ? .v2Primary : .gray)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Action Button
    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.v2Primary)

                Text(label)
                    .font(.v2Footnote)
                    .foregroundColor(.v2TextTertiary)
            }
            .frame(width: 50)
        }
    }

    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack(spacing: 12) {
            if showActionMenu {
                // Menu items - scrollable for more features
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        // Quick Tools Section
                        fabSectionHeader("Quick Tools")

                        fabMenuItem(icon: "doc.text.viewfinder", label: "Scan Receipt", color: .v2Teal) {
                            showReceiptScanner = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "chart.line.uptrend.xyaxis", label: "Cash Forecast", color: .v2Info) {
                            showForecast = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "dollarsign.arrow.circlepath", label: "Cash Flow", color: .v2Success) {
                            showCashFlow = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "percent", label: "Calculator", color: .v2Warning) {
                            showFinancingCalculator = true
                            showActionMenu = false
                        }

                        // Shopping Section
                        fabSectionHeader("Shopping")

                        fabMenuItem(icon: "tag.fill", label: "Offers", color: .v2Accent) {
                            showOffers = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "heart.fill", label: "Wishlist", color: .v2Premium) {
                            showWishlist = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "repeat.circle.fill", label: "Subscriptions", color: .orange) {
                            showSubscriptions = true
                            showActionMenu = false
                        }

                        // Premium Tools Section
                        fabSectionHeader("Premium Tools")

                        fabMenuItem(icon: "creditcard.fill", label: "Card Finder", color: .v2Primary) {
                            showCardRecommendations = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "storefront.fill", label: "Merchants", color: .cyan) {
                            showMerchantIntelligence = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "chart.pie.fill", label: "Investments", color: .green) {
                            showInvestmentPortfolio = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "calendar.badge.clock", label: "Life Scenarios", color: .purple) {
                            showLifeScenarios = true
                            showActionMenu = false
                        }

                        fabMenuItem(icon: "arrow.down.to.line.alt", label: "Debt Payoff", color: .red) {
                            showDebtPayoff = true
                            showActionMenu = false
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 400)
                .background(Color.v2CardBackgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            // Main FAB button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showActionMenu.toggle()
                }
            } label: {
                Image(systemName: showActionMenu ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.v2TextInverse)
                    .frame(width: 56, height: 56)
                    .background(V2Gradients.primary)
                    .clipShape(Circle())
                    .shadow(color: Color.v2Primary.opacity(0.4), radius: 12, y: 6)
            }
            .rotationEffect(.degrees(showActionMenu ? 45 : 0))
        }
    }

    // MARK: - FAB Section Header
    private func fabSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.v2TextTertiary)
                .tracking(0.5)
            Spacer()
        }
        .frame(width: 180)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - FAB Menu Item
    private func fabMenuItem(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(label)
                    .font(.v2CaptionMedium)
                    .foregroundColor(.v2TextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.v2TextTertiary)
            }
            .frame(width: 180)
        }
    }

    // MARK: - Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only respond to horizontal swipes
                if abs(value.translation.width) > abs(value.translation.height) {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                let velocity = value.predictedEndTranslation.width - value.translation.width

                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if value.translation.width > threshold || velocity > 200 {
                        v2NavState.swipeToPrevious()
                    } else if value.translation.width < -threshold || velocity < -200 {
                        v2NavState.swipeToNext()
                    }
                    dragOffset = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    FurgAppV2()
        .environmentObject(AuthManager())
        .environmentObject(FinanceManager())
        .environmentObject(ChatManager())
        .environmentObject(GoalsManager())
        .environmentObject(PlaidManager())
}
