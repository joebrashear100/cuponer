//
//  ConnectBankView.swift
//  Furg
//
//  Bank connection flow with Plaid integration
//

import SwiftUI

struct ConnectBankView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    @Environment(\.dismiss) var dismiss
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.furgCharcoal
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.furgMint.opacity(0.1),
                        Color.clear,
                        Color.furgSeafoam.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Hero illustration
                        heroSection
                            .offset(y: animate ? 0 : -20)
                            .opacity(animate ? 1 : 0)

                        // Connected banks
                        if !plaidManager.linkedBanks.isEmpty {
                            connectedBanksSection
                                .offset(y: animate ? 0 : 20)
                                .opacity(animate ? 1 : 0)
                        }

                        // Connect button
                        connectButtonSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Security info
                        securitySection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Connect Banks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Bank icons animation
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.1))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.furgMint.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "building.columns.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Connect Your Accounts")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Securely link your bank accounts to get personalized insights and track your finances in real-time.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Connected Banks Section

    private var connectedBanksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connected Accounts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if plaidManager.isLoading {
                    ProgressView()
                        .tint(.furgMint)
                } else {
                    Button {
                        Task { await plaidManager.syncBanks() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.furgMint)
                    }
                }
            }

            ForEach(plaidManager.linkedBanks) { bank in
                ConnectedBankRow(bank: bank) {
                    Task { await plaidManager.removeBank(bank) }
                }
            }

            if let lastSync = plaidManager.lastSyncDate {
                Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Connect Button Section

    private var connectButtonSection: some View {
        VStack(spacing: 16) {
            Button {
                Task { await plaidManager.presentPlaidLink() }
            } label: {
                HStack(spacing: 12) {
                    if plaidManager.isLoading {
                        ProgressView()
                            .tint(.furgCharcoal)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }

                    Text(plaidManager.linkedBanks.isEmpty ? "Connect Your Bank" : "Add Another Bank")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.furgCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(plaidManager.isLoading)

            if let error = plaidManager.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.furgDanger)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(spacing: 20) {
            // Powered by Plaid badge
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.furgMint)

                Text("Powered by Plaid")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.05))
            )

            // Security features
            VStack(spacing: 16) {
                SecurityFeatureRow(
                    icon: "lock.fill",
                    title: "Bank-Level Security",
                    description: "Your credentials are encrypted and never stored on our servers"
                )

                SecurityFeatureRow(
                    icon: "eye.slash.fill",
                    title: "Read-Only Access",
                    description: "We can only view your transactions, never move money"
                )

                SecurityFeatureRow(
                    icon: "checkmark.shield.fill",
                    title: "256-bit Encryption",
                    description: "Same security used by major banks worldwide"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
            )

            // Supported banks
            VStack(spacing: 12) {
                Text("Works with 12,000+ financial institutions")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))

                HStack(spacing: 16) {
                    ForEach(["Chase", "Bank of America", "Wells Fargo", "Citi"], id: \.self) { bank in
                        Text(bank)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Connected Bank Row

private struct ConnectedBankRow: View {
    let bank: PlaidManager.LinkedBank
    let onRemove: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.furgMint.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.furgMint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bank.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(bank.accounts.count) account\(bank.accounts.count == 1 ? "" : "s") linked")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Disconnect", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .confirmationDialog(
            "Disconnect \(bank.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("This will remove access to your accounts at \(bank.name). You can reconnect anytime.")
        }
    }
}

// MARK: - Security Feature Row

private struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.furgMint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(2)
            }
        }
    }
}

#Preview {
    ConnectBankView()
        .environmentObject(PlaidManager())
}
