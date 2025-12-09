//
//  RoundUpSettingsView.swift
//  Furg
//
//  Configure round-up investing automation
//

import SwiftUI

struct RoundUpSettingsView: View {
    @EnvironmentObject var roundUpManager: RoundUpManager
    @EnvironmentObject var goalsManager: GoalsManager
    @State private var animate = false
    @State private var showGoalPicker = false

    var body: some View {
        ZStack {
            // Dark background
            Color.furgCharcoal
                .ignoresSafeArea()

            // Animated gradient overlay
            CopilotBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    RoundUpHeader()
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value: animate)

                // Summary Card
                RoundUpSummaryCard(summary: roundUpManager.summary ?? roundUpManager.demoSummary)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Enable Toggle
                RoundUpToggleCard(
                    isEnabled: Binding(
                        get: { roundUpManager.config.enabled },
                        set: { newValue in
                            Task {
                                if newValue {
                                    await roundUpManager.enableRoundUps()
                                } else {
                                    await roundUpManager.disableRoundUps()
                                }
                            }
                        }
                    )
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                if roundUpManager.config.enabled {
                    // Round-Up Amount
                    RoundUpAmountCard(
                        selectedAmount: Binding(
                            get: { roundUpManager.config.roundUpTo },
                            set: { newValue in
                                Task { await roundUpManager.setRoundUpAmount(newValue) }
                            }
                        )
                    )
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)

                    // Multiplier
                    MultiplierCard(
                        multiplier: Binding(
                            get: { roundUpManager.config.multiplier },
                            set: { newValue in
                                Task { await roundUpManager.setMultiplier(newValue) }
                            }
                        )
                    )
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                    // Linked Goal
                    LinkedGoalCard(
                        goalId: roundUpManager.config.goalId,
                        goals: goalsManager.goals,
                        onSelectGoal: { goalId in
                            Task { await roundUpManager.linkGoal(goalId) }
                        }
                    )
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)

                    // Pending Round-Ups
                    if !roundUpManager.pendingRoundUps.isEmpty {
                        PendingRoundUpsCard(
                            roundUps: roundUpManager.pendingRoundUps,
                            onTransfer: {
                                Task { await roundUpManager.transferPendingRoundUps() }
                            }
                        )
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: animate)
                    }
                }

                // Estimation Card
                EstimatedSavingsCard(
                    monthlyEstimate: roundUpManager.estimateMonthlyRoundUp()
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: animate)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        }
        .task {
            await roundUpManager.loadConfig()
            await roundUpManager.loadSummary()
            await roundUpManager.loadPendingRoundUps()
        }
        .onAppear {
            withAnimation { animate = true }
        }
    }
}

// MARK: - Header

struct RoundUpHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Round-Ups")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)

                Text("Invest your spare change automatically")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.top, 60)
    }
}

// MARK: - Summary Card

struct RoundUpSummaryCard: View {
    let summary: RoundUpSummary

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Total Rounded Up")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.furgMint)

                Text(String(format: "%.2f", NSDecimalNumber(decimal: summary.totalRoundedUp).doubleValue))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 20) {
                SummaryStatItem(
                    label: "Transferred",
                    value: "$\(NSDecimalNumber(decimal: summary.totalTransferred).intValue)",
                    icon: "checkmark.circle.fill",
                    color: .furgSuccess
                )

                SummaryStatItem(
                    label: "Pending",
                    value: "$\(String(format: "%.2f", NSDecimalNumber(decimal: summary.pendingAmount).doubleValue))",
                    icon: "clock.fill",
                    color: .furgWarning
                )

                SummaryStatItem(
                    label: "Transactions",
                    value: "\(summary.transactionCount)",
                    icon: "arrow.left.arrow.right",
                    color: .furgInfo
                )
            }
        }
        .padding(20)
        .copilotCard()
    }
}

struct SummaryStatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)

            Text(value)
                .font(.furgHeadline)
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Toggle Card

struct RoundUpToggleCard: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isEnabled ? Color.furgMint.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: isEnabled ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.title2)
                    .foregroundColor(isEnabled ? .furgMint : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Round-Up Investing")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Text(isEnabled ? "Automatically saving your spare change" : "Turn on to start saving automatically")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(.furgMint)
        }
        .padding(16)
        .copilotCard()
    }
}

// MARK: - Round-Up Amount Card

struct RoundUpAmountCard: View {
    @Binding var selectedAmount: RoundUpAmount

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Round Up To")
                .font(.furgHeadline)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                ForEach(RoundUpAmount.allCases, id: \.self) { amount in
                    Button {
                        selectedAmount = amount
                    } label: {
                        VStack(spacing: 8) {
                            Text(amount.label)
                                .font(.furgBody)
                                .foregroundColor(selectedAmount == amount ? .furgCharcoal : .white)

                            // Example
                            Text(exampleText(for: amount))
                                .font(.furgCaption)
                                .foregroundColor(selectedAmount == amount ? .furgCharcoal.opacity(0.7) : .white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedAmount == amount ? Color.furgMint : Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16)
        .copilotCard()
    }

    func exampleText(for amount: RoundUpAmount) -> String {
        switch amount {
        case .nearestDollar: return "$4.73 → $5"
        case .nearestTwo: return "$4.73 → $6"
        case .nearestFive: return "$4.73 → $5"
        }
    }
}

// MARK: - Multiplier Card

struct MultiplierCard: View {
    @Binding var multiplier: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Multiplier")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(multiplier)x")
                    .font(.furgTitle2)
                    .foregroundColor(.furgMint)
            }

            HStack(spacing: 8) {
                ForEach([1, 2, 3, 5, 10], id: \.self) { mult in
                    Button {
                        multiplier = mult
                    } label: {
                        Text("\(mult)x")
                            .font(.furgBody)
                            .foregroundColor(multiplier == mult ? .furgCharcoal : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(multiplier == mult ? Color.furgMint : Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            Text("A 2x multiplier means $0.27 becomes $0.54")
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .copilotCard()
    }
}

// MARK: - Linked Goal Card

struct LinkedGoalCard: View {
    let goalId: String?
    let goals: [FurgSavingsGoal]
    let onSelectGoal: (String) -> Void

    @State private var showGoalPicker = false

    var linkedGoal: FurgSavingsGoal? {
        goals.first { $0.id == goalId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send Round-Ups To")
                .font(.furgHeadline)
                .foregroundColor(.white)

            Button {
                showGoalPicker = true
            } label: {
                HStack(spacing: 14) {
                    if let goal = linkedGoal {
                        ZStack {
                            Circle()
                                .fill(goal.category.color.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: goal.category.icon)
                                .font(.body)
                                .foregroundColor(goal.category.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.name)
                                .font(.furgBody)
                                .foregroundColor(.white)

                            Text("\(Int(goal.percentComplete))% complete")
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Text("Select a goal")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .copilotCard()
        .sheet(isPresented: $showGoalPicker) {
            GoalPickerSheet(goals: goals, selectedGoalId: goalId, onSelect: { goalId in
                onSelectGoal(goalId)
                showGoalPicker = false
            })
        }
    }
}

struct GoalPickerSheet: View {
    let goals: [FurgSavingsGoal]
    let selectedGoalId: String?
    let onSelect: (String) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            CopilotBackground()

            VStack(spacing: 20) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .copilotCard(cornerRadius: 12, opacity: 0.1)
                    }

                    Spacer()

                    Text("Select Goal")
                        .font(.furgTitle2)
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(goals) { goal in
                            Button {
                                onSelect(goal.id)
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(goal.category.color.opacity(0.2))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: goal.category.icon)
                                            .font(.body)
                                            .foregroundColor(goal.category.color)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.name)
                                            .font(.furgBody)
                                            .foregroundColor(.white)

                                        Text("\(goal.formattedCurrent) of \(goal.formattedTarget)")
                                            .font(.furgCaption)
                                            .foregroundColor(.white.opacity(0.5))
                                    }

                                    Spacer()

                                    if selectedGoalId == goal.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.furgMint)
                                    }
                                }
                                .padding(14)
                                .background(selectedGoalId == goal.id ? Color.furgMint.opacity(0.1) : Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Pending Round-Ups Card

struct PendingRoundUpsCard: View {
    let roundUps: [RoundUpTransaction]
    let onTransfer: () -> Void

    var totalPending: Decimal {
        roundUps.reduce(Decimal(0)) { $0 + $1.multipliedAmount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pending Round-Ups")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: totalPending).doubleValue))")
                    .font(.furgHeadline)
                    .foregroundColor(.furgMint)
            }

            VStack(spacing: 8) {
                ForEach(roundUps.prefix(5)) { roundUp in
                    HStack {
                        Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: roundUp.originalAmount).doubleValue))")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.6))

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))

                        Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: roundUp.roundedAmount).doubleValue))")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.6))

                        Spacer()

                        Text("+$\(String(format: "%.2f", NSDecimalNumber(decimal: roundUp.multipliedAmount).doubleValue))")
                            .font(.furgCaption.bold())
                            .foregroundColor(.furgMint)
                    }
                    .padding(.vertical, 4)
                }
            }

            Button(action: onTransfer) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Transfer Now")
                }
                .font(.furgBody.bold())
                .foregroundColor(.furgCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FurgGradients.mintGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .copilotCard()
    }
}

// MARK: - Estimated Savings Card

struct EstimatedSavingsCard: View {
    let monthlyEstimate: Decimal

    var yearlyEstimate: Decimal {
        monthlyEstimate * 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.furgMint)
                Text("Estimated Savings")
                    .font(.furgHeadline)
                    .foregroundColor(.white)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))

                    Text("$\(NSDecimalNumber(decimal: monthlyEstimate).intValue)")
                        .font(.furgTitle)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Yearly")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))

                    Text("$\(NSDecimalNumber(decimal: yearlyEstimate).intValue)")
                        .font(.furgTitle)
                        .foregroundColor(.furgMint)
                }
            }

            Text("Based on ~5 transactions per day. Your actual savings may vary.")
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(16)
        .copilotCard()
    }
}

#Preview {
    ZStack {
        CopilotBackground()
        RoundUpSettingsView()
    }
    .environmentObject(RoundUpManager())
    .environmentObject(GoalsManager())
}
