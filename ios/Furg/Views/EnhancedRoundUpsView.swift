//
//  EnhancedRoundUpsView.swift
//  Furg
//
//  Multi-card round-up settings for Plaid and FinanceKit
//

import SwiftUI

struct EnhancedRoundUpsView: View {
    @State private var animate = false
    @State private var totalRoundUpsToday: Double = 42.50
    @State private var connectedCardsCount: Int = 3
    @State private var enabledCardsCount: Int = 2

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Summary Card
                        summaryCard
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Quick Stats
                        quickStats
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Connected Cards
                        connectedCardsSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.15), value: animate)

                        // How It Works
                        howItWorksSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Round-Ups")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round-Ups Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(String(format: "%.2f", totalRoundUpsToday))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.furgMint)
                }

                Spacer()

                // Piggy bank animation
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.furgMint.opacity(0.3))
            }

            // Monthly projection
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.furgSuccess)

                Text("On track to save ~$\(Int(totalRoundUpsToday * 30)) this month")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [.furgMint.opacity(0.2), .furgCharcoal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgMint.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                icon: "creditcard.fill",
                value: "\(enabledCardsCount)",
                label: "Cards Active",
                color: .furgMint
            )

            QuickStatCard(
                icon: "arrow.up.circle.fill",
                value: "$\(String(format: "%.0f", totalRoundUpsToday * 365))",
                label: "Yearly Est.",
                color: .furgSuccess
            )
        }
    }

    // MARK: - Connected Cards

    private var connectedCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Cards")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text("\(connectedCardsCount) connected")
                    .font(.system(size: 12))
                    .foregroundColor(.furgMint)
            }

            // Card rows would be displayed here
            Text("Round-up management coming soon")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            // Add Card Button
            Button {
                // Add card action - would typically open Plaid Link or FinanceKit auth
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Connect Another Card")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.furgMint)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.furgMint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How Round-Ups Work")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 12) {
                HowItWorksStep(
                    number: 1,
                    icon: "creditcard",
                    title: "Make a purchase",
                    description: "Spend $4.50 on coffee"
                )

                HowItWorksStep(
                    number: 2,
                    icon: "arrow.up.right",
                    title: "We round up",
                    description: "Round to $5.00 (+$0.50)"
                )

                HowItWorksStep(
                    number: 3,
                    icon: "banknote",
                    title: "Save the difference",
                    description: "$0.50 goes to your savings"
                )
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CardRoundUpRow: View {
    let card: CardRoundUpSettings
    // @StateObject private var transactionManager = RealTimeTransactionManager.shared  // Disabled
    @State private var isEnabled: Bool
    @State private var showSettings = false

    init(card: CardRoundUpSettings) {
        self.card = card
        _isEnabled = State(initialValue: card.isEnabled)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Card Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(card.source == .financeKit ? Color.gray : Color.blue.opacity(0.3))
                        .frame(width: 50, height: 34)

                    if card.source == .financeKit {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    } else {
                        Text("••••")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(card.cardName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        if card.source == .financeKit {
                            Text("Apple Card")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Text("•••• \(card.cardLast4)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .tint(.furgMint)
                    .onChange(of: isEnabled) { _, newValue in
                        // TODO: Implement toggleRoundUp when transactionManager is available
                    }
            }
            .padding(14)

            // Expanded settings when enabled
            if isEnabled {
                Divider()
                    .background(Color.white.opacity(0.1))

                HStack(spacing: 16) {
                    // Round-up Level
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Round to")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 6) {
                            ForEach(CardRoundUpSettings.RoundUpLevel.allCases, id: \.self) { level in
                                Button {
                                    // TODO: Implement setRoundUpLevel when transactionManager is available
                                } label: {
                                    Text(level.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(card.roundUpAmount == level ? .furgCharcoal : .white.opacity(0.7))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(card.roundUpAmount == level ? Color.furgMint : Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    // Multiplier
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Multiplier")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 6) {
                            ForEach([1.0, 2.0, 3.0], id: \.self) { mult in
                                Button {
                                    // TODO: Implement setMultiplier when transactionManager is available
                                } label: {
                                    Text("\(Int(mult))x")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(card.multiplier == mult ? .furgCharcoal : .white.opacity(0.7))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(card.multiplier == mult ? Color.furgMint : Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isEnabled ? Color.furgMint.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct HowItWorksStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.furgMint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.furgMint.opacity(0.5))
        }
    }
}

#Preview {
    EnhancedRoundUpsView()
}
