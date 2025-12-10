//
//  ToolsHubView.swift
//  Furg
//
//  Premium tools hub - centralized access to all advanced features
//

import SwiftUI

struct ToolsHubView: View {
    @EnvironmentObject var navigationState: NavigationState
    @State private var animate = false
    @State private var showDebtPayoff = false
    @State private var showCardRecommendations = false
    @State private var showInvestments = false
    @State private var showMerchantIntel = false
    @State private var showLifeIntegration = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Premium Tools")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Advanced financial features to enhance your wealth management")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : -10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animate)

                    // Feature Grid (2 columns)
                    featureGrid

                    // Coming Soon Section
                    comingSoonSection

                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear { animate = true }
        .sheet(isPresented: $showDebtPayoff) {
            DebtPayoffView()
        }
        .sheet(isPresented: $showCardRecommendations) {
            CardRecommendationsView()
        }
        .sheet(isPresented: $showInvestments) {
            InvestmentPortfolioView()
        }
        .sheet(isPresented: $showMerchantIntel) {
            MerchantIntelligenceView()
        }
        .sheet(isPresented: $showLifeIntegration) {
            LifeIntegrationView()
        }
    }

    private var featureGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            PremiumToolCard(
                icon: "chart.line.downtrend.xyaxis",
                title: "Debt Payoff",
                description: "Track debts with snowball/avalanche strategies",
                color: Color(red: 0.95, green: 0.4, blue: 0.4),
                preview: "$38,500 total"
            ) {
                showDebtPayoff = true
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)

            PremiumToolCard(
                icon: "creditcard.fill",
                title: "Card Optimizer",
                description: "Get personalized card recommendations",
                color: Color(red: 0.6, green: 0.4, blue: 0.9),
                preview: "95% match"
            ) {
                showCardRecommendations = true
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: animate)

            PremiumToolCard(
                icon: "chart.pie.fill",
                title: "Investments",
                description: "Track portfolio & asset allocation",
                color: Color(red: 0.7, green: 0.4, blue: 0.9),
                preview: "+$2,450"
            ) {
                showInvestments = true
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animate)

            PremiumToolCard(
                icon: "building.2.fill",
                title: "Merchant Intel",
                description: "Best prices, return policies, deals",
                color: Color(red: 0.4, green: 0.8, blue: 0.9),
                preview: "5 insights"
            ) {
                showMerchantIntel = true
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: animate)

            PremiumToolCard(
                icon: "heart.text.square.fill",
                title: "Life Integration",
                description: "Connect spending to life events",
                color: Color(red: 0.9, green: 0.4, blue: 0.7),
                preview: "Risk: 45"
            ) {
                showLifeIntegration = true
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animate)
        }
        .padding(.horizontal, 16)
    }

    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Soon")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ComingSoonCard(icon: "doc.text", title: "Tax Planning")
                ComingSoonCard(icon: "handshake.fill", title: "Bill Negotiation")
                ComingSoonCard(icon: "chart.bar.fill", title: "Budget Automation")
            }
            .padding(.horizontal, 16)
        }
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: animate)
    }
}

// MARK: - Premium Tool Card Component

struct PremiumToolCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let preview: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)

                    if let preview = preview {
                        Text(preview)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(color)
                            .padding(.top, 4)
                    }
                }

                Spacer()
            }
            .padding(14)
            .frame(height: 160)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coming Soon Card Component

struct ComingSoonCard: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 40, height: 40)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.3))

            Spacer()

            Text("Coming Soon")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    ToolsHubView()
        .environmentObject(NavigationState())
}
