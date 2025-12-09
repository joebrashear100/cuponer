//
//  CategoriesView.swift
//  Furg
//
//  Detailed spending breakdown by category with trends and analysis
//

import SwiftUI
import Charts

// MARK: - Category Spending Model

struct CategorySpending: Identifiable {
    let id = UUID()
    let category: SpendingCategory
    let amount: Double
    let budget: Double?
    let previousMonth: Double
    let transactionCount: Int
    let topMerchants: [String]

    var percentOfTotal: Double { 0 } // Computed in view
    var vsLastMonth: Double { ((amount - previousMonth) / previousMonth) * 100 }
    var isOverBudget: Bool { budget != nil && amount > budget! }
}

enum SpendingCategory: String, CaseIterable, Identifiable {
    case housing = "Housing"
    case food = "Food & Dining"
    case transportation = "Transportation"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case health = "Health & Fitness"
    case subscriptions = "Subscriptions"
    case travel = "Travel"
    case personal = "Personal Care"
    case education = "Education"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .housing: return "house.fill"
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        case .subscriptions: return "repeat"
        case .travel: return "airplane"
        case .personal: return "sparkles"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .housing: return .blue
        case .food: return .orange
        case .transportation: return .purple
        case .shopping: return .pink
        case .utilities: return .yellow
        case .entertainment: return .green
        case .health: return .red
        case .subscriptions: return .indigo
        case .travel: return .cyan
        case .personal: return .mint
        case .education: return .brown
        case .other: return .gray
        }
    }
}

// MARK: - Categories View

struct CategoriesView: View {
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedCategory: CategorySpending?
    @State private var animate = false
    @State private var showBudgetEditor = false
    @State private var isLoading = false
    @State private var hasError = false

    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }

    var demoData: [CategorySpending] {
        [
            CategorySpending(category: .housing, amount: 2100, budget: 2200, previousMonth: 2100, transactionCount: 2, topMerchants: ["Rent", "Renters Insurance"]),
            CategorySpending(category: .food, amount: 687, budget: 600, previousMonth: 542, transactionCount: 34, topMerchants: ["Whole Foods", "Chipotle", "Starbucks"]),
            CategorySpending(category: .transportation, amount: 312, budget: 400, previousMonth: 287, transactionCount: 12, topMerchants: ["Uber", "Shell", "Parking"]),
            CategorySpending(category: .shopping, amount: 445, budget: 300, previousMonth: 234, transactionCount: 8, topMerchants: ["Amazon", "Target", "Apple"]),
            CategorySpending(category: .utilities, amount: 156, budget: 200, previousMonth: 148, transactionCount: 4, topMerchants: ["Electric Co", "Internet", "Water"]),
            CategorySpending(category: .entertainment, amount: 89, budget: 150, previousMonth: 120, transactionCount: 5, topMerchants: ["Netflix", "Spotify", "AMC"]),
            CategorySpending(category: .health, amount: 125, budget: nil, previousMonth: 80, transactionCount: 3, topMerchants: ["Equinox", "CVS"]),
            CategorySpending(category: .subscriptions, amount: 87, budget: 100, previousMonth: 87, transactionCount: 6, topMerchants: ["Netflix", "Spotify", "iCloud"]),
        ]
    }

    var totalSpending: Double {
        demoData.reduce(0) { $0 + $1.amount }
    }

    var sortedData: [CategorySpending] {
        demoData.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    // Header
                    header
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // Period Selector
                    periodSelector
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.1), value: animate)

                    // Summary Card
                    summaryCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.15), value: animate)

                    // Pie Chart
                    pieChartSection
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.2), value: animate)

                    // Category List - Fixed scrolling by using explicit IDs
                    categoryList
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.25), value: animate)

                    // Insights
                    insightsSection
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.3), value: animate)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
            .refreshable {
                // Pull to refresh
                isLoading = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isLoading = false
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailSheet(category: category)
        }
        .sheet(isPresented: $showBudgetEditor) {
            BudgetEditorSheet(categories: demoData)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Categories")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Where your money goes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                showBudgetEditor = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation { selectedPeriod = period }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .furgCharcoal : .white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color.furgMint : Color.white.opacity(0.1))
                        )
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL SPENT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)

                Text(formatCurrency(totalSpending))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("+8.2%")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.furgWarning)

                Text("vs last month")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Pie Chart

    private var pieChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            Chart(sortedData) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(4)
            }
            .frame(height: 200)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(sortedData.prefix(6)) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 8, height: 8)

                        Text(item.category.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)

                        Spacer()

                        Text("\(Int((item.amount / totalSpending) * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            ForEach(sortedData) { item in
                Button {
                    selectedCategory = item
                } label: {
                    CategoryRow(item: item, total: totalSpending)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Spending Insights")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                InsightBubble(
                    icon: "exclamationmark.triangle.fill",
                    color: .furgWarning,
                    text: "Food & Dining is 14% over budget. Consider meal prepping to reduce restaurant spending."
                )

                InsightBubble(
                    icon: "checkmark.circle.fill",
                    color: .furgSuccess,
                    text: "Great job on Transportation! You're $88 under budget this month."
                )

                InsightBubble(
                    icon: "arrow.up.right.circle.fill",
                    color: .furgDanger,
                    text: "Shopping increased 90% vs last month. 3 purchases at Amazon totaled $234."
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Views

private struct CategoryRow: View {
    let item: CategorySpending
    let total: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: item.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(item.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.category.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    if item.isOverBudget {
                        Text("OVER")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.furgDanger))
                    }
                }

                HStack(spacing: 8) {
                    Text("\(item.transactionCount) transactions")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    if item.vsLastMonth != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: item.vsLastMonth > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(abs(Int(item.vsLastMonth)))%")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(item.vsLastMonth > 0 ? .furgWarning : .furgSuccess)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(item.amount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if let budget = item.budget {
                    Text("of \(formatCurrency(budget))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

private struct InsightBubble: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Category Detail Sheet

private struct CategoryDetailSheet: View {
    let category: CategorySpending
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(category.category.color.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: category.category.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(category.category.color)
                            }

                            Text(category.category.rawValue)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(formatCurrency(category.amount))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(category.isOverBudget ? .furgDanger : .white)
                        }
                        .padding(.top, 20)

                        // Budget Progress
                        if let budget = category.budget {
                            budgetProgress(spent: category.amount, budget: budget)
                        }

                        // Stats
                        HStack(spacing: 16) {
                            CategoryStatCard(title: "Transactions", value: "\(category.transactionCount)")
                            CategoryStatCard(title: "vs Last Month", value: "\(category.vsLastMonth > 0 ? "+" : "")\(Int(category.vsLastMonth))%", color: category.vsLastMonth > 0 ? .furgWarning : .furgSuccess)
                            CategoryStatCard(title: "Daily Avg", value: formatCurrency(category.amount / 30))
                        }

                        // Top Merchants
                        topMerchants

                        // Set Reminder
                        Button {
                            RemindersService.shared.createBudgetReminder()
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Set Budget Alert")
                            }
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

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle(category.category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }

    private func budgetProgress(spent: Double, budget: Double) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Budget Progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(Int((spent/budget) * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(spent > budget ? .furgDanger : .furgMint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(spent > budget ?
                              LinearGradient(colors: [.furgWarning, .furgDanger], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: min(geo.size.width * (spent / budget), geo.size.width))
                }
            }
            .frame(height: 12)

            HStack {
                Text(formatCurrency(spent))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(formatCurrency(budget))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var topMerchants: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Merchants")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            ForEach(category.topMerchants, id: \.self) { merchant in
                HStack {
                    Circle()
                        .fill(category.category.color.opacity(0.3))
                        .frame(width: 8, height: 8)

                    Text(merchant)
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.03))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

private struct CategoryStatCard: View {
    let title: String
    let value: String
    var color: Color = .white

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Budget Editor Sheet

private struct BudgetEditorSheet: View {
    let categories: [CategorySpending]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Set monthly budget limits for each category. FURG will alert you when you're approaching or exceeding them.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        ForEach(categories) { category in
                            BudgetEditRow(category: category)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .foregroundColor(.furgMint)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct BudgetEditRow: View {
    let category: CategorySpending
    @State private var budgetAmount: String = ""

    init(category: CategorySpending) {
        self.category = category
        _budgetAmount = State(initialValue: category.budget.map { String(Int($0)) } ?? "")
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: category.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(category.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text("Avg: $\(Int(category.amount))/mo")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            HStack(spacing: 4) {
                Text("$")
                    .foregroundColor(.white.opacity(0.5))

                TextField("0", text: $budgetAmount)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .foregroundColor(.white)
            }
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    CategoriesView()
}
