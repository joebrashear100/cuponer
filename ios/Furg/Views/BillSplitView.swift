//
//  BillSplitView.swift
//  Furg
//
//  Split expenses with friends and track who owes what
//

import SwiftUI

struct BillSplitView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var showNewSplit = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Balance summary
                        balanceSummary
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Tab selector
                        HStack(spacing: 0) {
                            TabButton(title: "Owed to You", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            TabButton(title: "You Owe", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                        }
                        .padding(4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Split list
                        if selectedTab == 0 {
                            owedToYouSection
                        } else {
                            youOweSection
                        }

                        // Recent splits
                        recentSplitsSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNewSplit = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.furgCharcoal)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.furgMint, .furgSeafoam],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .furgMint.opacity(0.4), radius: 12, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Split Bills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .sheet(isPresented: $showNewSplit) {
                NewSplitSheet()
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Balance Summary

    private var balanceSummary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("You're Owed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Text("$234.50")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.furgSuccess)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.furgSuccess.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 8) {
                Text("You Owe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Text("$67.25")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.furgDanger)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.furgDanger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Owed to You

    private var owedToYouSection: some View {
        VStack(spacing: 12) {
            SplitPersonRow(
                name: "Alex Chen",
                initials: "AC",
                amount: 87.50,
                isOwed: true,
                details: "Dinner at Nobu"
            )

            SplitPersonRow(
                name: "Jordan Smith",
                initials: "JS",
                amount: 45.00,
                isOwed: true,
                details: "Uber to airport"
            )

            SplitPersonRow(
                name: "Sam Wilson",
                initials: "SW",
                amount: 102.00,
                isOwed: true,
                details: "Concert tickets"
            )
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.2), value: animate)
    }

    // MARK: - You Owe

    private var youOweSection: some View {
        VStack(spacing: 12) {
            SplitPersonRow(
                name: "Taylor Brown",
                initials: "TB",
                amount: 67.25,
                isOwed: false,
                details: "Groceries split"
            )
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.spring(response: 0.6).delay(0.2), value: animate)
    }

    // MARK: - Recent Splits

    private var recentSplitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Splits")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 10) {
                RecentSplitRow(
                    title: "Dinner at Nobu",
                    totalAmount: 350.00,
                    splitWith: 4,
                    date: "Dec 5",
                    isSettled: false
                )

                RecentSplitRow(
                    title: "Uber to airport",
                    totalAmount: 90.00,
                    splitWith: 2,
                    date: "Dec 3",
                    isSettled: false
                )

                RecentSplitRow(
                    title: "Movie night",
                    totalAmount: 120.00,
                    splitWith: 4,
                    date: "Nov 28",
                    isSettled: true
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct SplitPersonRow: View {
    let name: String
    let initials: String
    let amount: Double
    let isOwed: Bool
    let details: String

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(details)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(String(format: "%.2f", amount))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isOwed ? .furgSuccess : .furgDanger)

                Button {
                    // Send reminder or pay
                } label: {
                    Text(isOwed ? "Remind" : "Pay")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.furgMint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.furgMint.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

struct RecentSplitRow: View {
    let title: String
    let totalAmount: Double
    let splitWith: Int
    let date: String
    let isSettled: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isSettled ? Color.furgSuccess.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: isSettled ? "checkmark.circle.fill" : "person.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isSettled ? .furgSuccess : .white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text("\(splitWith) people • $\(String(format: "%.2f", totalAmount))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))

                Text(isSettled ? "Settled" : "Pending")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSettled ? .furgSuccess : .furgWarning)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - New Split Sheet

struct NewSplitSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var description = ""
    @State private var amount = ""
    @State private var selectedFriends: Set<String> = []
    @State private var splitType: BillSplitType = .equal

    let friends = [
        ("Alex Chen", "AC"),
        ("Jordan Smith", "JS"),
        ("Sam Wilson", "SW"),
        ("Taylor Brown", "TB"),
        ("Casey Davis", "CD")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Amount input
                        VStack(spacing: 8) {
                            Text("TOTAL AMOUNT")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)

                            HStack(alignment: .center) {
                                Text("$")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundColor(.furgMint)

                                TextField("0.00", text: $amount)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.03))
                        )

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)

                            TextField("What's this for?", text: $description)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Split type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SPLIT TYPE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)

                            HStack(spacing: 10) {
                                SplitTypeButton(type: .equal, isSelected: splitType == .equal) {
                                    splitType = .equal
                                }
                                SplitTypeButton(type: .percentage, isSelected: splitType == .percentage) {
                                    splitType = .percentage
                                }
                                SplitTypeButton(type: .custom, isSelected: splitType == .custom) {
                                    splitType = .custom
                                }
                            }
                        }

                        // Friends selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SPLIT WITH")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)

                            VStack(spacing: 10) {
                                ForEach(friends, id: \.0) { friend in
                                    FriendSelectRow(
                                        name: friend.0,
                                        initials: friend.1,
                                        isSelected: selectedFriends.contains(friend.0)
                                    ) {
                                        if selectedFriends.contains(friend.0) {
                                            selectedFriends.remove(friend.0)
                                        } else {
                                            selectedFriends.insert(friend.0)
                                        }
                                    }
                                }
                            }
                        }

                        // Per person amount
                        if !selectedFriends.isEmpty, let totalAmount = Double(amount), totalAmount > 0 {
                            HStack {
                                Text("Per person:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))

                                Spacer()

                                Text("$\(String(format: "%.2f", totalAmount / Double(selectedFriends.count + 1)))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.furgMint)
                            }
                            .padding(16)
                            .background(Color.furgMint.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Create button
                        Button {
                            dismiss()
                        } label: {
                            Text("Create Split")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.furgCharcoal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.furgMint, .furgSeafoam],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(amount.isEmpty || selectedFriends.isEmpty)
                        .opacity(amount.isEmpty || selectedFriends.isEmpty ? 0.5 : 1)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

enum BillSplitType {
    case equal, percentage, custom

    var label: String {
        switch self {
        case .equal: return "Equal"
        case .percentage: return "By %"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .equal: return "equal.circle.fill"
        case .percentage: return "percent"
        case .custom: return "slider.horizontal.3"
        }
    }
}

struct SplitTypeButton: View {
    let type: BillSplitType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 18))

                Text(type.label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.furgMint : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct FriendSelectRow: View {
    let name: String
    let initials: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.furgMint.opacity(0.5), .furgSeafoam.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Text(initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .furgMint : .white.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.furgMint.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.furgMint.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    BillSplitView()
}
