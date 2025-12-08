//
//  InvestmentPortfolioManager.swift
//  Furg
//
//  Created for radical life integration - investment portfolio tracking
//

import Foundation
import Combine

// MARK: - Investment Models

struct BrokerageAccount: Identifiable, Codable {
    let id: String
    let brokerage: BrokerageType
    let accountType: AccountType
    let accountName: String
    let accountNumber: String // Last 4 digits
    var holdings: [Holding]
    var cashBalance: Double
    var totalValue: Double
    var dayChange: Double
    var dayChangePercent: Double
    var totalGain: Double
    var totalGainPercent: Double
    var lastUpdated: Date
    var isConnected: Bool
}

enum BrokerageType: String, Codable, CaseIterable {
    case fidelity = "Fidelity"
    case schwab = "Charles Schwab"
    case vanguard = "Vanguard"
    case etrade = "E*TRADE"
    case tdAmeritrade = "TD Ameritrade"
    case robinhood = "Robinhood"
    case interactiveBrokers = "Interactive Brokers"
    case merrillEdge = "Merrill Edge"
    case wellsFargo = "Wells Fargo"
    case morganStanley = "Morgan Stanley"
    case betterment = "Betterment"
    case wealthfront = "Wealthfront"
    case sofi = "SoFi"
    case webull = "Webull"
    case publicApp = "Public"
    case acorns = "Acorns"
    case stash = "Stash"
    case m1Finance = "M1 Finance"
    case ally = "Ally Invest"
    case firstrade = "Firstrade"

    var iconName: String {
        return "building.columns.fill"
    }

    var color: String {
        switch self {
        case .fidelity: return "#4CAF50"
        case .schwab: return "#00A3E0"
        case .vanguard: return "#B71C1C"
        case .robinhood: return "#00C805"
        case .betterment: return "#0091EA"
        default: return "#607D8B"
        }
    }
}

enum AccountType: String, Codable, CaseIterable {
    case individual = "Individual Brokerage"
    case joint = "Joint Brokerage"
    case traditionalIRA = "Traditional IRA"
    case rothIRA = "Roth IRA"
    case sep = "SEP IRA"
    case simple = "SIMPLE IRA"
    case rollover = "Rollover IRA"
    case k401 = "401(k)"
    case k403b = "403(b)"
    case hsa = "HSA"
    case education529 = "529 Plan"
    case coverdell = "Coverdell ESA"
    case custodial = "Custodial (UGMA/UTMA)"
    case trust = "Trust"
    case crypto = "Crypto"
}

struct Holding: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    let assetType: AssetType
    var shares: Double
    var averageCost: Double
    var currentPrice: Double
    var marketValue: Double
    var dayChange: Double
    var dayChangePercent: Double
    var totalGain: Double
    var totalGainPercent: Double
    var percentOfPortfolio: Double
    var dividendYield: Double?
    var lastDividend: DividendInfo?
    var sector: String?
    var peRatio: Double?
    var fiftyTwoWeekHigh: Double?
    var fiftyTwoWeekLow: Double?
}

enum AssetType: String, Codable, CaseIterable {
    case stock = "Stock"
    case etf = "ETF"
    case mutualFund = "Mutual Fund"
    case bond = "Bond"
    case bondFund = "Bond Fund"
    case reit = "REIT"
    case crypto = "Cryptocurrency"
    case option = "Options"
    case cash = "Cash"
    case moneyMarket = "Money Market"
    case cd = "CD"
    case other = "Other"
}

struct DividendInfo: Codable {
    let amount: Double
    let frequency: DividendFrequency
    let exDate: Date?
    let payDate: Date?
    let annualAmount: Double
}

enum DividendFrequency: String, Codable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnual = "Semi-Annual"
    case annual = "Annual"
    case irregular = "Irregular"
}

struct Transaction: Identifiable, Codable {
    let id: String
    let accountId: String
    let date: Date
    let type: TransactionType
    let symbol: String?
    let shares: Double?
    let price: Double?
    let amount: Double
    let description: String
    let status: TransactionStatus
}

enum TransactionType: String, Codable {
    case buy = "Buy"
    case sell = "Sell"
    case dividend = "Dividend"
    case interest = "Interest"
    case deposit = "Deposit"
    case withdrawal = "Withdrawal"
    case transfer = "Transfer"
    case fee = "Fee"
    case split = "Stock Split"
    case merger = "Merger"
    case spinoff = "Spinoff"
    case reinvestment = "Dividend Reinvestment"
}

enum TransactionStatus: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case failed = "Failed"
}

// MARK: - Portfolio Analytics

struct PortfolioSummary: Codable {
    let totalValue: Double
    let totalCost: Double
    let totalGain: Double
    let totalGainPercent: Double
    let dayChange: Double
    let dayChangePercent: Double
    let cashTotal: Double
    let investedTotal: Double
    let accountCount: Int
    let holdingCount: Int
    let lastUpdated: Date
}

struct AssetAllocation: Codable {
    let assetType: AssetType
    let value: Double
    let percentage: Double
    let holdings: [String] // symbols
}

struct SectorAllocation: Codable {
    let sector: String
    let value: Double
    let percentage: Double
    let holdings: [String]
}

struct PerformanceData: Codable {
    let period: PerformancePeriod
    let startValue: Double
    let endValue: Double
    let change: Double
    let changePercent: Double
    let dataPoints: [PerformancePoint]
}

enum PerformancePeriod: String, Codable, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case sixMonth = "6M"
    case ytd = "YTD"
    case year = "1Y"
    case threeYear = "3Y"
    case fiveYear = "5Y"
    case all = "All"
}

struct PerformancePoint: Codable {
    let date: Date
    let value: Double
}

struct DividendSummary: Codable {
    let totalAnnualDividends: Double
    let monthlyAverage: Double
    let yieldOnCost: Double
    let currentYield: Double
    let upcomingDividends: [UpcomingDividend]
    let dividendHistory: [DividendPayment]
}

struct UpcomingDividend: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    let exDate: Date
    let payDate: Date
    let amount: Double
    let sharesOwned: Double
    let expectedPayout: Double
}

struct DividendPayment: Identifiable, Codable {
    let id: String
    let date: Date
    let symbol: String
    let amount: Double
    let isReinvested: Bool
}

// MARK: - Investment Insights

struct InvestmentInsight: Identifiable {
    let id = UUID()
    let type: InvestmentInsightType
    let title: String
    let description: String
    let symbol: String?
    let actionable: Bool
    let action: String?
    let priority: Int
    let timestamp: Date
}

enum InvestmentInsightType: String {
    case overweight = "Overweight Position"
    case underweight = "Underweight Position"
    case taxLossHarvest = "Tax Loss Harvest"
    case dividendIncrease = "Dividend Increase"
    case priceAlert = "Price Alert"
    case rebalanceNeeded = "Rebalance Needed"
    case newHigh = "New High"
    case newLow = "New Low"
    case largeLoss = "Large Loss"
    case largeGain = "Large Gain"
    case concentrationRisk = "Concentration Risk"
    case sectorImbalance = "Sector Imbalance"
    case upcomingDividend = "Upcoming Dividend"
    case costBasisOpportunity = "Cost Basis Opportunity"
}

// MARK: - Goals

struct InvestmentGoal: Identifiable, Codable {
    let id: String
    let name: String
    let targetAmount: Double
    var currentAmount: Double
    let targetDate: Date?
    let monthlyContribution: Double
    let expectedReturn: Double
    let linkedAccounts: [String]
    var projectedCompletion: Date?
    var onTrack: Bool
}

// MARK: - Manager

class InvestmentPortfolioManager: ObservableObject {
    static let shared = InvestmentPortfolioManager()

    @Published var accounts: [BrokerageAccount] = []
    @Published var portfolioSummary: PortfolioSummary?
    @Published var assetAllocation: [AssetAllocation] = []
    @Published var sectorAllocation: [SectorAllocation] = []
    @Published var performanceData: [PerformancePeriod: PerformanceData] = [:]
    @Published var dividendSummary: DividendSummary?
    @Published var recentTransactions: [Transaction] = []
    @Published var insights: [InvestmentInsight] = []
    @Published var goals: [InvestmentGoal] = []
    @Published var isLoading = false
    @Published var lastSyncTime: Date?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadData()
        setupSampleData()
    }

    // MARK: - Data Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "investmentAccounts"),
           let accounts = try? JSONDecoder().decode([BrokerageAccount].self, from: data) {
            self.accounts = accounts
        }

        if let data = UserDefaults.standard.data(forKey: "investmentGoals"),
           let goals = try? JSONDecoder().decode([InvestmentGoal].self, from: data) {
            self.goals = goals
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "investmentAccounts")
        }
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: "investmentGoals")
        }
    }

    // MARK: - Sample Data

    private func setupSampleData() {
        // Only setup if no accounts exist
        guard accounts.isEmpty else {
            calculatePortfolioSummary()
            return
        }

        // Sample holdings
        let fidelityHoldings: [Holding] = [
            Holding(
                id: UUID().uuidString,
                symbol: "VOO",
                name: "Vanguard S&P 500 ETF",
                assetType: .etf,
                shares: 25,
                averageCost: 380.50,
                currentPrice: 425.30,
                marketValue: 10632.50,
                dayChange: 85.25,
                dayChangePercent: 0.81,
                totalGain: 1120.00,
                totalGainPercent: 11.77,
                percentOfPortfolio: 22.5,
                dividendYield: 1.35,
                lastDividend: DividendInfo(amount: 1.55, frequency: .quarterly, exDate: Date(), payDate: Date().addingTimeInterval(86400 * 14), annualAmount: 6.20),
                sector: "Broad Market",
                peRatio: nil,
                fiftyTwoWeekHigh: 450.00,
                fiftyTwoWeekLow: 360.00
            ),
            Holding(
                id: UUID().uuidString,
                symbol: "AAPL",
                name: "Apple Inc.",
                assetType: .stock,
                shares: 50,
                averageCost: 145.00,
                currentPrice: 178.50,
                marketValue: 8925.00,
                dayChange: 125.00,
                dayChangePercent: 1.42,
                totalGain: 1675.00,
                totalGainPercent: 23.10,
                percentOfPortfolio: 18.9,
                dividendYield: 0.52,
                lastDividend: DividendInfo(amount: 0.24, frequency: .quarterly, exDate: Date(), payDate: Date(), annualAmount: 0.96),
                sector: "Technology",
                peRatio: 29.5,
                fiftyTwoWeekHigh: 199.62,
                fiftyTwoWeekLow: 140.00
            ),
            Holding(
                id: UUID().uuidString,
                symbol: "VTI",
                name: "Vanguard Total Stock Market ETF",
                assetType: .etf,
                shares: 30,
                averageCost: 195.00,
                currentPrice: 222.80,
                marketValue: 6684.00,
                dayChange: 53.40,
                dayChangePercent: 0.81,
                totalGain: 834.00,
                totalGainPercent: 14.26,
                percentOfPortfolio: 14.2,
                dividendYield: 1.42,
                lastDividend: nil,
                sector: "Broad Market",
                peRatio: nil,
                fiftyTwoWeekHigh: 240.00,
                fiftyTwoWeekLow: 185.00
            ),
            Holding(
                id: UUID().uuidString,
                symbol: "MSFT",
                name: "Microsoft Corporation",
                assetType: .stock,
                shares: 15,
                averageCost: 280.00,
                currentPrice: 378.91,
                marketValue: 5683.65,
                dayChange: 42.60,
                dayChangePercent: 0.76,
                totalGain: 1483.65,
                totalGainPercent: 35.32,
                percentOfPortfolio: 12.1,
                dividendYield: 0.75,
                lastDividend: DividendInfo(amount: 0.75, frequency: .quarterly, exDate: Date(), payDate: Date(), annualAmount: 3.00),
                sector: "Technology",
                peRatio: 35.2,
                fiftyTwoWeekHigh: 420.00,
                fiftyTwoWeekLow: 275.00
            ),
            Holding(
                id: UUID().uuidString,
                symbol: "BND",
                name: "Vanguard Total Bond Market ETF",
                assetType: .bondFund,
                shares: 60,
                averageCost: 78.00,
                currentPrice: 72.50,
                marketValue: 4350.00,
                dayChange: 12.00,
                dayChangePercent: 0.28,
                totalGain: -330.00,
                totalGainPercent: -7.05,
                percentOfPortfolio: 9.2,
                dividendYield: 3.85,
                lastDividend: nil,
                sector: "Bonds",
                peRatio: nil,
                fiftyTwoWeekHigh: 82.00,
                fiftyTwoWeekLow: 70.00
            )
        ]

        let rothHoldings: [Holding] = [
            Holding(
                id: UUID().uuidString,
                symbol: "VGT",
                name: "Vanguard Information Technology ETF",
                assetType: .etf,
                shares: 12,
                averageCost: 380.00,
                currentPrice: 485.20,
                marketValue: 5822.40,
                dayChange: 69.84,
                dayChangePercent: 1.21,
                totalGain: 1262.40,
                totalGainPercent: 27.70,
                percentOfPortfolio: 12.4,
                dividendYield: 0.65,
                lastDividend: nil,
                sector: "Technology",
                peRatio: nil,
                fiftyTwoWeekHigh: 520.00,
                fiftyTwoWeekLow: 350.00
            ),
            Holding(
                id: UUID().uuidString,
                symbol: "SCHD",
                name: "Schwab US Dividend Equity ETF",
                assetType: .etf,
                shares: 40,
                averageCost: 68.00,
                currentPrice: 75.80,
                marketValue: 3032.00,
                dayChange: 24.00,
                dayChangePercent: 0.80,
                totalGain: 312.00,
                totalGainPercent: 11.47,
                percentOfPortfolio: 6.4,
                dividendYield: 3.45,
                lastDividend: DividendInfo(amount: 0.66, frequency: .quarterly, exDate: Date(), payDate: Date(), annualAmount: 2.64),
                sector: "Dividend",
                peRatio: nil,
                fiftyTwoWeekHigh: 82.00,
                fiftyTwoWeekLow: 65.00
            )
        ]

        // Create sample accounts
        let fidelityAccount = BrokerageAccount(
            id: UUID().uuidString,
            brokerage: .fidelity,
            accountType: .individual,
            accountName: "Individual Brokerage",
            accountNumber: "4521",
            holdings: fidelityHoldings,
            cashBalance: 2450.75,
            totalValue: 38725.90,
            dayChange: 318.25,
            dayChangePercent: 0.83,
            totalGain: 4782.65,
            totalGainPercent: 14.09,
            lastUpdated: Date(),
            isConnected: true
        )

        let rothAccount = BrokerageAccount(
            id: UUID().uuidString,
            brokerage: .fidelity,
            accountType: .rothIRA,
            accountName: "Roth IRA",
            accountNumber: "7823",
            holdings: rothHoldings,
            cashBalance: 850.00,
            totalValue: 9704.40,
            dayChange: 93.84,
            dayChangePercent: 0.98,
            totalGain: 1574.40,
            totalGainPercent: 19.36,
            lastUpdated: Date(),
            isConnected: true
        )

        accounts = [fidelityAccount, rothAccount]

        // Setup sample goals
        goals = [
            InvestmentGoal(
                id: UUID().uuidString,
                name: "Retirement",
                targetAmount: 1000000,
                currentAmount: 48430.30,
                targetDate: Calendar.current.date(byAdding: .year, value: 25, to: Date()),
                monthlyContribution: 500,
                expectedReturn: 0.07,
                linkedAccounts: [fidelityAccount.id, rothAccount.id],
                projectedCompletion: nil,
                onTrack: true
            ),
            InvestmentGoal(
                id: UUID().uuidString,
                name: "House Down Payment",
                targetAmount: 80000,
                currentAmount: 38725.90,
                targetDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()),
                monthlyContribution: 1000,
                expectedReturn: 0.05,
                linkedAccounts: [fidelityAccount.id],
                projectedCompletion: nil,
                onTrack: true
            )
        ]

        calculatePortfolioSummary()
        calculateAllocations()
        generatePerformanceData()
        calculateDividendSummary()
        generateInsights()
        save()
    }

    // MARK: - Portfolio Calculations

    func calculatePortfolioSummary() {
        let totalValue = accounts.reduce(0) { $0 + $1.totalValue }
        let totalCost = accounts.reduce(0) { sum, account in
            sum + account.holdings.reduce(0) { $0 + ($1.averageCost * $1.shares) }
        }
        let cashTotal = accounts.reduce(0) { $0 + $1.cashBalance }
        let dayChange = accounts.reduce(0) { $0 + $1.dayChange }
        let holdingCount = accounts.reduce(0) { $0 + $1.holdings.count }

        portfolioSummary = PortfolioSummary(
            totalValue: totalValue,
            totalCost: totalCost,
            totalGain: totalValue - totalCost,
            totalGainPercent: totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0,
            dayChange: dayChange,
            dayChangePercent: totalValue > 0 ? (dayChange / (totalValue - dayChange)) * 100 : 0,
            cashTotal: cashTotal,
            investedTotal: totalValue - cashTotal,
            accountCount: accounts.count,
            holdingCount: holdingCount,
            lastUpdated: Date()
        )
    }

    func calculateAllocations() {
        var assetMap: [AssetType: (value: Double, symbols: [String])] = [:]
        var sectorMap: [String: (value: Double, symbols: [String])] = [:]

        for account in accounts {
            // Add cash
            let existingCash = assetMap[.cash] ?? (0, [])
            assetMap[.cash] = (existingCash.value + account.cashBalance, existingCash.symbols)

            for holding in account.holdings {
                // Asset allocation
                let existing = assetMap[holding.assetType] ?? (0, [])
                var symbols = existing.symbols
                if !symbols.contains(holding.symbol) {
                    symbols.append(holding.symbol)
                }
                assetMap[holding.assetType] = (existing.value + holding.marketValue, symbols)

                // Sector allocation
                if let sector = holding.sector {
                    let existingSector = sectorMap[sector] ?? (0, [])
                    var sectorSymbols = existingSector.symbols
                    if !sectorSymbols.contains(holding.symbol) {
                        sectorSymbols.append(holding.symbol)
                    }
                    sectorMap[sector] = (existingSector.value + holding.marketValue, sectorSymbols)
                }
            }
        }

        let totalValue = portfolioSummary?.totalValue ?? 1

        assetAllocation = assetMap.map { type, data in
            AssetAllocation(
                assetType: type,
                value: data.value,
                percentage: (data.value / totalValue) * 100,
                holdings: data.symbols
            )
        }.sorted { $0.value > $1.value }

        sectorAllocation = sectorMap.map { sector, data in
            SectorAllocation(
                sector: sector,
                value: data.value,
                percentage: (data.value / totalValue) * 100,
                holdings: data.symbols
            )
        }.sorted { $0.value > $1.value }
    }

    func generatePerformanceData() {
        guard let summary = portfolioSummary else { return }

        // Generate sample performance data for different periods
        let periods: [PerformancePeriod] = [.day, .week, .month, .threeMonth, .ytd, .year]

        for period in periods {
            let (days, expectedReturn) = periodConfig(period)
            var dataPoints: [PerformancePoint] = []

            let startValue = summary.totalValue / (1 + expectedReturn)
            let valueChange = summary.totalValue - startValue

            for i in 0...days {
                let date = Calendar.current.date(byAdding: .day, value: -days + i, to: Date()) ?? Date()
                let progress = Double(i) / Double(days)
                let randomVariance = Double.random(in: -0.02...0.02)
                let value = startValue + (valueChange * progress) + (startValue * randomVariance)
                dataPoints.append(PerformancePoint(date: date, value: max(0, value)))
            }

            performanceData[period] = PerformanceData(
                period: period,
                startValue: startValue,
                endValue: summary.totalValue,
                change: valueChange,
                changePercent: expectedReturn * 100,
                dataPoints: dataPoints
            )
        }
    }

    private func periodConfig(_ period: PerformancePeriod) -> (days: Int, expectedReturn: Double) {
        switch period {
        case .day: return (1, 0.008)
        case .week: return (7, 0.015)
        case .month: return (30, 0.025)
        case .threeMonth: return (90, 0.065)
        case .sixMonth: return (180, 0.085)
        case .ytd: return (Calendar.current.component(.dayOfYear, from: Date()), 0.12)
        case .year: return (365, 0.14)
        case .threeYear: return (365 * 3, 0.35)
        case .fiveYear: return (365 * 5, 0.65)
        case .all: return (365 * 5, 0.65)
        }
    }

    func calculateDividendSummary() {
        var totalAnnual: Double = 0
        var upcomingDividends: [UpcomingDividend] = []
        var history: [DividendPayment] = []

        for account in accounts {
            for holding in account.holdings {
                if let dividend = holding.lastDividend {
                    totalAnnual += dividend.annualAmount * holding.shares

                    if let exDate = dividend.exDate, let payDate = dividend.payDate,
                       exDate > Date() {
                        upcomingDividends.append(UpcomingDividend(
                            id: UUID().uuidString,
                            symbol: holding.symbol,
                            name: holding.name,
                            exDate: exDate,
                            payDate: payDate,
                            amount: dividend.amount,
                            sharesOwned: holding.shares,
                            expectedPayout: dividend.amount * holding.shares
                        ))
                    }
                }
            }
        }

        // Generate sample dividend history
        for i in 0..<12 {
            let date = Calendar.current.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            history.append(DividendPayment(
                id: UUID().uuidString,
                date: date,
                symbol: ["VOO", "AAPL", "SCHD", "MSFT"].randomElement()!,
                amount: Double.random(in: 20...80),
                isReinvested: Bool.random()
            ))
        }

        let totalValue = portfolioSummary?.totalValue ?? 1
        let totalCost = portfolioSummary?.totalCost ?? 1

        dividendSummary = DividendSummary(
            totalAnnualDividends: totalAnnual,
            monthlyAverage: totalAnnual / 12,
            yieldOnCost: (totalAnnual / totalCost) * 100,
            currentYield: (totalAnnual / totalValue) * 100,
            upcomingDividends: upcomingDividends.sorted { $0.exDate < $1.exDate },
            dividendHistory: history.sorted { $0.date > $1.date }
        )
    }

    // MARK: - Insights

    func generateInsights() {
        var newInsights: [InvestmentInsight] = []

        guard let summary = portfolioSummary else { return }

        // Check for concentration risk
        for account in accounts {
            for holding in account.holdings {
                if holding.percentOfPortfolio > 25 {
                    newInsights.append(InvestmentInsight(
                        type: .concentrationRisk,
                        title: "High Concentration in \(holding.symbol)",
                        description: "\(holding.symbol) represents \(String(format: "%.1f", holding.percentOfPortfolio))% of your portfolio. Consider diversifying to reduce risk.",
                        symbol: holding.symbol,
                        actionable: true,
                        action: "Review position",
                        priority: 8,
                        timestamp: Date()
                    ))
                }

                // Tax loss harvesting opportunity
                if holding.totalGainPercent < -10 {
                    newInsights.append(InvestmentInsight(
                        type: .taxLossHarvest,
                        title: "Tax Loss Harvest Opportunity",
                        description: "\(holding.symbol) is down \(String(format: "%.1f", abs(holding.totalGainPercent)))%. Consider selling to realize the loss for tax purposes.",
                        symbol: holding.symbol,
                        actionable: true,
                        action: "Review for harvest",
                        priority: 7,
                        timestamp: Date()
                    ))
                }

                // Large gain notification
                if holding.totalGainPercent > 50 {
                    newInsights.append(InvestmentInsight(
                        type: .largeGain,
                        title: "Significant Gain in \(holding.symbol)",
                        description: "You're up \(String(format: "%.1f", holding.totalGainPercent))% on \(holding.symbol). Consider taking some profits.",
                        symbol: holding.symbol,
                        actionable: true,
                        action: "Review position",
                        priority: 5,
                        timestamp: Date()
                    ))
                }

                // 52-week high
                if let high = holding.fiftyTwoWeekHigh,
                   holding.currentPrice >= high * 0.98 {
                    newInsights.append(InvestmentInsight(
                        type: .newHigh,
                        title: "\(holding.symbol) Near 52-Week High",
                        description: "\(holding.symbol) is trading near its 52-week high of \(formatCurrency(high)).",
                        symbol: holding.symbol,
                        actionable: false,
                        action: nil,
                        priority: 4,
                        timestamp: Date()
                    ))
                }
            }
        }

        // Sector imbalance
        if let techAllocation = sectorAllocation.first(where: { $0.sector == "Technology" }),
           techAllocation.percentage > 40 {
            newInsights.append(InvestmentInsight(
                type: .sectorImbalance,
                title: "High Technology Exposure",
                description: "Technology represents \(String(format: "%.1f", techAllocation.percentage))% of your portfolio. Consider diversifying into other sectors.",
                symbol: nil,
                actionable: true,
                action: "View allocation",
                priority: 6,
                timestamp: Date()
            ))
        }

        // Cash drag
        let cashPercent = (summary.cashTotal / summary.totalValue) * 100
        if cashPercent > 10 {
            newInsights.append(InvestmentInsight(
                type: .rebalanceNeeded,
                title: "Excess Cash",
                description: "You have \(String(format: "%.1f", cashPercent))% in cash. Consider investing to meet your goals.",
                symbol: nil,
                actionable: true,
                action: "Deploy cash",
                priority: 5,
                timestamp: Date()
            ))
        }

        // Upcoming dividends
        if let dividends = dividendSummary?.upcomingDividends.first {
            newInsights.append(InvestmentInsight(
                type: .upcomingDividend,
                title: "Upcoming Dividend",
                description: "\(dividends.symbol) goes ex-dividend soon. Expected payout: \(formatCurrency(dividends.expectedPayout))",
                symbol: dividends.symbol,
                actionable: false,
                action: nil,
                priority: 3,
                timestamp: Date()
            ))
        }

        insights = newInsights.sorted { $0.priority > $1.priority }
    }

    // MARK: - Account Management

    func connectAccount(brokerage: BrokerageType, credentials: [String: String]) async -> Bool {
        // Simulate OAuth flow / API connection
        isLoading = true

        // In real implementation, this would:
        // 1. Use Plaid or similar service for OAuth
        // 2. Fetch account data from brokerage API
        // 3. Store credentials securely in Keychain

        try? await Task.sleep(nanoseconds: 2_000_000_000)

        isLoading = false
        return true
    }

    func disconnectAccount(_ accountId: String) {
        accounts.removeAll { $0.id == accountId }
        calculatePortfolioSummary()
        calculateAllocations()
        save()
    }

    func refreshAccount(_ accountId: String) async {
        guard let index = accounts.firstIndex(where: { $0.id == accountId }) else { return }

        isLoading = true

        // Simulate API refresh
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        accounts[index] = BrokerageAccount(
            id: accounts[index].id,
            brokerage: accounts[index].brokerage,
            accountType: accounts[index].accountType,
            accountName: accounts[index].accountName,
            accountNumber: accounts[index].accountNumber,
            holdings: accounts[index].holdings,
            cashBalance: accounts[index].cashBalance,
            totalValue: accounts[index].totalValue,
            dayChange: accounts[index].dayChange,
            dayChangePercent: accounts[index].dayChangePercent,
            totalGain: accounts[index].totalGain,
            totalGainPercent: accounts[index].totalGainPercent,
            lastUpdated: Date(),
            isConnected: true
        )

        calculatePortfolioSummary()
        lastSyncTime = Date()
        isLoading = false
        save()
    }

    func refreshAllAccounts() async {
        for account in accounts {
            await refreshAccount(account.id)
        }
        generateInsights()
    }

    // MARK: - Goals

    func addGoal(_ goal: InvestmentGoal) {
        goals.append(goal)
        save()
    }

    func updateGoal(_ goal: InvestmentGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            save()
        }
    }

    func deleteGoal(_ goalId: String) {
        goals.removeAll { $0.id == goalId }
        save()
    }

    func calculateGoalProgress(_ goal: InvestmentGoal) -> Double {
        return (goal.currentAmount / goal.targetAmount) * 100
    }

    func projectGoalCompletion(_ goal: InvestmentGoal) -> Date? {
        let remaining = goal.targetAmount - goal.currentAmount
        guard remaining > 0, goal.monthlyContribution > 0 else { return nil }

        let monthlyGrowth = goal.monthlyContribution * (1 + goal.expectedReturn / 12)
        let monthsNeeded = remaining / monthlyGrowth

        return Calendar.current.date(byAdding: .month, value: Int(monthsNeeded), to: Date())
    }

    // MARK: - Analytics

    func getTopPerformers(limit: Int = 5) -> [Holding] {
        return accounts.flatMap { $0.holdings }
            .sorted { $0.totalGainPercent > $1.totalGainPercent }
            .prefix(limit)
            .map { $0 }
    }

    func getWorstPerformers(limit: Int = 5) -> [Holding] {
        return accounts.flatMap { $0.holdings }
            .sorted { $0.totalGainPercent < $1.totalGainPercent }
            .prefix(limit)
            .map { $0 }
    }

    func getLargestPositions(limit: Int = 5) -> [Holding] {
        return accounts.flatMap { $0.holdings }
            .sorted { $0.marketValue > $1.marketValue }
            .prefix(limit)
            .map { $0 }
    }

    func getHolding(symbol: String) -> (holding: Holding, account: BrokerageAccount)? {
        for account in accounts {
            if let holding = account.holdings.first(where: { $0.symbol == symbol }) {
                return (holding, account)
            }
        }
        return nil
    }

    // MARK: - Utilities

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
