import SwiftUI
import Charts

struct InvestmentPortfolioView: View {
    @StateObject private var investmentManager = InvestmentPortfolioManager.shared
    @State private var selectedPeriod: TimePeriod = .oneMonth
    @State private var showingDividends = false

    var totalPortfolioValue: Double {
        investmentManager.holdings.reduce(0) { $0 + $1.currentValue }
    }

    var totalGainLoss: Double {
        investmentManager.holdings.reduce(0) { $0 + ($1.currentValue - $1.costBasis) }
    }

    var gainLossPercentage: Double {
        let totalCostBasis = investmentManager.holdings.reduce(0) { $0 + $1.costBasis }
        guard totalCostBasis > 0 else { return 0 }
        return (totalGainLoss / totalCostBasis) * 100
    }

    var performanceData: [ChartDataPoint] {
        investmentManager.getPerformanceData(for: selectedPeriod)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Investment Portfolio")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Track and optimize your investments")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Portfolio Overview
                        VStack(spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Total Value")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))

                                    Text("$\(Int(totalPortfolioValue))")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Gain/Loss")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))

                                    HStack(spacing: 6) {
                                        Image(systemName: totalGainLoss >= 0 ? "arrow.up.right" : "arrow.down.left")
                                            .font(.system(size: 12, weight: .bold))

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("$\(Int(abs(totalGainLoss)))")
                                                .font(.system(size: 18, weight: .bold))

                                            Text(String(format: "%.1f%%", gainLossPercentage))
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(totalGainLoss >= 0 ? .furgSuccess : .furgDanger)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        // Performance Chart
                        if !performanceData.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Performance")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)

                                    Spacer()

                                    HStack(spacing: 8) {
                                        ForEach(TimePeriod.allCases, id: \.self) { period in
                                            Button(action: { selectedPeriod = period }) {
                                                Text(period.label)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(selectedPeriod == period ? .furgCharcoal : .white.opacity(0.6))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(selectedPeriod == period ? Color.furgMint : Color.clear)
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                // Simple chart using rectangles
                                HStack(alignment: .bottom, spacing: 6) {
                                    ForEach(0..<min(performanceData.count, 30), id: \.self) { index in
                                        let data = performanceData[index]
                                        let maxValue = performanceData.map { $0.value }.max() ?? 1
                                        let normalized = data.value / maxValue

                                        VStack(spacing: 0) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.furgMint.opacity(normalized > 0.5 ? 1 : 0.6))
                                                .frame(height: CGFloat(normalized * 100))
                                        }
                                    }
                                }
                                .frame(height: 120)
                                .padding(20)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                        }

                        // Asset Allocation
                        if !investmentManager.holdings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Asset Allocation")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)

                                let assetTypes = groupAssets()
                                ForEach(assetTypes.sorted(by: { $0.value > $1.value }), id: \.key) { type, value in
                                    let percentage = (value / totalPortfolioValue) * 100
                                    AssetAllocationRow(
                                        type: type,
                                        amount: value,
                                        percentage: percentage
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Top Holdings
                        if !investmentManager.holdings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Holdings")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)

                                ForEach(investmentManager.holdings.sorted(by: { $0.currentValue > $1.currentValue })) { holding in
                                    NavigationLink(destination: HoldingDetailView(holding: holding)) {
                                        HoldingRow(holding: holding)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: { showingDividends = true }) {
                                Label("Dividend Income", systemImage: "banknote.fill")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.furgMint.opacity(0.2))
                                    .cornerRadius(10)
                            }

                            Button(action: {}) {
                                Label("Rebalance Portfolio", systemImage: "arrow.left.arrow.right")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.furgInfo.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDividends) {
                DividendHistoryView()
            }
        }
    }

    private func groupAssets() -> [String: Double] {
        var grouped: [String: Double] = [:]
        for holding in investmentManager.holdings {
            grouped[holding.type, default: 0] += holding.currentValue
        }
        return grouped
    }
}

// MARK: - Supporting Views

struct AssetAllocationRow: View {
    let type: String
    let amount: Double
    let percentage: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(type)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(amount))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.furgMint)

                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.furgMint)
                            .frame(width: geometry.size.width * (percentage / 100))
                    }
            }
            .frame(height: 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct HoldingRow: View {
    let holding: Holding

    var gainLoss: Double {
        holding.currentValue - holding.costBasis
    }

    var gainLossPercent: Double {
        guard holding.costBasis > 0 else { return 0 }
        return (gainLoss / holding.costBasis) * 100
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(holding.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(holding.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(holding.currentValue))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.left")
                        .font(.system(size: 10, weight: .bold))

                    Text("$\(Int(abs(gainLoss))) (\(String(format: "%.1f%%", gainLossPercent)))")
                        .font(.system(size: 12))
                }
                .foregroundColor(gainLoss >= 0 ? .furgSuccess : .furgDanger)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Helper Views

struct HoldingDetailView: View {
    let holding: Holding
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Text(holding.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(holding.symbol)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        VStack(spacing: 12) {
                            DetailItem(label: "Current Value", value: "$\(Int(holding.currentValue))")
                            DetailItem(label: "Cost Basis", value: "$\(Int(holding.costBasis))")
                            DetailItem(label: "Shares", value: String(format: "%.2f", holding.shares))
                            DetailItem(label: "Current Price", value: String(format: "$%.2f", holding.currentPrice))
                            DetailItem(label: "Purchase Date", value: holding.purchaseDate.formatted(.dateTime.month().day().year()))
                        }

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct DividendHistoryView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dividend Income")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Year-to-date: $1,234.56")
                            .font(.system(size: 14))
                            .foregroundColor(.furgMint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)

                    VStack(spacing: 12) {
                        DividendRow(symbol: "AAPL", amount: 245.60, date: "Dec 15, 2024")
                        DividendRow(symbol: "VOO", amount: 189.40, date: "Nov 20, 2024")
                        DividendRow(symbol: "JNJ", amount: 156.80, date: "Nov 10, 2024")
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

struct DividendRow: View {
    let symbol: String
    let amount: Double
    let date: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.furgSuccess)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Time Period

enum TimePeriod: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case ytd = "YTD"
    case oneYear = "1Y"

    var label: String {
        rawValue
    }
}

// MARK: - Chart Data

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    InvestmentPortfolioView()
        .environmentObject(FinanceManager())
}
