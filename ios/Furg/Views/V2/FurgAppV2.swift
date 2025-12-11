//
//  FurgAppV2.swift
//  Furg
//
//  Main app container with horizontal swipe navigation
//  No bottom tab bar - uses gestures and floating action buttons
//

import SwiftUI

// MARK: - Main App Container V2

struct FurgAppV2: View {
    @State private var currentPage: AppPage = .dashboard
    @State private var dragOffset: CGFloat = 0
    @State private var showQuickActions = false
    @State private var showChat = false
    @State private var showGoals = false
    @State private var showInsights = false
    @State private var showTransactions = false
    // New V2 screens
    @State private var showSubscriptions = false
    @State private var showForecast = false
    @State private var showReceiptScanner = false
    @State private var showWishlist = false
    @State private var showFinancingCalculator = false
    @State private var showConnectBank = false
    @State private var showSpendingLimits = false
    @State private var showOffers = false

    enum AppPage: Int, CaseIterable {
        case dashboard = 0
        case spending = 1
        case accounts = 2

        var title: String {
            switch self {
            case .dashboard: return "Overview"
            case .spending: return "Spending"
            case .accounts: return "Accounts"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.v2Background.ignoresSafeArea()

            // Main content with swipe
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(AppPage.allCases, id: \.self) { page in
                        pageView(for: page)
                            .frame(width: geometry.size.width)
                    }
                }
                .offset(x: -CGFloat(currentPage.rawValue) * geometry.size.width + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            let velocity = value.predictedEndTranslation.width - value.translation.width

                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if value.translation.width > threshold || velocity > 300 {
                                    // Swipe right - go to previous page
                                    if currentPage.rawValue > 0 {
                                        currentPage = AppPage(rawValue: currentPage.rawValue - 1) ?? currentPage
                                    }
                                } else if value.translation.width < -threshold || velocity < -300 {
                                    // Swipe left - go to next page
                                    if currentPage.rawValue < AppPage.allCases.count - 1 {
                                        currentPage = AppPage(rawValue: currentPage.rawValue + 1) ?? currentPage
                                    }
                                }
                                dragOffset = 0
                            }
                        }
                )
            }

            // Floating elements
            VStack {
                Spacer()

                // Bottom navigation dots and FAB
                bottomNavigation
            }
        }
        .sheet(isPresented: $showChat) {
            ChatViewV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showGoals) {
            GoalsV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showInsights) {
            InsightsV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showTransactions) {
            FullTransactionsListV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showSubscriptions) {
            SubscriptionsViewV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showForecast) {
            ForecastViewV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showReceiptScanner) {
            ReceiptScannerV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showWishlist) {
            WishlistViewV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showFinancingCalculator) {
            FinancingCalculatorV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showConnectBank) {
            ConnectBankViewV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showSpendingLimits) {
            SpendingLimitsViewV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(isPresented: $showOffers) {
            OffersViewV2()
                .presentationBackground(Color.v2Background)
        }
    }

    // MARK: - Page Views

    @ViewBuilder
    func pageView(for page: AppPage) -> some View {
        switch page {
        case .dashboard:
            DashboardPageV2(
                showGoals: $showGoals,
                showInsights: $showInsights,
                showTransactions: $showTransactions
            )
        case .spending:
            SpendingPageV2()
        case .accounts:
            AccountsPageV2()
        }
    }

    // MARK: - Bottom Navigation

    var bottomNavigation: some View {
        HStack(spacing: 20) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(AppPage.allCases, id: \.self) { page in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage = page
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(currentPage == page ? Color.v2Mint : Color.white.opacity(0.3))
                                .frame(width: currentPage == page ? 8 : 6, height: currentPage == page ? 8 : 6)

                            if currentPage == page {
                                Text(page.title)
                                    .font(.v2CaptionSmall)
                                    .foregroundColor(.v2Mint)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.v2CardBackground.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            )

            Spacer()

            // Quick actions FAB
            Menu {
                Section("Quick Actions") {
                    Button {
                        showChat = true
                    } label: {
                        Label("Chat with AI", systemImage: "sparkles")
                    }

                    Button {
                        showReceiptScanner = true
                    } label: {
                        Label("Scan Receipt", systemImage: "camera.fill")
                    }

                    Button {
                        showTransactions = true
                    } label: {
                        Label("All Transactions", systemImage: "list.bullet")
                    }
                }

                Section("Features") {
                    Button {
                        showGoals = true
                    } label: {
                        Label("Goals", systemImage: "target")
                    }

                    Button {
                        showInsights = true
                    } label: {
                        Label("Insights", systemImage: "lightbulb.fill")
                    }

                    Button {
                        showForecast = true
                    } label: {
                        Label("Forecast", systemImage: "chart.line.uptrend.xyaxis")
                    }

                    Button {
                        showSubscriptions = true
                    } label: {
                        Label("Subscriptions", systemImage: "arrow.clockwise")
                    }

                    Button {
                        showSpendingLimits = true
                    } label: {
                        Label("Spending Limits", systemImage: "gauge.with.needle")
                    }
                }

                Section("Tools") {
                    Button {
                        showOffers = true
                    } label: {
                        Label("Offers & Cashback", systemImage: "tag.fill")
                    }

                    Button {
                        showWishlist = true
                    } label: {
                        Label("Wishlist", systemImage: "heart.fill")
                    }

                    Button {
                        showFinancingCalculator = true
                    } label: {
                        Label("Loan Calculator", systemImage: "percent")
                    }

                    Button {
                        showConnectBank = true
                    } label: {
                        Label("Connect Bank", systemImage: "building.columns.fill")
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.v2Mint, .v2Lime],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .v2Mint.opacity(0.4), radius: 10, y: 5)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.v2Background)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Dashboard Page

struct DashboardPageV2: View {
    @Binding var showGoals: Bool
    @Binding var showInsights: Bool
    @Binding var showTransactions: Bool

    @State private var monthlyBudget: Double = 2000
    @State private var totalSpent: Double = 1350
    @State private var monthlyIncome: Double = 4500
    @State private var showSettings = false
    @State private var showCategoryDetail: CategorySpendingV2?

    var remainingBudget: Double { monthlyBudget - totalSpent }
    var budgetProgress: Double { totalSpent / monthlyBudget }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                headerSection

                VStack(spacing: 20) {
                    // Hero card
                    heroCard

                    // Quick actions
                    quickActionsRow

                    // Budget chart
                    budgetChartCard

                    // Categories
                    categoriesSection

                    // Recent transactions
                    recentTransactionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for floating nav
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetV2()
                .presentationBackground(Color.v2Background)
        }
        .sheet(item: $showCategoryDetail) { category in
            CategoryDetailV2(category: category)
                .presentationBackground(Color.v2Background)
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.v2Caption)
                    .foregroundColor(.v2TextSecondary)
                Text("December 2025")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)
            }

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.v2TextSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.v2CardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    var heroCard: some View {
        V2Card(padding: 24) {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(.v2Mint)
                        Text(formatNumber(remainingBudget))
                            .font(.v2DisplayLarge)
                            .foregroundColor(.v2TextPrimary)
                    }

                    Text("left to spend this month")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)
                }

                // Progress
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(V2Gradients.budgetLine)
                                .frame(width: geo.size.width * min(budgetProgress, 1))
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("$\(Int(totalSpent)) spent")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                        Spacer()
                        Text("$\(Int(monthlyBudget)) budget")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
                }
            }
        }
    }

    var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButtonV2(icon: "target", label: "Goals", color: .v2Blue) {
                showGoals = true
            }
            QuickActionButtonV2(icon: "lightbulb.fill", label: "Insights", color: .v2Gold) {
                showInsights = true
            }
            QuickActionButtonV2(icon: "list.bullet", label: "Activity", color: .v2Purple) {
                showTransactions = true
            }
        }
    }

    var budgetChartCard: some View {
        V2Card {
            V2BudgetLineChart(
                dailySpending: generateSampleDailySpending(),
                monthlyBudget: monthlyBudget,
                daysInMonth: 31
            )
        }
    }

    var categoriesSection: some View {
        VStack(spacing: 12) {
            V2SectionHeader(title: "Top Categories")

            V2Card(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(sampleCategories.prefix(3), id: \.name) { category in
                        Button { showCategoryDetail = category } label: {
                            V2CategoryRow(
                                name: category.name,
                                icon: category.icon,
                                color: category.color,
                                spent: category.amount,
                                budget: category.budget
                            )
                        }
                        if category.name != sampleCategories.prefix(3).last?.name {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    var recentTransactionsSection: some View {
        VStack(spacing: 12) {
            V2SectionHeader(title: "Recent", action: "See all") {
                showTransactions = true
            }

            V2Card(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(sampleTransactionsV2.prefix(3)) { tx in
                        V2TransactionRow(
                            icon: tx.icon,
                            iconColor: tx.color,
                            merchant: tx.merchant,
                            category: tx.category,
                            amount: tx.amount,
                            date: tx.dateGroup
                        )
                        if tx.id != sampleTransactionsV2.prefix(3).last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    func generateSampleDailySpending() -> [DailySpendingPoint] {
        var cumulative: Double = 0
        return (1...15).map { day in
            let daily = Double.random(in: 30...120)
            cumulative += daily
            return DailySpendingPoint(day: day, amount: daily, cumulativeAmount: cumulative)
        }
    }

    var sampleCategories: [CategorySpendingV2] {
        [
            CategorySpendingV2(name: "Food & Dining", icon: "fork.knife", color: .v2CategoryFood, amount: 387, budget: 500),
            CategorySpendingV2(name: "Shopping", icon: "bag.fill", color: .v2CategoryShopping, amount: 264, budget: 300),
            CategorySpendingV2(name: "Transportation", icon: "car.fill", color: .v2CategoryTransport, amount: 156, budget: 200)
        ]
    }
}

// MARK: - Spending Page

struct SpendingPageV2: View {
    @State private var selectedTimeframe: Timeframe = .month

    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Spending")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Timeframe selector
                HStack(spacing: 8) {
                    ForEach(Timeframe.allCases, id: \.self) { tf in
                        Button {
                            withAnimation { selectedTimeframe = tf }
                        } label: {
                            Text(tf.rawValue)
                                .font(.v2Caption)
                                .foregroundColor(selectedTimeframe == tf ? .v2Background : .v2TextSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedTimeframe == tf ? Color.v2Mint : Color.v2CardBackground)
                                .cornerRadius(16)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Category donut
                V2Card {
                    V2CategoryDonut(categories: allCategories)
                }
                .padding(.horizontal, 20)

                // All categories list
                VStack(spacing: 12) {
                    V2SectionHeader(title: "All Categories")
                        .padding(.horizontal, 20)

                    V2Card(padding: 16) {
                        VStack(spacing: 0) {
                            ForEach(allCategories, id: \.name) { cat in
                                V2CategoryRow(
                                    name: cat.name,
                                    icon: cat.icon,
                                    color: cat.color,
                                    spent: cat.amount,
                                    budget: cat.budget
                                )
                                if cat.name != allCategories.last?.name {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
    }

    var allCategories: [CategorySpendingV2] {
        [
            CategorySpendingV2(name: "Food & Dining", icon: "fork.knife", color: .v2CategoryFood, amount: 387, budget: 500),
            CategorySpendingV2(name: "Shopping", icon: "bag.fill", color: .v2CategoryShopping, amount: 264, budget: 300),
            CategorySpendingV2(name: "Transportation", icon: "car.fill", color: .v2CategoryTransport, amount: 156, budget: 200),
            CategorySpendingV2(name: "Entertainment", icon: "tv.fill", color: .v2CategoryEntertainment, amount: 89, budget: 150),
            CategorySpendingV2(name: "Health", icon: "heart.fill", color: .v2CategoryHealth, amount: 45, budget: 100),
            CategorySpendingV2(name: "Travel", icon: "airplane", color: .v2CategoryTravel, amount: 320, budget: 400)
        ]
    }
}

// MARK: - Accounts Page

struct AccountsPageV2: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Accounts")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)
                    Spacer()

                    Button {
                        // Add account
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.v2Mint)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Net worth card
                V2Card(padding: 20) {
                    VStack(spacing: 8) {
                        Text("Net Worth")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.v2Mint)
                            Text("24,650")
                                .font(.v2DisplayMedium)
                                .foregroundColor(.v2TextPrimary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                            Text("+$1,240 this month")
                                .font(.v2CaptionSmall)
                        }
                        .foregroundColor(.v2Lime)
                    }
                }
                .padding(.horizontal, 20)

                // Account groups
                VStack(spacing: 12) {
                    V2SectionHeader(title: "Cash")
                        .padding(.horizontal, 20)

                    V2Card(padding: 16) {
                        VStack(spacing: 0) {
                            AccountRowV2(name: "Chase Checking", balance: 4250, icon: "building.columns.fill", color: .v2Blue)
                            Divider().background(Color.white.opacity(0.06))
                            AccountRowV2(name: "Savings", balance: 12400, icon: "banknote.fill", color: .v2Lime)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    V2SectionHeader(title: "Credit Cards")
                        .padding(.horizontal, 20)

                    V2Card(padding: 16) {
                        VStack(spacing: 0) {
                            AccountRowV2(name: "Apple Card", balance: -1200, icon: "creditcard.fill", color: .v2TextPrimary)
                            Divider().background(Color.white.opacity(0.06))
                            AccountRowV2(name: "Chase Sapphire", balance: -800, icon: "creditcard.fill", color: .v2Blue)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    V2SectionHeader(title: "Investments")
                        .padding(.horizontal, 20)

                    V2Card(padding: 16) {
                        AccountRowV2(name: "Robinhood", balance: 10000, icon: "chart.line.uptrend.xyaxis", color: .v2Lime)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
    }
}

struct AccountRowV2: View {
    let name: String
    let balance: Double
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            Text(name)
                .font(.v2Body)
                .foregroundColor(.v2TextPrimary)

            Spacer()

            Text(balance >= 0 ? "$\(Int(balance))" : "-$\(Int(abs(balance)))")
                .font(.v2BodyBold)
                .foregroundColor(balance >= 0 ? .v2TextPrimary : .v2Coral)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Action Button

struct QuickActionButtonV2: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            V2Card(padding: 14, cornerRadius: 16) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)

                    Text(label)
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FurgAppV2()
}
