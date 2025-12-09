//
//  AssetAllocationView.swift
//  Furg
//
//  Asset allocation analysis and optimization recommendations
//

import SwiftUI
import Charts

struct AssetAllocationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedRiskProfile: RiskProfile = .moderate
    @State private var showRebalanceSheet = false

    enum RiskProfile: String, CaseIterable {
        case conservative = "Conservative"
        case moderate = "Moderate"
        case aggressive = "Aggressive"

        var stockAllocation: Double {
            switch self {
            case .conservative: return 30
            case .moderate: return 60
            case .aggressive: return 80
            }
        }

        var bondAllocation: Double {
            switch self {
            case .conservative: return 60
            case .moderate: return 30
            case .aggressive: return 15
            }
        }

        var alternativeAllocation: Double {
            switch self {
            case .conservative: return 10
            case .moderate: return 10
            case .aggressive: return 5
            }
        }
    }

    // Current allocation (demo data)
    let currentAllocation: [AssetClass] = [
        AssetClass(name: "US Stocks", percentage: 45, amount: 61275, color: .blue, icon: "chart.line.uptrend.xyaxis"),
        AssetClass(name: "International Stocks", percentage: 15, amount: 20425, color: .purple, icon: "globe"),
        AssetClass(name: "Bonds", percentage: 20, amount: 27233, color: .green, icon: "building.columns"),
        AssetClass(name: "Real Estate", percentage: 12, amount: 16340, color: .orange, icon: "house.fill"),
        AssetClass(name: "Crypto", percentage: 5, amount: 6808, color: .yellow, icon: "bitcoinsign.circle"),
        AssetClass(name: "Cash", percentage: 3, amount: 4085, color: .gray, icon: "dollarsign.circle")
    ]

    var totalPortfolio: Double {
        currentAllocation.reduce(0) { $0 + $1.amount }
    }

    var currentStocks: Double {
        currentAllocation.filter { $0.name.contains("Stocks") }.reduce(0) { $0 + $1.percentage }
    }

    var currentBonds: Double {
        currentAllocation.first(where: { $0.name == "Bonds" })?.percentage ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Portfolio overview
                        portfolioOverview
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Current allocation
                        currentAllocationSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Risk profile selector
                        riskProfileSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Recommended changes
                        recommendedChanges
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        // Diversification score
                        diversificationScore
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.4), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Asset Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animate = true
                }
            }
            .sheet(isPresented: $showRebalanceSheet) {
                RebalanceSheet(
                    currentAllocation: currentAllocation,
                    targetProfile: selectedRiskProfile,
                    totalPortfolio: totalPortfolio
                )
            }
        }
    }

    // MARK: - Portfolio Overview

    private var portfolioOverview: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Portfolio")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(totalPortfolio).formatted())")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("+12.4%")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.furgSuccess)

                    Text("YTD Return")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Quick stats
            HStack(spacing: 0) {
                QuickStat(label: "Stocks", value: "\(Int(currentStocks))%", color: .blue)
                QuickStat(label: "Bonds", value: "\(Int(currentBonds))%", color: .green)
                QuickStat(label: "Other", value: "\(Int(100 - currentStocks - currentBonds))%", color: .orange)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Current Allocation

    private var currentAllocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Allocation")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // Pie chart
            Chart(currentAllocation) { asset in
                SectorMark(
                    angle: .value("Amount", asset.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(asset.color.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(currentAllocation) { asset in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(asset.color)
                            .frame(width: 10, height: 10)

                        Text(asset.name)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Text("\(Int(asset.percentage))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Risk Profile Section

    private var riskProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.furgMint)
                Text("Target Risk Profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Profile selector
            HStack(spacing: 8) {
                ForEach(RiskProfile.allCases, id: \.self) { profile in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRiskProfile = profile
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(profile.rawValue)
                                .font(.system(size: 13, weight: .medium))

                            Text("\(Int(profile.stockAllocation))% stocks")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(selectedRiskProfile == profile ? .furgCharcoal : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedRiskProfile == profile ? Color.furgMint : Color.white.opacity(0.05))
                        )
                    }
                }
            }

            // Target breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Target allocation for \(selectedRiskProfile.rawValue):")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: CGFloat(selectedRiskProfile.stockAllocation) / 100 * 300)

                    Rectangle()
                        .fill(Color.green)
                        .frame(width: CGFloat(selectedRiskProfile.bondAllocation) / 100 * 300)

                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: CGFloat(selectedRiskProfile.alternativeAllocation) / 100 * 300)
                }
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                HStack {
                    Label("\(Int(selectedRiskProfile.stockAllocation))% Stocks", systemImage: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)

                    Spacer()

                    Label("\(Int(selectedRiskProfile.bondAllocation))% Bonds", systemImage: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)

                    Spacer()

                    Label("\(Int(selectedRiskProfile.alternativeAllocation))% Alt", systemImage: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Recommended Changes

    private var recommendedChanges: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.furgMint)
                Text("Recommended Rebalance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            let stockDiff = selectedRiskProfile.stockAllocation - currentStocks
            let bondDiff = selectedRiskProfile.bondAllocation - currentBonds

            VStack(spacing: 10) {
                RebalanceRow(
                    asset: "Stocks",
                    current: currentStocks,
                    target: selectedRiskProfile.stockAllocation,
                    change: stockDiff,
                    amount: totalPortfolio * abs(stockDiff) / 100
                )

                RebalanceRow(
                    asset: "Bonds",
                    current: currentBonds,
                    target: selectedRiskProfile.bondAllocation,
                    change: bondDiff,
                    amount: totalPortfolio * abs(bondDiff) / 100
                )

                if abs(stockDiff) > 5 || abs(bondDiff) > 5 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.furgWarning)

                        Text("Your portfolio is significantly off-balance from your target")
                            .font(.system(size: 12))
                            .foregroundColor(.furgWarning)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.furgWarning.opacity(0.1))
                    )
                }
            }

            Button {
                showRebalanceSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("View Rebalance Plan")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.furgCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Diversification Score

    private var diversificationScore: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Diversification Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: 0.78)
                        .stroke(Color.furgMint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("78")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            VStack(spacing: 10) {
                DiversificationFactor(
                    name: "Asset Class Spread",
                    score: 85,
                    description: "Good variety across asset types"
                )

                DiversificationFactor(
                    name: "Geographic Diversity",
                    score: 65,
                    description: "Consider more international exposure"
                )

                DiversificationFactor(
                    name: "Sector Balance",
                    score: 75,
                    description: "Slightly overweight in tech"
                )

                DiversificationFactor(
                    name: "Correlation",
                    score: 82,
                    description: "Assets are reasonably uncorrelated"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Supporting Types

struct AssetClass: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let amount: Double
    let color: Color
    let icon: String
}

// MARK: - Supporting Views

private struct QuickStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RebalanceRow: View {
    let asset: String
    let current: Double
    let target: Double
    let change: Double
    let amount: Double

    var body: some View {
        HStack {
            Text(asset)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            Text("\(Int(current))%")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))

            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))

            Text("\(Int(target))%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text(change >= 0 ? "+\(Int(change))%" : "\(Int(change))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(change >= 0 ? .furgSuccess : .furgDanger)
                .frame(width: 45, alignment: .trailing)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

private struct DiversificationFactor: View {
    let name: String
    let score: Int
    let description: String

    var scoreColor: Color {
        if score >= 80 { return .furgSuccess }
        if score >= 60 { return .furgWarning }
        return .furgDanger
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

private struct RebalanceSheet: View {
    let currentAllocation: [AssetClass]
    let targetProfile: AssetAllocationView.RiskProfile
    let totalPortfolio: Double
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Summary
                        VStack(spacing: 12) {
                            Text("To rebalance to a \(targetProfile.rawValue) portfolio:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("You'll need to make the following trades")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)

                        // Trades
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Trades")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            TradeRow(
                                action: "Sell",
                                asset: "Crypto (BTC/ETH)",
                                amount: 2000,
                                reason: "Reduce high-risk allocation"
                            )

                            TradeRow(
                                action: "Buy",
                                asset: "Bond ETF (BND)",
                                amount: 4000,
                                reason: "Increase fixed income"
                            )

                            TradeRow(
                                action: "Sell",
                                asset: "US Stocks",
                                amount: 2000,
                                reason: "Slightly overweight"
                            )
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)

                        // Tax implications
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.furgWarning)
                                Text("Tax Considerations")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text("Selling assets may trigger capital gains taxes. Consider rebalancing within tax-advantaged accounts (401k, IRA) first.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.furgWarning.opacity(0.1))
                        )
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Rebalance Plan")
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

private struct TradeRow: View {
    let action: String
    let asset: String
    let amount: Int
    let reason: String

    var isSell: Bool { action == "Sell" }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSell ? Color.furgDanger.opacity(0.2) : Color.furgSuccess.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: isSell ? "arrow.down" : "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSell ? .furgDanger : .furgSuccess)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(action)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSell ? .furgDanger : .furgSuccess)

                    Text(asset)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }

                Text(reason)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text("$\(amount.formatted())")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    AssetAllocationView()
}
