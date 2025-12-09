//
//  CreditFactorsDetailView.swift
//  Furg
//
//  Detailed credit score factors with improvement tips and history
//

import SwiftUI
import Charts

struct CreditFactorsDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedFactor: DetailedCreditFactor?

    // Demo data
    let creditScore = 752
    let scoreHistory: [ScoreHistoryPoint] = {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { i in
            ScoreHistoryPoint(
                date: calendar.date(byAdding: .month, value: -i, to: now)!,
                score: 720 + Int.random(in: -10...35)
            )
        }
    }()

    let factors: [DetailedCreditFactor] = [
        DetailedCreditFactor(
            name: "Payment History",
            status: .excellent,
            weight: 35,
            currentValue: "100%",
            description: "Your track record of paying bills on time",
            details: "You've made 48 on-time payments with no missed or late payments in the last 7 years.",
            tips: [
                "Continue making all payments on time",
                "Set up autopay for recurring bills",
                "Even one late payment can impact your score significantly"
            ],
            icon: "checkmark.circle.fill",
            history: [100, 100, 100, 100, 100, 100]
        ),
        DetailedCreditFactor(
            name: "Credit Utilization",
            status: .good,
            weight: 30,
            currentValue: "23%",
            description: "How much of your available credit you're using",
            details: "You're using $3,450 of your $15,000 total available credit across 2 credit cards.",
            tips: [
                "Keep utilization below 30%, ideally under 10%",
                "Consider requesting a credit limit increase",
                "Pay down balances before statement closing date"
            ],
            icon: "chart.bar.fill",
            history: [28, 25, 30, 22, 19, 23]
        ),
        DetailedCreditFactor(
            name: "Credit Age",
            status: .fair,
            weight: 15,
            currentValue: "4.2 years",
            description: "The average age of all your credit accounts",
            details: "Your oldest account is 7 years old. Your newest is 6 months old. Average age: 4.2 years.",
            tips: [
                "Avoid opening too many new accounts",
                "Keep old accounts open, even if unused",
                "Time is your friend - this improves naturally"
            ],
            icon: "clock.fill",
            history: [3.8, 3.9, 4.0, 4.1, 4.1, 4.2]
        ),
        DetailedCreditFactor(
            name: "Credit Mix",
            status: .good,
            weight: 10,
            currentValue: "3 types",
            description: "The variety of credit accounts you have",
            details: "You have 2 credit cards, 1 auto loan, and 1 student loan. A good mix of revolving and installment credit.",
            tips: [
                "Having different types of credit helps your score",
                "Don't open new accounts just to improve mix",
                "Quality over quantity matters"
            ],
            icon: "square.stack.3d.up.fill",
            history: [2, 2, 3, 3, 3, 3]
        ),
        DetailedCreditFactor(
            name: "Hard Inquiries",
            status: .excellent,
            weight: 10,
            currentValue: "1",
            description: "Recent applications for new credit",
            details: "You have 1 hard inquiry from 8 months ago. Hard inquiries fall off after 2 years.",
            tips: [
                "Only apply for credit when necessary",
                "Multiple inquiries for same loan type within 14-45 days count as one",
                "Checking your own score is a soft inquiry (no impact)"
            ],
            icon: "magnifyingglass",
            history: [2, 2, 1, 1, 1, 1]
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Score overview
                        scoreOverview
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Score history chart
                        scoreHistoryChart
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Factors breakdown
                        factorsBreakdown
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Score simulation
                        scoreSimulator
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Credit Score Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animate = true
                }
            }
            .sheet(item: $selectedFactor) { factor in
                FactorDetailSheet(factor: factor)
            }
        }
    }

    // MARK: - Score Overview

    private var scoreOverview: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 16)
                    .frame(width: 180, height: 180)

                // Score arc
                Circle()
                    .trim(from: 0, to: CGFloat(creditScore - 300) / 550)
                    .stroke(
                        AngularGradient(
                            colors: [.furgMint, .furgSeafoam, .furgSuccess],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(creditScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Very Good")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.furgMint)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text("+12 pts")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.furgSuccess)
                }
            }

            // Score ranges
            HStack(spacing: 0) {
                ForEach(ScoreRange.allCases, id: \.self) { range in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(range.color)
                            .frame(height: 4)

                        Text(range.label)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)

            Text("Score Range: 300 - 850")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Score History

    private var scoreHistoryChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score History")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Chart {
                ForEach(scoreHistory) { point in
                    LineMark(
                        x: .value("Month", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint.opacity(0.3), .furgMint.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(30)
                }
            }
            .chartYScale(domain: 650...800)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let score = value.as(Int.self) {
                            Text("\(score)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(height: 180)
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

    // MARK: - Factors Breakdown

    private var factorsBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Score Factors")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("Tap for details")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            ForEach(factors) { factor in
                Button {
                    selectedFactor = factor
                } label: {
                    FactorRow(factor: factor)
                }
                .buttonStyle(.plain)
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

    // MARK: - Score Simulator

    private var scoreSimulator: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.furgMint)
                Text("Score Simulator")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("See how actions could affect your score")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 12) {
                SimulatorRow(
                    action: "Pay off credit card balance",
                    impact: "+15 to +25 pts",
                    isPositive: true
                )

                SimulatorRow(
                    action: "Open new credit card",
                    impact: "-5 to -15 pts (short term)",
                    isPositive: false
                )

                SimulatorRow(
                    action: "Increase credit limit",
                    impact: "+5 to +10 pts",
                    isPositive: true
                )

                SimulatorRow(
                    action: "Miss a payment",
                    impact: "-60 to -110 pts",
                    isPositive: false
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.furgMint.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgMint.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Supporting Types

struct ScoreHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

enum ScoreRange: CaseIterable {
    case poor, fair, good, veryGood, excellent

    var label: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        case .excellent: return "Excellent"
        }
    }

    var color: Color {
        switch self {
        case .poor: return .furgDanger
        case .fair: return .orange
        case .good: return .furgWarning
        case .veryGood: return .furgSuccess
        case .excellent: return .furgMint
        }
    }
}

struct DetailedCreditFactor: Identifiable {
    let id = UUID()
    let name: String
    let status: FactorStatus
    let weight: Int
    let currentValue: String
    let description: String
    let details: String
    let tips: [String]
    let icon: String
    let history: [Double]
}

// MARK: - Supporting Views

private struct FactorRow: View {
    let factor: DetailedCreditFactor

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(factor.status.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: factor.icon)
                    .font(.system(size: 18))
                    .foregroundColor(factor.status.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(factor.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text(factor.currentValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                HStack {
                    Text("\(factor.weight)% of score")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    Text(statusLabel(factor.status))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(factor.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(factor.status.color.opacity(0.15))
                        )
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func statusLabel(_ status: FactorStatus) -> String {
        switch status {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

private struct SimulatorRow: View {
    let action: String
    let impact: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(isPositive ? .furgSuccess : .furgDanger)

            Text(action)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            Text(impact)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isPositive ? .furgSuccess : .furgDanger)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

private struct FactorDetailSheet: View {
    let factor: DetailedCreditFactor
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(factor.status.color.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: factor.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(factor.status.color)
                            }

                            Text(factor.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(factor.currentValue)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(factor.status.color)

                            Text(factor.description)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Text(factor.details)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Tips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.furgWarning)
                                Text("Tips to Improve")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            ForEach(factor.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.furgMint)

                                    Text(tip)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.furgWarning.opacity(0.1))
                        )

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle(factor.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

#Preview {
    CreditFactorsDetailView()
}
