//
//  IncomeTrackerView.swift
//  Furg
//
//  Track multiple income sources and predict paydays
//

import SwiftUI
import Charts

struct IncomeTrackerView: View {
    @StateObject private var incomeManager = IncomeManager.shared
    @State private var showAddIncome = false
    @State private var selectedSource: IncomeSource?
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Income Summary
                        incomeSummaryCard
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Upcoming Paydays
                        upcomingPaydaysSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Income Sources
                        incomeSourcesSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.15), value: animate)

                        // Income Breakdown Chart
                        incomeBreakdownChart
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Recommendations
                        if let recommendations = getRecommendations(), !recommendations.isEmpty {
                            recommendationsSection(recommendations)
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.25), value: animate)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Income")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddIncome = true
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
            }
            .sheet(isPresented: $showAddIncome) {
                AddIncomeSourceView()
            }
            .sheet(item: $selectedSource) { source in
                IncomeSourceDetailView(source: source)
            }
        }
    }

    // MARK: - Income Summary Card

    private var incomeSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Income")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(incomeManager.totalMonthlyIncome))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if let daysUntil = incomeManager.getDaysUntilNextPayday() {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next Payday")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        Text(daysUntil == 0 ? "Today!" : "\(daysUntil) days")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.furgSuccess)
                    }
                }
            }

            if let summary = incomeManager.summary {
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("$\(Int(summary.totalAnnualGross))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Annual")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)

                    Divider().background(Color.white.opacity(0.2)).frame(height: 30)

                    VStack(spacing: 4) {
                        Text("\(Int(summary.diversificationScore))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.furgMint)
                        Text("Diversified")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)

                    Divider().background(Color.white.opacity(0.2)).frame(height: 30)

                    VStack(spacing: 4) {
                        Text("\(Int(summary.stabilityScore))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.furgSuccess)
                        Text("Stable")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [.furgSuccess.opacity(0.3), .furgCharcoal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Upcoming Paydays

    private var upcomingPaydaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Paydays")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            if incomeManager.upcomingPaydays.isEmpty {
                Text("No upcoming paydays")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
            } else {
                ForEach(incomeManager.upcomingPaydays.prefix(4)) { payday in
                    PaydayRow(payday: payday)
                }
            }
        }
    }

    // MARK: - Income Sources

    private var incomeSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Income Sources")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text("\(incomeManager.activeSourceCount) active")
                    .font(.system(size: 12))
                    .foregroundColor(.furgMint)
            }

            ForEach(incomeManager.incomeSources.filter { $0.isActive }) { source in
                IncomeSourceRow(source: source)
                    .onTapGesture {
                        selectedSource = source
                    }
            }

            if incomeManager.incomeSources.filter({ $0.isActive }).isEmpty {
                Button {
                    showAddIncome = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Income Source")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.furgMint)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.furgMint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Income Breakdown Chart

    private var incomeBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Income by Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            if let summary = incomeManager.summary, !summary.incomeByType.isEmpty {
                Chart {
                    ForEach(Array(summary.incomeByType.sorted { $0.value > $1.value }), id: \.key) { type, amount in
                        SectorMark(
                            angle: .value("Amount", amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(colorForIncomeType(type))
                        .annotation(position: .overlay) {
                            if amount / summary.totalMonthlyGross > 0.15 {
                                Text("\(Int(amount / summary.totalMonthlyGross * 100))%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 180)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(summary.incomeByType.sorted { $0.value > $1.value }), id: \.key) { type, amount in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForIncomeType(type))
                                .frame(width: 8, height: 8)
                            Text(type.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("$\(Int(amount))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
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

    // MARK: - Recommendations

    private func recommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.furgMint)
                Text("Insights")
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
    }

    // MARK: - Helpers

    private func getRecommendations() -> [String]? {
        return incomeManager.getIncomeRecommendations()
    }

    private func colorForIncomeType(_ type: IncomeType) -> Color {
        switch type {
        case .salary: return .blue
        case .hourly: return .green
        case .freelance: return .purple
        case .sideGig: return .orange
        case .rental: return .brown
        case .investment: return .mint
        case .dividends: return .teal
        case .pension: return .gray
        case .bonus: return .yellow
        case .commission: return .cyan
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

struct PaydayRow: View {
    let payday: PaydayPrediction

    var body: some View {
        HStack(spacing: 14) {
            VStack {
                Text(dayString(from: payday.predictedDate))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Text(dayNumber(from: payday.predictedDate))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(payday.isUpcoming ? .furgMint : .white)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(payday.sourceName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    if payday.isUpcoming {
                        Text("UPCOMING")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.furgCharcoal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.furgMint)
                            .clipShape(Capsule())
                    }

                    Text("\(Int(payday.confidence * 100))% confident")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Text("$\(Int(payday.expectedAmount))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.furgSuccess)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(payday.isUpcoming ? Color.furgMint.opacity(0.1) : Color.white.opacity(0.05))
        )
    }

    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct IncomeSourceRow: View {
    let source: IncomeSource

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: source.type.icon)
                .font(.system(size: 18))
                .foregroundColor(colorFromString(source.color))
                .frame(width: 44, height: 44)
                .background(colorFromString(source.color).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(source.type.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text(source.frequency.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(source.amount))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("$\(Int(source.monthlyAmount))/mo")
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
        case "brown": return .brown
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Add Income Source View

struct AddIncomeSourceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var incomeManager = IncomeManager.shared

    @State private var name = ""
    @State private var type: IncomeType = .salary
    @State private var amount = ""
    @State private var frequency: PayFrequency = .biweekly
    @State private var employer = ""
    @State private var taxWithholding = ""
    @State private var nextPayday = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FurgTextField("Income Source Name", text: $name, icon: "textformat")

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Income Type")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(IncomeType.allCases, id: \.self) { incomeType in
                                        Button {
                                            type = incomeType
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: incomeType.icon)
                                                    .font(.system(size: 16))
                                                Text(incomeType.rawValue)
                                                    .font(.system(size: 10))
                                                    .lineLimit(1)
                                            }
                                            .foregroundColor(type == incomeType ? .furgCharcoal : .white.opacity(0.7))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(type == incomeType ? Color.furgMint : Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            FurgTextField("Amount", text: $amount, icon: "dollarsign")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Frequency")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))

                                Picker("", selection: $frequency) {
                                    ForEach(PayFrequency.allCases, id: \.self) { freq in
                                        Text(freq.rawValue).tag(freq)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.furgMint)
                            }
                        }

                        FurgTextField("Employer (optional)", text: $employer, icon: "building.2")

                        FurgTextField("Tax Withholding %", text: $taxWithholding, icon: "percent")

                        DatePicker("Next Payday", selection: $nextPayday, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .foregroundColor(.white)
                            .tint(.furgMint)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveIncome()
                    }
                    .foregroundColor(.furgMint)
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    private func saveIncome() {
        let source = IncomeSource(
            id: UUID(),
            name: name,
            type: type,
            amount: Double(amount) ?? 0,
            frequency: frequency,
            nextPayday: nextPayday,
            employer: employer.isEmpty ? nil : employer,
            accountDepositId: nil,
            isActive: true,
            taxWithholdingPercent: (Double(taxWithholding) ?? 20) / 100,
            notes: nil,
            color: type.defaultColor
        )

        incomeManager.addIncomeSource(source)
        dismiss()
    }
}

// MARK: - Income Source Detail View

struct IncomeSourceDetailView: View {
    let source: IncomeSource
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: source.type.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.furgSuccess)

                            Text(source.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            if let employer = source.employer {
                                Text(employer)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 20)

                        // Amount Cards
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("Per Paycheck")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("$\(Int(source.amount))")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(spacing: 4) {
                                Text("Monthly")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("$\(Int(source.monthlyAmount))")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.furgSuccess)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.furgSuccess.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Details
                        VStack(spacing: 12) {
                            IncomeDetailRow(label: "Type", value: source.type.rawValue)
                            IncomeDetailRow(label: "Frequency", value: source.frequency.rawValue)
                            IncomeDetailRow(label: "Annual Income", value: "$\(Int(source.annualAmount))")
                            IncomeDetailRow(label: "Tax Withholding", value: "\(Int(source.taxWithholdingPercent * 100))%")
                            IncomeDetailRow(label: "Net per Paycheck", value: "$\(Int(source.netAmount))")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Upcoming Paydays
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Paydays")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))

                            ForEach(source.getNextPaydays(count: 4), id: \.self) { date in
                                HStack {
                                    Text(formatDate(date))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("$\(Int(source.netAmount))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.furgSuccess)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

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
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

private struct IncomeDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    IncomeTrackerView()
}
