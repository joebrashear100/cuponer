//
//  DebtPayoffView.swift
//  Furg
//
//  Comprehensive debt tracking and payoff strategy view
//

import SwiftUI
import Charts

struct DebtPayoffView: View {
    @StateObject private var debtManager = DebtPayoffManager.shared
    @State private var selectedStrategy: PayoffStrategy = .avalanche
    @State private var extraPayment: Double = 0
    @State private var showAddDebt = false
    @State private var selectedDebt: Debt?
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Summary Header
                        debtSummaryCard
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Strategy Selector
                        strategySelector
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Payoff Projection Chart
                        projectionChart
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.15), value: animate)

                        // Extra Payment Slider
                        extraPaymentSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Debt List
                        debtList
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        // Recommendations
                        recommendationsSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Debt Payoff")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDebt = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.furgMint)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
                if debtManager.currentPlan == nil {
                    debtManager.createPayoffPlan(strategy: selectedStrategy, extraMonthlyPayment: extraPayment)
                }
            }
            .sheet(isPresented: $showAddDebt) {
                AddDebtView()
            }
            .sheet(item: $selectedDebt) { debt in
                DebtDetailView(debt: debt)
            }
        }
    }

    // MARK: - Summary Card

    private var debtSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Debt")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(debtManager.totalDebt))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Debt Free")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text(debtManager.debtFreeDate, style: .date)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.furgMint)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(debtManager.overallProgress * 100))% paid off")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("$\(Int(debtManager.totalPaidOff)) of $\(Int(debtManager.totalOriginalDebt))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.furgMint, .green], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * debtManager.overallProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Stats row
            HStack(spacing: 0) {
                StatItem(label: "Monthly Min", value: "$\(Int(debtManager.totalMinimumPayments))")
                Divider().background(Color.white.opacity(0.2)).frame(height: 30)
                StatItem(label: "Avg APR", value: String(format: "%.1f%%", debtManager.averageInterestRate * 100))
                Divider().background(Color.white.opacity(0.2)).frame(height: 30)
                StatItem(label: "Monthly Interest", value: "$\(Int(debtManager.totalMonthlyInterest))")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [.furgDanger.opacity(0.3), .furgCharcoal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Strategy Selector

    private var strategySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payoff Strategy")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 10) {
                ForEach([PayoffStrategy.snowball, .avalanche], id: \.self) { strategy in
                    Button {
                        withAnimation {
                            selectedStrategy = strategy
                            debtManager.createPayoffPlan(strategy: strategy, extraMonthlyPayment: extraPayment)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: strategy == .snowball ? "snow" : "mountain.2.fill")
                                .font(.system(size: 20))

                            Text(strategy.rawValue)
                                .font(.system(size: 13, weight: .medium))

                            Text(strategy == .snowball ? "Quick wins" : "Save interest")
                                .font(.system(size: 10))
                                .foregroundColor(selectedStrategy == strategy ? .furgCharcoal.opacity(0.7) : .white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(selectedStrategy == strategy ? .furgCharcoal : .white.opacity(0.7))
                        .background(selectedStrategy == strategy ? Color.furgMint : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Projection Chart

    private var projectionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payoff Projection")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            if !debtManager.projections.isEmpty {
                Chart {
                    ForEach(Array(Set(debtManager.projections.map { $0.debtName })), id: \.self) { debtName in
                        let debtProjections = debtManager.projections.filter { $0.debtName == debtName }
                        ForEach(debtProjections.enumerated().filter { $0.offset % 3 == 0 }.map { $0.element }) { projection in
                            LineMark(
                                x: .value("Month", projection.month),
                                y: .value("Balance", projection.remainingBalance)
                            )
                            .foregroundStyle(by: .value("Debt", projection.debtName))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(Int(amount / 1000))k")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let month = value.as(Int.self), month % 12 == 0 {
                                Text("Y\(month / 12)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .frame(height: 180)
            } else {
                Text("Add debts to see projection")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Extra Payment Section

    private var extraPaymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Extra Monthly Payment")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text("$\(Int(extraPayment))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.furgMint)
            }

            Slider(value: $extraPayment, in: 0...500, step: 25)
                .tint(.furgMint)
                .onChange(of: extraPayment) { _, newValue in
                    debtManager.createPayoffPlan(strategy: selectedStrategy, extraMonthlyPayment: newValue)
                }

            if let plan = debtManager.currentPlan, extraPayment > 0 {
                HStack(spacing: 16) {
                    Label {
                        Text("Save $\(Int(plan.totalInterestSaved))")
                            .font(.system(size: 12, weight: .medium))
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.furgSuccess)
                    }
                    .foregroundColor(.furgSuccess)

                    Label {
                        Text("\(plan.monthsToDebtFree) months faster")
                            .font(.system(size: 12, weight: .medium))
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.furgMint)
                    }
                    .foregroundColor(.furgMint)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Debt List

    private var debtList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Debts")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            ForEach(debtManager.debts.filter { $0.isActive }) { debt in
                DebtRow(debt: debt)
                    .onTapGesture {
                        selectedDebt = debt
                    }
            }

            if debtManager.debts.filter({ $0.isActive }).isEmpty {
                Text("No active debts. Add one to get started!")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        let recommendations = debtManager.getRecommendations()
        guard !recommendations.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.furgMint)
                    Text("Recommendations")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                ForEach(recommendations, id: \.self) { recommendation in
                    Text(recommendation)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        )
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct DebtRow: View {
    let debt: Debt

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: debt.type.icon)
                .font(.system(size: 18))
                .foregroundColor(colorFromString(debt.color))
                .frame(width: 44, height: 44)
                .background(colorFromString(debt.color).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(debt.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", debt.interestRate * 100))% APR")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text("$\(Int(debt.minimumPayment))/mo")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(debt.currentBalance))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(Int(debt.percentPaid * 100))% paid")
                    .font(.system(size: 11))
                    .foregroundColor(.furgMint)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        default: return .gray
        }
    }
}

// MARK: - Add Debt View

struct AddDebtView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var debtManager = DebtPayoffManager.shared

    @State private var name = ""
    @State private var type: DebtType = .creditCard
    @State private var currentBalance = ""
    @State private var originalBalance = ""
    @State private var interestRate = ""
    @State private var minimumPayment = ""
    @State private var dueDay = 15
    @State private var lender = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Name
                        FurgTextField(placeholder: "Debt Name", text: $name, icon: "textformat")

                        // Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debt Type")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(DebtType.allCases, id: \.self) { debtType in
                                        Button {
                                            type = debtType
                                        } label: {
                                            VStack(spacing: 6) {
                                                Image(systemName: debtType.icon)
                                                    .font(.system(size: 18))
                                                Text(debtType.rawValue)
                                                    .font(.system(size: 11))
                                            }
                                            .foregroundColor(type == debtType ? .furgCharcoal : .white.opacity(0.7))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(type == debtType ? Color.furgMint : Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            }
                        }

                        // Amounts
                        HStack(spacing: 12) {
                            FurgTextField(placeholder: "Current Balance", text: $currentBalance, icon: "dollarsign")
                            FurgTextField(placeholder: "Original Balance", text: $originalBalance, icon: "dollarsign")
                        }

                        HStack(spacing: 12) {
                            FurgTextField(placeholder: "APR %", text: $interestRate, icon: "percent")
                            FurgTextField(placeholder: "Min Payment", text: $minimumPayment, icon: "dollarsign")
                        }

                        // Lender
                        FurgTextField(placeholder: "Lender Name", text: $lender, icon: "building.2")

                        // Due Day
                        HStack {
                            Text("Due Day of Month")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Picker("", selection: $dueDay) {
                                ForEach(1...31, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.furgMint)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDebt()
                    }
                    .foregroundColor(.furgMint)
                    .disabled(name.isEmpty || currentBalance.isEmpty)
                }
            }
        }
    }

    private func saveDebt() {
        let debt = Debt(
            id: UUID(),
            name: name,
            type: type,
            originalBalance: Double(originalBalance) ?? Double(currentBalance) ?? 0,
            currentBalance: Double(currentBalance) ?? 0,
            interestRate: (Double(interestRate) ?? 0) / 100,
            minimumPayment: Double(minimumPayment) ?? 0,
            dueDay: dueDay,
            lender: lender,
            accountNumber: nil,
            startDate: Date(),
            notes: nil,
            isActive: true,
            color: type.defaultColor
        )

        debtManager.addDebt(debt)
        dismiss()
    }
}

// MARK: - Debt Detail View

struct DebtDetailView: View {
    let debt: Debt
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: debt.type.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.furgMint)

                            Text(debt.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(debt.lender)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)

                        // Balance Card
                        VStack(spacing: 12) {
                            Text("Current Balance")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))

                            Text("$\(String(format: "%.2f", debt.currentBalance))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            // Progress
                            VStack(spacing: 4) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.furgMint)
                                            .frame(width: geo.size.width * debt.percentPaid)
                                    }
                                }
                                .frame(height: 8)

                                Text("\(Int(debt.percentPaid * 100))% paid off")
                                    .font(.system(size: 11))
                                    .foregroundColor(.furgMint)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )

                        // Details Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DetailCard(label: "Interest Rate", value: String(format: "%.2f%%", debt.interestRate * 100), icon: "percent")
                            DetailCard(label: "Minimum Payment", value: "$\(Int(debt.minimumPayment))", icon: "creditcard")
                            DetailCard(label: "Monthly Interest", value: "$\(Int(debt.monthlyInterest))", icon: "chart.line.uptrend.xyaxis")
                            DetailCard(label: "Payoff Date", value: formatDate(debt.payoffDate), icon: "calendar")
                        }

                        // Record Payment Button
                        Button {
                            // Record payment action
                        } label: {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                Text("Record Payment")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgCharcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.furgMint)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

struct DetailCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.furgMint)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DebtPayoffView()
}
