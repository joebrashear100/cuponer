//
//  PurchasePlanView.swift
//  Furg
//
//  Purchase timeline and planning view
//

import SwiftUI

struct PurchasePlanView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var showBudgetSheet = false
    @State private var showFinancingCalculator = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    SummarySection(wishlistManager: wishlistManager)

                    // Budget Quick View
                    BudgetQuickView(
                        budget: wishlistManager.budget,
                        onEdit: { showBudgetSheet = true }
                    )

                    // Financing Calculator Button
                    Button(action: { showFinancingCalculator = true }) {
                        HStack {
                            Image(systemName: "percent")
                            Text("Compare Financing Options")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Timeline
                    if wishlistManager.purchasePlans.isEmpty {
                        EmptyTimelineView()
                    } else if wishlistManager.budget.monthlySavings <= 0 {
                        NoBudgetWarningView(onSetup: { showBudgetSheet = true })
                    } else {
                        TimelineSection(plans: wishlistManager.purchasePlans)
                        PurchaseOrderTable(plans: wishlistManager.purchasePlans)
                    }
                }
                .padding()
            }
            .navigationTitle("Purchase Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showBudgetSheet = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showBudgetSheet) {
                BudgetSettingsSheet(wishlistManager: wishlistManager)
            }
            .sheet(isPresented: $showFinancingCalculator) {
                FinancingCalculatorView()
                    .environmentObject(wishlistManager)
            }
        }
    }
}

// MARK: - Summary Section

struct SummarySection: View {
    @ObservedObject var wishlistManager: WishlistManager

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "Total Wishlist",
                value: String(format: "$%.0f", wishlistManager.totalWishlistValue),
                icon: "heart.fill",
                color: .pink
            )

            SummaryCard(
                title: "Monthly Savings",
                value: String(format: "$%.0f", wishlistManager.budget.monthlySavings),
                icon: "arrow.down.circle.fill",
                color: .green
            )

            SummaryCard(
                title: "Items Remaining",
                value: "\(wishlistManager.activeItems.count)",
                icon: "list.bullet",
                color: .blue
            )

            SummaryCard(
                title: "Months to Complete",
                value: wishlistManager.totalMonthsToComplete == Int.max
                    ? "—"
                    : "\(wishlistManager.totalMonthsToComplete)",
                icon: "calendar",
                color: .orange
            )
        }
    }
}

struct SummaryCard: View {
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
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Budget Quick View

struct BudgetQuickView: View {
    let budget: PurchaseBudget
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Budget Overview")
                    .font(.headline)

                Spacer()

                Button("Edit", action: onEdit)
                    .font(.subheadline)
            }

            HStack(spacing: 16) {
                BudgetMiniCard(
                    label: "Income",
                    value: String(format: "$%.0f", budget.monthlyIncome)
                )

                BudgetMiniCard(
                    label: "Expenses",
                    value: String(format: "$%.0f", budget.monthlyExpenses)
                )

                BudgetMiniCard(
                    label: "Savings Rate",
                    value: "\(Int(budget.savingsGoalPercent))%"
                )

                BudgetMiniCard(
                    label: "Current Savings",
                    value: String(format: "$%.0f", budget.currentSavings)
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BudgetMiniCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Timeline Section

struct TimelineSection: View {
    let plans: [PurchasePlan]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                        TimelineNode(
                            index: index + 1,
                            plan: plan,
                            isLast: index == plans.count - 1
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TimelineNode: View {
    let index: Int
    let plan: PurchasePlan
    let isLast: Bool

    var priorityColor: Color {
        switch plan.item.priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                // Node circle
                ZStack {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 32, height: 32)

                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                // Item details
                VStack(spacing: 4) {
                    Text(plan.item.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .frame(width: 80)

                    Text(plan.item.formattedPrice)
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text(plan.estimatedPurchaseDate, format: .dateTime.month(.abbreviated).year())
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 100)

            // Connector line
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 2)
                    .offset(y: -40)
            }
        }
    }
}

// MARK: - Purchase Order Table

struct PurchaseOrderTable: View {
    let plans: [PurchasePlan]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Purchase Order")
                .font(.headline)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("#")
                        .frame(width: 30, alignment: .leading)
                    Text("Item")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Price")
                        .frame(width: 70, alignment: .trailing)
                    Text("Date")
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
                .padding(.horizontal)

                Divider()

                // Rows
                ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                    PurchaseOrderRow(index: index + 1, plan: plan)

                    if index < plans.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct PurchaseOrderRow: View {
    let index: Int
    let plan: PurchasePlan

    var priorityColor: Color {
        switch plan.item.priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var body: some View {
        HStack {
            Text("\(index)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .leading)

            HStack(spacing: 8) {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                Text(plan.item.name)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(plan.item.formattedPrice)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .trailing)

            Text(plan.estimatedPurchaseDate, format: .dateTime.month(.abbreviated).day())
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
    }
}

// MARK: - Empty States

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No items to plan")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Add items to your wishlist to see\nwhen you can purchase them")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct NoBudgetWarningView: View {
    let onSetup: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Set up your budget")
                .font(.headline)

            Text("Configure your income and savings rate\nto see when you can afford each item")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button("Set Up Budget", action: onSetup)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Budget Settings Sheet

struct BudgetSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    let wishlistManager: WishlistManager

    @State private var monthlyIncome: String
    @State private var monthlyExpenses: String
    @State private var savingsGoalPercent: String
    @State private var currentSavings: String

    init(wishlistManager: WishlistManager) {
        self.wishlistManager = wishlistManager
        let budget = wishlistManager.budget
        _monthlyIncome = State(initialValue: budget.monthlyIncome > 0 ? String(format: "%.0f", budget.monthlyIncome) : "")
        _monthlyExpenses = State(initialValue: budget.monthlyExpenses > 0 ? String(format: "%.0f", budget.monthlyExpenses) : "")
        _savingsGoalPercent = State(initialValue: String(format: "%.0f", budget.savingsGoalPercent))
        _currentSavings = State(initialValue: budget.currentSavings > 0 ? String(format: "%.0f", budget.currentSavings) : "")
    }

    var previewBudget: PurchaseBudget {
        PurchaseBudget(
            monthlyIncome: Double(monthlyIncome) ?? 0,
            monthlyExpenses: Double(monthlyExpenses) ?? 0,
            savingsGoalPercent: Double(savingsGoalPercent) ?? 20,
            currentSavings: Double(currentSavings) ?? 0
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Monthly Income & Expenses") {
                    HStack {
                        Text("Monthly Income")
                        Spacer()
                        Text("$")
                        TextField("0", text: $monthlyIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Monthly Expenses")
                        Spacer()
                        Text("$")
                        TextField("0", text: $monthlyExpenses)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Savings") {
                    HStack {
                        Text("Savings Goal")
                        Spacer()
                        TextField("20", text: $savingsGoalPercent)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("% of disposable")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Current Savings")
                        Spacer()
                        Text("$")
                        TextField("0", text: $currentSavings)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Preview") {
                    HStack {
                        Text("Disposable Income")
                        Spacer()
                        Text(String(format: "$%.0f", previewBudget.disposableIncome))
                            .foregroundColor(previewBudget.disposableIncome >= 0 ? .primary : .red)
                    }

                    HStack {
                        Text("Monthly Savings")
                        Spacer()
                        Text(String(format: "$%.0f", previewBudget.monthlySavings))
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Annual Savings")
                        Spacer()
                        Text(String(format: "$%.0f", previewBudget.monthlySavings * 12))
                            .foregroundColor(.green)
                    }
                }

                Section {
                    Button("Save Budget") {
                        saveBudget()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Budget Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveBudget() {
        wishlistManager.updateBudget(previewBudget)
        dismiss()
    }
}

#Preview {
    PurchasePlanView()
        .environmentObject(WishlistManager())
}
