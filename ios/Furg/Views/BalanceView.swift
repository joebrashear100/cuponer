//
//  BalanceView.swift
//  Furg
//
//  Balance dashboard with hide/reveal functionality
//

import SwiftUI

struct BalanceView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showHideSheet = false
    @State private var hideAmount = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let balance = financeManager.balance {
                        // Main balance card
                        VStack(spacing: 16) {
                            Text("Available")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Text("$\(Int(balance.visibleBalance))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)

                            if balance.hiddenBalance > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.caption)
                                    Text("$\(Int(balance.hiddenBalance)) hidden")
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(16)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(
                                title: "Total Balance",
                                value: "$\(Int(balance.totalBalance))",
                                icon: "dollarsign.circle.fill",
                                color: .blue
                            )

                            StatCard(
                                title: "Safety Buffer",
                                value: "$\(Int(balance.safetyBuffer))",
                                icon: "shield.fill",
                                color: .green
                            )

                            StatCard(
                                title: "Truly Available",
                                value: "$\(Int(balance.trulyAvailable))",
                                icon: "checkmark.circle.fill",
                                color: .purple
                            )

                            StatCard(
                                title: "Hidden",
                                value: "$\(Int(balance.hiddenBalance))",
                                icon: "eye.slash.fill",
                                color: .orange
                            )
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button(action: { showHideSheet = true }) {
                                HStack {
                                    Image(systemName: "eye.slash.fill")
                                    Text("Hide Money")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button(action: { /* Reveal money */ }) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("Reveal Hidden Money")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }

                        // Upcoming bills
                        if let upcoming = financeManager.upcomingBills {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Bills (30 days)")
                                    .font(.headline)

                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("$\(Int(upcoming.total))")
                                            .font(.title2)
                                            .bold()
                                        Text("\(upcoming.count) bills")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }

                    } else {
                        // Loading or error state
                        VStack(spacing: 16) {
                            if financeManager.isLoading {
                                ProgressView()
                                Text("Loading balance...")
                                    .foregroundColor(.gray)
                            } else {
                                Text("Connect a bank to see your balance")
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding()
            }
            .navigationTitle("Balance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await financeManager.refreshAll() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await financeManager.loadBalance()
                await financeManager.loadUpcomingBills()
            }
            .sheet(isPresented: $showHideSheet) {
                HideMoneySheet(hideAmount: $hideAmount, financeManager: financeManager)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct HideMoneySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var hideAmount: String
    let financeManager: FinanceManager
    @State private var purpose = "forced_savings"
    @State private var showResult = false
    @State private var resultMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Amount") {
                    TextField("Amount to hide", text: $hideAmount)
                        .keyboardType(.decimalPad)
                }

                Section("Purpose") {
                    Picker("Purpose", selection: $purpose) {
                        Text("Forced Savings").tag("forced_savings")
                        Text("Savings Goal").tag("savings_goal")
                        Text("Emergency Fund").tag("emergency")
                    }
                }

                Section {
                    Button("Hide Money") {
                        Task {
                            await hideMoneyAction()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Hide Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Result", isPresented: $showResult) {
                Button("OK") {
                    if resultMessage.contains("Hidden") {
                        dismiss()
                    }
                }
            } message: {
                Text(resultMessage)
            }
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
    BalanceView()
        .environmentObject(FinanceManager())
}
