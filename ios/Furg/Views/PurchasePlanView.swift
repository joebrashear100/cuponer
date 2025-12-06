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
    @State private var animate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Purchase Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.furgCharcoal)

                        Text("Track your path to ownership")
                            .font(.subheadline)
                            .foregroundColor(.furgCharcoal.opacity(0.6))
                    }

                    Spacer()

                    Button(action: { showBudgetSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.furgMint)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.3)))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .offset(y: animate ? 0 : -20)
                .opacity(animate ? 1 : 0)

                // Summary Cards
                GlassSummarySection(wishlistManager: wishlistManager)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Budget Quick View
                GlassBudgetQuickView(
                    budget: wishlistManager.budget,
                    onEdit: { showBudgetSheet = true }
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                // Financing Calculator Button
                Button(action: { showFinancingCalculator = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)

                            Image(systemName: "percent")
                                .font(.body.bold())
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Financing Calculator")
                                .font(.headline)
                                .foregroundColor(.furgCharcoal)

                            Text("Compare payment options")
                                .font(.caption)
                                .foregroundColor(.furgCharcoal.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.furgMint)
                    }
                    .padding()
                    .glassCard()
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)

                // Timeline
                if wishlistManager.purchasePlans.isEmpty {
                    GlassEmptyTimelineView()
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                } else if wishlistManager.budget.monthlySavings <= 0 {
                    GlassNoBudgetWarningView(onSetup: { showBudgetSheet = true })
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                } else {
                    GlassTimelineSection(plans: wishlistManager.purchasePlans)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                    GlassPurchaseOrderTable(plans: wishlistManager.purchasePlans)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)
                }

                Spacer(minLength: 100)
            }
        }
        .onAppear { animate = true }
        .sheet(isPresented: $showBudgetSheet) {
            GlassBudgetSettingsSheet(wishlistManager: wishlistManager)
        }
        .sheet(isPresented: $showFinancingCalculator) {
            FinancingCalculatorView()
                .environmentObject(wishlistManager)
        }
    }
}

// MARK: - Glass Summary Section

struct GlassSummarySection: View {
    @ObservedObject var wishlistManager: WishlistManager

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            GlassSummaryCard(
                title: "Total Wishlist",
                value: String(format: "$%.0f", wishlistManager.totalWishlistValue),
                icon: "heart.fill",
                gradient: [.furgPistachio, .furgMint]
            )

            GlassSummaryCard(
                title: "Monthly Savings",
                value: String(format: "$%.0f", wishlistManager.budget.monthlySavings),
                icon: "arrow.down.circle.fill",
                gradient: [.furgMint, .furgSeafoam]
            )

            GlassSummaryCard(
                title: "Items Remaining",
                value: "\(wishlistManager.activeItems.count)",
                icon: "list.bullet",
                gradient: [.furgSeafoam, .furgSage]
            )

            GlassSummaryCard(
                title: "Months to Complete",
                value: wishlistManager.totalMonthsToComplete == Int.max
                    ? "—"
                    : "\(wishlistManager.totalMonthsToComplete)",
                icon: "calendar",
                gradient: [.furgSage, .furgPistachio]
            )
        }
        .padding(.horizontal)
    }
}

struct GlassSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.furgCharcoal)

            Text(title)
                .font(.caption)
                .foregroundColor(.furgCharcoal.opacity(0.6))
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Glass Budget Quick View

struct GlassBudgetQuickView: View {
    let budget: PurchaseBudget
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Budget Overview")
                    .font(.headline)
                    .foregroundColor(.furgCharcoal)

                Spacer()

                Button(action: onEdit) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.furgMint)
                }
            }

            HStack(spacing: 12) {
                GlassBudgetMiniCard(
                    label: "Income",
                    value: String(format: "$%.0f", budget.monthlyIncome)
                )

                GlassBudgetMiniCard(
                    label: "Expenses",
                    value: String(format: "$%.0f", budget.monthlyExpenses)
                )

                GlassBudgetMiniCard(
                    label: "Savings %",
                    value: "\(Int(budget.savingsGoalPercent))%"
                )

                GlassBudgetMiniCard(
                    label: "Saved",
                    value: String(format: "$%.0f", budget.currentSavings)
                )
            }
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }
}

struct GlassBudgetMiniCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.furgCharcoal)

            Text(label)
                .font(.caption2)
                .foregroundColor(.furgCharcoal.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - Glass Timeline Section

struct GlassTimelineSection: View {
    let plans: [PurchasePlan]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(.furgCharcoal)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                        GlassTimelineNode(
                            index: index + 1,
                            plan: plan,
                            isLast: index == plans.count - 1
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical)
        .glassCard()
        .padding(.horizontal)
    }
}

struct GlassTimelineNode: View {
    let index: Int
    let plan: PurchasePlan
    let isLast: Bool

    var priorityGradient: [Color] {
        switch plan.item.priority {
        case .low: return [.gray, .gray.opacity(0.7)]
        case .medium: return [.furgSeafoam, .furgMint]
        case .high: return [.furgMint, .furgPistachio]
        case .urgent: return [.furgWarning, .orange]
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                // Node circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: priorityGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                        .shadow(color: priorityGradient[0].opacity(0.3), radius: 4, x: 0, y: 2)

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
                        .foregroundColor(.furgCharcoal)
                        .lineLimit(1)
                        .frame(width: 80)

                    Text(plan.item.formattedPrice)
                        .font(.caption2)
                        .foregroundColor(.furgMint)
                        .fontWeight(.semibold)

                    Text(plan.estimatedPurchaseDate, format: .dateTime.month(.abbreviated).year())
                        .font(.caption2)
                        .foregroundColor(.furgCharcoal.opacity(0.5))
                }
            }
            .frame(width: 100)

            // Connector line
            if !isLast {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.furgMint.opacity(0.5), .furgSeafoam.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 40, height: 3)
                    .cornerRadius(1.5)
                    .offset(y: -40)
            }
        }
    }
}

// MARK: - Glass Purchase Order Table

struct GlassPurchaseOrderTable: View {
    let plans: [PurchasePlan]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Purchase Order")
                .font(.headline)
                .foregroundColor(.furgCharcoal)

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
                .foregroundColor(.furgCharcoal.opacity(0.6))
                .padding(.vertical, 8)
                .padding(.horizontal)

                Rectangle()
                    .fill(Color.furgMint.opacity(0.3))
                    .frame(height: 1)

                // Rows
                ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                    GlassPurchaseOrderRow(index: index + 1, plan: plan)

                    if index < plans.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }
}

struct GlassPurchaseOrderRow: View {
    let index: Int
    let plan: PurchasePlan

    var priorityGradient: [Color] {
        switch plan.item.priority {
        case .low: return [.gray, .gray.opacity(0.7)]
        case .medium: return [.furgSeafoam, .furgMint]
        case .high: return [.furgMint, .furgPistachio]
        case .urgent: return [.furgWarning, .orange]
        }
    }

    var body: some View {
        HStack {
            Text("\(index)")
                .font(.subheadline)
                .foregroundColor(.furgCharcoal.opacity(0.5))
                .frame(width: 30, alignment: .leading)

            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(
                        colors: priorityGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 10, height: 10)

                Text(plan.item.name)
                    .font(.subheadline)
                    .foregroundColor(.furgCharcoal)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(plan.item.formattedPrice)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.furgCharcoal)
                .frame(width: 70, alignment: .trailing)

            Text(plan.estimatedPurchaseDate, format: .dateTime.month(.abbreviated).day())
                .font(.caption)
                .foregroundColor(.furgCharcoal.opacity(0.6))
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
    }
}

// MARK: - Glass Empty States

struct GlassEmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.furgMint.opacity(0.3), .furgSeafoam.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.furgMint)
            }

            Text("No items to plan")
                .font(.headline)
                .foregroundColor(.furgCharcoal)

            Text("Add items to your wishlist to see\nwhen you can purchase them")
                .font(.subheadline)
                .foregroundColor(.furgCharcoal.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassCard()
        .padding(.horizontal)
    }
}

struct GlassNoBudgetWarningView: View {
    let onSetup: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.furgWarning.opacity(0.3), .orange.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.furgWarning)
            }

            Text("Set up your budget")
                .font(.headline)
                .foregroundColor(.furgCharcoal)

            Text("Configure your income and savings rate\nto see when you can afford each item")
                .font(.subheadline)
                .foregroundColor(.furgCharcoal.opacity(0.6))
                .multilineTextAlignment(.center)

            Button(action: onSetup) {
                Text("Set Up Budget")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassCard()
        .padding(.horizontal)
    }
}

// MARK: - Glass Budget Settings Sheet

struct GlassBudgetSettingsSheet: View {
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
        ZStack {
            AnimatedMeshBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.furgCharcoal.opacity(0.6))

                        Spacer()

                        Text("Budget Settings")
                            .font(.headline)
                            .foregroundColor(.furgCharcoal)

                        Spacer()

                        Button("Save") { saveBudget() }
                            .foregroundColor(.furgMint)
                            .fontWeight(.semibold)
                    }
                    .padding()

                    // Income & Expenses Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MONTHLY INCOME & EXPENSES")
                            .font(.caption)
                            .foregroundColor(.furgCharcoal.opacity(0.6))
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            GlassInputRow(
                                label: "Monthly Income",
                                prefix: "$",
                                text: $monthlyIncome
                            )

                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                                .padding(.horizontal)

                            GlassInputRow(
                                label: "Monthly Expenses",
                                prefix: "$",
                                text: $monthlyExpenses
                            )
                        }
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // Savings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SAVINGS")
                            .font(.caption)
                            .foregroundColor(.furgCharcoal.opacity(0.6))
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            GlassInputRow(
                                label: "Savings Goal",
                                suffix: "% of disposable",
                                text: $savingsGoalPercent
                            )

                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                                .padding(.horizontal)

                            GlassInputRow(
                                label: "Current Savings",
                                prefix: "$",
                                text: $currentSavings
                            )
                        }
                        .glassCard()
                        .padding(.horizontal)
                    }

                    // Preview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREVIEW")
                            .font(.caption)
                            .foregroundColor(.furgCharcoal.opacity(0.6))
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            GlassPreviewRow(
                                label: "Disposable Income",
                                value: String(format: "$%.0f", previewBudget.disposableIncome),
                                valueColor: previewBudget.disposableIncome >= 0 ? .furgCharcoal : .furgDanger
                            )

                            GlassPreviewRow(
                                label: "Monthly Savings",
                                value: String(format: "$%.0f", previewBudget.monthlySavings),
                                valueColor: .furgSuccess,
                                isBold: true
                            )

                            GlassPreviewRow(
                                label: "Annual Savings",
                                value: String(format: "$%.0f", previewBudget.monthlySavings * 12),
                                valueColor: .furgSuccess
                            )
                        }
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func saveBudget() {
        wishlistManager.updateBudget(previewBudget)
        dismiss()
    }
}

struct GlassInputRow: View {
    let label: String
    var prefix: String? = nil
    var suffix: String? = nil
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.furgCharcoal)

            Spacer()

            if let prefix = prefix {
                Text(prefix)
                    .foregroundColor(.furgCharcoal.opacity(0.5))
            }

            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: suffix != nil ? 60 : 100)
                .foregroundColor(.furgCharcoal)

            if let suffix = suffix {
                Text(suffix)
                    .font(.caption)
                    .foregroundColor(.furgCharcoal.opacity(0.5))
            }
        }
        .padding()
    }
}

struct GlassPreviewRow: View {
    let label: String
    let value: String
    var valueColor: Color = .furgCharcoal
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.furgCharcoal)

            Spacer()

            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(isBold ? .semibold : .regular)
        }
    }
}

// Keep old names for backward compatibility
typealias SummarySection = GlassSummarySection
typealias SummaryCard = GlassSummaryCard
typealias BudgetQuickView = GlassBudgetQuickView
typealias BudgetMiniCard = GlassBudgetMiniCard
typealias TimelineSection = GlassTimelineSection
typealias TimelineNode = GlassTimelineNode
typealias PurchaseOrderTable = GlassPurchaseOrderTable
typealias PurchaseOrderRow = GlassPurchaseOrderRow
typealias EmptyTimelineView = GlassEmptyTimelineView
typealias NoBudgetWarningView = GlassNoBudgetWarningView
typealias BudgetSettingsSheet = GlassBudgetSettingsSheet

#Preview {
    ZStack {
        AnimatedMeshBackground()
        PurchasePlanView()
            .environmentObject(WishlistManager())
    }
}
