//
//  FinancialHealthView.swift
//  Furg
//
//  Comprehensive financial health score dashboard
//

import SwiftUI
import Charts

struct FinancialHealthView: View {
    @StateObject private var healthManager = FinancialHealthManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedComponent: ScoreComponent?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Main score card
                        mainScoreCard
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Score history chart
                        scoreHistoryCard
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Score breakdown
                        scoreBreakdownSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Recommendations
                        if !healthManager.recommendations.isEmpty {
                            recommendationsSection
                                .offset(y: animate ? 0 : 20)
                                .opacity(animate ? 1 : 0)
                                .animation(.spring(response: 0.6).delay(0.3), value: animate)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Financial Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Main Score Card

    private var mainScoreCard: some View {
        VStack(spacing: 24) {
            // Grade and score
            HStack(spacing: 24) {
                // Grade circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: animate ? Double(healthManager.healthScore) / 100 : 0)
                        .stroke(
                            AngularGradient(
                                colors: [healthManager.healthGrade.color, healthManager.healthGrade.color.opacity(0.5)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0).delay(0.3), value: animate)

                    VStack(spacing: 4) {
                        Text(healthManager.healthGrade.rawValue)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(healthManager.healthGrade.color)

                        Text("\(healthManager.healthScore)/100")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(healthManager.healthGrade.description)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("Your financial health score is based on savings, debt, budget adherence, and more.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(3)

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundColor(.furgSuccess)

                        Text("+3 from last month")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.furgSuccess)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(healthManager.healthGrade.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Score History

    private var scoreHistoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Score History")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("30 Days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Chart {
                ForEach(healthManager.scoreHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Color.furgMint)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 50, 100]) { value in
                    AxisValueLabel {
                        if let score = value.as(Int.self) {
                            Text("\(score)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .frame(height: 150)
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

    // MARK: - Score Breakdown

    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(healthManager.scoreBreakdown) { component in
                    ComponentRow(component: component, isSelected: selectedComponent?.id == component.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedComponent?.id == component.id {
                                    selectedComponent = nil
                                } else {
                                    selectedComponent = component
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommendations")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(healthManager.recommendations.count) tips")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(spacing: 12) {
                ForEach(healthManager.recommendations) { rec in
                    RecommendationRow(recommendation: rec)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ComponentRow: View {
    let component: ScoreComponent
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(component.status.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: component.icon)
                        .font(.system(size: 16))
                        .foregroundColor(component.status.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(component.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(component.detail)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(component.score)/\(component.maxScore)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(component.status.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(component.status.color)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(component.status.color)
                        .frame(width: geometry.size.width * component.percentage)
                }
            }
            .frame(height: 6)

            // Expanded content
            if isSelected, let rec = component.recommendation {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.furgWarning)

                    Text(rec)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }
                .padding(12)
                .background(Color.furgWarning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? component.status.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
                )
        )
    }
}

struct RecommendationRow: View {
    let recommendation: HealthRecommendation

    var body: some View {
        HStack(spacing: 14) {
            // Priority indicator
            Rectangle()
                .fill(recommendation.priority.color)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: recommendation.icon)
                        .font(.system(size: 12))
                        .foregroundColor(recommendation.priority.color)

                    Text(recommendation.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(recommendation.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))

                Text(recommendation.impact)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.furgMint)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    FinancialHealthView()
}
