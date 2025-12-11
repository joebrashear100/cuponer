//
//  ConnectBankViewV2.swift
//  Furg
//
//  Bank connection flow (Plaid-style integration)
//

import SwiftUI

struct ConnectBankViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedBank: BankInstitution?
    @State private var connectionState: ConnectionState = .selectBank
    @State private var showCredentials = false

    enum ConnectionState {
        case selectBank
        case authenticating
        case selectingAccounts
        case success
    }

    var filteredBanks: [BankInstitution] {
        if searchText.isEmpty {
            return popularBanks
        }
        return allBanks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                switch connectionState {
                case .selectBank:
                    bankSelectionView
                case .authenticating:
                    authenticatingView
                case .selectingAccounts:
                    accountSelectionView
                case .success:
                    successView
                }
            }
            .navigationTitle(connectionState == .selectBank ? "Connect Bank" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Bank Selection View

    var bankSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.v2TextTertiary)

                    TextField("Search banks...", text: $searchText)
                        .font(.v2Body)
                        .foregroundColor(.v2TextPrimary)
                }
                .padding(14)
                .background(Color.v2CardBackground)
                .cornerRadius(12)

                // Security badge
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.v2Success)

                    Text("Bank-level security. Your credentials are encrypted and never stored.")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextSecondary)
                }
                .padding(12)
                .background(Color.v2Success.opacity(0.1))
                .cornerRadius(10)

                // Popular banks
                if searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Banks")
                            .font(.v2Headline)
                            .foregroundColor(.v2TextPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(popularBanks) { bank in
                                Button {
                                    selectedBank = bank
                                    startConnection()
                                } label: {
                                    PopularBankCard(bank: bank)
                                }
                            }
                        }
                    }
                }

                // All banks list
                VStack(alignment: .leading, spacing: 12) {
                    Text(searchText.isEmpty ? "All Banks" : "Results")
                        .font(.v2Headline)
                        .foregroundColor(.v2TextPrimary)

                    V2Card(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(filteredBanks) { bank in
                                Button {
                                    selectedBank = bank
                                    startConnection()
                                } label: {
                                    BankRowV2(bank: bank)
                                }

                                if bank.id != filteredBanks.last?.id {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                    }
                }

                // Manual connection option
                Button {
                    // Manual account entry
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Can't find your bank?")
                                .font(.v2Body)
                            Text("Add account manually")
                                .font(.v2CaptionSmall)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.v2TextSecondary)
                    .padding(16)
                    .background(Color.v2CardBackground)
                    .cornerRadius(12)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Authenticating View

    var authenticatingView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let bank = selectedBank {
                // Bank logo
                ZStack {
                    Circle()
                        .fill(bank.color.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: bank.icon)
                        .font(.system(size: 40))
                        .foregroundColor(bank.color)
                }

                VStack(spacing: 8) {
                    Text("Connecting to \(bank.name)")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("Please wait while we establish a secure connection...")
                        .font(.v2Body)
                        .foregroundColor(.v2TextSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Loading animation
            ZStack {
                Circle()
                    .stroke(Color.v2CardBackground, lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.v2Primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
            }

            // Status steps
            VStack(alignment: .leading, spacing: 12) {
                ConnectionStep(text: "Encrypting connection", isComplete: true)
                ConnectionStep(text: "Verifying credentials", isComplete: false, isActive: true)
                ConnectionStep(text: "Fetching accounts", isComplete: false)
            }
            .padding(20)
            .background(Color.v2CardBackground)
            .cornerRadius(16)

            Spacer()
        }
        .padding(20)
        .onAppear {
            // Simulate connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    connectionState = .selectingAccounts
                }
            }
        }
    }

    // MARK: - Account Selection View

    var accountSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let bank = selectedBank {
                // Bank logo
                ZStack {
                    Circle()
                        .fill(bank.color.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: bank.icon)
                        .font(.system(size: 32))
                        .foregroundColor(bank.color)
                }

                Text("Select Accounts")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)

                Text("Choose which accounts to connect to Furg")
                    .font(.v2Body)
                    .foregroundColor(.v2TextSecondary)
            }

            // Account list
            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(sampleAccounts) { account in
                        AccountSelectionRow(account: account)

                        if account.id != sampleAccounts.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }

            Spacer()

            // Connect button
            Button {
                withAnimation {
                    connectionState = .success
                }
            } label: {
                Text("Connect Selected Accounts")
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.v2Primary)
                    .cornerRadius(14)
            }
        }
        .padding(20)
    }

    // MARK: - Success View

    var successView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color.v2Success.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.v2Success.opacity(0.3))
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.v2Success)
            }

            VStack(spacing: 12) {
                Text("Successfully Connected!")
                    .font(.v2DisplaySmall)
                    .foregroundColor(.v2TextPrimary)

                if let bank = selectedBank {
                    Text("\(bank.name) is now linked to your Furg account")
                        .font(.v2Body)
                        .foregroundColor(.v2TextSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Summary
            V2Card {
                VStack(spacing: 16) {
                    HStack {
                        Text("Accounts Connected")
                            .font(.v2Body)
                            .foregroundColor(.v2TextSecondary)
                        Spacer()
                        Text("2")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Primary)
                    }

                    HStack {
                        Text("Total Balance")
                            .font(.v2Body)
                            .foregroundColor(.v2TextSecondary)
                        Spacer()
                        Text("$12,450.32")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)
                    }

                    HStack {
                        Text("Auto-sync")
                            .font(.v2Body)
                            .foregroundColor(.v2TextSecondary)
                        Spacer()
                        Text("Enabled")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Success)
                    }
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.v2Primary)
                    .cornerRadius(14)
            }
        }
        .padding(20)
    }

    // MARK: - Helpers

    func startConnection() {
        withAnimation {
            connectionState = .authenticating
        }
    }

    // MARK: - Sample Data

    var popularBanks: [BankInstitution] {
        [
            BankInstitution(name: "Chase", icon: "building.columns.fill", color: .blue),
            BankInstitution(name: "Bank of America", icon: "building.columns.fill", color: .red),
            BankInstitution(name: "Wells Fargo", icon: "building.columns.fill", color: .yellow),
            BankInstitution(name: "Citi", icon: "building.columns.fill", color: .blue),
            BankInstitution(name: "Capital One", icon: "creditcard.fill", color: .red),
            BankInstitution(name: "US Bank", icon: "building.columns.fill", color: .blue)
        ]
    }

    var allBanks: [BankInstitution] {
        popularBanks + [
            BankInstitution(name: "TD Bank", icon: "building.columns.fill", color: .green),
            BankInstitution(name: "PNC Bank", icon: "building.columns.fill", color: .orange),
            BankInstitution(name: "Truist", icon: "building.columns.fill", color: .purple),
            BankInstitution(name: "USAA", icon: "building.columns.fill", color: .blue),
            BankInstitution(name: "Navy Federal", icon: "building.columns.fill", color: .blue),
            BankInstitution(name: "Ally Bank", icon: "building.columns.fill", color: .purple),
            BankInstitution(name: "Discover Bank", icon: "creditcard.fill", color: .orange),
            BankInstitution(name: "Marcus by Goldman Sachs", icon: "building.columns.fill", color: .blue),
            BankInstitution(name: "American Express", icon: "creditcard.fill", color: .blue),
            BankInstitution(name: "Charles Schwab", icon: "chart.line.uptrend.xyaxis", color: .blue)
        ]
    }

    var sampleAccounts: [BankAccountV2] {
        [
            BankAccountV2(name: "Checking ••••4523", type: "Checking", balance: 8245.67, isSelected: true),
            BankAccountV2(name: "Savings ••••8901", type: "Savings", balance: 4204.65, isSelected: true),
            BankAccountV2(name: "Credit Card ••••2234", type: "Credit Card", balance: -1523.45, isSelected: false)
        ]
    }
}

// MARK: - Bank Institution Model

struct BankInstitution: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

// MARK: - Bank Account Model

struct BankAccountV2: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let balance: Double
    var isSelected: Bool
}

// MARK: - Popular Bank Card

struct PopularBankCard: View {
    let bank: BankInstitution

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(bank.color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: bank.icon)
                    .font(.system(size: 24))
                    .foregroundColor(bank.color)
            }

            Text(bank.name)
                .font(.v2Caption)
                .foregroundColor(.v2TextPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.v2CardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Bank Row

struct BankRowV2: View {
    let bank: BankInstitution

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(bank.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: bank.icon)
                    .font(.system(size: 18))
                    .foregroundColor(bank.color)
            }

            Text(bank.name)
                .font(.v2Body)
                .foregroundColor(.v2TextPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.v2TextTertiary)
        }
        .padding(16)
    }
}

// MARK: - Connection Step

struct ConnectionStep: View {
    let text: String
    let isComplete: Bool
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.v2Success : (isActive ? Color.v2Primary : Color.v2BackgroundSecondary))
                    .frame(width: 24, height: 24)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.v2TextInverse)
                } else if isActive {
                    Circle()
                        .fill(Color.v2Primary.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }

            Text(text)
                .font(.v2Body)
                .foregroundColor(isComplete ? .v2Success : (isActive ? .v2TextPrimary : .v2TextTertiary))
        }
    }
}

// MARK: - Account Selection Row

struct AccountSelectionRow: View {
    @State var account: BankAccountV2

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                account.isSelected.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(account.isSelected ? Color.v2Primary : Color.v2TextTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if account.isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.v2Primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.v2TextInverse)
                    }
                }
            }

            // Icon
            ZStack {
                Circle()
                    .fill(Color.v2Primary.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: account.type == "Credit Card" ? "creditcard.fill" : "banknote.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.v2Primary)
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)

                Text(account.type)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }

            Spacer()

            Text(account.balance >= 0 ? "$\(String(format: "%.2f", account.balance))" : "-$\(String(format: "%.2f", abs(account.balance)))")
                .font(.v2BodyBold)
                .foregroundColor(account.balance >= 0 ? .v2TextPrimary : .v2Danger)
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview {
    ConnectBankViewV2()
}
