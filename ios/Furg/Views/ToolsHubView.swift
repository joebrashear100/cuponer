//
//  ToolsHubView.swift
//  Furg
//
//  Hub for accessing advanced financial tools and features
//

import SwiftUI

struct ToolsHubView: View {
    @State private var selectedTool: FinancialTool?

    enum FinancialTool: String, CaseIterable, Identifiable {
        case cardRecommendations = "Card Recommendations"
        case merchantIntelligence = "Merchant Intelligence"
        case investmentPortfolio = "Investment Portfolio"
        case lifeScenarios = "Life Scenarios"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .cardRecommendations: return "creditcard.fill"
            case .merchantIntelligence: return "storefront.fill"
            case .investmentPortfolio: return "chart.line.uptrend.xyaxis"
            case .lifeScenarios: return "calendar.badge.clock"
            }
        }

        var description: String {
            switch self {
            case .cardRecommendations: return "Find the best credit cards for your spending"
            case .merchantIntelligence: return "Analyze where you spend and get insights"
            case .investmentPortfolio: return "Track and optimize your investments"
            case .lifeScenarios: return "Plan financial scenarios and life events"
            }
        }

        var color: Color {
            switch self {
            case .cardRecommendations: return .furgMint
            case .merchantIntelligence: return .furgInfo
            case .investmentPortfolio: return .furgSuccess
            case .lifeScenarios: return .furgWarning
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Financial Tools")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Advanced financial planning and insights")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Tools Grid
                        VStack(spacing: 16) {
                            ForEach(FinancialTool.allCases, id: \.self) { tool in
                                NavigationLink(destination: destinationView(for: tool)) {
                                    ToolCard(tool: tool)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func destinationView(for tool: FinancialTool) -> some View {
        switch tool {
        case .cardRecommendations:
            CardRecommendationsView()
        case .merchantIntelligence:
            MerchantIntelligenceView()
        case .investmentPortfolio:
            InvestmentPortfolioView()
        case .lifeScenarios:
            LifeIntegrationView()
        }
    }
}

// MARK: - Tool Card

struct ToolCard: View {
    let tool: ToolsHubView.FinancialTool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: tool.icon)
                    .font(.system(size: 28))
                    .foregroundColor(tool.color)
                    .frame(width: 56, height: 56)
                    .background(tool.color.opacity(0.2))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(tool.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }
}

#Preview {
    ToolsHubView()
        .environmentObject(FinanceManager())
}
