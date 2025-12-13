//
//  AccountsView.swift
//  Furg
//
//  Accounts overview with net worth tracking and credit score
//  Inspired by Copilot Money's accounts and dashboard
//

import SwiftUI
import Charts

// MARK: - Account Models

struct Account: Identifiable {
    let id = UUID()
    let name: String
    let institution: String
    let type: AccountType
    let balance: Double
    let icon: String
    let color: Color
    let lastUpdated: Date
    var loanDetails: LoanDetails?
    var propertyDetails: PropertyDetails?
    var creditCardDetails: CreditCardDetails?
    var previousBalance: Double? // For calculating % change
    var isAsset: Bool { type != .creditCard && type != .loan && type != .mortgage && type != .studentLoan && type != .autoLoan }

    var balanceChange: Double? {
        guard let prev = previousBalance, prev != 0 else { return nil }
        return ((balance - prev) / abs(prev)) * 100
    }

    // TODO: Add AccountDetailView.swift to Xcode project
    /*
    /// Convert to AccountInfo for AccountDetailView
    func toAccountInfo() -> AccountInfo {
        let accountType: AccountInfo.AccountType
        switch type {
        case .checking: accountType = .checking
        case .savings: accountType = .savings
        case .investment, .crypto, .retirement: accountType = .investment
        case .creditCard: accountType = .credit
        default: accountType = .checking
        }

        return AccountInfo(
            name: name,
            institution: institution,
            type: accountType,
            balance: balance,
            change: balanceChange ?? 0,
            lastFour: "••••",
            interestRate: loanDetails?.interestRate ?? creditCardDetails?.apr,
            openedDate: lastUpdated.formatted(.dateTime.month().year()),
            color: color,
            icon: icon
        )
    }
    */
}

// MARK: - Credit Card Details

struct CreditCardDetails {
    let creditLimit: Double
    let currentBalance: Double
    let minimumPayment: Double
    let dueDate: Date
    let apr: Double
    let lastStatementBalance: Double

    var utilization: Double {
        guard creditLimit > 0 else { return 0 }
        return (currentBalance / creditLimit) * 100
    }

    var availableCredit: Double {
        creditLimit - currentBalance
    }

    var utilizationStatus: UtilizationStatus {
        switch utilization {
        case 0..<10: return .excellent
        case 10..<30: return .good
        case 30..<50: return .fair
        case 50..<75: return .poor
        default: return .critical
        }
    }

    enum UtilizationStatus {
        case excellent, good, fair, poor, critical

        var color: Color {
            switch self {
            case .excellent: return .furgMint
            case .good: return .furgSuccess
            case .fair: return .furgWarning
            case .poor: return .orange
            case .critical: return .furgDanger
            }
        }

        var label: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            case .critical: return "Critical"
            }
        }
    }
}

enum AccountType: String, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case investment = "Investment"
    case crypto = "Crypto"
    case creditCard = "Credit Card"
    case loan = "Loan"
    case mortgage = "Mortgage"
    case studentLoan = "Student Loan"
    case autoLoan = "Auto Loan"
    case property = "Real Estate"
    case retirement = "Retirement"

    var icon: String {
        switch self {
        case .checking: return "banknote"
        case .savings: return "building.columns"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .crypto: return "bitcoinsign.circle"
        case .creditCard: return "creditcard"
        case .loan: return "doc.text"
        case .mortgage: return "house.fill"
        case .studentLoan: return "graduationcap.fill"
        case .autoLoan: return "car.fill"
        case .property: return "house"
        case .retirement: return "chart.pie"
        }
    }

    var isLiability: Bool {
        switch self {
        case .creditCard, .loan, .mortgage, .studentLoan, .autoLoan:
            return true
        default:
            return false
        }
    }
}

// MARK: - Loan Details

struct LoanDetails {
    let originalAmount: Double
    let interestRate: Double
    let monthlyPayment: Double
    let remainingBalance: Double
    let termMonths: Int
    let startDate: Date
    let payoffDate: Date

    var totalPaid: Double { originalAmount - remainingBalance }
    var percentPaid: Double { totalPaid / originalAmount * 100 }
    var monthsRemaining: Int {
        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: payoffDate).month ?? 0
        return max(0, months)
    }
    var totalInterest: Double { (monthlyPayment * Double(termMonths)) - originalAmount }
}

// MARK: - Property Details

struct PropertyDetails {
    let address: String
    let purchasePrice: Double
    let purchaseDate: Date
    let currentValue: Double
    let propertyType: PropertyType
    let squareFeet: Int?
    let bedrooms: Int?
    let bathrooms: Double?
    let mortgageBalance: Double?
    let monthlyRent: Double? // If rental property
    let zestimateHistory: [PropertyValuePoint]

    var equity: Double {
        currentValue - (mortgageBalance ?? 0)
    }
    var appreciation: Double {
        currentValue - purchasePrice
    }
    var appreciationPercent: Double {
        (appreciation / purchasePrice) * 100
    }
}

enum PropertyType: String, CaseIterable {
    case primaryResidence = "Primary Residence"
    case investmentProperty = "Investment Property"
    case vacationHome = "Vacation Home"
    case land = "Land"

    var icon: String {
        switch self {
        case .primaryResidence: return "house.fill"
        case .investmentProperty: return "building.2.fill"
        case .vacationHome: return "sun.horizon.fill"
        case .land: return "map.fill"
        }
    }
}

struct PropertyValuePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct NetWorthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let assets: Double
    let liabilities: Double
    var netWorth: Double { assets - liabilities }
}

struct CreditScoreData {
    let score: Int
    let rating: String
    let change: Int
    let factors: [CreditFactor]
    let lastUpdated: Date
}

struct CreditFactor: Identifiable {
    let id = UUID()
    let name: String
    let status: FactorStatus
    let description: String
    let icon: String
}

enum FactorStatus {
    case excellent, good, fair, poor

    var color: Color {
        switch self {
        case .excellent: return .furgMint
        case .good: return .furgSuccess
        case .fair: return .furgWarning
        case .poor: return .furgDanger
        }
    }
}

// MARK: - Accounts View

struct AccountsView: View {
    @State private var selectedSection: AccountSection = .netWorth
    @State private var animate = false
    @State private var showAddAccount = false
    @State private var selectedAccount: Account?
    @State private var showAccountDetail = false

    enum AccountSection: String, CaseIterable {
        case netWorth = "Net Worth"
        case accounts = "Accounts"
        case credit = "Credit Score"
    }

    // Demo data
    var accounts: [Account] {
        let calendar = Calendar.current
        let now = Date()

        // Property value history
        let propertyHistory = (0..<12).map { i in
            PropertyValuePoint(
                date: calendar.date(byAdding: .month, value: -i, to: now)!,
                value: 425000 + Double(12-i) * Double.random(in: 2000...5000)
            )
        }

        return [
            // Cash & Savings
            Account(name: "Primary Checking", institution: "Chase", type: .checking, balance: 4520.45, icon: "building.columns.fill", color: .blue, lastUpdated: now, loanDetails: nil, propertyDetails: nil, creditCardDetails: nil, previousBalance: 4180.20),
            Account(name: "High Yield Savings", institution: "Marcus", type: .savings, balance: 15230.00, icon: "banknote.fill", color: .furgMint, lastUpdated: now, loanDetails: nil, propertyDetails: nil, creditCardDetails: nil, previousBalance: 14850.00),

            // Investments
            Account(name: "Investment Portfolio", institution: "Fidelity", type: .investment, balance: 45670.23, icon: "chart.line.uptrend.xyaxis", color: .purple, lastUpdated: now, loanDetails: nil, propertyDetails: nil, creditCardDetails: nil, previousBalance: 43520.00),
            Account(name: "401(k)", institution: "Vanguard", type: .retirement, balance: 82450.00, icon: "chart.pie.fill", color: .orange, lastUpdated: now, loanDetails: nil, propertyDetails: nil, creditCardDetails: nil, previousBalance: 79800.00),
            Account(name: "Bitcoin Wallet", institution: "Coinbase", type: .crypto, balance: 8234.56, icon: "bitcoinsign.circle.fill", color: .yellow, lastUpdated: now, loanDetails: nil, propertyDetails: nil, creditCardDetails: nil, previousBalance: 7890.00),

            // Real Estate
            Account(
                name: "123 Main St", institution: "Zillow", type: .property, balance: 485000.00,
                icon: "house.fill", color: .cyan, lastUpdated: now, loanDetails: nil,
                propertyDetails: PropertyDetails(
                    address: "123 Main Street, Austin, TX 78701",
                    purchasePrice: 380000,
                    purchaseDate: calendar.date(byAdding: .year, value: -3, to: now)!,
                    currentValue: 485000,
                    propertyType: .primaryResidence,
                    squareFeet: 2200,
                    bedrooms: 4,
                    bathrooms: 2.5,
                    mortgageBalance: 298000,
                    monthlyRent: nil,
                    zestimateHistory: propertyHistory
                )
            ),

            // Credit Cards
            Account(
                name: "Sapphire Reserve", institution: "Chase", type: .creditCard, balance: -2340.50,
                icon: "creditcard.fill", color: .indigo, lastUpdated: now, loanDetails: nil, propertyDetails: nil,
                creditCardDetails: CreditCardDetails(
                    creditLimit: 15000,
                    currentBalance: 2340.50,
                    minimumPayment: 85,
                    dueDate: calendar.date(byAdding: .day, value: 12, to: now)!,
                    apr: 24.99,
                    lastStatementBalance: 1890
                ),
                previousBalance: -2150.00
            ),

            // Loans
            Account(
                name: "Home Mortgage", institution: "Wells Fargo", type: .mortgage, balance: -298000.00,
                icon: "house.fill", color: .red, lastUpdated: now,
                loanDetails: LoanDetails(
                    originalAmount: 350000,
                    interestRate: 6.25,
                    monthlyPayment: 2156,
                    remainingBalance: 298000,
                    termMonths: 360,
                    startDate: calendar.date(byAdding: .year, value: -3, to: now)!,
                    payoffDate: calendar.date(byAdding: .year, value: 27, to: now)!
                ),
                propertyDetails: nil
            ),
            Account(
                name: "Student Loans", institution: "Nelnet", type: .studentLoan, balance: -24500.00,
                icon: "graduationcap.fill", color: .orange, lastUpdated: now,
                loanDetails: LoanDetails(
                    originalAmount: 45000,
                    interestRate: 5.5,
                    monthlyPayment: 485,
                    remainingBalance: 24500,
                    termMonths: 120,
                    startDate: calendar.date(byAdding: .year, value: -5, to: now)!,
                    payoffDate: calendar.date(byAdding: .year, value: 5, to: now)!
                ),
                propertyDetails: nil
            ),
            Account(
                name: "Auto Loan", institution: "Toyota Finance", type: .autoLoan, balance: -18500.00,
                icon: "car.fill", color: .green, lastUpdated: now,
                loanDetails: LoanDetails(
                    originalAmount: 32000,
                    interestRate: 4.9,
                    monthlyPayment: 580,
                    remainingBalance: 18500,
                    termMonths: 60,
                    startDate: calendar.date(byAdding: .year, value: -2, to: now)!,
                    payoffDate: calendar.date(byAdding: .year, value: 3, to: now)!
                ),
                propertyDetails: nil
            ),
        ]
    }

    var netWorthHistory: [NetWorthDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { i in
            let date = calendar.date(byAdding: .month, value: -i, to: now)!
            let baseAssets = 140000.0
            let baseLiabilities = 22000.0
            return NetWorthDataPoint(
                date: date,
                assets: baseAssets + Double(12-i) * Double.random(in: 1500...3500),
                liabilities: baseLiabilities - Double(12-i) * Double.random(in: 200...500)
            )
        }
    }

    var creditScore: CreditScoreData {
        CreditScoreData(
            score: 752,
            rating: "Very Good",
            change: 12,
            factors: [
                CreditFactor(name: "Payment History", status: .excellent, description: "100% on-time payments", icon: "checkmark.circle.fill"),
                CreditFactor(name: "Credit Utilization", status: .good, description: "23% used", icon: "chart.bar.fill"),
                CreditFactor(name: "Credit Age", status: .fair, description: "4 years average", icon: "clock.fill"),
                CreditFactor(name: "Credit Mix", status: .good, description: "3 account types", icon: "square.stack.3d.up.fill"),
                CreditFactor(name: "Hard Inquiries", status: .excellent, description: "1 in last 2 years", icon: "magnifyingglass")
            ],
            lastUpdated: Date()
        )
    }

    var totalAssets: Double { accounts.filter { $0.isAsset }.reduce(0) { $0 + $1.balance } }
    var totalLiabilities: Double { accounts.filter { !$0.isAsset }.reduce(0) { $0 + abs($1.balance) } }
    var netWorth: Double { totalAssets - totalLiabilities }

    // MARK: - Account Performance Summary

    private var accountPerformanceSummary: some View {
        let performingAccounts = accounts.filter { $0.balanceChange != nil }
        let topGainers = performingAccounts.sorted { ($0.balanceChange ?? 0) > ($1.balanceChange ?? 0) }.prefix(3)
        let topLosers = performingAccounts.sorted { ($0.balanceChange ?? 0) < ($1.balanceChange ?? 0) }.prefix(2)

        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.furgMint)
                Text("Account Performance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            if !topGainers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Top Growth")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.furgSuccess)
                    }

                    ForEach(Array(topGainers), id: \.id) { account in
                        PerformanceAccountRow(account: account, isPositive: true)
                    }
                }
            }

            if !topLosers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Needs Attention")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.furgError)
                    }

                    ForEach(Array(topLosers), id: \.id) { account in
                        PerformanceAccountRow(account: account, isPositive: false)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    header
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // Section selector
                    sectionSelector
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)

                    // Content based on selection
                    switch selectedSection {
                    case .netWorth:
                        netWorthSection
                    case .accounts:
                        accountsSection
                    case .credit:
                        creditScoreSection
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
        }
        // TODO: Add AccountDetailView.swift to Xcode project
        /*
        .sheet(isPresented: $showAccountDetail) {
            if let account = selectedAccount {
                AccountDetailView(account: account.toAccountInfo())
            }
        }
        */
    }

    // MARK: - Helper to convert Account to AccountInfo

    private func selectAccount(_ account: Account) {
        selectedAccount = account
        showAccountDetail = true
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Accounts")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Last synced just now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                showAddAccount = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Section Selector

    private var sectionSelector: some View {
        HStack(spacing: 8) {
            ForEach(AccountSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSection = section
                    }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedSection == section ? .furgCharcoal : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSection == section ? Color.furgMint : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }

    // MARK: - Net Worth Section

    private var netWorthSection: some View {
        VStack(spacing: 20) {
            // Net worth card
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Total Net Worth")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text(formatCurrency(netWorth))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))

                        Text("+$4,230 (2.8%) this month")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.furgSuccess)
                }

                // Assets vs Liabilities
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.furgMint)
                                .frame(width: 8, height: 8)

                            Text("Assets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Text(formatCurrency(totalAssets))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Liabilities")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            Circle()
                                .fill(Color.furgDanger)
                                .frame(width: 8, height: 8)
                        }

                        Text(formatCurrency(totalLiabilities))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.1), value: animate)

            // Net worth chart
            VStack(alignment: .leading, spacing: 16) {
                Text("Net Worth Over Time")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Chart {
                    ForEach(netWorthHistory) { point in
                        LineMark(
                            x: .value("Month", point.date),
                            y: .value("Net Worth", point.netWorth)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Month", point.date),
                            y: .value("Net Worth", point.netWorth)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgMint.opacity(0.3), .furgMint.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatCompact(amount))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.white.opacity(0.1))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .frame(height: 180)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.2), value: animate)

            // Account Performance Summary
            accountPerformanceSummary
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.35), value: animate)

            // Asset allocation
            VStack(alignment: .leading, spacing: 16) {
                Text("Asset Allocation")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                let assetAccounts = accounts.filter { $0.isAsset }
                Chart(assetAccounts) { account in
                    SectorMark(
                        angle: .value("Balance", account.balance),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(account.color.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(assetAccounts) { account in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(account.color)
                                .frame(width: 8, height: 8)

                            Text(account.type.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            Text("\(Int((account.balance / totalAssets) * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.3), value: animate)

            // Debt Payoff Tracker
            debtPayoffSection
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.4), value: animate)

            // Financial Insights
            financialInsightsSection
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.5), value: animate)
        }
    }

    // MARK: - Debt Payoff Section

    private var debtPayoffSection: some View {
        let debtAccounts = accounts.filter { $0.type.isLiability && $0.loanDetails != nil }

        return Group {
            if !debtAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .foregroundColor(.furgMint)
                        Text("Debt Payoff Progress")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(Int(totalDebtPaidPercent))% paid")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.furgMint)
                    }

                    ForEach(debtAccounts) { account in
                        if let loan = account.loanDetails {
                            DebtProgressRow(account: account, loan: loan)
                        }
                    }

                    // Summary stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Total Debt")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            Text(formatCurrency(totalLiabilities))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.furgDanger)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("Monthly Payments")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            Text(formatCurrency(totalMonthlyPayments))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("Debt-Free Date")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            Text(debtFreeDate)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.furgSuccess)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    private var totalDebtPaidPercent: Double {
        let debtAccounts = accounts.filter { $0.type.isLiability && $0.loanDetails != nil }
        guard !debtAccounts.isEmpty else { return 0 }
        let totalOriginal = debtAccounts.compactMap { $0.loanDetails?.originalAmount }.reduce(0, +)
        let totalRemaining = debtAccounts.compactMap { $0.loanDetails?.remainingBalance }.reduce(0, +)
        guard totalOriginal > 0 else { return 0 }
        return ((totalOriginal - totalRemaining) / totalOriginal) * 100
    }

    private var totalMonthlyPayments: Double {
        accounts.filter { $0.type.isLiability && $0.loanDetails != nil }
            .compactMap { $0.loanDetails?.monthlyPayment }
            .reduce(0, +)
    }

    private var debtFreeDate: String {
        let debtAccounts = accounts.filter { $0.type.isLiability && $0.loanDetails != nil }
        guard let latestPayoff = debtAccounts.compactMap({ $0.loanDetails?.payoffDate }).max() else {
            return "N/A"
        }
        return latestPayoff.formatted(.dateTime.month(.abbreviated).year())
    }

    // MARK: - Financial Insights Section

    private var financialInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.furgMint)
                Text("Financial Insights")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Generate insights based on data
            ForEach(generateInsights(), id: \.title) { insight in
                InsightRow(icon: insight.icon, color: insight.iconColor, text: insight.description)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private func generateInsights() -> [AccountInsight] {
        var insights: [AccountInsight] = []

        // Emergency fund check
        let liquidAssets = accounts.filter { $0.type == .checking || $0.type == .savings }
            .reduce(0) { $0 + $1.balance }
        let monthlyExpenses = totalMonthlyPayments + 2500 // Estimate

        if liquidAssets < monthlyExpenses * 3 {
            insights.append(AccountInsight(
                icon: "exclamationmark.shield.fill",
                iconColor: .furgWarning,
                title: "Emergency Fund Low",
                description: "You have \(formatCurrency(liquidAssets)) in liquid assets. Aim for 3-6 months of expenses (\(formatCurrency(monthlyExpenses * 3))-\(formatCurrency(monthlyExpenses * 6))).",
                actionLabel: "Build Savings"
            ))
        }

        // Credit utilization check
        if let ccAccount = accounts.first(where: { $0.creditCardDetails != nil }),
           let cc = ccAccount.creditCardDetails,
           cc.utilization > 30 {
            insights.append(AccountInsight(
                icon: "creditcard.trianglebadge.exclamationmark.fill",
                iconColor: .furgDanger,
                title: "High Credit Utilization",
                description: "Your credit utilization is \(Int(cc.utilization))%. Keeping it below 30% helps your credit score.",
                actionLabel: "Pay Down Balance"
            ))
        }

        // Investment diversification
        let investmentBalance = accounts.filter { $0.type == .investment || $0.type == .retirement }
            .reduce(0) { $0 + $1.balance }
        if investmentBalance > 50000 {
            insights.append(AccountInsight(
                icon: "chart.pie.fill",
                iconColor: .furgSuccess,
                title: "Strong Investment Portfolio",
                description: "You've built \(formatCurrency(investmentBalance)) in investments. Consider rebalancing annually.",
                actionLabel: "Review Allocation"
            ))
        }

        // Property equity
        if let propertyAccount = accounts.first(where: { $0.propertyDetails != nil }),
           let property = propertyAccount.propertyDetails {
            insights.append(AccountInsight(
                icon: "house.fill",
                iconColor: .cyan,
                title: "Home Equity: \(formatCurrency(property.equity))",
                description: "Your property has appreciated \(String(format: "%.1f", property.appreciationPercent))% since purchase.",
                actionLabel: "View Details"
            ))
        }

        // Net worth milestone
        if netWorth > 100000 {
            insights.append(AccountInsight(
                icon: "star.fill",
                iconColor: .furgMint,
                title: "Net Worth Milestone",
                description: "Congratulations! You've crossed \(formatCurrency(Double(Int(netWorth / 50000) * 50000))) in net worth.",
                actionLabel: nil
            ))
        }

        return insights
    }

    // MARK: - Accounts Section

    private var accountsSection: some View {
        VStack(spacing: 16) {
            // Group by type
            let groupedAccounts = Dictionary(grouping: accounts) { $0.type }

            ForEach(AccountType.allCases, id: \.self) { type in
                if let typeAccounts = groupedAccounts[type], !typeAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(type.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))

                            Spacer()

                            Text(formatCurrency(typeAccounts.reduce(0) { $0 + $1.balance }))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4)

                        ForEach(typeAccounts) { account in
                            Button {
                                selectAccount(account)
                            } label: {
                                AccountRow(account: account)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                }
            }
        }
    }

    // MARK: - Credit Score Section

    private var creditScoreSection: some View {
        VStack(spacing: 20) {
            // Score gauge
            VStack(spacing: 20) {
                ZStack {
                    // Background arc
                    Circle()
                        .trim(from: 0.25, to: 0.75)
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)
                        .rotationEffect(.degrees(180))
                        .frame(width: 200, height: 200)

                    // Score arc
                    Circle()
                        .trim(from: 0.25, to: 0.25 + (Double(creditScore.score - 300) / 550) * 0.5)
                        .stroke(
                            LinearGradient(
                                colors: scoreGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(180))
                        .frame(width: 200, height: 200)

                    VStack(spacing: 4) {
                        Text("\(creditScore.score)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.white)

                        Text(creditScore.rating)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.furgMint)

                        HStack(spacing: 4) {
                            Image(systemName: creditScore.change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .bold))

                            Text("\(abs(creditScore.change)) pts")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(creditScore.change > 0 ? .furgSuccess : .furgDanger)
                    }
                }

                // Score range labels
                HStack {
                    Text("300")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))

                    Spacer()

                    Text("850")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 40)

                Text("Updated \(creditScore.lastUpdated.formatted(.dateTime.month().day()))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            // Credit factors
            VStack(alignment: .leading, spacing: 16) {
                Text("Credit Factors")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                ForEach(creditScore.factors) { factor in
                    CreditFactorRow(factor: factor)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.1), value: animate)

            // Tips card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.furgWarning)

                    Text("Tips to Improve")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Keep your credit utilization below 30% and avoid opening new accounts to improve your score.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.furgWarning.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.furgWarning.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.2), value: animate)
        }
    }

    private var scoreGradientColors: [Color] {
        if creditScore.score >= 750 {
            return [.furgMint, .furgSeafoam]
        } else if creditScore.score >= 700 {
            return [.furgSuccess, .furgMint]
        } else if creditScore.score >= 650 {
            return [.furgWarning, .furgSuccess]
        } else {
            return [.furgDanger, .furgWarning]
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatCompact(_ amount: Double) -> String {
        if amount >= 1000000 {
            return String(format: "$%.1fM", amount / 1000000)
        } else if amount >= 1000 {
            return String(format: "$%.0fK", amount / 1000)
        }
        return String(format: "$%.0f", amount)
    }
}

// MARK: - Account Row

private struct AccountRow: View {
    let account: Account

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(account.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: account.icon)
                        .font(.system(size: 18))
                        .foregroundColor(account.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Text(account.institution)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(account.balance))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(account.balance < 0 ? .furgDanger : .white)

                    // Balance change indicator
                    if let change = account.balanceChange {
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(String(format: "%.1f%%", abs(change)))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(changeColor(for: change, isLiability: account.type.isLiability))
                    }
                }
            }

            // Credit card utilization section
            if let ccDetails = account.creditCardDetails {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 12)

                VStack(spacing: 10) {
                    // Utilization bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Credit Utilization")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            Spacer()

                            Text(String(format: "%.0f%%", ccDetails.utilization))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(ccDetails.utilizationStatus.color)

                            Text("• \(ccDetails.utilizationStatus.label)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ccDetails.utilizationStatus.color.opacity(0.8))
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ccDetails.utilizationStatus.color)
                                    .frame(width: geo.size.width * min(ccDetails.utilization / 100, 1.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    // Credit details row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Available")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                            Text(formatCurrency(ccDetails.availableCredit))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.furgMint)
                        }

                        Spacer()

                        VStack(alignment: .center, spacing: 2) {
                            Text("Limit")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                            Text(formatCurrency(ccDetails.creditLimit))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Due")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                            Text(ccDetails.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.furgWarning)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private func changeColor(for change: Double, isLiability: Bool) -> Color {
        // For liabilities (debt), decrease is good (green), increase is bad (red)
        // For assets, increase is good (green), decrease is bad (red)
        if isLiability {
            return change <= 0 ? .furgSuccess : .furgDanger
        } else {
            return change >= 0 ? .furgSuccess : .furgDanger
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Credit Factor Row

private struct CreditFactorRow: View {
    let factor: CreditFactor

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(factor.status.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: factor.icon)
                    .font(.system(size: 16))
                    .foregroundColor(factor.status.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(factor.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(factor.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text(statusLabel(factor.status))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(factor.status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(factor.status.color.opacity(0.15))
                )
        }
        .padding(.vertical, 8)
    }

    private func statusLabel(_ status: FactorStatus) -> String {
        switch status {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

// MARK: - Add Account Sheet

private struct AddAccountSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Connect your bank to automatically sync your accounts")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        // Connect with Plaid
                    } label: {
                        HStack {
                            Image(systemName: "building.columns.fill")
                            Text("Connect Bank Account")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.furgCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Button {
                        // Manual add
                    } label: {
                        Text("Add Account Manually")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.furgMint)
                    }

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

// MARK: - Performance Account Row

private struct PerformanceAccountRow: View {
    let account: Account
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(account.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: account.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(account.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Text(account.institution)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            if let change = account.balanceChange {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%.1f%%", abs(change)))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(isPositive ? .furgSuccess : .furgError)

                    Text(formatCurrency(account.balance))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Account Insight Model

private struct AccountInsight {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let actionLabel: String?
}

// MARK: - Debt Progress Row

private struct DebtProgressRow: View {
    let account: Account
    let loan: LoanDetails

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(account.color.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: account.type.icon)
                            .font(.system(size: 12))
                            .foregroundColor(account.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text("\(loan.monthsRemaining) months remaining")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(loan.remainingBalance))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(String(format: "%.1f", loan.percentPaid))% paid")
                        .font(.system(size: 10))
                        .foregroundColor(.furgMint)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(loan.percentPaid / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}


#Preview {
    AccountsView()
}
