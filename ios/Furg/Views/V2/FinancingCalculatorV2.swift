//
//  FinancingCalculatorV2.swift
//  Furg
//
//  Loan and payment calculator
//

import SwiftUI
import Charts

struct FinancingCalculatorV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var loanAmount: Double = 25000
    @State private var interestRate: Double = 6.5
    @State private var loanTermMonths: Int = 60
    @State private var showAmortization = false

    var monthlyPayment: Double {
        let principal = loanAmount
        let monthlyRate = interestRate / 100 / 12
        let numPayments = Double(loanTermMonths)

        if monthlyRate == 0 {
            return principal / numPayments
        }

        let payment = principal * (monthlyRate * pow(1 + monthlyRate, numPayments)) / (pow(1 + monthlyRate, numPayments) - 1)
        return payment
    }

    var totalPayment: Double {
        monthlyPayment * Double(loanTermMonths)
    }

    var totalInterest: Double {
        totalPayment - loanAmount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Result card
                    resultCard

                    // Inputs
                    inputsSection

                    // Breakdown chart
                    breakdownChart

                    // Comparison
                    comparisonSection

                    // Amortization button
                    Button {
                        showAmortization = true
                    } label: {
                        HStack {
                            Image(systemName: "tablecells")
                            Text("View Amortization Schedule")
                        }
                        .font(.v2Body)
                        .foregroundColor(.v2Primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.v2Primary.opacity(0.12))
                        .cornerRadius(14)
                    }
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Loan Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showAmortization) {
                AmortizationScheduleV2(
                    principal: loanAmount,
                    rate: interestRate,
                    months: loanTermMonths
                )
                .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - Result Card

    var resultCard: some View {
        V2Card(padding: 24) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Monthly Payment")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.v2Primary)
                        Text(String(format: "%.0f", monthlyPayment))
                            .font(.v2DisplayLarge)
                            .foregroundColor(.v2TextPrimary)
                    }

                    Text("/month for \(loanTermMonths) months")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }

                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Total Payment")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                        Text("$\(Int(totalPayment))")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)
                    }

                    VStack(spacing: 4) {
                        Text("Total Interest")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                        Text("$\(Int(totalInterest))")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Danger)
                    }

                    VStack(spacing: 4) {
                        Text("Interest %")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                        Text(String(format: "%.1f%%", (totalInterest / loanAmount) * 100))
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Warning)
                    }
                }
            }
        }
    }

    // MARK: - Inputs Section

    var inputsSection: some View {
        V2Card {
            VStack(spacing: 24) {
                // Loan amount
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Loan Amount")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)
                        Spacer()
                        Text("$\(Int(loanAmount))")
                            .font(.v2MetricMedium)
                            .foregroundColor(.v2Primary)
                    }

                    Slider(value: $loanAmount, in: 1000...100000, step: 1000)
                        .tint(.v2Primary)
                }

                Divider().background(Color.white.opacity(0.1))

                // Interest rate
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Interest Rate")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)
                        Spacer()
                        Text(String(format: "%.1f%%", interestRate))
                            .font(.v2MetricMedium)
                            .foregroundColor(.v2Primary)
                    }

                    Slider(value: $interestRate, in: 0...30, step: 0.1)
                        .tint(.v2Primary)
                }

                Divider().background(Color.white.opacity(0.1))

                // Loan term
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Loan Term")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)
                        Spacer()
                        Text("\(loanTermMonths) months")
                            .font(.v2MetricMedium)
                            .foregroundColor(.v2Primary)
                    }

                    HStack(spacing: 8) {
                        ForEach([12, 24, 36, 48, 60, 72], id: \.self) { months in
                            Button {
                                loanTermMonths = months
                            } label: {
                                Text("\(months)mo")
                                    .font(.v2Caption)
                                    .foregroundColor(loanTermMonths == months ? .v2TextInverse : .v2TextSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(loanTermMonths == months ? Color.v2Primary : Color.v2BackgroundSecondary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Breakdown Chart

    var breakdownChart: some View {
        V2Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Payment Breakdown")
                    .font(.v2Headline)
                    .foregroundColor(.v2TextPrimary)

                HStack(spacing: 20) {
                    // Donut chart
                    ZStack {
                        Circle()
                            .stroke(Color.v2Danger, lineWidth: 20)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: loanAmount / totalPayment)
                            .stroke(Color.v2Primary, lineWidth: 20)
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.v2Primary)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Principal")
                                    .font(.v2Caption)
                                    .foregroundColor(.v2TextSecondary)
                                Text("$\(Int(loanAmount))")
                                    .font(.v2BodyBold)
                                    .foregroundColor(.v2TextPrimary)
                            }
                        }

                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.v2Danger)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Interest")
                                    .font(.v2Caption)
                                    .foregroundColor(.v2TextSecondary)
                                Text("$\(Int(totalInterest))")
                                    .font(.v2BodyBold)
                                    .foregroundColor(.v2TextPrimary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Comparison Section

    var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Comparison")
                .font(.v2Headline)
                .foregroundColor(.v2TextPrimary)

            HStack(spacing: 12) {
                ComparisonCard(
                    title: "36 months",
                    payment: calculatePayment(months: 36),
                    interest: calculateInterest(months: 36),
                    isSelected: loanTermMonths == 36
                ) {
                    loanTermMonths = 36
                }

                ComparisonCard(
                    title: "60 months",
                    payment: calculatePayment(months: 60),
                    interest: calculateInterest(months: 60),
                    isSelected: loanTermMonths == 60
                ) {
                    loanTermMonths = 60
                }
            }
        }
    }

    func calculatePayment(months: Int) -> Double {
        let monthlyRate = interestRate / 100 / 12
        let numPayments = Double(months)
        if monthlyRate == 0 { return loanAmount / numPayments }
        return loanAmount * (monthlyRate * pow(1 + monthlyRate, numPayments)) / (pow(1 + monthlyRate, numPayments) - 1)
    }

    func calculateInterest(months: Int) -> Double {
        return calculatePayment(months: months) * Double(months) - loanAmount
    }
}

// MARK: - Comparison Card

struct ComparisonCard: View {
    let title: String
    let payment: Double
    let interest: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.v2Caption)
                    .foregroundColor(isSelected ? .v2Primary : .v2TextSecondary)

                Text("$\(Int(payment))/mo")
                    .font(.v2BodyBold)
                    .foregroundColor(isSelected ? .v2Primary : .v2TextPrimary)

                Text("$\(Int(interest)) interest")
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.v2CardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.v2Primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Amortization Schedule

struct AmortizationScheduleV2: View {
    let principal: Double
    let rate: Double
    let months: Int
    @Environment(\.dismiss) var dismiss

    var schedule: [(month: Int, payment: Double, principal: Double, interest: Double, balance: Double)] {
        var result: [(Int, Double, Double, Double, Double)] = []
        let monthlyRate = rate / 100 / 12
        let numPayments = Double(months)

        var balance = principal
        let monthlyPayment: Double

        if monthlyRate == 0 {
            monthlyPayment = principal / numPayments
        } else {
            monthlyPayment = principal * (monthlyRate * pow(1 + monthlyRate, numPayments)) / (pow(1 + monthlyRate, numPayments) - 1)
        }

        for month in 1...months {
            let interestPayment = balance * monthlyRate
            let principalPayment = monthlyPayment - interestPayment
            balance -= principalPayment

            result.append((month, monthlyPayment, principalPayment, interestPayment, max(balance, 0)))
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Month")
                            .frame(width: 50, alignment: .leading)
                        Text("Principal")
                            .frame(maxWidth: .infinity)
                        Text("Interest")
                            .frame(maxWidth: .infinity)
                        Text("Balance")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.v2CardBackground)

                    ForEach(schedule, id: \.month) { row in
                        HStack {
                            Text("\(row.month)")
                                .frame(width: 50, alignment: .leading)
                            Text("$\(Int(row.principal))")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.v2Primary)
                            Text("$\(Int(row.interest))")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.v2Danger)
                            Text("$\(Int(row.balance))")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(.v2Caption)
                        .foregroundColor(.v2TextPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
            .background(Color.v2Background)
            .navigationTitle("Amortization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FinancingCalculatorV2()
}
