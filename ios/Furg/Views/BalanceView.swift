//
//  BalanceView.swift
//  Furg
//
//  Modern glassmorphism balance dashboard
//

import SwiftUI

struct BalanceView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showHideSheet = false
    @State private var hideAmount = ""
    @State private var animate = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(greeting)")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Your Balance")
                            .font(.furgLargeTitle)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        Task { await financeManager.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.furgMint)
                            .padding(12)
                            .glassCard(cornerRadius: 14, opacity: 0.1)
                    }
                }
                .padding(.top, 60)

                // Main balance card
                MainBalanceCard(balance: financeManager.balance, animate: animate)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Quick stats
                if let balance = financeManager.balance {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MiniStatCard(
                            title: "Safety Buffer",
                            value: "$\(Int(balance.safetyBuffer))",
                            icon: "shield.lefthalf.filled",
                            color: .furgSuccess
                        )

                        MiniStatCard(
                            title: "Pending",
                            value: "$\(Int(balance.pendingBalance))",
                            icon: "clock.fill",
                            color: .furgInfo
                        )
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)
                }

                // Action buttons
                HStack(spacing: 16) {
                    ActionButton(
                        icon: "eye.slash.fill",
                        label: "Hide",
                        color: .furgMint
                    ) {
                        showHideSheet = true
                    }

                    ActionButton(
                        icon: "eye.fill",
                        label: "Reveal",
                        color: .furgSeafoam
                    ) {
                        // Reveal action
                    }

                    ActionButton(
                        icon: "plus",
                        label: "Add",
                        color: .furgPistachio
                    ) {
                        // Add bank action
                    }
                }
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)

                // Upcoming bills section
                if let upcoming = financeManager.upcomingBills, !upcoming.bills.isEmpty {
                    UpcomingBillsCard(upcoming: upcoming)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                }

                // Demo mode indicator
                if !financeManager.hasBankConnected {
                    DemoModeCard()
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)
                }

                // Hidden accounts
                if let balance = financeManager.balance, let accounts = balance.hiddenAccounts, !accounts.isEmpty {
                    HiddenAccountsSection(accounts: accounts)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .task {
            await financeManager.loadBalance()
            await financeManager.loadUpcomingBills()
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .sheet(isPresented: $showHideSheet) {
            HideMoneySheet(hideAmount: $hideAmount, financeManager: financeManager)
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
}

// MARK: - Main Balance Card

struct MainBalanceCard: View {
    let balance: BalanceSummary?
    let animate: Bool

    var body: some View {
        VStack(spacing: 20) {
            if let balance = balance {
                // Balance amount
                VStack(spacing: 8) {
                    Text("AVAILABLE")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(.furgMint)

                        Text("\(Int(balance.availableBalance))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    // Hidden indicator
                    if balance.hiddenBalance > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash.fill")
                                .font(.caption)
                            Text("$\(Int(balance.hiddenBalance)) hidden from view")
                                .font(.furgCaption)
                        }
                        .foregroundColor(.furgMint.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.furgMint.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                // Total balance row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Balance")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                        Text("$\(Int(balance.totalBalance))")
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "building.columns.fill")
                        .font(.title2)
                        .foregroundColor(.furgMint.opacity(0.6))
                }
                .padding(.horizontal, 8)

            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "banknote")
                        .font(.system(size: 40))
                        .foregroundColor(.furgMint.opacity(0.5))

                    Text("Connect a bank account")
                        .font(.furgHeadline)
                        .foregroundColor(.white.opacity(0.7))

                    Text("Link your bank to see your balance and track spending")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(24)
        .glassCard()
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.furgTitle2)
                .foregroundColor(.white)

            Text(title)
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .glassCard(cornerRadius: 20, opacity: 0.08)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard(cornerRadius: 20, opacity: 0.08)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Upcoming Bills Card

struct UpcomingBillsCard: View {
    let upcoming: UpcomingBillsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Bills")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(upcoming.daysAhead ?? 30) days")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(Int(upcoming.totalAmount))")
                        .font(.furgTitle)
                        .foregroundColor(.furgWarning)

                    Text("\(upcoming.bills.count) bills due")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.furgWarning.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.furgWarning)
                }
            }

            // Bill list preview
            if !upcoming.bills.isEmpty {
                VStack(spacing: 8) {
                    ForEach(upcoming.bills.prefix(3)) { bill in
                        HStack {
                            Text(bill.merchant)
                                .font(.furgBody)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(bill.formattedAmount)
                                .font(.furgBody)
                                .foregroundColor(.white)
                            Text(bill.nextDue)
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20, opacity: 0.08)
    }
}

// MARK: - Demo Mode Card

struct DemoModeCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.furgInfo.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.furgInfo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Demo Mode")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Text("Connect a bank to see real data")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .glassCard(cornerRadius: 16, opacity: 0.08)
    }
}

// MARK: - Hidden Accounts Section

struct HiddenAccountsSection: View {
    let accounts: [ShadowAccount]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(.furgMint)
                Text("Hidden Savings")
                    .font(.furgHeadline)
                    .foregroundColor(.white)
                Spacer()
            }

            ForEach(accounts) { account in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.purpose.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.9))

                        Text(account.createdAt)
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    Text("$\(Int(account.balance))")
                        .font(.furgTitle2)
                        .foregroundColor(.furgMint)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20, opacity: 0.08)
    }
}

// MARK: - Hide Money Sheet

struct HideMoneySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var hideAmount: String
    let financeManager: FinanceManager
    @State private var purpose = "forced_savings"
    @State private var showResult = false
    @State private var resultMessage = ""

    let purposes = [
        ("forced_savings", "Forced Savings", "piggybank.fill"),
        ("savings_goal", "Savings Goal", "target"),
        ("emergency", "Emergency Fund", "cross.case.fill")
    ]

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .glassCard(cornerRadius: 12, opacity: 0.1)
                    }
                    Spacer()
                    Text("Hide Money")
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                Spacer()

                // Amount input
                VStack(spacing: 12) {
                    Text("AMOUNT")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    HStack(alignment: .center, spacing: 4) {
                        Text("$")
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundColor(.furgMint)

                        TextField("0", text: $hideAmount)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                    }
                }
                .padding(32)
                .glassCard()

                // Purpose selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("PURPOSE")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    ForEach(purposes, id: \.0) { id, label, icon in
                        Button {
                            purpose = id
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(purpose == id ? .furgMint : .white.opacity(0.4))
                                    .frame(width: 24)

                                Text(label)
                                    .font(.furgBody)
                                    .foregroundColor(.white)

                                Spacer()

                                if purpose == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.furgMint)
                                }
                            }
                            .padding(16)
                            .background(purpose == id ? Color.furgMint.opacity(0.1) : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(purpose == id ? Color.furgMint.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Hide button
                Button {
                    Task { await hideMoneyAction() }
                } label: {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                        Text("Hide Money")
                    }
                    .font(.furgHeadline)
                    .foregroundColor(.furgCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(FurgGradients.mintGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .alert("Result", isPresented: $showResult) {
            Button("OK") {
                if resultMessage.contains("Successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(resultMessage)
        }
    }

    private func hideMoneyAction() async {
        guard let amount = Double(hideAmount), amount > 0 else {
            resultMessage = "Please enter a valid amount"
            showResult = true
            return
        }

        let success = await financeManager.hideAmount(amount, purpose: purpose)

        if success {
            resultMessage = "Successfully hidden $\(Int(amount))!"
        } else {
            resultMessage = financeManager.errorMessage ?? "Failed to hide money"
        }

        showResult = true
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground()
        BalanceView()
    }
    .environmentObject(FinanceManager())
}
